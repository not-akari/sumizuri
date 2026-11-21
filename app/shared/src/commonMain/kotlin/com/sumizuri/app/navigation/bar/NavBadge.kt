package com.sumizuri.app.navigation.bar

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.ui.motion.RollingCount
import com.sumizuri.app.ui.text.compactCount
import com.sumizuri.app.ui.theme.LocalReduceMotion

// The count of new chapters on a tab, a small pill in the accent. A ring in the color behind it makes it look punched out of the icon. It pops in when it first shows, rolls when the number changes, and shortens a big number to 1.2k.
@Composable
internal fun NavBadge(count: Int, modifier: Modifier = Modifier, ring: Color = Color.Unspecified) {
    if (count <= 0) return
    val colors = MaterialTheme.colorScheme
    val pop = remember { Animatable(1f) }
    val reduce = LocalReduceMotion.current
    LaunchedEffect(Unit) {
        if (reduce) return@LaunchedEffect
        pop.snapTo(0.4f)
        pop.animateTo(1f, spring(0.4f, Spring.StiffnessMedium))
    }
    Box(
        modifier
            .graphicsLayer {
                scaleX = pop.value
                scaleY = pop.value
            }.then(if (ring.isSpecified) Modifier.background(ring, CircleShape).padding(2.dp) else Modifier)
            .background(colors.primary, CircleShape)
            .defaultMinSize(minWidth = 16.dp, minHeight = 16.dp),
        contentAlignment = Alignment.Center,
    ) {
        RollingCount(count, Modifier.padding(horizontal = 4.dp)) {
            Text(
                compactCount(it),
                style = MaterialTheme.typography.labelSmall,
                fontSize = 9.sp,
                lineHeight = 12.sp,
                fontWeight = FontWeight.Bold,
                color = colors.onPrimary,
                maxLines = 1,
            )
        }
    }
}
