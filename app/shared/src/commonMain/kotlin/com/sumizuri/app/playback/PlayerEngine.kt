package com.sumizuri.app.playback

import androidx.compose.ui.graphics.Color
import kotlinx.coroutines.flow.StateFlow

// What the screen of the player asks of whatever plays the video, which is a different engine on each system but the same to the screen.
interface PlayerEngine {
    val state: StateFlow<PlayerState>

    // Opens a video at a time. It plays at once, or waits paused so the place can be set before anything is heard.
    fun open(media: PlayerMedia, startMs: Long, play: Boolean = true)

    fun play()

    fun pause()

    fun seekTo(positionMs: Long)

    fun setSpeed(speed: Float)

    // From 0 for silence to 100 for the usual sound, and a little above for a quiet video.
    fun setVolume(percent: Int)

    // Chooses a subtitle by its id, or none with null.
    fun selectSubtitle(id: String?)

    fun selectAudio(id: String)

    // Changes how subtitles look, for the engines that can do it while playing.
    fun setSubtitleStyle(style: SubtitleStyle) = Unit

    // Lifts the subtitles over the controls by this share of the height of the picture, 0 while they are hidden, for the engines that draw them as a layer of their own.
    fun setSubtitleLift(share: Float) = Unit

    // The colors at the edges of the picture, left, right, top and bottom, for the light around the video. Empty for an engine that cannot tell them, or while they are not asked for.
    val ambient: StateFlow<List<Color>> get() = NoAmbient

    // Starts or stops reading the colors of the picture, which costs a little on each frame.
    fun setAmbient(on: Boolean) = Unit

    // The small picture of the video at the time last asked for, for the seek bar.
    val thumbnail: StateFlow<VideoThumbnail?> get() = NoThumbnails

    // Asks for the small picture of the video at a time.
    fun thumbnailAt(positionMs: Long) = Unit

    // Lets go of the video and what plays it. The engine cannot be used after.
    fun release()
}
