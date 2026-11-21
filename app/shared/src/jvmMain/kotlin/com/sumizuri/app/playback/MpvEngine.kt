package com.sumizuri.app.playback

import androidx.compose.runtime.mutableStateOf
import com.sumizuri.app.core.log.AppLog
import com.sun.jna.Memory
import com.sun.jna.Native
import com.sun.jna.Pointer
import com.sun.jna.ptr.PointerByReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.jetbrains.skia.ColorAlphaType
import org.jetbrains.skia.ColorType
import org.jetbrains.skia.Image
import org.jetbrains.skia.ImageInfo
import java.util.Locale
import java.util.concurrent.ConcurrentLinkedDeque
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

// The widest frame drawn. A bigger video is drawn smaller, as every frame is drawn by the processor.
private const val WidestFrame = 1920

// How many frames may wait for the screen before no more are made.
private const val MostWaiting = 3

// How often the place, the length and the waiting are read while a video plays, in seconds.
private const val LookEvery = 0.25

// Plays video through libmpv, which comes with the app on Windows. mpv is started away from the screen, so the window never waits for it, and a video asked for before then plays once it is ready. mpv draws every frame into memory and the screen of the player shows it, so the controls can lie over the picture. One thread waits for what mpv says and reads where the video is, and another draws the frames. A computer without libmpv gets a problem that says so.
class MpvEngine(style: SubtitleStyle = SubtitleStyle()) : PlayerEngine {
    private val mutable = MutableStateFlow(PlayerState())
    override val state: StateFlow<PlayerState> = mutable

    // The newest frame, which the surface draws, and whether it lights the bars around the picture with a soft copy of it.
    val frame = mutableStateOf<Image?>(null)
    val lit = MutableStateFlow(false)
    override fun setAmbient(on: Boolean) {
        lit.value = on
    }
    private val thumbs = MutableStateFlow<VideoThumbnail?>(null)
    private var thumbnailer: MpvThumbnails? = null
    override val thumbnail get() = thumbs

    override fun thumbnailAt(positionMs: Long) = withMpv { mpv, _ ->
        (thumbnailer ?: MpvThumbnails(mpv, thumbs).also { thumbnailer = it }).ask(positionMs, lastMedia)
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var api: MpvApi? = null

    @Volatile private var handle: Pointer? = null

    @Volatile private var render: Pointer? = null

    @Volatile private var alive = true
    private val frames = Semaphore(0)

    // Kept here so the garbage collector never frees the callback while mpv may still call it.
    private val update = MpvUpdate { frames.release() }

    private var subtitleStyle = style
    private var lifted = 0f

    // The subtitle files of the video, added once mpv has loaded it.
    @Volatile private var pending = emptyList<PlayerTrack>()

    // What the log of mpv said about the video now playing, so a failure can say why it came.
    private val signs = LogSigns()
    private var lastMedia: PlayerMedia? = null

    // The frames made and not yet passed by the screen, the oldest first. The screen frees the ones before the frame it drew, on its own thread, so no frame is freed while it is drawn.
    private val made = ConcurrentLinkedDeque<Image>()
    private var bytes = ByteArray(0)
    private var buffer: Memory? = null

    @Volatile private var videoWidth = 0

    @Volatile private var videoHeight = 0

    private val ready: Job = scope.launch {
        val found = MpvLibrary.api()
        val made = found?.mpv_create()
        if (found == null || made == null) {
            mutable.update { it.copy(problem = PlayerProblem.EngineMissing, buffering = false) }
            return@launch
        }
        api = found
        val options = MpvPlayOptions + subtitleOptions(subtitleStyle, lifted)
        for ((name, value) in options) found.mpv_set_option_string(made, name, value)
        if (found.mpv_initialize(made) < 0) {
            found.mpv_terminate_destroy(made)
            mutable.update { it.copy(problem = PlayerProblem.EngineMissing, buffering = false) }
            return@launch
        }
        // What goes wrong inside mpv, such as a site that refuses the video, goes to the log of the app.
        found.mpv_request_log_messages(made, "warn")
        val sw = Mpv.text("sw")
        val result = PointerByReference()
        if (found.mpv_render_context_create(result, made, Mpv.params(Mpv.ParamApiType to sw)) < 0) {
            found.mpv_terminate_destroy(made)
            mutable.update { it.copy(problem = PlayerProblem.EngineMissing, buffering = false) }
            return@launch
        }
        val context = result.value
        found.mpv_render_context_set_update_callback(context, update, null)
        val keep = synchronized(this@MpvEngine) {
            if (alive) {
                handle = made
                render = context
            }
            alive
        }
        if (!keep) {
            found.mpv_render_context_free(context)
            found.mpv_terminate_destroy(made)
            return@launch
        }
        thread(name = "mpv events", isDaemon = true) { listen(found, made) }
        thread(name = "mpv frames", isDaemon = true) { draw(found, context) }
    }

    // Plays once mpv is ready, with the headers the site wants, the sound kept apart from the picture, and the speed and the loudness already chosen.
    override fun open(media: PlayerMedia, startMs: Long, play: Boolean) {
        lastMedia = media
        pending = media.subtitles
        signs.clear()
        mutable.update {
            PlayerState(
                speed = it.speed,
                volume = it.volume,
                problem = it.problem.takeIf { problem -> problem == PlayerProblem.EngineMissing },
                buffering = it.problem != PlayerProblem.EngineMissing,
            )
        }
        scope.launch {
            ready.join()
            val mpv = api ?: return@launch
            val here = handle ?: return@launch
            mpv.useHeaders(here, media.headers)
            mpv.command(here, "change-list", "audio-files", "clr", "")
            media.pairedAudio?.url?.let { mpv.command(here, "change-list", "audio-files", "append", it) }
            mpv.mpv_set_property_string(here, "start", if (startMs > 0) seconds(startMs) else "none")
            mpv.mpv_set_property_string(here, "pause", if (play) "no" else "yes")
            val now = mutable.value
            mpv.mpv_set_property_string(here, "speed", String.format(Locale.ROOT, "%.2f", now.speed))
            mpv.mpv_set_property_string(here, "volume", now.volume.coerceIn(0, 200).toString())
            mpv.command(here, "loadfile", media.url, "replace")
        }
    }

    override fun play() = withMpv { mpv, here ->
        if (mutable.value.ended) mpv.command(here, "seek", "0", "absolute")
        mpv.mpv_set_property_string(here, "pause", "no")
    }

    override fun pause() = withMpv { mpv, here -> mpv.mpv_set_property_string(here, "pause", "yes") }

    override fun seekTo(positionMs: Long) {
        mutable.update { it.copy(positionMs = positionMs.coerceAtLeast(0), ended = false) }
        withMpv { mpv, here -> mpv.command(here, "seek", seconds(positionMs.coerceAtLeast(0)), "absolute") }
    }

    override fun setSpeed(speed: Float) {
        mutable.update { it.copy(speed = speed) }
        withMpv { mpv, here -> mpv.mpv_set_property_string(here, "speed", String.format(Locale.ROOT, "%.2f", speed)) }
    }

    override fun setVolume(percent: Int) {
        mutable.update { it.copy(volume = percent) }
        withMpv { mpv, here -> mpv.mpv_set_property_string(here, "volume", percent.coerceIn(0, 200).toString()) }
    }

    override fun selectSubtitle(id: String?) {
        mutable.update { it.copy(subtitle = id) }
        withMpv { mpv, here -> mpv.mpv_set_property_string(here, "sid", id ?: "no") }
    }

    override fun selectAudio(id: String) {
        mutable.update { it.copy(audio = id) }
        withMpv { mpv, here -> mpv.mpv_set_property_string(here, "aid", id) }
    }

    // mpv changes the look of its subtitles while it plays.
    override fun setSubtitleStyle(style: SubtitleStyle) {
        subtitleStyle = style
        withMpv { mpv, here ->
            for ((name, value) in subtitleOptions(style, lifted)) mpv.mpv_set_property_string(here, name, value)
        }
    }

    override fun setSubtitleLift(share: Float) {
        if (lifted == share) return
        lifted = share
        val margin = subtitleMargin(subtitleStyle, lifted)
        withMpv { mpv, here -> mpv.mpv_set_property_string(here, "sub-margin-y", margin) }
    }

    // Lets mpv go away from the screen, since it waits for what it plays to stop.
    override fun release() {
        val (mpv, here, context) = synchronized(this) {
            alive = false
            Triple(api, handle, render).also {
                handle = null
                render = null
            }
        }
        thumbnailer?.close()
        frames.release()
        scope.cancel()
        if (mpv != null && here != null) {
            thread(name = "mpv release", isDaemon = true) {
                if (context != null) {
                    // The thread that draws holds the render context while it draws, so it is let go only once that thread has stopped.
                    synchronized(update) {
                        mpv.mpv_render_context_set_update_callback(context, null, null)
                        mpv.mpv_render_context_free(context)
                    }
                }
                mpv.mpv_terminate_destroy(here)
            }
        }
        frame.value = null
        while (true) made.pollFirst()?.close() ?: break
    }

    // Runs a change on mpv away from the screen once it is ready, or not at all when it never became ready.
    private fun withMpv(change: (MpvApi, Pointer) -> Unit) {
        scope.launch {
            ready.join()
            val mpv = api ?: return@launch
            val here = handle ?: return@launch
            change(mpv, here)
        }
    }

    // Waits for what mpv says, and between its messages reads where the video is.
    private fun listen(mpv: MpvApi, here: Pointer) {
        while (alive) {
            val event = mpv.mpv_wait_event(here, LookEvery)
            when (event.getInt(0)) {
                Mpv.EventShutdown -> return

                Mpv.EventFileLoaded -> loaded(mpv, here)

                Mpv.EventVideoReconfig -> {
                    videoWidth = mpv.number(here, "dwidth")?.toInt() ?: 0
                    videoHeight = mpv.number(here, "dheight")?.toInt() ?: 0
                    mutable.update { it.copy(videoWidth = videoWidth, videoHeight = videoHeight) }
                }

                Mpv.EventPlaybackRestart -> mutable.update { it.copy(buffering = false) }

                Mpv.EventLogMessage -> {
                    val data = event.getPointer(Native.POINTER_SIZE.toLong() * 2)
                    val prefix = data?.getPointer(0)?.getString(0).orEmpty()
                    val text = data
                        ?.getPointer(Native.POINTER_SIZE.toLong() * 2)
                        ?.getString(0)
                        .orEmpty()
                        .trim()
                    if (text.isNotEmpty()) AppLog.warn("mpv", "$prefix: $text")
                    if (signs.read(text)) mutable.update { it.copy(message = text) }
                }

                Mpv.EventEndFile -> {
                    val data = event.getPointer(Native.POINTER_SIZE.toLong() * 2)
                    when (data?.getInt(0)) {
                        Mpv.EndEof -> mutable.update { it.copy(playing = false, ended = true) }

                        Mpv.EndError -> {
                            val reason = signs.cutAt?.let(::cutReason) ?: mpv.mpv_error_string(data.getInt(4))
                            AppLog.warn("mpv", "the video stopped with an error, $reason")
                            mutable.update {
                                it.copy(
                                    problem = PlayerProblem.Failed,
                                    message = reason,
                                    buffering = false,
                                    playing = false,
                                )
                            }
                        }
                    }
                }
            }
            if (alive) look(mpv, here)
        }
    }

    // The video is loaded: the subtitle files are added, and the tracks are read.
    private fun loaded(mpv: MpvApi, here: Pointer) {
        for (track in pending) {
            track.url?.let { url -> mpv.command(here, "sub-add", url, "auto", track.label, track.language.orEmpty()) }
        }
        pending = emptyList()
        mutable.update { it.copy(ready = true, ended = false) }
        readTracks(mpv, here)
    }

    // Where the video is, how long it is, whether it plays or waits for the network, and how far ahead it has loaded.
    private fun look(mpv: MpvApi, here: Pointer) {
        val position = mpv.number(here, "time-pos")
        val length = mpv.number(here, "duration")
        val paused = mpv.text(here, "pause") == "yes"
        val waiting = mpv.text(here, "paused-for-cache") == "yes" || mpv.text(here, "seeking") == "yes"
        val ahead = mpv.number(here, "demuxer-cache-time")
        val ended = mpv.text(here, "eof-reached") == "yes"
        mutable.update { now ->
            now.copy(
                positionMs = position?.let { (it * 1000).toLong() } ?: now.positionMs,
                durationMs = length?.let { (it * 1000).toLong() } ?: now.durationMs,
                bufferedMs = ahead?.let { (it * 1000).toLong() } ?: now.bufferedMs,
                playing = now.ready && !paused && !ended,
                buffering = if (now.ready) waiting else now.buffering,
                ended = now.ended || ended,
            )
        }
        // The list of tracks grows when a subtitle file is added after the video loaded.
        val count = mpv.number(here, "track-list/count")?.toInt() ?: 0
        if (count != knownTracks) readTracks(mpv, here)
    }

    @Volatile private var knownTracks = -1

    // The subtitle and audio tracks mpv knows, read again when their number changes.
    private fun readTracks(mpv: MpvApi, here: Pointer) {
        val count = mpv.number(here, "track-list/count")?.toInt() ?: 0
        knownTracks = count
        val found = mpv.tracks(here, count)
        mutable.update {
            it.copy(subtitles = found.subtitles, audios = found.audios, subtitle = found.subtitle, audio = found.audio)
        }
    }

    // Draws each frame mpv has ready into memory and makes an image of it for the screen.
    private fun draw(mpv: MpvApi, context: Pointer) {
        val size = Memory(8)
        val stride = Memory(8)
        val format = Mpv.text("bgr0")
        while (alive) {
            frames.tryAcquire(200, TimeUnit.MILLISECONDS)
            synchronized(update) {
                if (!alive) return
                if (mpv.mpv_render_context_update(context) and Mpv.UpdateFrame == 0L) return@synchronized
                val sourceWidth = videoWidth
                val sourceHeight = videoHeight
                if (sourceWidth <= 0 || sourceHeight <= 0) return@synchronized
                val width = sourceWidth.coerceAtMost(WidestFrame)
                val height = (sourceHeight.toLong() * width / sourceWidth).toInt().coerceAtLeast(1)
                val rowBytes = width * 4L
                val memory =
                    buffer?.takeIf { it.size() == rowBytes * height } ?: Memory(rowBytes * height).also { buffer = it }
                size.setInt(0, width)
                size.setInt(4, height)
                if (Native.SIZE_T_SIZE == 8) stride.setLong(0, rowBytes) else stride.setInt(0, rowBytes.toInt())
                val params = Mpv.params(
                    Mpv.ParamSwSize to size,
                    Mpv.ParamSwFormat to format,
                    Mpv.ParamSwStride to stride,
                    Mpv.ParamSwPointer to memory,
                )
                if (mpv.mpv_render_context_render(context, params) >= 0) show(memory, width, height)
            }
        }
    }

    // Makes an image of the frame mpv drew. The earlier of the two images kept is freed. Called by the screen once it has drawn a frame: every frame made before it is freed.
    fun drawn(image: Image) {
        while (true) {
            val oldest = made.peekFirst() ?: return
            if (oldest === image) return
            made.pollFirst()?.close()
        }
    }

    private fun show(memory: Memory, width: Int, height: Int) {
        // A screen that has fallen behind, or is out of sight, gets no more frames until it catches up.
        if (made.size >= MostWaiting) return
        val count = width * height * 4
        if (bytes.size != count) bytes = ByteArray(count)
        memory.read(0, bytes, 0, count)
        val image = Image.makeRaster(
            ImageInfo(width, height, ColorType.BGRA_8888, ColorAlphaType.OPAQUE),
            bytes,
            width * 4,
        )
        made.addLast(image)
        frame.value = image
    }
}
