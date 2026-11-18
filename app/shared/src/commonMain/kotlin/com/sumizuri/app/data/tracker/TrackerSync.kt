package com.sumizuri.app.data.tracker

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.download.canTellNetwork
import com.sumizuri.app.data.download.onUnmeteredNetwork
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.shareIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

private const val Tag = "tracker"

// A sync asked for after reading waits this long, so a few chapters in a row make one sync.
private const val AfterReadingMs = 30_000L

// A change made by hand is sent this soon.
private const val AfterChangeMs = 2_000L

// The log of each tracker is kept on this device only, as everything of sync that belongs to one device is.
private const val LogPrefix = "sync.trackerLog."
private const val LogKept = 30
private const val ConflictsKept = 20

// The order the entries of a list are shown in.
private val ListOrder = listOf(TrackStatus.Current, TrackStatus.Repeating, TrackStatus.Planning, TrackStatus.Paused, TrackStatus.Completed, TrackStatus.Dropped)

// Keeps the linked titles of this profile the same as their entries on the trackers, both ways. Each field that only one side changed since they last agreed is taken from that side. When both changed, progress keeps the further place and the rest keeps the newer change. Reading here moves progress on by itself.
class TrackerSync(
    private val db: AppDatabase,
    private val accounts: TrackerAccounts,
    private val settings: SettingsRepository,
    private val apis: TrackerApis,
    // Which titles each tracker is used for.
    val use: TrackerUse,
    private val scope: CoroutineScope,
) {
    private val lock = Mutex()
    private val runs = MutableStateFlow<Map<TrackerId, TrackerRun>>(emptyMap())
    val run: StateFlow<Map<TrackerId, TrackerRun>> = runs
    private var soon: Job? = null
    private val json = Json { ignoreUnknownKeys = true }
    private val logSerializer = ListSerializer(TrackerLogEntry.serializer())

    // The links of each tracker are read once and shared by its card, its page and its sheets, while one of them watches.
    private val linkFlows = TrackerId.entries.associateWith { tracker ->
        db.trackerLinks().observeAll(tracker.id).shareIn(scope, SharingStarted.WhileSubscribed(KeepMs), replay = 1)
    }

    fun links(tracker: TrackerId): Flow<List<TrackerLinkEntity>> = linkFlows.getValue(tracker)

    fun linksOf(titleId: Long): Flow<List<TrackerLinkEntity>> = db.trackerLinks().observeOf(titleId)

    // The log of each tracker is read once and shared by the pages that show it, while one does.
    private var logs: Map<TrackerId, Flow<List<TrackerLogEntry>>> = emptyMap()

    fun log(tracker: TrackerId): Flow<List<TrackerLogEntry>> = logs[tracker] ?: settings
        .text(LogPrefix + tracker.id)
        .map { text -> text?.let { runCatching { json.decodeFromString(logSerializer, it) }.getOrNull() }.orEmpty() }
        .shareIn(scope, SharingStarted.WhileSubscribed(KeepMs), replay = 1)
        .also { logs = logs + (tracker to it) }

    suspend fun search(tracker: TrackerId, name: String, kind: Kind): List<TrackerMedia> {
        val account = accounts.signedIn(tracker)
        return apis.of(tracker).search(account, name, kind)
    }

    // The entries of the list of the person on the tracker that no title here is linked to, those being read first.
    suspend fun unlinkedOn(tracker: TrackerId): List<OnTracker> {
        val account = accounts.signedIn(tracker)
        val linked = db.trackerLinks().allOf(tracker.id).map { it.remoteId }.toSet()
        val all = listOf(false, true).flatMap { anime ->
            apis.of(tracker).collection(account, anime).map { (entry, media) ->
                OnTracker(entry, media, if (anime) Kind.Anime else if (media.kindHere == Kind.Novel) Kind.Novel else Kind.Manga)
            }
        }
        return all.filter { it.entry.mediaId !in linked }.sortedWith(compareBy({ ListOrder.indexOf(TrackStatus.of(it.entry.status)) }, { it.media.name.lowercase() }))
    }

    // Links titles of the library to the trackers, one by one or all by their names.
    val linker = TrackerLinker(db, accounts, settings, apis, use, scope) { syncSoon(AfterChangeMs) }

    suspend fun link(tracker: TrackerId, titleId: Long, kind: Kind, media: TrackerMedia) = linker.link(tracker, titleId, kind, media)

    // Links an entry of the list on the tracker to a title of the library the person picked, keeping how the entry stands there.
    suspend fun linkEntry(tracker: TrackerId, titleId: Long, kind: Kind, item: OnTracker) =
        linker.link(tracker, titleId, kind, item.media.copy(listKnown = true, onList = item.entry))

    // Removes an entry from the list on the tracker that no title here is linked to.
    suspend fun removeOn(tracker: TrackerId, entry: RemoteEntry) =
        apis.of(tracker).delete(accounts.signedIn(tracker), entry.entryId, entry.mediaId)

    // Just after signing in, the library is matched with the list and synced, so the person sees it work at once.
    fun afterSignIn(tracker: TrackerId) {
        scope.launch {
            runCatching { linker.matchList(tracker) }.onFailure { if (it is CancellationException) throw it }
            syncAll()
        }
    }

    // A change the person made by hand, which is sent in a moment.
    suspend fun change(titleId: Long, tracker: TrackerId, status: String, progress: Int, score: Int) {
        val link = db.trackerLinks().get(titleId, tracker.id) ?: return
        db.trackerLinks().put(
            link.copy(
                status = status,
                progress = progress.coerceAtLeast(0),
                score = score.coerceIn(0, 100),
                changedAt = nowMillis(),
            ),
        )
        syncSoon(AfterChangeMs)
    }

    // Gives many linked titles one status, sent together in a moment.
    suspend fun changeStatus(tracker: TrackerId, titleIds: Collection<Long>, status: String) {
        val now = nowMillis()
        for (titleId in titleIds) {
            val link = db.trackerLinks().get(titleId, tracker.id) ?: continue
            if (link.status != status) db.trackerLinks().put(link.copy(status = status, changedAt = now))
        }
        syncSoon(AfterChangeMs)
    }

    // Unlinks many titles one after another, and says how many could not be removed on the tracker. Those stay linked.
    suspend fun unlinkMany(tracker: TrackerId, titleIds: Collection<Long>, removeThere: Boolean): Int = titleIds.count { titleId ->
        runCatching { unlink(titleId, tracker, removeThere) }
            .onFailure { if (it is CancellationException) throw it }
            .isFailure
    }

    // Unlinks a title, and removes its entry on the tracker too when asked.
    suspend fun unlink(titleId: Long, tracker: TrackerId, removeThere: Boolean) {
        val link = db.trackerLinks().get(titleId, tracker.id) ?: return
        val entry = link.entryId
        if (removeThere && entry != null && !link.gone) {
            val account = accounts.signedIn(tracker)
            apis.of(tracker).delete(account, entry, link.remoteId)
        }
        db.trackerLinks().delete(titleId, tracker.id)
    }

    // Puts an entry that was removed on the tracker back from what this device holds.
    suspend fun addAgain(titleId: Long, tracker: TrackerId) {
        val link = db.trackerLinks().get(titleId, tracker.id) ?: return
        db.trackerLinks().put(
            link.copy(
                entryId = null,
                agreedStatus = null,
                agreedProgress = null,
                agreedScore = null,
                gone = false,
                changedAt = nowMillis(),
            ),
        )
        syncSoon(AfterChangeMs)
    }

    private val asking = MutableStateFlow<List<TrackerLinkEntity>>(emptyList())

    // The links of titles just taken out of the library, which wait for the person to say what happens to their entries.
    val removing: StateFlow<List<TrackerLinkEntity>> = asking

    fun removedFromLibrary(titleIds: List<Long>) {
        scope.launch {
            val linked = titleIds.chunked(500).flatMap { db.trackerLinks().ofTitles(it) }
            if (linked.isEmpty()) return@launch
            // The rule can answer for the person, who is only asked when it says so.
            when (settings.trackerRules().onRemove) {
                OnRemove.Ask -> asking.update { (it + linked).distinctBy { link -> link.titleId to link.tracker } }
                OnRemove.Keep -> settle(linked, emptySet())
                OnRemove.Remove -> settle(linked, TrackerId.entries.toSet())
            }
        }
    }

    // Ends the links of the removed titles the person was asked about, and removes their entries on the trackers picked. When asked, the answer can become the rule.
    suspend fun settleRemoved(removeOn: Set<TrackerId>, remember: Boolean = false) {
        val links = asking.value
        asking.value = emptyList()
        if (remember) settings.setText(SettingKey.TrackerOnRemove, (if (removeOn.isEmpty()) OnRemove.Keep else OnRemove.Remove).code)
        settle(links, removeOn)
    }

    // An entry that could not be removed stays on the tracker.
    private suspend fun settle(links: List<TrackerLinkEntity>, removeOn: Set<TrackerId>) {
        for (link in links) {
            val tracker = TrackerId.of(link.tracker) ?: continue
            runCatching { unlink(link.titleId, tracker, tracker in removeOn) }
                .onFailure { AppLog.warn(Tag, "could not remove an entry on ${tracker.id}, ${it.message}") }
        }
    }

    // Another account knows nothing of what this one agreed with the tracker.
    suspend fun forget(tracker: TrackerId) {
        db.trackerLinks().forgetAgreed(tracker.id)
        runs.update { it - tracker }
    }

    // Told when a place in a chapter is kept. A sync follows a little later when the rules ask for it, so reading several chapters in a row makes one.
    fun afterReading() {
        scope.launch { if (settings.trackerRules().afterReading) syncSoon(AfterReadingMs, auto = true) }
    }

    private fun syncSoon(afterMs: Long, auto: Boolean = false) {
        soon?.cancel()
        soon = scope.launch {
            delay(afterMs)
            syncAll(auto)
        }
    }

    // Syncs every tracker this profile is signed in to, and says nothing of what goes wrong, which the page and the log show. A sync the app starts by itself keeps to Wi-Fi when the rules ask for that.
    suspend fun syncAll(auto: Boolean = false) {
        if (auto && settings.trackerRules().wifiOnly && canTellNetwork && !onUnmeteredNetwork()) return
        for (tracker in accounts.accounts.first().keys) {
            try {
                sync(tracker)
            } catch (error: CancellationException) {
                throw error
            } catch (_: TrackerProblem) {
            }
        }
    }

    // One sync of one tracker. Only one runs at a time. A sync the person asks for reads every linked entry, which also finds the ones removed on the tracker.
    suspend fun sync(tracker: TrackerId, whole: Boolean = false): TrackerRun.Done = lock.withLock {
        set(tracker, TrackerRun.Running)
        try {
            val done = once(tracker, whole)
            set(tracker, done)
            record(
                tracker,
                TrackerLogEntry(
                    done.at,
                    ok = true,
                    changedHere = done.changedHere,
                    sent = done.sent,
                    gone = done.gone,
                    conflicts = lastConflicts.take(ConflictsKept),
                ),
            )
            done
        } catch (error: CancellationException) {
            set(tracker, TrackerRun.Idle)
            throw error
        } catch (error: Exception) {
            val problem = TrackerProblem.from(error)
            AppLog.warn(Tag, "sync of ${tracker.id} failed, ${error.message}")
            set(tracker, TrackerRun.Failed(problem))
            record(tracker, TrackerLogEntry(nowMillis(), ok = false, message = problem.message.orEmpty()))
            throw problem
        }
    }

    private var lastConflicts = emptyList<TrackerConflict>()

    private suspend fun once(tracker: TrackerId, whole: Boolean): TrackerRun.Done {
        val account = accounts.signedIn(tracker)
        linker.matchListIfDue(tracker)
        val rules = settings.trackerRules()
        val links = raiseFromReading(tracker, rules)
        val read = readRemote(apis.of(tracker), settings, tracker, account, links, whole)
        var written = 0L
        val conflicts = mutableListOf<TrackerConflict>()
        var changedHere = 0
        var sent = 0
        val sending = mutableListOf<Pair<TrackerLinkEntity, TrackerLinkEntity>>()
        // What changed in the links, written together at the end.
        val writes = mutableListOf<TrackerLinkEntity>()
        var gone = 0
        for (found in links) {
            if (found.gone) {
                gone++
                continue
            }
            var link = found
            // An entry the tracker did not change since the last sync is as the two sides agreed it.
            val there = read.entries[link.remoteId] ?: if (read.whole) null else agreedEntry(link)
            // An entry this device agreed on before and that is gone now was removed on the tracker. The rules say whether the person decides, the link goes, or the entry is put back.
            if (there == null && link.agreedStatus != null) {
                gone++
                when (rules.gone) {
                    WhenGone.Ask -> writes += link.copy(gone = true)

                    WhenGone.Unlink -> db.trackerLinks().delete(link.titleId, link.tracker)

                    WhenGone.AddBack ->
                        link =
                            link.copy(entryId = null, agreedStatus = null, agreedProgress = null, agreedScore = null)
                }
                if (rules.gone != WhenGone.AddBack) continue
            }
            val merged = if (there == null) link else mergeLink(link, there, rules, conflicts)
            if (there == null || merged.status != there.status || merged.progress != there.progress || merged.score != there.score) {
                sending += link to merged
            } else {
                changedHere += settle(link, agreedLink(merged, there), writes)
            }
        }
        // Every write of this sync goes to the tracker together, many to a request. One the tracker did not keep is sent again next time.
        if (sending.isNotEmpty()) {
            val saved = apis.of(tracker).saveMany(
                account,
                sending.map { (_, merged) -> EntrySave(merged.remoteId, merged.status, merged.progress, merged.score, merged.entryId) },
            )
            for ((link, merged) in sending) {
                val kept = saved[merged.remoteId] ?: continue
                written = maxOf(written, kept.updatedAt)
                sent++
                changedHere += settle(link, agreedLink(merged, kept), writes)
            }
            if (sent < sending.size) AppLog.warn(Tag, "${tracker.id} did not keep ${sending.size - sent} of the changes, they go again next time")
        }
        if (writes.isNotEmpty()) db.trackerLinks().putAll(writes)
        lastConflicts = conflicts
        markRead(settings, tracker, read, written)
        // New entries on the list may be titles of the library, which are linked to them.
        if (!read.whole && read.changed.isNotEmpty() && rules.matchList) linker.matchEntries(tracker, read.changed)
        if (sent > 0 ||
            changedHere > 0
        ) {
            AppLog.info(Tag, "synced ${tracker.id}, $changedHere changed here and $sent sent")
        }
        return TrackerRun.Done(nowMillis(), changedHere, sent, gone)
    }

    // Keeps a link as both sides now hold it, and gives 1 when that changed what this device showed.
    private fun settle(link: TrackerLinkEntity, final: TrackerLinkEntity, writes: MutableList<TrackerLinkEntity>): Int {
        // Only the time it agreed is not worth a write.
        if (final.copy(syncedAt = link.syncedAt) != link) writes += final
        return if (final.status != link.status || final.progress != link.progress || final.score != link.score) 1 else 0
    }

    // Moves each link on with reading here, as the rules say, and gives every link of the tracker as it is then.
    private suspend fun raiseFromReading(tracker: TrackerId, rules: TrackerRules): List<TrackerLinkEntity> {
        val links = db.trackerLinks().allOf(tracker.id)
        if (!rules.readingMoves || links.isEmpty()) return links
        val highest = db.trackerLinks().readMarks().associate { it.titleId to it.number }
        // The chapter read last only matters to a title finished or read again.
        val again = links.any { TrackStatus.of(it.status).let { s -> s == TrackStatus.Completed || s == TrackStatus.Repeating } }
        val last = if (again) db.trackerLinks().lastReads().associateBy { it.titleId } else emptyMap()
        var moved = 0
        val now = links.map { link -> followReading(link, highest[link.titleId], last[link.titleId], rules)?.also { moved++ } ?: link }
        if (moved > 0) db.trackerLinks().putAll(now.filterIndexed { index, link -> link !== links[index] })
        return now
    }


    private fun set(tracker: TrackerId, run: TrackerRun) = runs.update { it + (tracker to run) }

    private suspend fun record(tracker: TrackerId, entry: TrackerLogEntry) {
        val before = log(tracker).first()
        settings.setText(
            LogPrefix + tracker.id,
            json.encodeToString(logSerializer, (listOf(entry) + before).take(LogKept)),
        )
    }
}
