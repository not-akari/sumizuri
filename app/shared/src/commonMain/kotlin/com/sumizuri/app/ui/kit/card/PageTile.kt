package com.sumizuri.app.ui.kit.card

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

// A tile that opens a page: its icon on a round wash, its name, and how it stands in a line or two. One that needs a look has its icon in the error color.
@Composable
fun PageTile(
    icon: ImageVector,
    title: String,
    summary: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    alert: Boolean = false,
) {
    val colors = MaterialTheme.colorScheme
    CardButton(onClick, modifier) {
        Box(
            Modifier
                .padding(start = 12.dp)
                .size(38.dp)
                .clip(CircleShape)
                .background(if (alert) colors.error.copy(alpha = 0.16f) else softFill(strong = true)),
            contentAlignment = Alignment.Center,
        ) { Icon(icon, null, Modifier.size(20.dp), tint = if (alert) colors.error else colors.primary) }
        Column(Modifier.weight(1f).padding(12.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (summary.isNotBlank()) {
                Text(
                    summary,
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

// Tiles in even rows of the given number of columns, each row as tall as its tallest tile.
@Composable
fun TileGrid(columns: Int, tiles: List<@Composable (Modifier) -> Unit>, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        for (line in tiles.chunked(columns.coerceAtLeast(1))) {
            Row(
                Modifier.fillMaxWidth().height(IntrinsicSize.Min),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                for (tile in line) tile(Modifier.weight(1f).fillMaxHeight())
                repeat(columns - line.size) { Box(Modifier.weight(1f)) }
            }
        }
    }
}
