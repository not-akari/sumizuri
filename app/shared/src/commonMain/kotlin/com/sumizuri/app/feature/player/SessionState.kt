package com.sumizuri.app.feature.player

import com.sumizuri.app.data.model.player.PlayerPrefs
import com.sumizuri.app.source.model.SourceVideo
import org.jetbrains.compose.resources.StringResource

// Where the session is: asking for the videos and opening one, playing, or stopped by a failure.
enum class PlayerPhase { Loading, Ready, Failed }

// Why the session stopped. The source could not list the videos or has none, the video did not start, it stopped with an error, the connection dropped, or the player of the system is missing.
enum class FailureKind { Source, NoVideos, DidNotStart, Playback, Network, EngineMissing }

// A failure with the words the engine or the source gave, the address to open to pass a bot check, and a fixed note that replaces the usual reason.
class PlayerFailure(
    val kind: FailureKind,
    val detail: String? = null,
    val challengeUrl: String? = null,
    val note: StringResource? = null,
)

// An episode in the list of the title.
class EpisodeRef(
    val id: Long,
    val number: Double,
    val name: String?,
    val read: Boolean,
    // The season the source puts it in, with its name, or null when the source has no seasons.
    val season: String? = null,
    val seasonName: String? = null,
)

// What the screen of the player reads from the session: the phase, the episodes with the one that plays, the videos with the one that plays, and the choices of the person.
data class SessionState(
    val phase: PlayerPhase = PlayerPhase.Loading,
    val failure: PlayerFailure? = null,
    val titleName: String = "",
    val episodes: List<EpisodeRef> = emptyList(),
    val index: Int = 0,
    val videos: List<SourceVideo> = emptyList(),
    val current: SourceVideo? = null,
    val prefs: PlayerPrefs = PlayerPrefs(),
) {
    val episode: EpisodeRef? get() = episodes.getOrNull(index)
    val hasNext: Boolean get() = index < episodes.size - 1
    val hasPrevious: Boolean get() = index > 0
    val hasAnotherVideo: Boolean get() = videos.indexOf(current) + 1 in 1 until videos.size
}
