package com.sumizuri.app.feature.updates.row

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.displayName
import com.sumizuri.app.ui.text.unitCount

// A row on the timeline: a line runs down the left with a node where the row sits, and the chapters are one chip that names the first and the last, with how many there are beside it.
@Composable
internal fun UpdateTimelineRow(
    item: UpdateItem,
    last: Boolean,
    onOpen: () -> Unit,
    onAction: () -> Unit,
    action: FeedAction = FeedAction.MarkRead,
) {
    val colors = MaterialTheme.colorScheme
    val line = colors.outlineVariant
    val node = colors.primary
    val ring = colors.background
    Row(
        Modifier
            .fillMaxWidth()
            .drawBehind {
                val x = 6.dp.toPx()
                drawLine(
                    line,
                    Offset(x, 0f),
                    Offset(x, if (last) 36.dp.toPx() else size.height),
                    strokeWidth = 2.dp.toPx(),
                )
                drawCircle(ring, 7.dp.toPx(), Offset(x, 35.dp.toPx()))
                drawCircle(node, 5.dp.toPx(), Offset(x, 35.dp.toPx()))
            }.clickable(onClick = onOpen)
            .padding(start = 26.dp, top = 10.dp, bottom = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CoverArt(item.title, Modifier.width(40.dp), letterSize = 14)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Text(
                item.title.displayName(),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            // The time goes with the chips under the name, so a narrow phone keeps the room for the name.
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(5.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
                itemVerticalAlignment = Alignment.CenterVertically,
            ) {
                FeedChip(feedSpanText(item.title.kind, item.numbers, null))
                if (item.count > 1) FeedChip(unitCount(item.title.kind, item.count), quiet = true)
                Text(
                    agoText(item.at),
                    style = MaterialTheme.typography.labelMedium,
                    color = colors.outline,
                    maxLines = 1,
                )
            }
        }
        FeedActionButton(action, onAction)
    }
}
