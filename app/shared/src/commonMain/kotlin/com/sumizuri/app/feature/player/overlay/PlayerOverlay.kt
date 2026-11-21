package com.sumizuri.app.feature.player.overlay

import androidx.compose.animation.AnimatedVisibilityScope
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.VolumeDown
import androidx.compose.material.icons.automirrored.outlined.VolumeOff
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.outlined.Fullscreen
import androidx.compose.material.icons.outlined.FullscreenExit
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.PictureInPictureAlt
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.SkipNext
import androidx.compose.material.icons.rounded.SkipPrevious
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.feature.player.PlayerPhase
import com.sumizuri.app.feature.player.SessionState
import com.sumizuri.app.feature.player.picker.Picker
import com.sumizuri.app.playback.PlayerState
import com.sumizuri.app.playback.VideoThumbnail
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_back_seconds
import com.sumizuri.app.shared.resources.player_close
import com.sumizuri.app.shared.resources.player_forward_seconds
import com.sumizuri.app.shared.resources.player_fullscreen_short
import com.sumizuri.app.shared.resources.player_lock_short
import com.sumizuri.app.shared.resources.player_mini_short
import com.sumizuri.app.shared.resources.player_next
import com.sumizuri.app.shared.resources.player_pause
import com.sumizuri.app.shared.resources.player_play
import com.sumizuri.app.shared.resources.player_previous
import com.sumizuri.app.shared.resources.player_volume
import com.sumizuri.app.ui.kit.dock.DockAction
import com.sumizuri.app.ui.kit.dock.DockMargin
import com.sumizuri.app.ui.kit.dock.IslandHang
import com.sumizuri.app.ui.kit.dock.IslandInside
import com.sumizuri.app.ui.kit.dock.IslandSurface
import com.sumizuri.app.ui.kit.dock.IslandWidth
import com.sumizuri.app.ui.kit.dock.LocalDockLabels
import com.sumizuri.app.ui.kit.dock.WideIslandWidth
import com.sumizuri.app.ui.kit.dock.cascade
import com.sumizuri.app.ui.kit.dock.isWideWindow
import com.sumizuri.app.ui.kit.input.InkSlider
import com.sumizuri.app.ui.text.numberedName
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// How solid the island is over the video, and the room each named action takes in the row of a wide island.
private const val IslandShade = 0.92f
private val WideActionWidth = 72.dp

// The controls over the video, built like the reader: the buttons to play in the middle, and one island at the bottom. On a phone the island holds the way back with the names, the line to jump along and a row of named actions, and a choice opens inside it above them. On a wide window the names and the named actions share one row, the line runs under them with the sound and the window buttons at its end, and a choice hangs above the right end. The island slides up as it shows, a ring of ink spreads from it once, and its rows rise in from the bottom one after another.
@Composable
internal fun AnimatedVisibilityScope.PlayerOverlay(
    session: SessionState,
    engine: PlayerState,
    fullscreen: Boolean,
    calls: OverlayCalls,
    thumbnail: VideoThumbnail? = null,
    // The choice open in the island, and what each choice shows.
    picker: Picker? = null,
    pickerContent: @Composable (Picker) -> Unit = {},
    // Told how tall the island is, so the buttons in the corners sit just above it.
    onIslandRoom: (Dp) -> Unit = {},
) {
    val reduce = LocalReduceMotion.current
    val wide = isWideWindow()
    val density = LocalDensity.current
    // A choice takes at most half the height of the window, so the video stays in sight.
    val panelMax = with(density) { (LocalWindowInfo.current.containerSize.height * 0.5f).toDp() }
    val actions = playerActions(session, engine, picker, calls)
    val choice: @Composable (Picker?) -> Unit = { shown -> shown?.let { pickerContent(it) } }
    val seek: @Composable (Modifier) -> Unit = { look ->
        SeekBar(
            engine.positionMs,
            engine.bufferedMs,
            engine.durationMs,
            calls.onSeek,
            calls.onScrubStart,
            calls.onScrubEnd,
            look,
            thumbnail = thumbnail,
            onPreview = calls.onPreview,
        )
    }
    Box(Modifier.fillMaxSize()) {
        // While the episode is still being found or opened, the loading card in the middle takes the place of the buttons. An open choice puts them away, so it never sits over them.
        if (picker == null && session.phase != PlayerPhase.Loading) {
            Box(Modifier.align(Alignment.Center)) { Transport(session, engine, calls) }
        }
        Box(
            Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .windowInsetsPadding(
                    WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom + WindowInsetsSides.Horizontal),
                ).onSizeChanged { onIslandRoom(with(density) { it.height.toDp() }) }
                .padding(DockMargin)
                .animateEnterExit(
                    enter = if (reduce) EnterTransition.None else slideInVertically(spring(0.8f, 420f)) { it / 3 },
                    exit = if (reduce) ExitTransition.None else slideOutVertically(tween(140)) { it / 4 },
                ),
            contentAlignment = Alignment.BottomCenter,
        ) {
            Column(
                Modifier.widthIn(max = if (wide) WideIslandWidth else IslandWidth).fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                if (wide) IslandHang(picker, null, true, panelMax, choice)
                // Solid while a choice is open inside it, so its words never sit over the video.
                IslandSurface(open = true, shade = IslandShade, solid = picker != null && !wide) {
                    Column(Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 4.dp)) {
                        if (wide) {
                            CompositionLocalProvider(LocalDockLabels provides true) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    TitleRow(session, calls, Modifier.weight(1f).cascade(1, reduce, true))
                                    Row(Modifier.width(WideActionWidth * actions.size).cascade(2, reduce, true)) {
                                        actions.forEach { DockAction(it.icon, it.label, it.active, it.onClick) }
                                    }
                                }
                            }
                            Row(Modifier.cascade(0, reduce, true), verticalAlignment = Alignment.CenterVertically) {
                                seek(Modifier.weight(1f))
                                WindowButtons(engine.volume, fullscreen, calls)
                            }
                        } else {
                            IslandInside(picker, null, true, panelMax, choice)
                            Row(Modifier.cascade(2, reduce, true), verticalAlignment = Alignment.CenterVertically) {
                                TitleRow(session, calls, Modifier.weight(1f))
                                WindowButtons(engine.volume, fullscreen, calls)
                            }
                            seek(Modifier.cascade(1, reduce, true))
                            CompositionLocalProvider(LocalDockLabels provides true) {
                                Row(Modifier.fillMaxWidth().padding(vertical = 2.dp).cascade(0, reduce, true)) {
                                    actions.forEach { DockAction(it.icon, it.label, it.active, it.onClick) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// The way back, and the episode with the title under it.
@Composable
private fun TitleRow(session: SessionState, calls: OverlayCalls, modifier: Modifier = Modifier) {
    val episode = session.episode
    Row(modifier.padding(horizontal = 4.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        IconButton(
            calls.onClose,
        ) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, stringResource(Res.string.player_close)) }
        Column(Modifier.weight(1f).padding(start = 4.dp)) {
            Text(
                episode?.let { numberedName(Kind.Anime, it.number, it.name) }.orEmpty(),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (session.titleName.isNotBlank()) {
                Text(
                    session.titleName,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

// The buttons for the window: the sound on a computer, the small player, and full screen on a computer or the lock on a phone.
@Composable
private fun WindowButtons(volume: Int, fullscreen: Boolean, calls: OverlayCalls) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        // The speaker mutes or brings the sound back, the bar sets it.
        calls.onVolume?.let { set ->
            IconButton({ set(if (volume > 0) 0 else 100) }) {
                Icon(
                    when {
                        volume <= 0 -> Icons.AutoMirrored.Outlined.VolumeOff
                        volume < 50 -> Icons.AutoMirrored.Outlined.VolumeDown
                        else -> Icons.AutoMirrored.Outlined.VolumeUp
                    },
                    stringResource(Res.string.player_volume),
                )
            }
            InkSlider(volume.toFloat(), { set(it.roundToInt()) }, Modifier.width(96.dp), valueRange = 0f..100f)
        }
        calls.onMini?.let {
            IconButton(it) { Icon(Icons.Outlined.PictureInPictureAlt, stringResource(Res.string.player_mini_short)) }
        }
        val toggle = calls.onFullscreen
        if (toggle == null) {
            IconButton(calls.onLock) { Icon(Icons.Outlined.Lock, stringResource(Res.string.player_lock_short)) }
        } else {
            IconButton(toggle) {
                Icon(
                    if (fullscreen) Icons.Outlined.FullscreenExit else Icons.Outlined.Fullscreen,
                    stringResource(Res.string.player_fullscreen_short),
                )
            }
        }
    }
}

// The buttons to play in the middle of the video: the episode before, a jump back, play or pause, a jump on, and the episode after.
@Composable
private fun Transport(session: SessionState, engine: PlayerState, calls: OverlayCalls) {
    val jump = session.prefs.doubleTapSeconds
    Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
        RoundButton(Icons.Rounded.SkipPrevious, 44, stringResource(Res.string.player_previous), calls.onPrevious)
        RoundButton(jumpIcon(jump, forward = false), 52, stringResource(Res.string.player_back_seconds, jump), {
            calls.onJump(false)
        })
        RoundButton(
            if (engine.playing) Icons.Rounded.Pause else Icons.Rounded.PlayArrow,
            72,
            stringResource(if (engine.playing) Res.string.player_pause else Res.string.player_play),
            calls.onPlayPause,
            primary = true,
            busy = engine.buffering,
        )
        RoundButton(jumpIcon(jump, forward = true), 52, stringResource(Res.string.player_forward_seconds, jump), {
            calls.onJump(true)
        })
        RoundButton(Icons.Rounded.SkipNext, 44, stringResource(Res.string.player_next), calls.onNext)
    }
}
