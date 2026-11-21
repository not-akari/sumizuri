package com.sumizuri.app.ui.motion

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

// Rolls a number to the next like the wheel of a counter: a bigger one comes up from below and a smaller one drops in from above. With less motion asked for it simply changes.
@Composable
fun RollingCount(count: Int, modifier: Modifier = Modifier, content: @Composable (Int) -> Unit) {
    val ms = motionMs(AppMotion.Medium)
    AnimatedContent(
        count,
        modifier,
        transitionSpec = {
            if (ms == 0) {
                EnterTransition.None togetherWith ExitTransition.None
            } else {
                val up = targetState > initialState
                val enter = slideInVertically(tween(ms, easing = AppMotion.Entrance)) { if (up) it else -it } +
                    fadeIn(tween(ms))
                val exit = slideOutVertically(tween(ms, easing = AppMotion.Exit)) { if (up) -it else it } +
                    fadeOut(tween(ms / 2))
                enter togetherWith exit using SizeTransform(clip = true)
            }
        },
        label = "rolling",
    ) { content(it) }
}
