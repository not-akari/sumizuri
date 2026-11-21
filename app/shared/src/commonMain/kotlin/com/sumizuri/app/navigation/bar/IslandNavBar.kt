package com.sumizuri.app.navigation.bar

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.theme.LocalReduceMotion
import com.sumizuri.app.ui.theme.LocalThemeSpec
import org.jetbrains.compose.resources.stringResource

// The floating bar. The chosen tab opens out to show its name, and the block of color under it moves like a drop of ink: the edge that leads runs ahead and the edge behind follows slowly, so it stretches and then gathers up again. A ring of ink spreads from it when a tab is chosen, and the whole bar rises into place when the app opens.
@Composable
internal fun IslandNavBar(
    tabs: List<Destination>,
    selected: Destination,
    labels: NavLabels,
    avatar: NavAvatar?,
    badges: Map<Destination, Int>,
    onSelect: (Destination) -> Unit,
    modifier: Modifier = Modifier,
) {
    val spec = LocalThemeSpec.current
    val colors = MaterialTheme.colorScheme
    val shape = spec.shapes.navBar.toShape()
    val blob = CircleShape
    val reduce = LocalReduceMotion.current
    val density = LocalDensity.current
    val measurer = rememberTextMeasurer()
    val labelStyle = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold)
    val names = tabs.map { stringResource(it.label) }
    val showName = labels != NavLabels.Never
    BoxWithConstraints(modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        val nameWidths = names.map {
            with(density) {
                measurer
                    .measure(it, labelStyle)
                    .size.width
                    .toDp()
            }
        }
        val index = tabs.indexOf(selected).coerceAtLeast(0)
        val extra = if (showName) 2.dp + nameWidths[index] + 14.dp else 0.dp
        val room = maxWidth - IslandMetrics.Margin * 2 - IslandMetrics.Padding * 2 - extra
        val slot: Dp = (room / tabs.size).coerceIn(IslandMetrics.MinSlot, IslandMetrics.MaxSlot)
        val left = slot * index
        val right = left + slot + extra
        // The edge that leads is quick and the one behind is slow, which stretches the block while it travels.
        var before by remember { mutableIntStateOf(index) }
        val forward = index >= before
        SideEffect { before = index }
        val quick = if (reduce) snap() else spring<Dp>(0.8f, Spring.StiffnessMedium)
        val slow = if (reduce) snap() else spring<Dp>(0.75f, Spring.StiffnessLow)
        val edgeLeft by animateDpAsState(left, if (forward) slow else quick, label = "left")
        val edgeRight by animateDpAsState(right, if (forward) quick else slow, label = "right")
        // The ring of ink starts again each time another tab is chosen.
        val ring = remember { Animatable(1f) }
        LaunchedEffect(index) {
            if (reduce) return@LaunchedEffect
            ring.snapTo(0f)
            ring.animateTo(1f, tween(520, easing = AppMotion.Exit))
        }
        Box(
            Modifier
                .shadow(
                    10.dp,
                    shape,
                    ambientColor = Color.Black.copy(alpha = 0.3f),
                    spotColor = Color.Black.copy(alpha = 0.45f),
                ).clip(shape)
                .background(colors.surfaceContainerHigh.copy(alpha = 0.92f))
                .border(0.8.dp, colors.outlineVariant.copy(alpha = 0.35f), shape)
                .drawBehind {
                    val centre = Offset(((edgeLeft + edgeRight) / 2 + IslandMetrics.Padding).toPx(), size.height / 2)
                    val spread = ring.value
                    if (spread <
                        1f
                    ) {
                        drawCircle(
                            colors.primary.copy(alpha = 0.28f * (1f - spread)),
                            size.width * 0.5f * spread,
                            centre,
                        )
                    }
                }.padding(IslandMetrics.Padding),
        ) {
            Box(
                Modifier
                    .offset(edgeLeft)
                    .width((edgeRight - edgeLeft).coerceAtLeast(0.dp))
                    .height(IslandMetrics.SlotHeight)
                    .background(colors.primaryContainer, blob),
            )
            Row {
                tabs.forEachIndexed { at, tab ->
                    IslandSlot(
                        tab,
                        names[at],
                        nameWidths[at],
                        tab == selected && showName,
                        tab == selected,
                        avatar,
                        badges[tab] ?: 0,
                        slot,
                    ) { onSelect(tab) }
                }
            }
        }
    }
}

// One tab of the island: the icon in a square of its own, which grows when the tab is chosen, and the name that opens out beside it.
@Composable
private fun IslandSlot(
    destination: Destination,
    name: String,
    nameWidth: Dp,
    open: Boolean,
    selected: Boolean,
    avatar: NavAvatar?,
    badge: Int,
    slot: Dp,
    onClick: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val source = remember { MutableInteractionSource() }
    val reduce = LocalReduceMotion.current
    val ms = motionMs(AppMotion.Fast)
    val width by animateDpAsState(
        if (open) slot + 2.dp + nameWidth + 14.dp else slot,
        if (reduce) snap() else spring(0.8f, Spring.StiffnessMediumLow),
        label = "slot",
    )
    val grow by animateFloatAsState(
        if (selected) 1.14f else 1f,
        if (reduce) snap() else spring(0.5f, Spring.StiffnessMedium),
        label = "grow",
    )
    val say by animateFloatAsState(
        if (open) 1f else 0f,
        tween(ms, delayMillis = if (open) ms / 2 else 0),
        label = "say",
    )
    val tint by animateColorAsState(
        if (selected) colors.onPrimaryContainer else colors.onSurfaceVariant,
        tween(ms),
        label = "tint",
    )
    // The count is ringed in what lies behind it: the chosen blob or the island.
    val ring by animateColorAsState(
        if (selected) colors.primaryContainer else colors.surfaceContainerHigh,
        tween(ms),
        label = "ring",
    )
    Row(
        Modifier
            .width(width)
            .height(IslandMetrics.SlotHeight)
            .feedbackScale(source)
            .clickable(interactionSource = source, indication = null, role = Role.Tab, onClick = onClick),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier.width(slot).fillMaxHeight().graphicsLayer {
                scaleX = grow
                scaleY = grow
            },
            contentAlignment = Alignment.Center,
        ) { NavIcon(destination, selected, avatar, tint, 22.dp, badge, ring) }
        Text(
            name,
            Modifier.padding(start = 2.dp).graphicsLayer { alpha = say },
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold,
            color = tint,
            maxLines = 1,
            overflow = TextOverflow.Clip,
            softWrap = false,
        )
    }
}
