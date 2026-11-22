package com.sumizuri.app.ui.theme

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.layer.GraphicsLayer
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.pointerInput
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import kotlin.math.hypot
import kotlin.math.max

// How long a press is taken as the place a change of look starts from.
private const val OriginMs = 4000L

// Where the last press on the screen landed, so a change of look spreads out from what was pressed. A TV, which has no presses, gives the middle of the card that was chosen.
object ThemeReveal {
    internal var origin: Offset? = null
    internal var at = 0L

    fun from(point: Offset) {
        origin = point
        at = nowMillis()
    }
}

// Which of the two pictures holds the screen as it is drawn now, which one holds how it looked before a change, and where that change spreads out from.
private class FadeState {
    var key: Any? = null
    var live = 0
    var frozen: Int? = null
    var waiting = false
    var center: Offset? = null
    val hole = Path()
}

// A change of look, such as another theme or light and dark, spreads out from where it was asked for, as ink soaks into paper, or with spread off simply fades. The screen is built once in the new look, and a picture of how it looked just before is drawn around a growing circle. Each step only draws that picture again, so a slow phone or a TV box never builds the whole screen again for it.
@Composable
internal fun ThemeFade(key: Any, spread: Boolean = true, content: @Composable () -> Unit) {
    val pictures = arrayOf(rememberGraphicsLayer(), rememberGraphicsLayer())
    val state = remember { FadeState() }
    val progress = remember { Animatable(0f) }
    val ms = motionMs(AppMotion.Page + 260)
    if (state.key != key) {
        // The picture drawn last still shows the old look, so it is kept and the new look is drawn into the other one.
        if (state.key != null && ms > 0) {
            state.frozen = state.live
            state.live = 1 - state.live
            state.waiting = true
            state.center = ThemeReveal.origin?.takeIf { nowMillis() - ThemeReveal.at < OriginMs }
        }
        state.key = key
    }
    LaunchedEffect(key) {
        if (!state.waiting) return@LaunchedEffect
        progress.snapTo(0f)
        state.waiting = false
        progress.animateTo(1f, tween(ms, easing = FastOutSlowInEasing))
        state.frozen = null
    }
    Box(
        Modifier
            .then(if (spread) Modifier.trackPresses() else Modifier)
            .drawWithContent {
                val live: GraphicsLayer = pictures[state.live]
                live.record { this@drawWithContent.drawContent() }
                drawLayer(live)
                val frozen = state.frozen ?: return@drawWithContent
                // Until the change has begun, the old look covers the new one fully, so it never flashes.
                if (state.waiting) {
                    drawLayer(pictures[frozen])
                    return@drawWithContent
                }
                if (!spread) {
                    pictures[frozen].alpha = 1f - progress.value
                    drawLayer(pictures[frozen])
                    pictures[frozen].alpha = 1f
                    return@drawWithContent
                }
                val center = state.center ?: Offset(size.width / 2f, size.height / 2f)
                // The circle reaches the farthest corner at the end, so nothing of the old look is left.
                val far = max(
                    max(hypot(center.x, center.y), hypot(size.width - center.x, center.y)),
                    max(hypot(center.x, size.height - center.y), hypot(size.width - center.x, size.height - center.y)),
                )
                val radius = far * progress.value
                state.hole.rewind()
                state.hole.addOval(Rect(center, radius))
                clipPath(state.hole, ClipOp.Difference) { drawLayer(pictures[frozen]) }
            },
        propagateMinConstraints = true,
    ) { content() }
}

// Keeps where each press lands for the change of look to start from. It only listens, so every press still reaches what is under it.
private fun Modifier.trackPresses(): Modifier = pointerInput(Unit) {
    awaitPointerEventScope {
        while (true) {
            val event = awaitPointerEvent(PointerEventPass.Initial)
            if (event.type == PointerEventType.Press) event.changes.firstOrNull()?.let { ThemeReveal.from(it.position) }
        }
    }
}
