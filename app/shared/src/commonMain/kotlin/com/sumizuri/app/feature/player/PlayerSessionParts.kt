package com.sumizuri.app.feature.player

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.net.SiteKinds
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.playback.PlayerMedia
import com.sumizuri.app.playback.PlayerProblem
import com.sumizuri.app.playback.PlayerTrack
import com.sumizuri.app.playback.hls.expandHlsMasters
import com.sumizuri.app.playback.hls.isHls
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_failure_cut
import com.sumizuri.app.shared.resources.player_failure_unreadable
import com.sumizuri.app.source.model.SourceVideo

// Where an episode was and how long it is, taken at one moment so the place kept matches the length.
internal class Snapshot(val positionMs: Long, val durationMs: Long)

// A video of the source as the engine plays it, with its subtitle and sound tracks and the subtitle files added from the device.
internal fun mediaOf(video: SourceVideo, extraSubtitles: List<PlayerTrack>): PlayerMedia {
    val subtitles = video.subtitles.mapIndexed { at, one -> PlayerTrack("sub$at", one.label, one.language, one.url) }
    val audios = video.audioTracks.mapIndexed { at, one -> PlayerTrack("aud$at", one.label, one.language, one.url) }
    val paired = video.pairedAudio?.let { PlayerTrack("paired", it.label, it.language, it.url) }
    return PlayerMedia(video.url, video.headers, subtitles + extraSubtitles, audios, paired, video.type)
}

// What the screen tells the person when the engine stops on a problem.
internal fun failureOf(problem: PlayerProblem?, message: String?): PlayerFailure = when {
    problem == PlayerProblem.EngineMissing -> PlayerFailure(FailureKind.EngineMissing)

    message != null && PlayerErrors.isCut(
        message,
    ) -> PlayerFailure(FailureKind.Network, message, note = Res.string.player_failure_cut)

    message != null && PlayerErrors.isNetwork(message) -> PlayerFailure(FailureKind.Network, message)

    message != null && PlayerErrors.isUnreadable(
        message,
    ) -> PlayerFailure(FailureKind.Playback, message, note = Res.string.player_failure_unreadable)

    else -> PlayerFailure(FailureKind.Playback, message)
}

// The videos with each stream playlist opened up into its qualities, so the person can pick one.
internal suspend fun withQualities(videos: List<SourceVideo>, log: PlaybackLog): List<SourceVideo> {
    if (videos.none { it.isHls }) return videos
    val started = nowMillis()
    val expanded = expandHlsMasters(videos)
    if (expanded.size != videos.size) {
        val qualities = expanded.joinToString(", ") { it.quality ?: "?" }
        log.add("Read the playlist in ${nowMillis() - started} ms: $qualities")
    }
    return expanded
}

// The hosts of the videos and of their tracks take the way of anime.
internal fun markAnime(videos: List<SourceVideo>, sourceId: String? = null) {
    for (video in videos) {
        val addresses =
            listOf(video.url) + video.subtitles.mapNotNull { it.url } + video.audioTracks.mapNotNull { it.url }
        addresses.forEach { SiteKinds.mark(it, Kind.Anime, sourceId) }
    }
}
