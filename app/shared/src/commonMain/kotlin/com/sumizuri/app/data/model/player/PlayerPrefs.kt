package com.sumizuri.app.data.model.player

import com.sumizuri.app.playback.AspectMode

// Which video of an episode is taken when it has several: the one that was picked last, the sharpest, or the lightest.
enum class QualityMode { Remember, Best, Lowest }

// Whether the subtitled or the dubbed version is taken when the source gives both.
enum class AudioPreference { Any, Sub, Dub }

// How the letters of a subtitle stand out from the picture.
enum class SubtitleBackground { None, Outline, Box }

// How the player is set, as the person chose.
data class PlayerPrefs(
    val qualityMode: QualityMode = QualityMode.Remember,
    val audioPreference: AudioPreference = AudioPreference.Any,
    // The quality that was picked last, kept for the mode that remembers it.
    val preferredQuality: String = "",
    val speed: Float = 1f,
    // The subtitle language to turn on when a video has it, as a code such as en, or nothing for no choice.
    val subtitleLanguage: String = "",
    val showSubtitles: Boolean = true,
    // The size and the color are places in their lists, and the raise lifts the letters off the bottom edge.
    val subtitleSize: Int = 1,
    val subtitleColor: Int = 0,
    val subtitleBackground: SubtitleBackground = SubtitleBackground.Outline,
    val subtitleBold: Boolean = false,
    val subtitleRaise: Int = 1,
    // How far a double tap and the jump buttons go, and how far the skip button goes, in seconds.
    val doubleTapSeconds: Int = 5,
    val skipSeconds: Int = 30,
    // How long the controls stay after the last touch, in seconds, with 0 for never hiding.
    val hideControlsSeconds: Int = 3,
    // A drag along the screen jumps and a drag up and down on the right side sets the volume.
    val swipeGestures: Boolean = true,
    // A double tap on the sides jumps, and one in the middle pauses.
    val doubleTapSeek: Boolean = true,
    // The speed while the screen is held down, with 1 for off.
    val holdSpeed: Float = 2f,
    val showLog: Boolean = false,
    // The next episode starts by itself when one ends.
    val autoNext: Boolean = true,
    // When a video does not start, the next server is tried by itself instead of asking, until one plays or none is left.
    val autoNextServer: Boolean = false,
    // How much of an episode must be played, in percent, for it to count as watched.
    val watchedAt: Int = 90,
    // An episode starts where it was left.
    val resume: Boolean = true,
    val aspect: AspectMode = AspectMode.Fit,
    // A soft light in the colors of the edges of the picture fills the bars around a video.
    val ambient: Boolean = true,
) {
    companion object {
        val DoubleTapSteps = listOf(5, 10, 15, 20, 30, 60)
        val SkipSteps = listOf(30, 60, 75, 85, 90, 120)
        val HideSteps = listOf(0, 2, 3, 5, 8, 15)
        val Speeds = listOf(0.5f, 0.75f, 1f, 1.25f, 1.5f, 1.75f, 2f, 2.5f, 3f)
        val HoldSpeeds = listOf(1f, 1.5f, 2f, 3f)
        val WatchedAt = listOf(70, 80, 90, 95, 100)

        // The sizes of the subtitles in sp, and the colors they can have.
        val SubtitleSizes = listOf(18, 24, 32)
        val SubtitleColors = listOf(0xFFFFFFFFL, 0xFFFFEB3BL, 0xFF80DEEAL, 0xFFA5D6A7L)
    }
}
