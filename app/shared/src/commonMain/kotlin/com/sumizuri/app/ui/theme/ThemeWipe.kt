package com.sumizuri.app.ui.theme

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import kotlinx.coroutines.delay
import kotlin.math.hypot
import kotlin.math.max

// How long the new look is given to be drawn under the ink before the ink fades.
private const val SettleMs = 120L

// A change of look for a TV that needs no picture of the screen: ink in the page color of the new look spreads from the card that was picked until it covers the screen, the look changes under it, and the ink fades to show it. A picture of the old screen is not a true copy on Android, where parts of the screen are drawn on their own, so the change that draws one shows old and new mixed there.
object ThemeWipe {
    internal var run by mutableStateOf<WipeRun?>(null)

    // Starts the change from a point with the page color of the new look, and calls apply once the ink covers the screen. With less motion it applies at once.
    fun start(color: Color, origin: Offset, apply: () -> Unit) {
        run = WipeRun(color, origin, apply)
    }
}

internal class WipeRun(val color: Color, val origin: Offset, val apply: () -> Unit) {
    val spread = Animatable(0f)
    val shown = Animatable(1f)
}

// The ink of a change of look over the whole window, while one runs.
@Composable
fun ThemeWipeLayer() {
    val run = ThemeWipe.run ?: return
    val spreadMs = motionMs(AppMotion.Page + 120)
    val fadeMs = motionMs(AppMotion.Page)
    LaunchedEffect(run) {
        if (spreadMs > 0) run.spread.animateTo(1f, tween(spreadMs, easing = FastOutSlowInEasing))
        run.apply()
        delay(SettleMs)
        if (fadeMs > 0) run.shown.animateTo(0f, tween(fadeMs))
        if (ThemeWipe.run === run) ThemeWipe.run = null
    }
    Canvas(Modifier.fillMaxSize()) {
        val center = run.origin.takeIf { it != Offset.Zero } ?: Offset(size.width / 2f, size.height / 2f)
        // The circle reaches the farthest corner at the end, so the whole screen is covered.
        val far = max(
            max(hypot(center.x, center.y), hypot(size.width - center.x, center.y)),
            max(hypot(center.x, size.height - center.y), hypot(size.width - center.x, size.height - center.y)),
        )
        drawCircle(run.color.copy(alpha = run.shown.value), radius = far * run.spread.value, center = center)
    }
}
