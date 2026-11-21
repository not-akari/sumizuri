package com.sumizuri.app.feature.updates.row

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.displayName

// A new chapter as a dense line like a mail inbox: a dot, a small cover, the title in bold and the chapters, or the range of them, under it. Under the mouse the line glows faintly and its dot swells.
@Composable
internal fun UpdateInboxRow(
    item: UpdateItem,
    onOpen: () -> Unit,
    onAction: () -> Unit,
    action: FeedAction = FeedAction.MarkRead,
) {
    val colors = MaterialTheme.colorScheme
    val below = feedSpanText(item.title.kind, item.numbers, item.name)
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val swell by animateFloatAsState(
        if (hovered) 1.4f else 1f,
        if (motionMs(AppMotion.Fast) == 0) snap() else spring(0.45f, Spring.StiffnessMedium),
        label = "swell",
    )
    val glow by animateColorAsState(
        colors.onSurface.copy(alpha = if (hovered) 0.05f else 0f),
        tween(motionMs(AppMotion.Fast)),
        label = "glow",
    )
    Row(
        Modifier
            .fillMaxWidth()
            .feedbackScale(source, hover = false)
            .background(glow, MaterialTheme.shapes.small)
            .clickable(source, indication = null, onClick = onOpen)
            .padding(start = 4.dp, top = 6.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            Modifier
                .size(8.dp)
                .graphicsLayer {
                    scaleX = swell
                    scaleY = swell
                }.background(colors.primary, CircleShape),
        )
        CoverArt(item.title, Modifier.width(30.dp), letterSize = 12)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Text(
                item.title.displayName(),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            // The time sits after the line under the name, so a narrow phone keeps the room for the name.
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    below,
                    Modifier.weight(1f, fill = false),
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    "  ·  " + agoText(item.at),
                    style = MaterialTheme.typography.labelMedium,
                    color = colors.outline,
                    maxLines = 1,
                )
            }
        }
        FeedActionButton(action, onAction)
    }
}
