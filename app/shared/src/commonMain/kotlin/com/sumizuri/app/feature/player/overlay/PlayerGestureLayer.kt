package com.sumizuri.app.feature.player.overlay

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.VolumeDown
import androidx.compose.material.icons.automirrored.rounded.VolumeOff
import androidx.compose.material.icons.automirrored.rounded.VolumeUp
import androidx.compose.material.icons.rounded.FastForward
import androidx.compose.material.icons.rounded.FastRewind
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.feature.player.formatTime
import com.sumizuri.app.playback.PlayerEngine
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

private class Hud(val icon: ImageVector, val text: String)

// The touch layer over the picture. A tap and a double tap are handed on. On a phone a drag along the screen jumps, a drag up and down on the right half sets the volume, and holding the screen speeds the video up while it is held. What the gesture does shows in a pill in the middle.
@Composable
internal fun PlayerGestureLayer(
    engine: PlayerEngine,
    touch: Boolean,
    holdSpeed: Float,
    onTap: () -> Unit,
    onDoubleTap: (Float) -> Unit,
    modifier: Modifier = Modifier,
) {
    // The tap handlers change with the screen (full screen on or off), but the gesture detector below lives on, so it calls the newest ones.
    val tap by rememberUpdatedState(onTap)
    val doubleTap by rememberUpdatedState(onDoubleTap)
    var hud by remember { mutableStateOf<Hud?>(null) }
    var hudJob by remember { mutableStateOf<Job?>(null) }
    val scope = rememberCoroutineScope()
    fun show(next: Hud, keep: Boolean = false) {
        hudJob?.cancel()
        hud = next
        if (!keep) {
            hudJob = scope.launch {
                delay(650)
                hud = null
            }
        }
    }
    fun hideSoon() {
        hudJob?.cancel()
        hudJob = scope.launch {
            delay(450)
            hud = null
        }
    }
    Box(modifier.fillMaxSize()) {
        Box(
            Modifier
                .fillMaxSize()
                .pointerInput(touch, holdSpeed) {
                    detectTapGestures(
                        onPress = {
                            if (!touch || holdSpeed <= 1f) return@detectTapGestures
                            var held = false
                            var before = 1f
                            val job = scope.launch {
                                delay(viewConfiguration.longPressTimeoutMillis)
                                held = true
                                before = engine.state.value.speed
                                engine.setSpeed(holdSpeed)
                                show(Hud(Icons.Rounded.FastForward, speedText(holdSpeed) + "×"), keep = true)
                            }
                            tryAwaitRelease()
                            job.cancel()
                            if (held) {
                                engine.setSpeed(before)
                                hideSoon()
                            }
                        },
                        onTap = { tap() },
                        onDoubleTap = { offset -> doubleTap(if (size.width <= 0) 0.5f else offset.x / size.width) },
                    )
                }.pointerInput(touch) {
                    if (!touch) return@pointerInput
                    var from = 0L
                    var target = 0L
                    var moved = 0f
                    detectHorizontalDragGestures(
                        onDragStart = {
                            from = engine.state.value.positionMs
                            target = from
                            moved = 0f
                        },
                        onHorizontalDrag = { change, delta ->
                            change.consume()
                            moved += delta
                            target =
                                PlayerGestureMath.clamp(
                                    from + PlayerGestureMath.dragSeekDelta(moved, size.width.toFloat()),
                                    engine.state.value.durationMs,
                                )
                            show(
                                Hud(
                                    if (moved >=
                                        0
                                    ) {
                                        Icons.Rounded.FastForward
                                    } else {
                                        Icons.Rounded.FastRewind
                                    },
                                    "${formatTime(target)}   ${PlayerGestureMath.seekHint(target, from)}",
                                ),
                                keep = true,
                            )
                        },
                        onDragEnd = {
                            engine.seekTo(target)
                            hideSoon()
                        },
                        onDragCancel = { hideSoon() },
                    )
                }.pointerInput(touch) {
                    if (!touch) return@pointerInput
                    var from: Float? = null
                    var moved = 0f
                    detectVerticalDragGestures(
                        onDragStart = { offset ->
                            from = if (offset.x > size.width / 2) {
                                engine.state.value.volume
                                    .toFloat()
                            } else {
                                null
                            }
                            moved = 0f
                        },
                        onVerticalDrag = { change, delta ->
                            val start = from ?: return@detectVerticalDragGestures
                            change.consume()
                            moved += delta
                            val volume = PlayerGestureMath.dragVolume(start, moved, size.height.toFloat())
                            engine.setVolume(volume.roundToInt())
                            show(
                                Hud(
                                    if (volume <= 0f) {
                                        Icons.AutoMirrored.Rounded.VolumeOff
                                    } else if (volume < 50f) {
                                        Icons.AutoMirrored.Rounded.VolumeDown
                                    } else {
                                        Icons.AutoMirrored.Rounded.VolumeUp
                                    },
                                    "${volume.roundToInt()}%",
                                ),
                                keep = true,
                            )
                        },
                        onDragEnd = { hideSoon() },
                        onDragCancel = { hideSoon() },
                    )
                },
        )
        hud?.let { pill ->
            Row(
                Modifier
                    .align(
                        Alignment.Center,
                    ).background(
                        Color.Black.copy(alpha = 0.72f),
                        RoundedCornerShape(28.dp),
                    ).padding(horizontal = 18.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(pill.icon, null, Modifier.size(28.dp), tint = Color.White)
                Text(
                    pill.text,
                    Modifier.padding(start = 10.dp),
                    color = Color.White,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold,
                    style = TextStyle(fontFeatureSettings = "tnum"),
                )
            }
        }
    }
}
