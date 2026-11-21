package com.sumizuri.app.feature.updates.row

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.ui.kit.card.SoftGap
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.motion.RollingCount
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.displayName

// A new chapter as a soft card like the chapter rows: a cover, the title, and under it which chapter it is and when it came, with the count and the button at the end. The time sits under the name so a phone keeps the whole line for the name. The compact list has a smaller cover.
@Composable
internal fun UpdateCardRow(
    item: UpdateItem,
    dense: Boolean,
    onOpen: () -> Unit,
    onAction: () -> Unit,
    action: FeedAction = FeedAction.MarkRead,
) {
    val colors = MaterialTheme.colorScheme
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    Row(
        Modifier
            .padding(vertical = SoftGap / 2)
            .fillMaxWidth()
            .feedbackScale(source, hover = false)
            .softCard(lit = hovered)
            .clickable(source, indication = null, onClick = onOpen)
            .padding(start = 10.dp, top = 6.dp, bottom = 6.dp, end = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CoverArt(item.title, Modifier.width(if (dense) 32.dp else 42.dp), letterSize = 16)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                item.title.displayName(),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    feedSpanText(item.title.kind, item.numbers, item.name),
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
        if (item.count > 1) CountPill(item.count)
        FeedActionButton(action, onAction)
    }
}

// The count of chapters a row stands for, when it stands for more than one. It rolls when a chapter comes or goes.
@Composable
private fun CountPill(count: Int) {
    RollingCount(
        count,
        Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(MaterialTheme.colorScheme.primary)
            .padding(horizontal = 7.dp, vertical = 1.dp),
    ) {
        Text(
            it.toString(),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onPrimary,
        )
    }
}
