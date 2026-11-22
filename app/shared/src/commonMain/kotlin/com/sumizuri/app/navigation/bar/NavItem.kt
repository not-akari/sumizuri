package com.sumizuri.app.navigation.bar

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource

// One tab of the bottom bar or the rail: the icon, which takes the accent and pops up with a small bounce when the tab is chosen, and under it the name. The strip draws the pill of ink behind the chosen icon from the spot given, and a tab under the mouse glows faintly.
@Composable
internal fun NavItem(
    destination: Destination,
    selected: Boolean,
    avatar: NavAvatar?,
    badge: Int,
    labels: NavLabels,
    wide: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    // Where the strip learns the place of this icon for its pill of ink.
    spot: Modifier = Modifier,
) {
    val colors = MaterialTheme.colorScheme
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    // A remote or a keyboard on it lights the pill and rings it, so the place of the focus is always seen.
    val focused by source.collectIsFocusedAsState()
    val ms = motionMs(AppMotion.Fast)
    val reduce = LocalReduceMotion.current
    val lift by animateFloatAsState(
        if (selected) 1.12f else 1f,
        if (reduce) snap() else spring(0.42f, Spring.StiffnessMediumLow),
        label = "lift",
    )
    val glow by animateColorAsState(
        when {
            focused -> colors.primary.copy(alpha = 0.22f)
            hovered && !selected -> colors.onSurface.copy(alpha = 0.07f)
            else -> colors.onSurface.copy(alpha = 0f)
        },
        tween(ms),
        label = "glow",
    )
    val tint by animateColorAsState(
        when {
            selected -> colors.primary
            hovered -> colors.onSurface
            else -> colors.onSurfaceVariant
        },
        tween(ms),
        label = "tint",
    )
    // The count is ringed in what lies behind it: the pill of ink or the page.
    val ring by animateColorAsState(
        if (selected) softFill(strong = true).compositeOver(colors.background) else colors.background,
        tween(ms),
        label = "ring",
    )
    Column(
        modifier
            .feedbackScale(
                source,
            ).clickable(interactionSource = source, indication = null, role = Role.Tab, onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp, Alignment.CenterVertically),
    ) {
        Box(
            spot
                .width(if (wide) 56.dp else 64.dp)
                .height(32.dp)
                .background(glow, CircleShape)
                .border(2.dp, colors.primary.copy(alpha = if (focused) 1f else 0f), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Box(
                Modifier.graphicsLayer {
                    scaleX = lift
                    scaleY = lift
                },
            ) { NavIcon(destination, selected, avatar, tint, badge = badge, ring = ring) }
        }
        if (labels == NavLabels.Always || (labels == NavLabels.Selected && selected)) {
            NavLabel(
                stringResource(destination.label),
                selected,
                tint,
                dot = false,
            )
        }
    }
}
