package com.sumizuri.app.ui.motion

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.hoverable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import com.sumizuri.app.ui.theme.LocalReduceMotion
import com.sumizuri.app.ui.theme.LocalThemeSpec

// Makes a piece shrink a little while it is pressed and grow a little while the pointer rests on it, by the amounts the theme sets. A wide piece, such as a row, leaves the growing out. The piece must use the same interaction source for its clicks.
@Composable
fun Modifier.feedbackScale(source: MutableInteractionSource, hover: Boolean = true): Modifier {
    if (LocalReduceMotion.current) return this
    val motion = LocalThemeSpec.current.options.motion
    val pressed by source.collectIsPressedAsState()
    val hovered by source.collectIsHoveredAsState()
    val scale by animateFloatAsState(
        if (pressed) {
            motion.pressScale
        } else if (hover && hovered) {
            motion.hoverScale
        } else {
            1f
        },
        tween(motionMs(AppMotion.Micro), easing = AppMotion.Exit),
        label = "feedback",
    )
    return hoverable(source).graphicsLayer {
        scaleX = scale
        scaleY = scale
    }
}
