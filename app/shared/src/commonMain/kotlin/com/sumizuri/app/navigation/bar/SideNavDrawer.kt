package com.sumizuri.app.navigation.bar

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.navigation.DrawerWidth
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.stringResource

// The wide panel down the side, with the name of every tab beside its icon, and the pill of ink of the chosen tab sliding between the rows.
@Composable
internal fun SideNavDrawer(
    tabs: List<Destination>,
    selected: Destination,
    avatar: NavAvatar?,
    badges: Map<Destination, Int>,
    onSelect: (Destination) -> Unit,
) {
    val marker = rememberInkMarker()
    marker.Follow(tabs.indexOf(selected), vertical = true)
    val fill = softFill(strong = true)
    val ring = MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
    Surface(Modifier.fillMaxHeight().width(DrawerWidth).sideEdge(), color = Color.Transparent) {
        Column(
            Modifier
                .fillMaxHeight()
                .windowInsetsPadding(WindowInsets.safeDrawing)
                .padding(12.dp)
                .inkLayer(marker, vertical = true, fill, ring),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            tabs.forEachIndexed { at, tab ->
                if (tab == Destination.Profile) Spacer(Modifier.weight(1f))
                DrawerRow(
                    tab,
                    tab == selected,
                    avatar,
                    badges[tab] ?: 0,
                    Modifier.inkSpot(marker, at),
                ) { onSelect(tab) }
            }
        }
    }
}

@Composable
private fun DrawerRow(
    destination: Destination,
    selected: Boolean,
    avatar: NavAvatar?,
    badge: Int,
    spot: Modifier,
    onClick: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val shape = CircleShape
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val ms = motionMs(AppMotion.Fast)
    val back by animateColorAsState(
        when {
            selected -> Color.Transparent
            hovered -> colors.onSurface.copy(alpha = 0.06f)
            else -> Color.Transparent
        },
        tween(ms),
        label = "row",
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
    Row(
        spot
            .fillMaxWidth()
            .feedbackScale(source)
            .background(back, shape)
            .clickable(interactionSource = source, indication = null, role = Role.Tab, onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        NavIcon(destination, selected, avatar, tint)
        Text(
            stringResource(destination.label),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
            color = tint,
            modifier = Modifier.weight(1f),
        )
        // The count of what is new stands at the end of the row, where it has room.
        NavBadge(badge)
    }
}
