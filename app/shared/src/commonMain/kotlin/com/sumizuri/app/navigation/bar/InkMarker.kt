package com.sumizuri.app.navigation.bar

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.toSize
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.theme.LocalReduceMotion
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

// The mark of the chosen tab, shared by the rail, the bar and the drawer: a pill of ink that travels to the tab picked, its leading edge running ahead and the one behind following slowly, with a ring of ink that spreads out from where it lands.
// How far the ring spreads past the pill and how thick it is.
private val RingReach = 9.dp
private val RingWidth = 2.dp

internal class InkMarker {
    // Where each tab sits in the window, and where the strip of tabs sits, so the pill can be drawn behind them.
    val spots = mutableStateMapOf<Int, Rect>()
    var origin by mutableStateOf(Offset.Zero)
    val start = Animatable(0f)
    val end = Animatable(0f)
    val ring = Animatable(1f)
    var shown by mutableStateOf(-1)
    var placed = false
}

@Composable
internal fun rememberInkMarker(): InkMarker = remember { InkMarker() }

// Marks a part as the place of one tab.
internal fun Modifier.inkSpot(marker: InkMarker, index: Int): Modifier = onGloballyPositioned {
    marker.spots[index] = Rect(it.positionInRoot(), it.size.toSize())
}

// Moves the pill to the chosen tab, along the length of the strip. The first place it takes, and every place when the person asked for less motion, it jumps to.
@Composable
internal fun InkMarker.Follow(index: Int, vertical: Boolean) {
    val reduce = LocalReduceMotion.current
    // The place is kept from the strip itself, so the pill rides along when the whole strip moves.
    val spot = spots[index]?.translate(-origin) ?: return
    LaunchedEffect(index, spot, vertical) {
        val from = if (vertical) spot.top else spot.left
        val to = if (vertical) spot.bottom else spot.right
        val forward = index >= shown
        val moving = placed && shown != index
        shown = index
        if (!placed || reduce) {
            start.snapTo(from)
            end.snapTo(to)
            placed = true
            return@LaunchedEffect
        }
        val quick = spring<Float>(0.8f, Spring.StiffnessMedium)
        val slow = spring<Float>(0.72f, Spring.StiffnessLow)
        coroutineScope {
            launch { start.animateTo(from, if (forward) slow else quick) }
            launch { end.animateTo(to, if (forward) quick else slow) }
            if (moving) {
                launch {
                    ring.snapTo(0f)
                    ring.animateTo(1f, tween(560, easing = AppMotion.Exit))
                }
            }
        }
    }
}

// Draws the pill and its ring behind the tabs of the strip this is put on.
internal fun Modifier.inkLayer(marker: InkMarker, vertical: Boolean, fill: Color, ringColor: Color): Modifier = this
    .onGloballyPositioned { marker.origin = it.positionInRoot() }
    .drawBehind {
        val spot = marker.spots[marker.shown]?.translate(-marker.origin) ?: return@drawBehind
        if (!marker.placed) return@drawBehind
        val a = marker.start.value
        val b = marker.end.value
        val rect = if (vertical) {
            Rect(spot.left, minOf(a, b), spot.right, maxOf(a, b))
        } else {
            Rect(minOf(a, b), spot.top, maxOf(a, b), spot.bottom)
        }
        val round = minOf(rect.width, rect.height) / 2
        drawRoundRect(fill, rect.topLeft, Size(rect.width, rect.height), CornerRadius(round))
        val spread = marker.ring.value
        // The ring is the outline of the pill where it lands, spreading out a little as it fades.
        if (spread < 1f) {
            val ring = spot.inflate(RingReach.toPx() * spread)
            drawRoundRect(
                ringColor.copy(alpha = ringColor.alpha * (1f - spread)),
                ring.topLeft,
                Size(ring.width, ring.height),
                CornerRadius(minOf(ring.width, ring.height) / 2),
                style = Stroke(RingWidth.toPx()),
            )
        }
    }
