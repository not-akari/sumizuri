package com.sumizuri.app.feature.lists

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.CoverTile
import com.sumizuri.app.ui.kit.cover.badge.SavedBadge
import com.sumizuri.app.ui.motion.entrance

// One title of a list in the grid, drawn by the same cover tile as the library: the cover from the library, or a painted one with its first letter when it is not there, its name, and the note of the person under it.
@Composable
internal fun ListCell(shown: ShownItem, onOpen: () -> Unit) {
    val item = shown.item
    val title = remember(item, shown.saved) { item.coverTitle(shown.saved) }
    Column {
        CoverTile(title, onOpen, showUnread = false)
        if (item.note.isNotBlank()) {
            Text(
                item.note,
                style = MaterialTheme.typography.bodySmall,
                fontStyle = FontStyle.Italic,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

// A row of a panel in the look of the reading mode panel: an icon, or a small picture in its place, and words on a rounded pill that lights when it is on.
@Composable
internal fun PanelRow(
    icon: ImageVector,
    text: String,
    onClick: () -> Unit,
    lit: Boolean = false,
    danger: Boolean = false,
    end: (@Composable () -> Unit)? = null,
    leading: (@Composable () -> Unit)? = null,
) {
    val colors = MaterialTheme.colorScheme
    val tint = when {
        danger -> colors.error
        lit -> colors.onSecondaryContainer
        else -> colors.onSurface
    }
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(if (lit) colors.secondaryContainer else Color.Transparent)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        if (leading !=
            null
        ) {
            leading()
        } else {
            Icon(icon, null, tint = if (danger || lit) tint else colors.onSurfaceVariant)
        }
        Text(text, Modifier.weight(1f), color = tint, maxLines = 2, overflow = TextOverflow.Ellipsis)
        end?.invoke()
    }
}
