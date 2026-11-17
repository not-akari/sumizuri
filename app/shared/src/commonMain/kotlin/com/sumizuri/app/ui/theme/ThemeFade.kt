package com.sumizuri.app.ui.theme

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.layer.GraphicsLayer
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs

// Which of the two pictures holds the screen as it is drawn now, and which holds how it looked before a change while that fades out.
private class FadeState {
    var key: Any? = null
    var live = 0
    var frozen: Int? = null
    var waiting = false
}

// A change of look, such as another theme or light and dark, turns from the old look to the new one instead of jumping. The screen is built once in the new look, and a picture of how it looked just before fades out over it. The fade only draws that picture again, so a slow phone never builds the whole screen again for every step of it.
@Composable
internal fun ThemeFade(key: Any, content: @Composable () -> Unit) {
    val pictures = arrayOf(rememberGraphicsLayer(), rememberGraphicsLayer())
    val state = remember { FadeState() }
    val alpha = remember { Animatable(0f) }
    val ms = motionMs(AppMotion.Medium + 140)
    if (state.key != key) {
        // The picture drawn last still shows the old look, so it is kept and the new look is drawn into the other one.
        if (state.key != null && ms > 0) {
            state.frozen = state.live
            state.live = 1 - state.live
            state.waiting = true
        }
        state.key = key
    }
    LaunchedEffect(key) {
        if (!state.waiting) return@LaunchedEffect
        alpha.snapTo(1f)
        state.waiting = false
        alpha.animateTo(0f, tween(ms, easing = AppMotion.Exit))
        state.frozen = null
    }
    Box(
        Modifier.drawWithContent {
            val live: GraphicsLayer = pictures[state.live]
            live.record { this@drawWithContent.drawContent() }
            // A picture that faded out before is drawn whole again once it holds the screen.
            live.alpha = 1f
            drawLayer(live)
            val frozen = state.frozen ?: return@drawWithContent
            // Until the fade has begun, the old look covers the new one fully, so the change never flashes.
            val shown = if (state.waiting) 1f else alpha.value
            if (shown > 0f) {
                pictures[frozen].alpha = shown
                drawLayer(pictures[frozen])
            }
        },
        propagateMinConstraints = true,
    ) { content() }
}
