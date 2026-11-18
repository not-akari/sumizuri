package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.db.tracker.LibraryTitle
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.SettingsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map

// The kinds the person uses each tracker for, which go with the other settings of the trackers.
private const val KindsPrefix = "tracker.use."

// The titles left out of each tracker by hand. They stay on this device, as the ids of titles are not the same on another one.
private const val LeftOutPrefix = "memo.tracker.skip."

// The titles a search by name found nothing for on each tracker, so the page can say so and Add all does not search them again for nothing.
private const val MissedPrefix = "memo.tracker.missed."

// Which titles a tracker is offered for: the kinds the person picked from those the tracker keeps, less the titles left out by hand. A title already linked keeps its link and its sync.
class TrackerUse(private val settings: SettingsRepository) {
    fun kinds(tracker: TrackerId): Flow<Set<Kind>> =
        settings.text(KindsPrefix + tracker.id).map { kindsOf(tracker, it) }

    suspend fun kindsNow(tracker: TrackerId): Set<Kind> = kindsOf(tracker, settings.textNow(KindsPrefix + tracker.id))

    // Turns a kind on or off. The last kind stays on, as a tracker used for nothing is one to sign out of.
    suspend fun toggle(tracker: TrackerId, kind: Kind) {
        val now = kindsNow(tracker)
        val next = if (kind in now) now - kind else now + kind
        if (next.isEmpty()) return
        settings.setText(KindsPrefix + tracker.id, next.map { it.code }.sorted().joinToString(","))
    }

    fun leftOut(tracker: TrackerId): Flow<Set<Long>> = settings.text(LeftOutPrefix + tracker.id).map(::idsOf)

    suspend fun leftOutNow(tracker: TrackerId): Set<Long> = idsOf(settings.textNow(LeftOutPrefix + tracker.id))

    suspend fun leaveOut(tracker: TrackerId, titleId: Long) = leaveOut(tracker, listOf(titleId))

    suspend fun leaveOut(tracker: TrackerId, titleIds: Collection<Long>) =
        saveIds(LeftOutPrefix, tracker, leftOutNow(tracker) + titleIds)

    suspend fun takeBack(tracker: TrackerId, titleId: Long) = takeBack(tracker, listOf(titleId))

    suspend fun takeBack(tracker: TrackerId, titleIds: Collection<Long>) =
        saveIds(LeftOutPrefix, tracker, leftOutNow(tracker) - titleIds.toSet())

    fun missed(tracker: TrackerId): Flow<Set<Long>> = settings.text(MissedPrefix + tracker.id).map(::idsOf)

    suspend fun missedNow(tracker: TrackerId): Set<Long> = idsOf(settings.textNow(MissedPrefix + tracker.id))

    // Keeps the titles a search found nothing for, and lets go of those that have a link now.
    suspend fun markMissed(tracker: TrackerId, searched: Set<Long>, unlinked: Set<Long>) =
        saveIds(MissedPrefix, tracker, (missedNow(tracker) + searched).intersect(unlinked))

    // The trackers offered for one title, as they change.
    fun offeredFor(titleId: Long, kind: Kind): Flow<Set<TrackerId>> = combine(
        TrackerId.entries.map { tracker ->
            combine(
                kinds(tracker),
                leftOut(tracker),
            ) { kinds, out -> tracker.takeIf { kind in kinds && titleId !in out } }
        },
    ) { found -> found.filterNotNull().toSet() }

    // Keeps only the titles the tracker is offered for.
    suspend fun filter(tracker: TrackerId, titles: List<LibraryTitle>): List<LibraryTitle> {
        val kinds = kindsNow(tracker)
        val out = leftOutNow(tracker)
        return titles.filter { Kind.fromCode(it.kind) in kinds && it.id !in out }
    }

    private suspend fun saveIds(prefix: String, tracker: TrackerId, ids: Set<Long>) {
        if (ids.isEmpty()) {
            settings.resetNames(prefix + tracker.id)
        } else {
            settings.setText(prefix + tracker.id, ids.sorted().joinToString(","))
        }
    }

    private fun kindsOf(tracker: TrackerId, text: String?): Set<Kind> {
        val picked = text
            ?.split(',')
            ?.mapNotNull { it.trim().toIntOrNull() }
            ?.map(Kind::fromCode)
            ?.toSet()
        return (picked ?: tracker.kinds).intersect(tracker.kinds).ifEmpty { tracker.kinds }
    }

    private fun idsOf(text: String?): Set<Long> = text
        ?.split(',')
        ?.mapNotNull {
            it.trim().toLongOrNull()
        }?.toSet()
        .orEmpty()
}
