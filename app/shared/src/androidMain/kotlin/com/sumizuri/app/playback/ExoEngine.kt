package com.sumizuri.app.playback

import android.content.Context
import android.net.Uri
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.MergingMediaSource
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient

// How often the position is read while a video plays, in milliseconds.
private const val TickMs = 250L

// Plays video with Media3, which streams the usual files and the adaptive HLS and DASH streams, sends the headers a site wants with every request, and shows the subtitles itself.
class ExoEngine(context: Context) : PlayerEngine {
    private val appContext = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    val exo: ExoPlayer = ExoPlayer.Builder(appContext).build()
    private val mutable = MutableStateFlow(PlayerState())
    override val state: StateFlow<PlayerState> = mutable

    // The colors at the edges of the picture, read from the screen by the view that shows the video while they are wanted.
    internal val glow = MutableStateFlow(emptyList<androidx.compose.ui.graphics.Color>())
    override val ambient: StateFlow<List<androidx.compose.ui.graphics.Color>> = glow

    internal var glowOn = false

    override fun setAmbient(on: Boolean) {
        glowOn = on
        if (!on) glow.value = emptyList()
    }
    private var ticking: Job? = null

    // How the subtitles look and whether they are lifted over the controls, which the surface reads.
    val style = MutableStateFlow(SubtitleStyle())
    val lift = MutableStateFlow(false)

    // Where each track id the screen sees is in the tracks of the player: the group and the place in it.
    private var places = emptyMap<String, Pair<Tracks.Group, Int>>()

    init {
        exo.addListener(
            object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) = push()

                override fun onIsPlayingChanged(isPlaying: Boolean) = push()

                override fun onVideoSizeChanged(videoSize: VideoSize) = mutable.update {
                    it.copy(videoWidth = videoSize.width, videoHeight = videoSize.height)
                }

                override fun onTracksChanged(tracks: Tracks) = readTracks(tracks)

                override fun onPlayerError(error: PlaybackException) = mutable.update {
                    it.copy(
                        problem = PlayerProblem.Failed,
                        message = listOfNotNull(error.errorCodeName, error.message).joinToString(": "),
                        buffering = false,
                        playing = false,
                    )
                }
            },
        )
        ticking = scope.launch {
            while (true) {
                delay(TickMs)
                push()
            }
        }
    }

    override fun open(media: PlayerMedia, startMs: Long, play: Boolean) {
        // Sites go through OkHttp with their headers, and a saved episode is read from its files.
        val factory = DefaultDataSource.Factory(appContext, OkHttpDataSource.Factory(OkHttpClient()).setDefaultRequestProperties(media.headers))
        val subtitles = media.subtitles.mapNotNull { track ->
            val address = track.url ?: return@mapNotNull null
            MediaItem.SubtitleConfiguration
                .Builder(Uri.parse(address))
                .setMimeType(subtitleMime(address))
                .setLanguage(track.language)
                .setLabel(track.label)
                .setId(track.id)
                .build()
        }
        val item = MediaItem
            .Builder()
            .setUri(media.url)
            .setSubtitleConfigurations(subtitles)
            .build()
        mutable.update { PlayerState(speed = it.speed, volume = it.volume) }
        val sources = DefaultMediaSourceFactory(factory)
        val video = sources.createMediaSource(item)
        // The sound that is kept apart from the picture is played together with it.
        val sound = media.pairedAudio?.url?.let { sources.createMediaSource(MediaItem.fromUri(Uri.parse(it))) }
        exo.setMediaSource(if (sound == null) video else MergingMediaSource(video, sound), startMs)
        exo.prepare()
        exo.playWhenReady = play
    }

    override fun play() {
        if (exo.playbackState == Player.STATE_ENDED) exo.seekTo(0)
        exo.play()
    }

    override fun pause() = exo.pause()

    override fun seekTo(positionMs: Long) {
        exo.seekTo(positionMs.coerceAtLeast(0))
        push()
    }

    override fun setSpeed(speed: Float) {
        exo.playbackParameters = PlaybackParameters(speed)
        push()
    }

    override fun setVolume(percent: Int) {
        exo.volume = (percent / 100f).coerceIn(0f, 1f)
        mutable.update { it.copy(volume = percent) }
    }

    override fun selectSubtitle(id: String?) {
        val params = exo.trackSelectionParameters.buildUpon()
        val place = id?.let { places[it] }
        if (place == null) {
            params.setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
        } else {
            params
                .setTrackTypeDisabled(
                    C.TRACK_TYPE_TEXT,
                    false,
                ).setOverrideForType(TrackSelectionOverride(place.first.mediaTrackGroup, place.second))
        }
        exo.trackSelectionParameters = params.build()
        mutable.update { it.copy(subtitle = id.takeIf { place != null }) }
    }

    override fun selectAudio(id: String) {
        val place = places[id] ?: return
        exo.trackSelectionParameters = exo.trackSelectionParameters
            .buildUpon()
            .setOverrideForType(TrackSelectionOverride(place.first.mediaTrackGroup, place.second))
            .build()
        mutable.update { it.copy(audio = id) }
    }

    override fun setSubtitleStyle(style: SubtitleStyle) {
        this.style.value = style
    }

    override fun setSubtitleLift(controlsShown: Boolean) {
        lift.value = controlsShown
    }

    override fun release() {
        ticking?.cancel()
        exo.release()
        scope.cancel()
    }

    private fun push() {
        val duration = exo.duration.takeIf { it != C.TIME_UNSET && it > 0 } ?: 0
        val phase = exo.playbackState
        mutable.update {
            it.copy(
                ready = phase == Player.STATE_READY || phase == Player.STATE_ENDED,
                playing = exo.isPlaying,
                buffering = phase == Player.STATE_BUFFERING,
                ended = phase == Player.STATE_ENDED,
                positionMs = exo.currentPosition.coerceAtLeast(0),
                durationMs = duration,
                bufferedMs = exo.bufferedPosition.coerceAtLeast(0),
                speed = exo.playbackParameters.speed,
            )
        }
    }

    // The subtitle and audio tracks of the video, with the ones chosen.
    private fun readTracks(tracks: Tracks) {
        val found = mutableMapOf<String, Pair<Tracks.Group, Int>>()
        val subtitles = mutableListOf<PlayerTrack>()
        val audios = mutableListOf<PlayerTrack>()
        var subtitle: String? = null
        var audio: String? = null
        tracks.groups.forEachIndexed { at, group ->
            val type = group.type
            if (type != C.TRACK_TYPE_TEXT && type != C.TRACK_TYPE_AUDIO) return@forEachIndexed
            for (index in 0 until group.length) {
                val format = group.getTrackFormat(index)
                val id = "$at:$index"
                val label = TrackNames.label(format.label, format.language)
                found[id] = group to index
                if (type == C.TRACK_TYPE_TEXT) {
                    subtitles += PlayerTrack(id, label, format.language, ordinal = subtitles.size + 1)
                    if (group.isTrackSelected(index)) subtitle = id
                } else {
                    audios += PlayerTrack(id, label, format.language, ordinal = audios.size + 1)
                    if (group.isTrackSelected(index)) audio = id
                }
            }
        }
        places = found
        mutable.update { it.copy(subtitles = subtitles, audios = audios, subtitle = subtitle, audio = audio) }
    }

    private fun subtitleMime(address: String): String {
        val clean = address.substringBefore('?').lowercase()
        return when {
            clean.endsWith(".vtt") -> MimeTypes.TEXT_VTT
            clean.endsWith(".ass") || clean.endsWith(".ssa") -> MimeTypes.TEXT_SSA
            clean.endsWith(".ttml") || clean.endsWith(".xml") -> MimeTypes.APPLICATION_TTML
            else -> MimeTypes.APPLICATION_SUBRIP
        }
    }
}
