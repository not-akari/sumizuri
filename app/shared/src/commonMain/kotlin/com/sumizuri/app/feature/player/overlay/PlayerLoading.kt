package com.sumizuri.app.feature.player.overlay

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.player.PlayerPhase
import com.sumizuri.app.feature.player.SessionState
import com.sumizuri.app.playback.PlayerState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_loading_buffering
import com.sumizuri.app.shared.resources.player_loading_finding
import com.sumizuri.app.shared.resources.player_loading_opening
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.dock.DockSurface
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource

// How long a stall lasts before the card shows, so a short wait does not flash it.
private const val ShowAfterMs = 350

// A small card in the middle of the video while it is not playing yet: the source is asked for the videos, the video opens, or it waits for more of the stream. While the controls are shown, a wait in the middle of a video shows on the play button instead.
@Composable
internal fun PlayerLoading(
    session: SessionState,
    engine: PlayerState,
    controls: Boolean,
    modifier: Modifier = Modifier,
) {
    val opening = session.phase == PlayerPhase.Loading
    val buffering = session.phase == PlayerPhase.Ready && engine.buffering
    val reduce = LocalReduceMotion.current
    val words = when {
        opening && session.current == null -> stringResource(Res.string.player_loading_finding)
        opening -> stringResource(Res.string.player_loading_opening)
        else -> stringResource(Res.string.player_loading_buffering)
    }
    // The words stay as they were while the card fades out.
    val shown = remember { mutableStateOf(words) }
    if (opening || buffering) shown.value = words
    val detail = session.current?.quality?.takeIf { opening }
    AnimatedVisibility(
        opening || (buffering && !controls),
        modifier,
        enter = fadeIn(tween(if (reduce) 150 else 200, delayMillis = ShowAfterMs)),
        exit = fadeOut(tween(160)),
    ) {
        DockSurface {
            Row(
                Modifier.padding(start = 18.dp, end = 22.dp, top = 14.dp, bottom = 14.dp),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                InkCircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.5.dp)
                Column {
                    val text by shown
                    Text(text, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                    if (detail != null) {
                        Text(
                            detail,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }
        }
    }
}
