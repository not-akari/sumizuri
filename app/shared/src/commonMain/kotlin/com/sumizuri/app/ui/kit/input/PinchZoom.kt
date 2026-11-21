package com.sumizuri.app.ui.kit.input

import androidx.compose.animation.core.animate
import androidx.compose.animation.core.tween
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculateCentroid
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.isSpecified
import androidx.compose.ui.geometry.lerp
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.isCtrlPressed
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlin.math.exp

// Under this the content counts as not zoomed, so it snaps back and a single finger scrolls it again.
private const val Snap = 1.02f

// How much one notch of the mouse wheel zooms with the control key held.
private const val WheelStep = 0.1f

// Two taps within this many milliseconds, and this many dp of each other, are a double tap, which zooms in to the scale below or back out.
private const val DoubleTapGap = 300L
private const val DoubleTapReach = 48
private const val DoubleTapScale = 2.5f

// Two fingers zoom and move what is under them, and with the control key the mouse wheel zooms. While zoomed one finger moves it too. Fingers are taken before the content under them, and only while zoomed or with two fingers down.
@Composable
fun Modifier.pinchZoom(maxScale: Float = 5f): Modifier {
    var scale by remember { mutableFloatStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    val scope = rememberCoroutineScope()
    var glide by remember { mutableStateOf<Job?>(null) }
    val glideMs by rememberUpdatedState(motionMs(AppMotion.Page))

    // Where a zoom by the factor around the focus ends: the point under it stays where it is, and the content never leaves the window.
    fun zoomed(focus: Offset, size: IntSize, factor: Float, pan: Offset): Pair<Float, Offset>? {
        // A gesture with no finger that was already down gives no centroid, and one NaN in the scale or offset leaves the content drawn nowhere.
        if (!focus.isSpecified || !pan.isSpecified || !factor.isFinite() || !focus.x.isFinite() || !focus.y.isFinite() || !pan.x.isFinite() || !pan.y.isFinite()) return null
        val next = (scale * factor).coerceIn(1f, maxScale)
        if (next < Snap) return 1f to Offset.Zero
        val from = focus - Offset(size.width / 2f, size.height / 2f)
        val moved = from - (from - offset) * (next / scale) + pan
        val limitX = size.width * (next - 1f) / 2f
        val limitY = size.height * (next - 1f) / 2f
        return next to Offset(moved.x.coerceIn(-limitX, limitX), moved.y.coerceIn(-limitY, limitY))
    }

    // Fingers and the wheel move the zoom at once, and take over from a glide that is still going.
    fun zoomAt(focus: Offset, size: IntSize, factor: Float, pan: Offset) {
        val (next, moved) = zoomed(focus, size, factor, pan) ?: return
        glide?.cancel()
        scale = next
        offset = moved
    }

    // A double tap glides to its zoom, unless the person asked for less motion.
    fun glideTo(target: Float, to: Offset) {
        glide?.cancel()
        if (glideMs <= 0) {
            scale = target
            offset = to
            return
        }
        val fromScale = scale
        val fromOffset = offset
        glide = scope.launch {
            animate(0f, 1f, animationSpec = tween(glideMs, easing = AppMotion.Entrance)) { t, _ ->
                scale = fromScale + (target - fromScale) * t
                offset = lerp(fromOffset, to, t)
            }
        }
    }

    return this
        .pointerInput(Unit) {
            var lastTapAt = -DoubleTapGap
            var lastTapPosition = Offset.Zero
            awaitEachGesture {
                val down = awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
                var tap = true
                do {
                    val event = awaitPointerEvent(PointerEventPass.Initial)
                    if (event.changes.count { it.pressed } >= 2 || scale > Snap) {
                        zoomAt(event.calculateCentroid(useCurrent = false), size, event.calculateZoom(), event.calculatePan())
                        event.changes.forEach { if (it.positionChanged()) it.consume() }
                    }
                    if (event.changes.size > 1 || event.changes.any { (it.position - down.position).getDistance() > viewConfiguration.touchSlop }) tap = false
                    if (tap && event.changes.none { it.pressed }) {
                        val up = event.changes.first()
                        if (up.uptimeMillis - lastTapAt <= DoubleTapGap && (up.position - lastTapPosition).getDistance() <= DoubleTapReach.dp.toPx()) {
                            // The second tap is taken here, so what is under it does not act on it too.
                            up.consume()
                            lastTapAt = -DoubleTapGap
                            if (scale > Snap) {
                                glideTo(1f, Offset.Zero)
                            } else {
                                zoomed(up.position, size, DoubleTapScale, Offset.Zero)?.let { (next, moved) -> glideTo(next, moved) }
                            }
                        } else {
                            lastTapAt = up.uptimeMillis
                            lastTapPosition = up.position
                        }
                    }
                } while (event.changes.any { it.pressed })
            }
        }.pointerInput(Unit) {
            awaitPointerEventScope {
                while (true) {
                    val event = awaitPointerEvent(PointerEventPass.Initial)
                    if (event.type == PointerEventType.Scroll && event.keyboardModifiers.isCtrlPressed) {
                        val change = event.changes.first()
                        zoomAt(change.position, size, exp(-change.scrollDelta.y * WheelStep), Offset.Zero)
                        change.consume()
                    }
                }
            }
        }.graphicsLayer {
            scaleX = scale
            scaleY = scale
            translationX = offset.x
            translationY = offset.y
        }
}
