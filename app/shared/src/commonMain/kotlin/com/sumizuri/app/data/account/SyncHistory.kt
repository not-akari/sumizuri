package com.sumizuri.app.data.account

import com.sumizuri.app.data.settings.SettingsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

// Why a sync ran: asked for on the sync page, on opening the app, on the timer, after reading, because another device sent changes, in the background while the app was closed, or from scratch.
@Serializable
enum class SyncWhy { Asked, Opened, Timer, AfterReading, OtherDevice, Background, FromScratch, Unknown }

// What one sync changed for one title on one side: put in or taken out of the library, made a favorite or not, chapters marked read or unread, bookmarks, the reading place, and the shelves it went on or off.
@Serializable
data class TitleChange(
    val name: String,
    val added: Boolean = false,
    val removed: Boolean = false,
    val favorite: Boolean? = null,
    val read: Int = 0,
    val unread: Int = 0,
    val bookmarks: Int = 0,
    val places: Int = 0,
    val shelvesIn: List<String> = emptyList(),
    val shelvesOut: List<String> = emptyList(),
)

// What one sync changed on one side: the first titles by name, how many titles changed in all, and how many settings and sources.
@Serializable
data class SyncChanges(
    val titles: List<TitleChange> = emptyList(),
    val titleCount: Int = 0,
    val settings: Int = 0,
    val sources: Int = 0,
    val lists: Int = 0,
) {
    val empty: Boolean get() = titleCount == 0 && settings == 0 && sources == 0 && lists == 0
}

// One sync as the details page lists it: when, why, how long it took, what came in and what went out with their sizes, the conflicts it settled, or why it failed. A failure that came again and again is one entry with how many times and when last.
@Serializable
data class SyncLogEntry(
    val at: Long,
    val ok: Boolean,
    val changedHere: Int = 0,
    val sent: Boolean = false,
    val bytes: Long = 0,
    val message: String = "",
    val conflicts: List<SyncConflict> = emptyList(),
    val why: SyncWhy = SyncWhy.Unknown,
    val tookMs: Long = 0,
    val fetchedRows: Int = 0,
    val fetchedBytes: Long = 0,
    val sentRows: Int = 0,
    val here: SyncChanges = SyncChanges(),
    val there: SyncChanges = SyncChanges(),
    val code: String = "",
    val times: Int = 1,
    val lastAt: Long = 0,
)

// How a sync of this profile went last, for the sync page.
sealed interface SyncRun {
    data object Idle : SyncRun
    data object Running : SyncRun
    data class Done(
        val at: Long,
        val changedHere: Int,
        val sent: Boolean,
        val bytes: Long = 0,
        val conflicts: List<SyncConflict> = emptyList(),
        val fetchedRows: Int = 0,
        val fetchedBytes: Long = 0,
        val sentRows: Int = 0,
        val here: SyncChanges = SyncChanges(),
        val there: SyncChanges = SyncChanges(),
    ) : SyncRun
    data class Failed(val problem: SyncProblem) : SyncRun
}

// How many titles each side of a sync names, so the history stays small.
private const val TitlesKept = 40

// The changes from one state to another, by title, with the names given for the keys.
fun changesBetween(before: SyncState, after: SyncState, names: Map<String, String>): SyncChanges {
    val changes = ArrayList<TitleChange>()
    var count = 0
    for (key in before.titles.keys + after.titles.keys) {
        val was = before.titles[key] ?: TitleMark()
        val now = after.titles[key] ?: TitleMark()
        if (was == now) continue
        val change = titleChange(names[key] ?: key.substringAfter("\n"), was, now) ?: continue
        count++
        if (changes.size < TitlesKept) changes += change
    }
    val settings = (before.settings.keys + after.settings.keys).count { before.settings[it] != after.settings[it] }
    val sources = (before.sources.keys + after.sources.keys).count { before.sources[it] != after.sources[it] }
    val lists = (before.lists.keys + after.lists.keys).count { before.lists[it] != after.lists[it] }
    return SyncChanges(changes, count, settings, sources, lists)
}

private fun titleChange(name: String, was: TitleMark, now: TitleMark): TitleChange? {
    var read = 0
    var unread = 0
    var bookmarks = 0
    var places = 0
    for (chapter in was.chapters.keys + now.chapters.keys) {
        val before = was.chapters[chapter] ?: ChapterMark()
        val after = now.chapters[chapter] ?: ChapterMark()
        if (!before.read && after.read) read++
        if (before.read && !after.read) unread++
        if (before.bookmarked != after.bookmarked) bookmarks += if (after.bookmarked) 1 else -1
        if (!after.read && before.position != after.position && after.position != null) places++
    }
    val change = TitleChange(
        name = name,
        added = !was.inLibrary && now.inLibrary,
        removed = was.inLibrary && !now.inLibrary,
        favorite = if (was.favorite != now.favorite) now.favorite else null,
        read = read,
        unread = unread,
        bookmarks = bookmarks,
        places = places,
        shelvesIn = (now.shelves - was.shelves).sorted(),
        shelvesOut = (was.shelves - now.shelves).sorted(),
    )
    return change.takeIf { it != TitleChange(name) }
}

// One change of a title as a plain line for the logs, such as Solo Leveling: 3 read, favorite.
fun describe(change: TitleChange): String {
    val parts = buildList {
        if (change.added) add("added")
        if (change.removed) add("removed")
        change.favorite?.let { add(if (it) "favorite" else "not a favorite") }
        if (change.read > 0) add("${change.read} read")
        if (change.unread > 0) add("${change.unread} unread")
        if (change.bookmarks != 0) add("${change.bookmarks} bookmarks")
        if (change.places > 0) add("${change.places} places")
        if (change.shelvesIn.isNotEmpty()) add("on " + change.shelvesIn.joinToString())
        if (change.shelvesOut.isNotEmpty()) add("off " + change.shelvesOut.joinToString())
    }
    return change.name + ": " + parts.joinToString()
}

// The syncs of a profile, newest first, kept in its settings.
class SyncHistory(private val settings: SettingsRepository) {
    private val json = Json { ignoreUnknownKeys = true }

    val entries: Flow<List<SyncLogEntry>> = settings.text(Key).map(::decode)

    // Keeps a sync at the top. A failure like the newest one is counted on it rather than kept again, so a server that is down for a day is one line.
    suspend fun record(entry: SyncLogEntry) {
        val now = decode(settings.textNow(Key))
        val top = now.firstOrNull()
        val kept = if (!entry.ok && top != null && !top.ok && top.code == entry.code && top.message == entry.message) {
            listOf(top.copy(times = top.times + 1, lastAt = entry.at)) + now.drop(1)
        } else {
            listOf(entry) + now
        }
        settings.setText(Key, json.encodeToString(ListSerializer(SyncLogEntry.serializer()), kept.take(Most)))
    }

    private fun decode(text: String?): List<SyncLogEntry> = text
        ?.let { runCatching { json.decodeFromString(ListSerializer(SyncLogEntry.serializer()), it) }.getOrNull() }
        .orEmpty()

    companion object {
        // The syncs of a profile, as a list kept in its settings, and how many are kept.
        const val Key = "sync.history"
        private const val Most = 30
    }
}

// How long something took, short, such as 0.4 s, 12 s or 3 min.
fun durationText(ms: Long): String = when {
    ms < 10_000 -> "${ms / 100 / 10.0} s"
    ms < 120_000 -> "${ms / 1000} s"
    else -> "${ms / 60_000} min"
}

// The recent syncs as plain text for asking for help: when, why, how long, the sizes, what changed by title, and failures with their code. Nothing secret is in it.
fun syncReport(entries: List<SyncLogEntry>, version: String, timeOf: (Long) -> String): String = buildString {
    appendLine("Sumizuri $version sync report")
    for (entry in entries.take(ReportRuns)) {
        appendLine()
        append(timeOf(entry.at))
            .append(", ")
            .append(entry.why.name)
            .append(", ")
            .append(durationText(entry.tookMs))
        if (!entry.ok) {
            append(", failed ").append(entry.code).append(": ").append(entry.message)
            if (entry.times >
                1
            ) {
                append(" (")
                    .append(entry.times)
                    .append(" times, last ")
                    .append(timeOf(entry.lastAt))
                    .append(")")
            }
            appendLine()
            continue
        }
        appendLine()
        appendLine(
            "fetched ${entry.fetchedRows} rows ${entry.fetchedBytes / 1024} KB, sent ${entry.sentRows} rows ${entry.bytes / 1024} KB",
        )
        for ((side, changes) in listOf("here" to entry.here, "sent" to entry.there)) {
            if (changes.empty) continue
            appendLine(
                "$side: ${changes.titleCount} titles, ${changes.settings} settings, ${changes.sources} sources, ${changes.lists} lists",
            )
            for (title in changes.titles) appendLine("  ${describe(title)}")
        }
        for (conflict in entry.conflicts) appendLine("conflict: ${conflict.kind} ${conflict.name}")
    }
}

// How many syncs a report holds.
private const val ReportRuns = 10
