package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.nowMillis

// When the entries were last read whole, and the newest change of the list seen, kept on this device.
private const val FullPrefix = "memo.tracker.full."
private const val SeenPrefix = "memo.tracker.seen."

// The list is read whole this often, which is the only way to find entries removed on the tracker.
private const val FullEveryMs = 24 * 60 * 60 * 1000L

// The most pages of changes one sync reads before it reads the list whole instead.
private const val MostPages = 4

// What a sync read of the tracker: the entries of the linked titles it knows, whether that is all of them, and the entries that changed, with their titles, for linking titles of the library to new ones.
internal class RemoteRead(
    val entries: Map<Long, RemoteEntry>,
    val whole: Boolean,
    val changed: List<Pair<RemoteEntry, TrackerMedia>>,
    val newest: Long,
)

// Reads what a sync needs of the tracker in as few requests as it can. Most of the time that is one page of the entries changed since the last sync, as an entry nobody changed is the same as the two sides last agreed. The entries of new links are read by their ids. Once a day, after a long gap, or when the person asks, every linked entry is read, which finds the ones removed there.
internal suspend fun readRemote(
    api: TrackerApi,
    settings: SettingsRepository,
    tracker: TrackerId,
    account: TrackerAccount,
    links: List<TrackerLinkEntity>,
    whole: Boolean,
): RemoteRead {
    val seen = settings.textNow(SeenPrefix + tracker.id)?.toLongOrNull()
    val lastWhole = settings.textNow(FullPrefix + tracker.id)?.toLongOrNull() ?: 0
    var changed = emptyList<Pair<RemoteEntry, TrackerMedia>>()
    var readWhole = whole || seen == null || nowMillis() - lastWhole > FullEveryMs
    // A tracker that can ask for its changes by their time does so in one go, and reads the list whole when there are too many.
    if (!readWhole && seen != null && api.changesByTime) {
        val since = api.changedSince(account, seen)
        if (since == null) readWhole = true else changed = since.filter { it.first.updatedAt > seen }
    } else if (!readWhole && seen != null) {
        val pages = mutableListOf<Pair<RemoteEntry, TrackerMedia>>()
        var page = 1
        while (true) {
            val (rows, more) = api.recent(account, page)
            pages += rows
            if (!more || rows.isEmpty() || rows.last().first.updatedAt <= seen) break
            // So many changes at once, such as an import on the site, are read faster whole.
            if (page >= MostPages) {
                readWhole = true
                break
            }
            page++
        }
        changed = pages.filter { it.first.updatedAt > seen }
    }
    val linked = links.filter { !it.gone }
    val entries: Map<Long, RemoteEntry> = if (readWhole) {
        if (linked.isEmpty()) {
            emptyMap()
        } else {
            api.entries(account, linked.map { it.remoteId })
        }
    } else {
        val byChange = changed.associate { it.first.mediaId to it.first }
        // A link that never agreed with the tracker has nothing to stand for its entry, so its entry is read by its id.
        val unknown = linked.filter { it.agreedStatus == null && it.remoteId !in byChange }.map { it.remoteId }
        val asked = if (unknown.isEmpty()) {
            emptyMap()
        } else {
            api.entries(account, unknown)
        }
        byChange + asked
    }
    val newest =
        (entries.values.map { it.updatedAt } + changed.map { it.first.updatedAt } + listOfNotNull(seen)).maxOrNull()
            ?: 0
    return RemoteRead(entries, readWhole, changed, newest)
}

// Keeps how far a sync that worked has read, with the time of the writes it made, so the next one starts from there.
internal suspend fun markRead(settings: SettingsRepository, tracker: TrackerId, read: RemoteRead, written: Long) {
    val newest = maxOf(read.newest, written)
    if (newest > 0) settings.setText(SeenPrefix + tracker.id, newest.toString())
    if (read.whole) settings.setText(FullPrefix + tracker.id, nowMillis().toString())
}

// The entry of a link the tracker did not change since they last agreed, as the two sides agreed it.
internal fun agreedEntry(link: TrackerLinkEntity): RemoteEntry? {
    val status = link.agreedStatus ?: return null
    return RemoteEntry(
        link.entryId ?: return null,
        link.remoteId,
        status,
        link.agreedProgress ?: 0,
        link.agreedScore ?: 0,
        link.remoteAt,
    )
}
