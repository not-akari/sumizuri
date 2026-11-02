package com.sumizuri.app.feature.player.overlay

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.outlined.AspectRatio
import androidx.compose.material.icons.outlined.Fullscreen
import androidx.compose.material.icons.outlined.FullscreenExit
import androidx.compose.material.icons.outlined.HighQuality
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.PictureInPictureAlt
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.Subtitles
import androidx.compose.material.icons.outlined.Tune
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.feature.player.PlayerPhase
import com.sumizuri.app.feature.player.SessionState
import com.sumizuri.app.feature.player.VideoChoice
import com.sumizuri.app.feature.player.picker.Picker
import com.sumizuri.app.feature.player.picker.hasAnyAudio
import com.sumizuri.app.feature.player.picker.hasSubtitleChoices
import com.sumizuri.app.playback.AspectMode
import com.sumizuri.app.playback.PlayerState
import com.sumizuri.app.playback.VideoThumbnail
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_audio
import com.sumizuri.app.shared.resources.player_back_seconds
import com.sumizuri.app.shared.resources.player_close
import com.sumizuri.app.shared.resources.player_episodes
import com.sumizuri.app.shared.resources.player_forward_seconds
import com.sumizuri.app.shared.resources.player_fullscreen_short
import com.sumizuri.app.shared.resources.player_lock_short
import com.sumizuri.app.shared.resources.player_mini_short
import com.sumizuri.app.shared.resources.player_next
import com.sumizuri.app.shared.resources.player_pause
import com.sumizuri.app.shared.resources.player_play
import com.sumizuri.app.shared.resources.player_previous
import com.sumizuri.app.shared.resources.player_quality
import com.sumizuri.app.shared.resources.player_settings_title
import com.sumizuri.app.shared.resources.player_speed
import com.sumizuri.app.shared.resources.player_subtitles
import com.sumizuri.app.ui.kit.dock.DockAction
import com.sumizuri.app.ui.kit.dock.DockMargin
import com.sumizuri.app.ui.kit.dock.DockRule
import com.sumizuri.app.ui.kit.dock.DockSurface
import com.sumizuri.app.ui.kit.dock.LocalDockLabels
import com.sumizuri.app.ui.kit.dock.isWideWindow
import com.sumizuri.app.ui.kit.dock.panelChange
import com.sumizuri.app.ui.kit.dock.tellsAsideCard
import com.sumizuri.app.ui.text.numberedUnit
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource

// The widest the capsule and the dock grow on a big window.
private val DockWidth = 760.dp

// How wide the top and the dock grow on a wide window.
private val WideDockWidth = 1100.dp

// The controls over the video, built like the reader: a capsule at the top with the way back, the names and the window buttons, the buttons to play in the middle, and a dock at the bottom with the line to jump along over a row of actions. A choice opens inside the dock, which grows to hold it, so the player has no panels or sheets of its own.
@Composable
internal fun PlayerOverlay(
    session: SessionState,
    engine: PlayerState,
    aspect: AspectMode,
    fullscreen: Boolean,
    calls: OverlayCalls,
    thumbnail: VideoThumbnail? = null,
    // The choice open in the dock, and what each choice shows.
    picker: Picker? = null,
    pickerContent: @Composable (Picker) -> Unit = {},
    // False when the open choice shows docked at the side of a wide window instead of in the dock.
    pickerInDock: Boolean = true,
) {
    val reduce = LocalReduceMotion.current
    val widest = if (isWideWindow()) WideDockWidth else DockWidth
    val inDock = picker.takeIf { pickerInDock }
    // A choice takes at most half the height of the window, so the video stays in sight.
    val panelMax = with(LocalDensity.current) { (LocalWindowInfo.current.containerSize.height * 0.5f).toDp() }
    // The width of the window, which an open card at the bottom right compares with the dock to sit beside it or above it.
    val window = with(LocalDensity.current) {
        LocalWindowInfo.current.containerSize.width
            .toDp()
    }
    Box(Modifier.fillMaxSize()) {
        Box(
            Modifier
                .align(Alignment.TopCenter)
                .fillMaxWidth()
                .windowInsetsPadding(
                    WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal),
                ).padding(DockMargin),
            contentAlignment = Alignment.TopCenter,
        ) {
            DockSurface(Modifier.widthIn(max = widest).fillMaxWidth()) { TopRow(session, fullscreen, calls) }
        }
        // While the episode is still being found or opened, the loading card in the middle takes the place of the buttons.
        if (inDock == null &&
            session.phase != PlayerPhase.Loading
        ) {
            Box(Modifier.align(Alignment.Center)) { Transport(session, engine, calls) }
        }
        Box(
            Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .tellsAsideCard(minOf(widest, window - DockMargin * 2), window)
                .windowInsetsPadding(
                    WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom + WindowInsetsSides.Horizontal),
                ).padding(DockMargin),
            contentAlignment = Alignment.BottomCenter,
        ) {
            // Solid while a choice is open, so its words never sit over the video.
            DockSurface(Modifier.widthIn(max = widest).fillMaxWidth(), solid = inDock != null) {
                Column(Modifier.padding(horizontal = 8.dp, vertical = 6.dp)) {
                    AnimatedContent(
                        inDock,
                        transitionSpec = { panelChange(reduce, null) },
                        label = "player panel",
                    ) { shown ->
                        if (shown != null) {
                            Column {
                                Box(Modifier.heightIn(max = panelMax)) { pickerContent(shown) }
                                DockRule()
                            }
                        }
                    }
                    SeekBar(
                        engine.positionMs,
                        engine.bufferedMs,
                        engine.durationMs,
                        calls.onSeek,
                        calls.onScrubStart,
                        calls.onScrubEnd,
                        thumbnail = thumbnail,
                        onPreview = calls.onPreview,
                    )
                    DockRule()
                    // A wide window has room for the name of each button under its icon, as in the reader.
                    CompositionLocalProvider(
                        LocalDockLabels provides isWideWindow(),
                    ) { Actions(session, engine, aspect, picker, calls) }
                }
            }
        }
    }
}

// The way back, the episode with the title under it, and the buttons for the window: the small player, and full screen on a computer or the lock on a phone.
@Composable
private fun TopRow(session: SessionState, fullscreen: Boolean, calls: OverlayCalls) {
    val episode = session.episode
    Row(Modifier.padding(horizontal = 4.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        IconButton(
            calls.onClose,
        ) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, stringResource(Res.string.player_close)) }
        Column(Modifier.weight(1f).padding(start = 4.dp)) {
            Text(
                episode
                    ?.let {
                        numberedUnit(Kind.Anime, it.number) +
                            (it.name?.takeIf { name -> name.isNotBlank() }?.let { name -> " · $name" } ?: "")
                    }.orEmpty(),
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

// The actions of the dock, each an icon that fills while its choice is open: the episodes, the subtitles, the sound, the quality, the speed, how the picture fits, and the settings. An action with nothing to choose is left out.
@Composable
private fun Actions(
    session: SessionState,
    engine: PlayerState,
    aspect: AspectMode,
    picker: Picker?,
    calls: OverlayCalls,
) {
    val video = session.current
    fun toggle(which: Picker) = calls.onOpen(which)
    Row(Modifier.fillMaxWidth().padding(vertical = 2.dp)) {
        if (session.episodes.size > 1) {
            DockAction(
                Icons.AutoMirrored.Outlined.FormatListBulleted,
                stringResource(Res.string.player_episodes),
                picker == Picker.Episodes,
                { toggle(Picker.Episodes) },
            )
        }
        if (hasSubtitleChoices(engine, video)) {
            DockAction(
                Icons.Outlined.Subtitles,
                stringResource(
                    Res.string.player_subtitles,
                ),
                picker == Picker.Subtitles,
                {
                    toggle(Picker.Subtitles)
                },
            )
        }
        if (hasAnyAudio(engine, video) || VideoChoice.versions(session.videos, video) != null) {
            DockAction(
                Icons.AutoMirrored.Outlined.VolumeUp,
                stringResource(Res.string.player_audio),
                picker == Picker.Audio,
                { toggle(Picker.Audio) },
            )
        }
        if (session.videos.size > 1) {
            DockAction(
                Icons.Outlined.HighQuality,
                stringResource(
                    Res.string.player_quality,
                ),
                picker == Picker.Quality,
                {
                    toggle(Picker.Quality)
                },
            )
        }
        DockAction(Icons.Outlined.Speed, stringResource(Res.string.player_speed), picker == Picker.Speed, {
            toggle(Picker.Speed)
        })
        DockAction(Icons.Outlined.AspectRatio, stringResource(aspect.label), false, calls.onFit)
        DockAction(Icons.Outlined.Tune, stringResource(Res.string.player_settings_title), picker == Picker.Settings, {
            toggle(Picker.Settings)
        })
    }
}
