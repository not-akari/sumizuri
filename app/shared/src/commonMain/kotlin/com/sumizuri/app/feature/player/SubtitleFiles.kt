package com.sumizuri.app.feature.player

import com.sumizuri.app.playback.PlayerEngine
import com.sumizuri.app.playback.PlayerState
import com.sumizuri.app.playback.PlayerTrack
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull

// How long a subtitle file that was added has to show up among the tracks before it is left off.
private const val AddedWithinMs = 5000L

// A subtitle file from the device as a track of the video, counted after the files added before it.
internal fun subtitleFileTrack(index: Int, path: String, name: String) =
    PlayerTrack("file$index", name, null, "file:///" + path.replace('\\', '/').removePrefix("/"))

// Turns on a subtitle file just added. The new track has its name when the engine keeps names, and is the last one in the list when it does not.
internal suspend fun PlayerEngine.selectAddedSubtitle(before: PlayerState, name: String) {
    val loaded = withTimeoutOrNull(AddedWithinMs) {
        state.first { now -> now.subtitles.size > before.subtitles.size || now.subtitles.any { it.label == name } }
    } ?: return
    val added = loaded.subtitles.firstOrNull { it.label == name } ?: loaded.subtitles.lastOrNull()
    added?.let { selectSubtitle(it.id) }
}
