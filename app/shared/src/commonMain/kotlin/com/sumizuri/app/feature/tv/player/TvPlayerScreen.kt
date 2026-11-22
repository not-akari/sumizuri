package com.sumizuri.app.feature.tv.player

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.player.AmbientGlow
import com.sumizuri.app.feature.player.PlayerPhase
import com.sumizuri.app.feature.player.PlayerSession
import com.sumizuri.app.feature.player.overlay.ActiveMarker
import com.sumizuri.app.feature.player.overlay.PlayerFailureView
import com.sumizuri.app.feature.player.overlay.PlayerGestureMath
import com.sumizuri.app.feature.player.overlay.PlayerLoading
import com.sumizuri.app.feature.player.overlay.PlayerMarkers
import com.sumizuri.app.feature.player.picker.Picker
import com.sumizuri.app.playback.AspectMode
import com.sumizuri.app.playback.PlayerEngine
import com.sumizuri.app.playback.PlayerSurface
import com.sumizuri.app.playback.PlayerSystemUi
import kotlinx.coroutines.delay

// What of the controls shows: nothing, the line of time alone after a jump or a pause, the line with its buttons, or the episodes of the season.
internal enum class TvControls { Hidden, Bar, Buttons, Episodes }

// How far up the subtitles go, as a share of the screen, over the line of time alone and over the whole controls.
private const val BarLift = 0.3f
private const val ControlsLift = 0.56f

// How long the controls stay after the last key while the video plays.
private const val HideMs = 5000L

// A press of left or right this soon after the last one counts as holding it, and the jumps grow.
private const val HoldGapMs = 450L

// The player on a TV, moved with the remote. While watching nothing is on the screen. OK pauses or plays and shows the line of time, or skips the intro while its button shows. Left and right jump 10 seconds, more as the key is held. Up, down or OK shows the buttons first, and down from them the episodes of the season. Subtitles, audio, quality and speed open as a row of cards where the buttons were. Back closes that row, then hides the controls, then leaves. The media keys of a remote work at any time.
@Composable
internal fun TvPlayerScreen(session: PlayerSession, engine: PlayerEngine, onClose: () -> Unit) {
    val state by session.state.collectAsStateWithLifecycle()
    val player by engine.state.collectAsStateWithLifecycle()
    val prefs = state.prefs
    var controls by remember { mutableStateOf(TvControls.Hidden) }
    // The choice open as a row of cards in place of the buttons.
    var strip by remember { mutableStateOf<Picker?>(null) }
    var tick by remember { mutableIntStateOf(0) }
    var rootFocused by remember { mutableStateOf(false) }
    val root = remember { FocusRequester() }
    val hold = remember { HoldCount() }
    val failed = state.phase == PlayerPhase.Failed
    val video = state.current
    val marker = video?.let { PlayerMarkers.active(player.positionMs, it.intro, it.outro, player.durationMs) }
    PlayerSystemUi(keepOn = player.playing)
    LaunchedEffect(Unit) { runCatching { root.requestFocus() } }

    fun show(to: TvControls) {
        controls = to
        tick++
    }

    // Hiding gives the focus back to the player first, so the remote keeps working on it.
    fun hide() {
        runCatching { root.requestFocus() }
        controls = TvControls.Hidden
        strip = null
    }

    fun seek(forward: Boolean) {
        val step = hold.step(nowMillis())
        val now = engine.state.value
        engine.seekTo(PlayerGestureMath.clamp(now.positionMs + if (forward) step else -step, now.durationMs))
        if (controls == TvControls.Hidden) show(TvControls.Bar) else tick++
    }

    fun playPause() {
        if (engine.state.value.playing) engine.pause() else engine.play()
        if (controls == TvControls.Hidden) show(TvControls.Bar) else tick++
    }

    fun skip(found: ActiveMarker) {
        if (found.endsEpisode && state.hasNext) session.nextEpisode() else engine.seekTo(found.skipToMs)
    }

    // The controls leave a few seconds after the last key while the video plays and no choice is open. A paused video keeps them.
    LaunchedEffect(tick, controls, player.playing, strip) {
        if (controls != TvControls.Hidden && player.playing && strip == null) {
            delay(HideMs)
            hide()
        }
    }
    NavigationBackHandler(
        rememberNavigationEventState(NavigationEventInfo.None),
        isBackEnabled =
        strip != null || controls != TvControls.Hidden,
    ) {
        if (strip != null) strip = null else hide()
    }
    LaunchedEffect(controls) { if (controls == TvControls.Episodes) session.reloadEpisodes() }
    // The subtitles rise over the controls while they show.
    LaunchedEffect(controls) {
        engine.setSubtitleLift(
            when (controls) {
                TvControls.Hidden -> 0f
                TvControls.Bar -> BarLift
                else -> ControlsLift
            },
        )
    }
    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black)
            .onPreviewKeyEvent { event ->
                if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                // The media keys of a remote work wherever the focus is.
                when (event.key) {
                    Key.MediaPlayPause, Key.MediaPlay, Key.MediaPause -> return@onPreviewKeyEvent true.also {
                        playPause()
                    }

                    Key.MediaFastForward -> return@onPreviewKeyEvent true.also { seek(true) }

                    Key.MediaRewind -> return@onPreviewKeyEvent true.also { seek(false) }

                    Key.MediaNext -> return@onPreviewKeyEvent true.also { if (state.hasNext) session.nextEpisode() }

                    Key.MediaPrevious -> return@onPreviewKeyEvent true.also {
                        if (state.hasPrevious) {
                            session
                                .previousEpisode()
                        }
                    }
                }
                // Any key keeps the controls up a while longer.
                tick++
                // While the buttons or a row hold the focus, the keys move it. Otherwise the player takes them, wherever the focus was left.
                if (failed || controls == TvControls.Buttons ||
                    controls == TvControls.Episodes
                ) {
                    return@onPreviewKeyEvent false
                }
                if (!rootFocused) runCatching { root.requestFocus() }
                when (event.key) {
                    Key.DirectionCenter, Key.Enter, Key.NumPadEnter -> if (marker != null &&
                        controls == TvControls.Hidden
                    ) {
                        skip(marker)
                    } else {
                        playPause()
                        show(TvControls.Buttons)
                    }

                    Key.DirectionLeft -> seek(false)

                    Key.DirectionRight -> seek(true)

                    Key.DirectionUp -> show(TvControls.Buttons)

                    Key.DirectionDown -> show(TvControls.Buttons)

                    else -> return@onPreviewKeyEvent false
                }
                true
            }.onFocusChanged { rootFocused = it.isFocused }
            .focusRequester(root)
            .focusable(),
    ) {
        val ambient by engine.ambient.collectAsState()
        val aspect = prefs.aspect
        LaunchedEffect(prefs.ambient, aspect) { engine.setAmbient(prefs.ambient && aspect == AspectMode.Fit) }
        if (prefs.ambient && aspect == AspectMode.Fit) AmbientGlow(ambient, Modifier.fillMaxSize())
        PlayerSurface(engine, aspect, Modifier.fillMaxSize())
        if (failed) {
            PlayerFailureView(state, session::solve, session::tryAnotherVideo, session::retry, onClose)
            return@Box
        }
        PlayerLoading(state, player, controls = controls != TvControls.Hidden, Modifier.align(Alignment.Center))
        // The skip of an intro or an ending shows on its own while the controls are hidden, and OK takes it.
        AnimatedVisibility(
            marker != null && controls == TvControls.Hidden,
            Modifier.align(Alignment.BottomEnd),
            enter = fadeIn(),
            exit = fadeOut(),
        ) {
            TvSkipHint(marker)
        }
        AnimatedVisibility(controls != TvControls.Hidden, enter = fadeIn(), exit = fadeOut()) {
            TvPlayerControls(
                state,
                player,
                controls,
                strip,
                marker,
                TvControlCalls(
                    onPlayPause = ::playPause,
                    onSeek = ::seek,
                    onPrevious = if (state.hasPrevious) ({ session.previousEpisode() }) else null,
                    onNext = if (state.hasNext) ({ session.nextEpisode() }) else null,
                    onSkip = ::skip,
                    onOpen = { picked ->
                        if (picked == Picker.Episodes) show(TvControls.Episodes) else strip = picked
                        tick++
                    },
                    onCloseStrip = { strip = null },
                    onEpisode = { id ->
                        hide()
                        session.openEpisode(id)
                    },
                    onShow = ::show,
                ),
                StripCalls(
                    onEpisode = { id ->
                        hide()
                        session.openEpisode(id)
                    },
                    onSubtitle = { id ->
                        strip = null
                        engine.selectSubtitle(id)
                    },
                    onAudio = { id ->
                        strip = null
                        engine.selectAudio(id)
                    },
                    onVideo = { video ->
                        strip = null
                        session.selectVideo(video)
                    },
                    onSpeed = { speed ->
                        strip = null
                        engine.setSpeed(speed)
                    },
                ),
            )
        }
    }
}

// Counts how long left or right has been held by how quickly the presses come, so a held key jumps further: 10 seconds, then 30, then a minute.
private class HoldCount {
    private var last = 0L
    private var streak = 0

    fun step(now: Long): Long {
        streak = if (now - last < HoldGapMs) streak + 1 else 0
        last = now
        return when {
            streak < 4 -> 10_000L
            streak < 12 -> 30_000L
            else -> 60_000L
        }
    }
}
