package com.sumizuri.app.feature.player

import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.FastForward
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isAltPressed
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.feature.player.overlay.ActiveMarker
import com.sumizuri.app.feature.player.overlay.OverlayCalls
import com.sumizuri.app.feature.player.overlay.PlayerFailureView
import com.sumizuri.app.feature.player.overlay.PlayerGestureLayer
import com.sumizuri.app.feature.player.overlay.PlayerGestureMath
import com.sumizuri.app.feature.player.overlay.PlayerLoading
import com.sumizuri.app.feature.player.overlay.PlayerLockedOverlay
import com.sumizuri.app.feature.player.overlay.PlayerLogPanel
import com.sumizuri.app.feature.player.overlay.PlayerOverlay
import com.sumizuri.app.feature.player.overlay.jumpIcon
import com.sumizuri.app.feature.player.picker.Picker
import com.sumizuri.app.feature.player.picker.PickerCalls
import com.sumizuri.app.feature.player.picker.PlayerPicker
import com.sumizuri.app.playback.AspectMode
import com.sumizuri.app.playback.LocalFullscreen
import com.sumizuri.app.playback.LocalMiniPlayer
import com.sumizuri.app.playback.PlayerEngine
import com.sumizuri.app.playback.PlayerSurface
import com.sumizuri.app.playback.PlayerSystemUi
import com.sumizuri.app.playback.PlayingNow
import com.sumizuri.app.playback.touchPlayer
import com.sumizuri.app.ui.kit.dock.AsideCard
import com.sumizuri.app.ui.kit.dock.KeepLast
import com.sumizuri.app.ui.kit.dock.isWideWindow
import com.sumizuri.app.ui.kit.input.FileKind
import com.sumizuri.app.ui.kit.input.rememberFilePicker
import kotlinx.coroutines.delay

// How far the arrow keys jump, how long the jump icon stays, how long the button to unlock stays, and the room kept under the buttons over the video while the controls show and while they are hidden.
private const val ArrowJumpMs = 5000L
private const val FlashMs = 550L
private const val UnlockMs = 2000L

// The screen of the player, laid out as in Flutter. The picture fills it. A tap shows or hides the controls, a double tap jumps on a phone and goes full screen on a computer, the keys and the wheel of the mouse work, and the controls can be locked. Buttons float over the picture to skip an intro or go on to the next episode. A failure takes the whole screen, and a choice opens in a panel.
@Composable
internal fun PlayerScreen(session: PlayerSession, engine: PlayerEngine, onClose: () -> Unit) {
    val state by session.state.collectAsStateWithLifecycle()
    val player by engine.state.collectAsStateWithLifecycle()
    val prefs = state.prefs
    val fullscreen = LocalFullscreen.current
    // The small floating player. While it shows, only the picture is drawn: a tap plays or pauses, and a double tap brings the player back.
    val mini = LocalMiniPlayer.current
    val small = mini?.active == true
    val shape = if (player.videoWidth > 0 &&
        player.videoHeight > 0
    ) {
        player.videoWidth.toFloat() / player.videoHeight
    } else {
        16f / 9f
    }
    LaunchedEffect(player.playing, shape) { PlayingNow.aspect = shape.takeIf { player.playing } }
    // Leaving the player any way at all (the back arrow, the next screen) gives the window its size back, not only Escape.
    val latestFullscreen by rememberUpdatedState(fullscreen)
    DisposableEffect(Unit) {
        onDispose {
            PlayingNow.aspect = null
            latestFullscreen?.takeIf { it.active }?.toggle()
        }
    }
    var visible by remember { mutableStateOf(true) }
    var tick by remember { mutableIntStateOf(0) }
    var scrubbing by remember { mutableStateOf(false) }
    var locked by remember { mutableStateOf(false) }
    var unlockShown by remember { mutableStateOf(false) }
    var flash by remember { mutableStateOf<Pair<ImageVector, Alignment>?>(null) }
    var picker by remember { mutableStateOf<Picker?>(null) }
    var logShown by remember(prefs.showLog) { mutableStateOf(prefs.showLog) }
    var aspect by remember(prefs.aspect) { mutableStateOf(prefs.aspect) }
    val focus = remember { FocusRequester() }
    val failed = state.phase == PlayerPhase.Failed
    val pickSubtitle =
        rememberFilePicker(FileKind.Subtitles) { path -> session.loadSubtitle(path.toString(), path.name) }
    PlayerSystemUi(keepOn = player.playing)
    // The back key of the phone closes an open choice first.
    val backState = rememberNavigationEventState(NavigationEventInfo.None)
    NavigationBackHandler(backState, isBackEnabled = picker != null) { picker = null }

    LaunchedEffect(Unit) { focus.requestFocus() }
    // The controls go a few seconds after the last touch while the video plays, and stay while the line is dragged or a choice is open.
    LaunchedEffect(tick, player.playing, visible, scrubbing, picker) {
        if (visible && player.playing && !scrubbing && picker == null && prefs.hideControlsSeconds > 0) {
            delay(prefs.hideControlsSeconds * 1000L)
            visible = false
        }
    }
    // Subtitles that the engine draws as a layer of their own stand higher while the bar shows.
    LaunchedEffect(visible, locked) { engine.setSubtitleLift(visible && !locked) }
    LaunchedEffect(flash) {
        if (flash != null) {
            delay(FlashMs)
            flash = null
        }
    }
    LaunchedEffect(unlockShown) {
        if (unlockShown) {
            delay(UnlockMs)
            unlockShown = false
        }
    }
    LaunchedEffect(picker) { if (picker == Picker.Episodes) session.reloadEpisodes() }

    fun show() {
        visible = true
        tick++
    }

    // Hiding the controls folds an open choice away with them.
    fun toggle() {
        if (visible) {
            visible = false
            picker = null
        } else {
            show()
        }
    }
    fun seekBy(deltaMs: Long) {
        val now = engine.state.value
        engine.seekTo(PlayerGestureMath.clamp(now.positionMs + deltaMs, now.durationMs))
    }
    fun skip(forward: Boolean) {
        val jump = prefs.doubleTapSeconds * 1000L
        seekBy(if (forward) jump else -jump)
        flash = jumpIcon(prefs.doubleTapSeconds, forward) to if (forward) Alignment.CenterEnd else Alignment.CenterStart
    }
    fun volumeBy(delta: Int) = engine.setVolume((engine.state.value.volume + delta).coerceIn(0, 100))
    fun volumeTo(percent: Int) = engine.setVolume(percent).also { show() }
    fun playPause() {
        if (engine.state.value.playing) engine.pause() else engine.play()
        show()
    }
    fun cycleFit() {
        val next = AspectMode.entries[(aspect.ordinal + 1) % AspectMode.entries.size]
        aspect = next
        session.updatePrefs { it.copy(aspect = next) }
        show()
    }
    fun doubleTap(share: Float) {
        when {
            !touchPlayer && fullscreen != null -> fullscreen.toggle()
            !prefs.doubleTapSeek -> playPause()
            share < 0.4f -> skip(false)
            share > 0.6f -> skip(true)
            else -> playPause()
        }
    }

    // Escape closes an open choice first, then leaves full screen, then the player.
    fun back() {
        when {
            picker != null -> picker = null
            fullscreen?.active == true -> fullscreen.toggle()
            else -> onClose()
        }
    }
    fun skipMarker(marker: ActiveMarker) {
        if (marker.endsEpisode && state.hasNext) {
            session.nextEpisode()
        } else {
            engine.seekTo(marker.skipToMs)
            flash = Icons.Rounded.FastForward to Alignment.Center
        }
        show()
    }

    val calls = OverlayCalls(
        onClose = onClose,
        onPlayPause = ::playPause,
        onJump = { forward ->
            skip(forward)
            show()
        },
        onPrevious = if (state.hasPrevious) ({ session.previousEpisode() }) else null,
        onNext = if (state.hasNext) ({ session.nextEpisode() }) else null,
        onSeek = { engine.seekTo(it) },
        onScrubStart = { scrubbing = true },
        onScrubEnd = { scrubbing = false },
        // An action opens its choice in the dock, and the same action closes it again.
        onOpen = {
            picker = if (picker == it) null else it
            show()
        },
        onLock = {
            locked = true
            visible = false
            unlockShown = false
        },
        onFullscreen = if (touchPlayer) {
            null
        } else {
            fullscreen?.let { control ->
                {
                    control.toggle()
                    show()
                }
            }
        },
        onFit = ::cycleFit,
        onPreview = engine::thumbnailAt,
        onMini = mini?.let { control -> { control.enter(shape) } },
        onVolume = if (touchPlayer) null else ::volumeTo,
    )
    val pickerCalls = PickerCalls(
        onClose = { picker = null },
        onOpen = { picker = it },
        onEpisode = { id ->
            picker = null
            session.openEpisode(id)
        },
        onSpeed = { speed ->
            picker = null
            engine.setSpeed(speed)
        },
        onVideo = { video ->
            picker = null
            session.selectVideo(video)
        },
        onSubtitle = { id ->
            picker = null
            engine.selectSubtitle(id)
        },
        onLoadSubtitle = {
            picker = null
            pickSubtitle()
        },
        onAudio = { id ->
            picker = null
            engine.selectAudio(id)
        },
        onFit = {
            picker = null
            cycleFit()
        },
        onToggleLog = {
            picker = null
            logShown = !logShown
        },
    )

    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(focus)
            .focusable()
            .onPreviewKeyEvent { event ->
                val plain = event.type == KeyEventType.KeyDown && !event.isCtrlPressed && !event.isAltPressed
                if (!plain) return@onPreviewKeyEvent false
                when (event.key) {
                    Key.Spacebar, Key.K -> playPause()
                    Key.DirectionLeft -> seekBy(-ArrowJumpMs)
                    Key.DirectionRight -> seekBy(ArrowJumpMs)
                    Key.J -> skip(false)
                    Key.L -> skip(true)
                    Key.DirectionUp -> volumeBy(5)
                    Key.DirectionDown -> volumeBy(-5)
                    Key.M -> engine.setVolume(if (engine.state.value.volume > 0) 0 else 100)
                    Key.F -> fullscreen?.toggle()
                    Key.N -> if (state.hasNext) session.nextEpisode()
                    Key.P -> if (state.hasPrevious) session.previousEpisode()
                    Key.Escape -> back()
                    else -> return@onPreviewKeyEvent false
                }
                true
            }.pointerInput(touchPlayer) {
                awaitPointerEventScope {
                    while (true) {
                        val event = awaitPointerEvent()
                        if (touchPlayer) continue
                        // The wheel sets the volume and a move of the mouse brings the controls back.
                        val wheel = event.changes
                            .first()
                            .scrollDelta.y
                        if (event.type == PointerEventType.Scroll && picker == null) volumeBy(if (wheel < 0) 5 else -5)
                        if (event.type == PointerEventType.Move) show()
                    }
                }
            },
    ) {
        // On a wide window a choice opens as a small card at the bottom right, over the video, which keeps its size.
        val aside = isWideWindow() && visible && !small && !failed && picker != null
        AsideCard(
            aside,
            Modifier.fillMaxSize(),
            panel = { KeepLast(picker) { PlayerPicker(it, state, player, aspect, logShown, pickerCalls) } },
        ) {
            Box(Modifier.fillMaxSize()) {
                // The light around the video, only where bars are left around the picture.
                val ambient by engine.ambient.collectAsState()
                val thumbnail by engine.thumbnail.collectAsState()
                LaunchedEffect(prefs.ambient, aspect) { engine.setAmbient(prefs.ambient && aspect == AspectMode.Fit) }
                if (prefs.ambient && aspect == AspectMode.Fit) AmbientGlow(ambient, Modifier.fillMaxSize())
                PlayerSurface(engine, aspect, Modifier.fillMaxSize())
                if (locked && !failed) {
                    PlayerLockedOverlay(unlockShown, onTap = { unlockShown = true }, onUnlock = {
                        locked = false
                        unlockShown = false
                        show()
                    })
                } else {
                    PlayerGestureLayer(
                        engine,
                        touch = touchPlayer && prefs.swipeGestures,
                        holdSpeed = prefs.holdSpeed,
                        onTap = if (small) ::playPause else ::toggle,
                        onDoubleTap = if (small) { _ -> mini.exit() } else ::doubleTap,
                    )
                    flash?.let { (icon, side) ->
                        Box(Modifier.fillMaxSize().padding(horizontal = 48.dp), contentAlignment = side) {
                            Icon(icon, null, Modifier.padding(0.dp), tint = Color.White)
                        }
                    }
                    if (failed) {
                        PlayerFailureView(state, session::solve, session::tryAnotherVideo, session::retry, onClose)
                    } else {
                        androidx.compose.animation.AnimatedVisibility(
                            visible && !small,
                            enter = fadeIn(),
                            exit = fadeOut(),
                        ) {
                            PlayerOverlay(
                                state,
                                player,
                                aspect,
                                fullscreen?.active == true,
                                calls,
                                thumbnail = thumbnail,
                                picker = picker,
                                pickerContent = { PlayerPicker(it, state, player, aspect, logShown, pickerCalls) },
                                pickerInDock = !aside,
                            )
                        }
                    }
                    if (logShown && (failed || visible)) {
                        val top = WindowInsetsSides.Top + WindowInsetsSides.Horizontal
                        PlayerCorner(Alignment.TopCenter, top, PaddingValues(start = 12.dp, end = 12.dp, top = 56.dp)) {
                            val name = state.episode?.let { "${state.titleName} ${it.number}" } ?: state.titleName
                            PlayerLogPanel(session.log, name)
                        }
                    }
                    if (!failed && picker == null) {
                        PlayerCornerButtons(state, player, visible, prefs.skipSeconds, ::skipMarker, {
                            seekBy(prefs.skipSeconds * 1000L)
                            flash = Icons.Rounded.FastForward to Alignment.Center
                            show()
                        }) { session.nextEpisode() }
                        PlayerLoading(state, player, controls = visible && !small, Modifier.align(Alignment.Center))
                    }
                }
            }
        }
    }
}
