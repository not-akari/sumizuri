package com.sumizuri.app.ui.kit.swipe

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.theme.LocalReduceMotion

// What shows behind a row while it is swiped: the action on a faint fill that turns full, with the icon popping, once letting go would do it.
@Composable
fun SwipeBackdrop(state: SwipeToDismissBoxState, icon: ImageVector, text: String, fill: Color, ink: Color) {
    val toRight = state.dismissDirection == SwipeToDismissBoxValue.StartToEnd
    val armed = state.targetValue != SwipeToDismissBoxValue.Settled
    val reduce = LocalReduceMotion.current
    val pop by animateFloatAsState(
        if (armed) 1.15f else 0.8f,
        if (reduce) snap() else spring(0.45f, Spring.StiffnessMedium),
        label = "pop",
    )
    val shade by animateColorAsState(
        if (armed) fill else fill.copy(alpha = fill.alpha * 0.45f),
        tween(motionMs(AppMotion.Fast)),
        label = "shade",
    )
    Row(
        Modifier
            .fillMaxSize()
            .clip(MaterialTheme.shapes.small)
            .background(shade)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = if (toRight) Arrangement.Start else Arrangement.End,
    ) {
        Icon(
            icon,
            null,
            Modifier.graphicsLayer {
                scaleX = pop
                scaleY = pop
            },
            tint = ink,
        )
        Text(text, Modifier.padding(start = 8.dp), color = ink, fontWeight = FontWeight.SemiBold)
    }
}
