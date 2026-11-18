package com.sumizuri.app.data.tracker

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.tracker.LibraryTitle
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.shareIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.math.floor

private const val Tag = "tracker"

// How many titles one step of linking the library searches, which is one request.
private const val SearchPart = 20

// When the whole list was last matched with the library, kept on this device.
private const val MatchedPrefix = "memo.tracker.matched."

// One title of several with the same name is taken when this many more people know it.
private const val KnownTimes = 10

// How far linking the library has got.
data class LinkProgress(val done: Int, val total: Int)

// What linking the library did: how many titles it linked, and how many wait for the person to pick.
// How long linking waits when a tracker asks it to slow down.
private const val SlowDownMs = 60_000L

data class LinkResult(
    val linked: Int,
    val left: Int,
    // The tracker asked to slow down twice, so the run stopped early, keeping what it had linked.
    val stopped: Boolean = false,
)

// How the last linking of the library ended.
sealed interface LinkOutcome {
    data class Done(val result: LinkResult) : LinkOutcome

    data class Failed(val problem: TrackerProblem) : LinkOutcome
}

// A name as titles are compared: small letters and digits only, so case, marks, spaces and the shape of quotes do not matter.
internal fun matchName(name: String): String = name.lowercase().filter { it.isLetterOrDigit() }

// Links titles of the library to the trackers by their names: to entries already on the list of the person, and, when asked, to titles found by a search, which the next sync adds to the list. Only a name that matches one of the names of the title on the tracker exactly links, so a guess is never made.
class TrackerLinker(
    private val db: AppDatabase,
    private val accounts: TrackerAccounts,
    private val settings: SettingsRepository,
    private val apis: TrackerApis,
    private val use: TrackerUse,
    private val scope: CoroutineScope,
    private val onLinked: () -> Unit,
) {
    private val lock = Mutex()
    private val mutable = MutableStateFlow<Map<TrackerId, LinkProgress>>(emptyMap())
    val progress: StateFlow<Map<TrackerId, LinkProgress>> = mutable

    // The library titles with no link to each tracker, read once and shared by the lists below while one of them is watched.
    private val noLink = TrackerId.entries.associateWith { tracker ->
        db.trackerLinks().observeUnlinked(tracker.id).shareIn(scope, SharingStarted.WhileSubscribed(KeepMs), replay = 1)
    }

    // The titles with no link to the tracker, of the kinds it is used for and not left out. The card and the page of the tracker share it.
    private val unlinkedFlows = TrackerId.entries.associateWith { tracker ->
        combine(noLink.getValue(tracker), use.kinds(tracker), use.leftOut(tracker)) { titles, kinds, out ->
            titles.filter { Kind.fromCode(it.kind) in kinds && it.id !in out }
        }.shareIn(scope, SharingStarted.WhileSubscribed(KeepMs), replay = 1)
    }

    fun unlinked(tracker: TrackerId): Flow<List<LibraryTitle>> = unlinkedFlows.getValue(tracker)

    // The titles the person left out of the tracker by hand, which the page offers to take back.
    fun leftOut(tracker: TrackerId): Flow<List<LibraryTitle>> = combine(
        noLink.getValue(tracker),
        use.leftOut(tracker),
    ) { titles, out -> titles.filter { it.id in out } }

    private suspend fun unlinkedOf(tracker: TrackerId): List<LibraryTitle> =
        use.filter(tracker, db.trackerLinks().unlinked(tracker.id))

    private val outcomes = MutableStateFlow<Map<TrackerId, LinkOutcome>>(emptyMap())
    val outcome: StateFlow<Map<TrackerId, LinkOutcome>> = outcomes

    // Links the library in the background, so it goes on when the page is left. Asking again while it runs does nothing. Titles a search found nothing for before are searched again only when asked.
    fun startLinking(tracker: TrackerId, again: Boolean = false) {
        if (tracker in mutable.value) return
        mutable.value = mutable.value + (tracker to LinkProgress(0, 0))
        scope.launch {
            val ended = try {
                LinkOutcome.Done(linkLibrary(tracker, again))
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                LinkOutcome.Failed(TrackerProblem.from(error))
            } finally {
                mutable.value = mutable.value - tracker
            }
            outcomes.value = outcomes.value + (tracker to ended)
        }
    }

    // Links one title to a title of the tracker. An entry the person already has there is taken as the rules say, and a new one starts from how far the title is read here. A title from a search already says whether it is on the list, so the tracker is only asked when it does not.
    suspend fun link(tracker: TrackerId, titleId: Long, kind: Kind, media: TrackerMedia) {
        val there = if (media.listKnown) {
            media.onList
        } else {
            val account = accounts.signedIn(tracker)
            apis.of(tracker).entries(account, listOf(media.id))[media.id]
        }
        put(tracker, titleId, kind, media, there, settings.trackerRules())
        AppLog.info(Tag, "linked a title to ${tracker.id} ${media.id}")
        onLinked()
    }

    // Links each title of the library whose name matches an entry on the list. Gives how many it linked.
    suspend fun matchList(tracker: TrackerId): Int = lock.withLock { matchListNow(tracker) }

    // Matches the whole list once, when the rules ask for it and it was never done, such as after updating the app while signed in. After that the changes of each sync are matched instead, which needs no more requests.
    suspend fun matchListIfDue(tracker: TrackerId) {
        if (!settings.trackerRules().matchList) return
        if (settings.textNow(MatchedPrefix + tracker.id) != null) return
        runCatching { matchList(tracker) }.onFailure { if (it is CancellationException) throw it }
    }

    // Links the whole library: first to the entries on the list, then each title left by a search on the tracker. A title with no sure match is left for the person.
    private suspend fun linkLibrary(tracker: TrackerId, again: Boolean): LinkResult = lock.withLock {
        var linked = matchListNow(tracker)
        var left = unlinkedOf(tracker)
        val taken = db
            .trackerLinks()
            .allOf(tracker.id)
            .map { it.remoteId }
            .toMutableSet()
        val rules = settings.trackerRules()
        var stopped = false
        // Titles linked to AniList are found here by their AniList ids first, in a few requests and with no guessing by name. Should that fail, the search by name below still finds them.
        val cross = try {
            crossFind(db, apis.of(tracker), tracker, accounts.signedIn(tracker), left)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            AppLog.warn(Tag, "${tracker.id} could not find titles by their AniList ids, ${error.message}")
            emptyList()
        }
        for (found in cross) {
            if (!taken.add(found.media.id)) continue
            put(tracker, found.title.id, Kind.fromCode(found.title.kind), found.media, found.entry, rules)
            linked++
        }
        if (cross.isNotEmpty()) left = unlinkedOf(tracker)
        if (!again) {
            val missed = use.missedNow(tracker)
            left = left.filter { it.id !in missed }
        }
        val searched = mutableSetOf<Long>()
        // The searches go many to a request, so a big library takes a few requests and not one for each title.
        for ((step, part) in left.chunked(SearchPart).withIndex()) {
            mutable.value = mutable.value + (tracker to LinkProgress(step * SearchPart, left.size))
            // A tracker that asks to slow down gets a minute, and the same titles are asked again once. A second refusal ends the run with what it linked kept.
            val found = try {
                searchExact(tracker, part)
            } catch (limited: TrackerProblem) {
                if (limited != TrackerProblem.Limited) throw limited
                AppLog.info(Tag, "${tracker.id} asked to slow down while linking, waiting a minute")
                delay(SlowDownMs)
                try {
                    searchExact(tracker, part)
                } catch (again: TrackerProblem) {
                    if (again != TrackerProblem.Limited) throw again
                    stopped = true
                    null
                }
            } ?: break
            searched += part.map { it.id }
            for (title in part) {
                val media = found[title.id] ?: continue
                if (!taken.add(media.id)) continue
                put(tracker, title.id, Kind.fromCode(title.kind), media, media.onList, rules)
                linked++
            }
        }
        if (linked > 0) onLinked()
        val stillLeft = unlinkedOf(tracker)
        use.markMissed(tracker, searched, stillLeft.map { it.id }.toSet())
        val result = LinkResult(linked, stillLeft.size, stopped)
        AppLog.info(Tag, "linked the library to ${tracker.id}, ${result.linked} linked and ${result.left} left")
        result
    }

    // Finds titles just added to the library on each tracker and links them when the rules ask for it.
    fun addedToLibrary(titleIds: List<Long>) {
        scope.launch {
            if (!settings.trackerRules().addNew) return@launch
            for (tracker in accounts.accounts.first().keys) {
                val waiting = unlinkedOf(tracker).filter { it.id in titleIds }
                if (waiting.isEmpty()) continue
                runCatching {
                    val found = searchExact(tracker, waiting)
                    for (title in waiting) {
                        found[title.id]?.let {
                            link(
                                tracker,
                                title.id,
                                Kind.fromCode(title.kind),
                                it,
                            )
                        }
                    }
                }.onFailure { if (it is CancellationException) throw it }
            }
        }
    }

    // Links titles of the library to entries that changed on the list, such as ones just added on the site, without reading the whole list.
    suspend fun matchEntries(tracker: TrackerId, items: List<Pair<RemoteEntry, TrackerMedia>>): Int = lock.withLock {
        val left = unlinkedOf(tracker)
        if (left.isEmpty()) return@withLock 0
        val taken = db
            .trackerLinks()
            .allOf(tracker.id)
            .map { it.remoteId }
            .toMutableSet()
        val rules = settings.trackerRules()
        var linked = 0
        for (anime in listOf(false, true)) {
            val fits = left.filter { (Kind.fromCode(it.kind) == Kind.Anime) == anime }
            val list = items.filter { (it.second.kindHere == Kind.Anime) == anime }
            if (fits.isNotEmpty() && list.isNotEmpty()) linked += linkByNames(tracker, fits, list, taken, rules)
        }
        if (linked > 0) {
            AppLog.info(Tag, "linked $linked titles to new entries on the list of ${tracker.id}")
            onLinked()
        }
        linked
    }

    // Links each title to the entry of the list with its name. A main name wins over another name the same, so a title is not taken for one that only goes by its name.
    private suspend fun linkByNames(
        tracker: TrackerId,
        titles: List<LibraryTitle>,
        list: List<Pair<RemoteEntry, TrackerMedia>>,
        taken: MutableSet<Long>,
        rules: TrackerRules,
    ): Int {
        // Names are kept with the kind of their title, so a novel and its manga of the same name each find their own.
        val byName = HashMap<Pair<Kind, String>, Pair<RemoteEntry, TrackerMedia>>()
        for (item in list) {
            for (name in item.second.names + item.second.name) {
                byName.getOrPut(item.second.kindHere to matchName(name)) { item }
            }
        }
        for (item in list) {
            for (name in item.second.synonyms) {
                byName.getOrPut(
                    item.second.kindHere to matchName(name),
                ) { item }
            }
        }
        var linked = 0
        for (title in titles) {
            val (entry, media) = byName[Kind.fromCode(title.kind) to matchName(title.name)] ?: continue
            if (!taken.add(media.id)) continue
            put(tracker, title.id, Kind.fromCode(title.kind), media, entry, rules)
            linked++
        }
        return linked
    }

    private suspend fun matchListNow(tracker: TrackerId): Int {
        val account = accounts.signedIn(tracker)
        val rules = settings.trackerRules()
        val left = unlinkedOf(tracker)
        val taken = db
            .trackerLinks()
            .allOf(tracker.id)
            .map { it.remoteId }
            .toMutableSet()
        var linked = 0
        if (left.isNotEmpty()) {
            for (anime in listOf(false, true)) {
                val fits = left.filter { (Kind.fromCode(it.kind) == Kind.Anime) == anime }
                if (fits.isEmpty()) continue
                val list = apis.of(tracker).collection(account, anime)
                linked += linkByNames(tracker, fits, list, taken, rules)
            }
        }
        settings.setText(MatchedPrefix + tracker.id, nowMillis().toString())
        if (linked > 0) {
            AppLog.info(Tag, "linked $linked titles to entries on the list of ${tracker.id}")
            onLinked()
        }
        return linked
    }

    // For each title, the one title of the tracker a search finds whose names hold its name exactly, when there is one. The searches go many to a request.
    private suspend fun searchExact(tracker: TrackerId, titles: List<LibraryTitle>): Map<Long, TrackerMedia> {
        val account = accounts.signedIn(tracker)
        val asked = titles.filter { matchName(it.name).isNotEmpty() }
        if (asked.isEmpty()) return emptyMap()
        val found = apis.of(tracker).searchMany(account, asked.map { searchWords(it.name) to Kind.fromCode(it.kind) })
        return asked
            .zip(found)
            .mapNotNull { (title, results) ->
                pickExact(matchName(title.name), results.filter { it.kindHere == Kind.fromCode(title.kind) })?.let {
                    title.id to
                        it
                }
            }.toMap()
    }

    private suspend fun put(
        tracker: TrackerId,
        titleId: Long,
        kind: Kind,
        media: TrackerMedia,
        there: RemoteEntry?,
        rules: TrackerRules,
    ) {
        val read = db.trackerLinks().readMarkOf(titleId)?.let { floor(it).toInt() } ?: 0
        val capped = media.total?.takeIf { it > 0 }?.let { read.coerceAtMost(it) } ?: read
        val base = TrackerLinkEntity(
            titleId = titleId,
            tracker = tracker.id,
            remoteId = media.id,
            remoteName = media.name,
            remoteCover = media.cover,
            remoteUrl = media.url,
            remoteTotal = media.total,
            kind = kind.code,
            status = if (capped > 0) TrackStatus.Current.code else TrackStatus.Planning.code,
            progress = capped,
            changedAt = nowMillis(),
        )
        db.trackerLinks().put(if (there == null) base else linkToEntry(base, there, capped, rules))
    }
}

// Curly quotes keep a search of the tracker from finding the title, so they are made straight.
private fun searchWords(name: String): String = name
    .map { letter ->
        when (letter.code) {
            0x2018, 0x2019 -> Char(0x27)
            0x201C, 0x201D -> Char(0x22)
            else -> letter
        }
    }.joinToString("")

// The one result whose names hold the name exactly. Of several, the one whose main name it is, or else one far better known than the rest, and none when it is not sure.
internal fun pickExact(key: String, results: List<TrackerMedia>): TrackerMedia? {
    val exact = results
        .filter { media ->
            (media.names + media.name + media.synonyms).any {
                matchName(it) == key
            }
        }.distinctBy { it.id }
    if (exact.size <= 1) return exact.singleOrNull()
    exact.filter { media -> (media.names + media.name).any { matchName(it) == key } }.singleOrNull()?.let { return it }
    val known = exact.sortedByDescending { it.popularity }
    return known.first().takeIf { it.popularity >= KnownTimes * known[1].popularity.coerceAtLeast(1) }
}
