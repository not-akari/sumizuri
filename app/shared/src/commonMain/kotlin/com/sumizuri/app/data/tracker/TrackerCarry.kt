package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// A link of a title to a tracker as a backup carries it: which entry it is, and what this device held, so a new device starts from it. What the link last agreed with the tracker stays behind, as it belongs to the account on this device.
@Serializable
data class ImportedTrack(
    val tracker: String,
    val remoteId: Long,
    val remoteName: String,
    val remoteCover: String? = null,
    val remoteUrl: String? = null,
    val remoteTotal: Int? = null,
    val status: String = TrackStatus.Planning.code,
    val progress: Int = 0,
    val score: Int = 0,
)

fun TrackerLinkEntity.carried() =
    ImportedTrack(tracker, remoteId, remoteName, remoteCover, remoteUrl, remoteTotal, status, progress, score)

// A link put in from a backup or another device. It has agreed on nothing yet, so its first sync joins it to the entry on the tracker by the rules.
fun ImportedTrack.linkOf(titleId: Long, kind: Int) = TrackerLinkEntity(
    titleId = titleId,
    tracker = tracker,
    remoteId = remoteId,
    remoteName = remoteName,
    remoteCover = remoteCover,
    remoteUrl = remoteUrl,
    remoteTotal = remoteTotal,
    kind = kind,
    status = status,
    progress = progress,
    score = score,
)

// Device sync carries each link as a value under its own name beside the settings, made from the link table and written back to it, so the other devices of the account know which entry a title is without linking it again. The value names only the entry, as the tracker holds the rest.
object LinkSync {
    const val Prefix = "trackerlink."

    @Serializable
    private data class Entry(
        @SerialName("r") val remoteId: Long,
        @SerialName("n") val name: String,
        @SerialName("c") val cover: String? = null,
        @SerialName("u") val url: String? = null,
        @SerialName("t") val total: Int? = null,
    )

    private val json = Json { ignoreUnknownKeys = true }

    fun key(tracker: String, titleKey: String) = "$Prefix$tracker.$titleKey"

    fun value(track: ImportedTrack): String = json.encodeToString(
        Entry.serializer(),
        Entry(track.remoteId, track.remoteName, track.remoteCover, track.remoteUrl, track.remoteTotal),
    )

    // The tracker and the key of the title a name is for, or null when it is not a link.
    fun parts(key: String): Pair<String, String>? {
        if (!key.startsWith(Prefix)) return null
        val rest = key.removePrefix(Prefix)
        val tracker = rest.substringBefore('.', "").takeIf { it.isNotEmpty() } ?: return null
        return tracker to rest.substringAfter('.')
    }

    // The link a value stands for, as a new link that has agreed on nothing.
    fun track(tracker: String, value: String): ImportedTrack? =
        runCatching { json.decodeFromString(Entry.serializer(), value) }.getOrNull()?.let {
            ImportedTrack(tracker, it.remoteId, it.name, it.cover, it.url, it.total)
        }
}
