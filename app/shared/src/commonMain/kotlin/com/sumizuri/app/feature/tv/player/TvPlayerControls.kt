package com.sumizuri.app.feature.tv.player

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.SkipNext
import androidx.compose.material.icons.rounded.SkipPrevious
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.feature.player.SessionState
import com.sumizuri.app.feature.player.formatTime
import com.sumizuri.app.feature.player.overlay.ActiveMarker
import com.sumizuri.app.feature.player.overlay.MarkerKind
import com.sumizuri.app.feature.player.picker.Picker
import com.sumizuri.app.playback.PlayerState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_audio
import com.sumizuri.app.shared.resources.player_episodes
import com.sumizuri.app.shared.resources.player_quality
import com.sumizuri.app.shared.resources.player_skip_ending
import com.sumizuri.app.shared.resources.player_skip_intro
import com.sumizuri.app.shared.resources.player_speed
import com.sumizuri.app.shared.resources.player_subtitles
import com.sumizuri.app.ui.text.numberedUnit
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// What the controls of the TV player can ask for.
internal class TvControlCalls(
    val onPlayPause: () -> Unit,
    val onSeek: (forward: Boolean) -> Unit,
    val onPrevious: (() -> Unit)?,
    val onNext: (() -> Unit)?,
    val onSkip: (ActiveMarker) -> Unit,
    val onOpen: (Picker) -> Unit,
    val onEpisode: (Long) -> Unit,
    // Moves between the buttons and the episodes with down and up.
    val onShow: (TvControls) -> Unit,
    // Closes the row of a choice and shows the buttons again.
    val onCloseStrip: () -> Unit,
)

// The controls low over the video, on a shade that darkens toward the bottom: the title and the episode, the line of time, and under it the buttons, the episodes of the season, or the cards of a choice in place of the buttons. The first button, the episode playing or the choice in use takes the focus as they show.
@Composable
internal fun TvPlayerControls(
    state: SessionState,
    player: PlayerState,
    controls: TvControls,
    strip: Picker?,
    marker: ActiveMarker?,
    calls: TvControlCalls,
    strips: StripCalls,
) {
    val first = remember { FocusRequester() }
    LaunchedEffect(controls, strip) {
        if (controls == TvControls.Hidden || controls == TvControls.Bar) return@LaunchedEffect
        repeat(4) {
            delay(80)
            runCatching { first.requestFocus() }
        }
    }
    Box(Modifier.fillMaxSize()) {
        Box(
            Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .fillMaxHeight(0.7f)
                .background(
                    Brush.verticalGradient(
                        0f to Color.Transparent,
                        0.45f to Color.Black.copy(alpha = 0.7f),
                        1f to Color.Black.copy(alpha = 0.94f),
                    ),
                ),
        )
        Column(Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(horizontal = 56.dp, vertical = 36.dp)) {
            Text(
                state.titleName,
                fontSize = 16.sp,
                color = Color.White.copy(alpha = 0.75f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            state.episode?.let { episode ->
                val number = numberedUnit(Kind.Anime, episode.number)
                // A name that starts with the number already says it, so the number is not put before it again.
                val name = episode.name?.trim()?.takeIf { it.isNotBlank() }
                Text(
                    when {
                        name == null -> number
                        name.startsWith(number, ignoreCase = true) -> name
                        else -> "$number  ·  $name"
                    },
                    fontSize = 26.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Spacer(Modifier.height(16.dp))
            TimeBar(player, focusable = controls == TvControls.Buttons, calls.onSeek)
            Row(Modifier.fillMaxWidth().padding(top = 6.dp)) {
                Text(formatTime(player.positionMs), fontSize = 14.sp, color = Color.White.copy(alpha = 0.8f))
                Spacer(Modifier.weight(1f))
                Text(formatTime(player.durationMs), fontSize = 14.sp, color = Color.White.copy(alpha = 0.8f))
            }
            when (controls) {
                TvControls.Buttons -> if (strip != null) {
                    Box(Modifier.upTo(calls.onCloseStrip)) { TvChoiceStrip(strip, state, player, first, strips) }
                } else {
                    Box(Modifier.downTo { calls.onShow(TvControls.Episodes) }) { Buttons(player, marker, calls, first) }
                }

                TvControls.Episodes -> Box(
                    Modifier.upTo {
                        calls.onShow(TvControls.Buttons)
                    },
                ) { TvEpisodeStrip(state, first, calls.onEpisode) }

                else -> Unit
            }
        }
    }
}

// The line of time with how much has played. With the buttons showing it can take the focus, and then left and right jump along it.
@Composable
private fun TimeBar(player: PlayerState, focusable: Boolean, onSeek: (Boolean) -> Unit) {
    val press = remember { MutableInteractionSource() }
    val focused by press.collectIsFocusedAsState()
    val share = if (player.durationMs > 0) (player.positionMs.toFloat() / player.durationMs).coerceIn(0f, 1f) else 0f
    val accent = MaterialTheme.colorScheme.primary
    BoxWithConstraints(
        Modifier
            .fillMaxWidth()
            .height(22.dp)
            .onPreviewKeyEvent { event ->
                if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                when (event.key) {
                    Key.DirectionLeft -> true.also { onSeek(false) }
                    Key.DirectionRight -> true.also { onSeek(true) }
                    else -> false
                }
            }.focusable(focusable, press),
        contentAlignment = Alignment.CenterStart,
    ) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(5.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.25f)),
        )
        Box(
            Modifier
                .fillMaxWidth(share)
                .height(5.dp)
                .clip(CircleShape)
                .background(accent),
        )
        Box(
            Modifier
                .offset(x = maxWidth * share - 8.dp)
                .size(16.dp)
                .background(accent, CircleShape)
                .border(if (focused) 3.dp else 0.dp, Color.White, CircleShape),
        )
    }
}

// The previous episode, play or pause, the next one and the skip of an intro on the left, and the panels on the right.
@Composable
private fun Buttons(player: PlayerState, marker: ActiveMarker?, calls: TvControlCalls, first: FocusRequester) {
    Row(
        Modifier.fillMaxWidth().padding(top = 18.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        calls.onPrevious?.let { RoundButton(Icons.Rounded.SkipPrevious, it) }
        RoundButton(
            if (player.playing) Icons.Rounded.Pause else Icons.Rounded.PlayArrow,
            calls.onPlayPause,
            Modifier.focusRequester(first),
        )
        calls.onNext?.let { RoundButton(Icons.Rounded.SkipNext, it) }
        marker?.let { found -> TvButton(stringResource(skipLabel(found)), { calls.onSkip(found) }) }
        Spacer(Modifier.weight(1f))
        listOf(
            Picker.Episodes to Res.string.player_episodes,
            Picker.Subtitles to Res.string.player_subtitles,
            Picker.Audio to Res.string.player_audio,
            Picker.Quality to Res.string.player_quality,
            Picker.Speed to Res.string.player_speed,
        ).forEach { (picker, name) -> Pill(stringResource(name)) { calls.onOpen(picker) } }
    }
}

// A small button of the right side, as wide as its name.
@Composable
private fun Pill(text: String, onClick: () -> Unit) {
    Box(Modifier.tvCard(onClick, RoundedCornerShape(50)).padding(horizontal = 18.dp, vertical = 11.dp)) {
        Text(text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = Color.White, maxLines = 1)
    }
}

// Down from the buttons goes to the episodes, and up from the episodes back to the buttons.
private fun Modifier.downTo(go: () -> Unit): Modifier = onPreviewKeyEvent { event ->
    (event.type == KeyEventType.KeyDown && event.key == Key.DirectionDown).also { if (it) go() }
}

private fun Modifier.upTo(go: () -> Unit): Modifier = onPreviewKeyEvent { event ->
    (event.type == KeyEventType.KeyDown && event.key == Key.DirectionUp).also { if (it) go() }
}

@Composable
private fun RoundButton(icon: ImageVector, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(modifier.size(56.dp).tvCard(onClick, CircleShape), contentAlignment = Alignment.Center) {
        Icon(icon, null, Modifier.size(30.dp), tint = Color.White)
    }
}

// The skip of an intro or an ending while the controls are hidden, with a sign that OK takes it.
@Composable
internal fun TvSkipHint(marker: ActiveMarker?) {
    val kept = marker ?: return
    Row(
        Modifier
            .padding(end = 56.dp, bottom = 48.dp)
            .background(Color.Black.copy(alpha = 0.65f), RoundedCornerShape(50))
            .padding(start = 22.dp, end = 8.dp, top = 8.dp, bottom = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(stringResource(skipLabel(kept)), fontSize = 18.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
        Text(
            "OK",
            Modifier
                .background(
                    MaterialTheme.colorScheme.primary,
                    RoundedCornerShape(50),
                ).padding(horizontal = 12.dp, vertical = 4.dp),
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onPrimary,
        )
    }
}

private fun skipLabel(marker: ActiveMarker) = if (marker.kind ==
    MarkerKind.Intro
) {
    Res.string.player_skip_intro
} else {
    Res.string.player_skip_ending
}
