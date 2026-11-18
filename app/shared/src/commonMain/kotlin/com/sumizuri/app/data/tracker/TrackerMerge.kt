package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.db.tracker.LastRead
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.text.nowMillis
import kotlin.math.floor
import kotlin.math.max

// Takes what this device and the tracker hold, field by field, against what they last agreed on. A field only one side changed comes from that side, and one both changed follows the rules.
internal fun mergeLink(
    link: TrackerLinkEntity,
    there: RemoteEntry,
    rules: TrackerRules,
    conflicts: MutableList<TrackerConflict>,
): TrackerLinkEntity {
    val newerHere = link.changedAt > there.updatedAt

    fun <T> pick(field: String, here: T, agreed: T?, remote: T, keep: Keep, higher: (T, T) -> T): T {
        val both = when (keep) {
            Keep.Higher -> higher(here, remote)
            Keep.Newer -> if (newerHere) here else remote
            Keep.Tracker -> remote
            Keep.Here -> here
        }
        return when {
            // The two never agreed, such as after signing in again, so the rule of the field decides, and the newer change is the tracker, as it is all this device knows.
            agreed == null -> if (keep == Keep.Newer) remote else both

            here == agreed -> remote

            remote == agreed || here == remote -> here

            else -> both.also { conflicts += TrackerConflict(link.remoteName, field, it == here) }
        }
    }
    return link.copy(
        status = pick("status", link.status, link.agreedStatus, there.status, rules.bothOther) { _, b -> b },
        progress = pick(
            "progress",
            link.progress,
            link.agreedProgress,
            there.progress,
            rules.bothProgress,
        ) { a, b -> max(a, b) },
        score = pick("score", link.score, link.agreedScore, there.score, rules.bothOther) { a, b -> max(a, b) },
    )
}

// A link after both sides hold the same entry.
internal fun agreedLink(link: TrackerLinkEntity, entry: RemoteEntry) = link.copy(
    entryId = entry.entryId,
    status = entry.status,
    progress = entry.progress,
    score = entry.score,
    agreedStatus = entry.status,
    agreedProgress = entry.progress,
    agreedScore = entry.score,
    remoteAt = entry.updatedAt,
    syncedAt = nowMillis(),
    gone = false,
)

// A new link to an entry the person already has on the tracker, starting from the side the rules say.
internal fun linkToEntry(
    base: TrackerLinkEntity,
    there: RemoteEntry,
    readHere: Int,
    rules: TrackerRules,
): TrackerLinkEntity {
    val taken = agreedLink(base, there)
    val progress = when (rules.onLink) {
        Keep.Here -> readHere
        Keep.Tracker -> there.progress
        else -> max(there.progress, readHere)
    }
    return taken.copy(progress = progress, changedAt = if (progress != there.progress) nowMillis() else 0)
}

// How a link moves with reading here, or null when it stays as it is. Progress follows the highest chapter read, and the status follows when the rules say so. A finished title read again becomes reread when the rules ask for it, and its progress then follows the chapter read last.
internal fun followReading(
    link: TrackerLinkEntity,
    highest: Double?,
    last: LastRead?,
    rules: TrackerRules,
): TrackerLinkEntity? {
    if (!rules.readingMoves || link.gone) return null
    val total = link.remoteTotal?.takeIf { it > 0 }
    fun capped(number: Double) = floor(number).toInt().let { if (total != null) it.coerceAtMost(total) else it }
    val done = { progress: Int -> total != null && progress >= total && rules.statusFollows }
    val now = nowMillis()
    return when (TrackStatus.of(link.status)) {
        TrackStatus.Completed -> {
            val again = last != null && rules.reread && last.at > max(link.changedAt, link.remoteAt)
            if (!again) return null
            link.copy(status = TrackStatus.Repeating.code, progress = capped(last.number), changedAt = now)
        }

        TrackStatus.Repeating -> {
            val read = capped(last?.number ?: return null)
            if (read <= link.progress) return null
            link.copy(
                progress = read,
                status = if (done(read)) TrackStatus.Completed.code else link.status,
                changedAt = now,
            )
        }

        else -> {
            val read = capped(highest ?: return null)
            if (read <= link.progress) return null
            val status = TrackStatus.of(link.status)
            val next = when {
                done(read) -> TrackStatus.Completed
                rules.statusFollows && status != TrackStatus.Current -> TrackStatus.Current
                else -> status
            }
            link.copy(progress = read, status = next.code, changedAt = now)
        }
    }
}
