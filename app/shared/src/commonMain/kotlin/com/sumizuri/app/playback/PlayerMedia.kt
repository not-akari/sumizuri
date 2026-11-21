package com.sumizuri.app.playback

import com.sumizuri.app.data.model.player.SubtitleBackground
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_aspect_fill
import com.sumizuri.app.shared.resources.player_aspect_fit
import com.sumizuri.app.shared.resources.player_aspect_stretch
import org.jetbrains.compose.resources.StringResource

// A subtitle or an audio track, with its place in the list of its kind for a track that has no name. One that came with the source has an address and is added to the video, and one that is in the video has only an id the engine knows it by.
data class PlayerTrack(
    val id: String,
    val label: String,
    val language: String? = null,
    val url: String? = null,
    val ordinal: Int = 0,
)

// What the engine is asked to play: the address of the video, the headers the site wants with it, the subtitle files and audio files that go with it, and the sound that is kept apart from the picture in some streams.
data class PlayerMedia(
    val url: String,
    val headers: Map<String, String> = emptyMap(),
    val subtitles: List<PlayerTrack> = emptyList(),
    val audios: List<PlayerTrack> = emptyList(),
    val pairedAudio: PlayerTrack? = null,
    // What the source says the address is ("hls", "mp4"), for an address whose ending does not tell.
    val type: String? = null,
)

// How the picture fills the screen: whole with bars, cropped to fill, or stretched out of shape.
enum class AspectMode(val label: StringResource) {
    Fit(Res.string.player_aspect_fit),
    Fill(Res.string.player_aspect_fill),
    Stretch(Res.string.player_aspect_stretch),
}

// How the subtitles are drawn: the size in sp, the color, what stands behind the letters, whether they are bold, and how high they stand over the bottom edge, as a place in a list of three.
data class SubtitleStyle(
    val sizeSp: Int = 24,
    val color: Long = 0xFFFFFFFF,
    val background: SubtitleBackground = SubtitleBackground.Outline,
    val bold: Boolean = false,
    val raise: Int = 1,
) {
    companion object {
        // The room under the letters for each place of the raise, in dp.
        val RaiseDp = listOf(10, 28, 64)
    }
}
