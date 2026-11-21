package com.sumizuri.app.feature.library.tile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.SourceState
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.library.CoverBadgeKind
import com.sumizuri.app.data.model.library.CoverCorner
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.cover.CoverPick
import com.sumizuri.app.ui.kit.cover.badge.SourceWarningBadge
import com.sumizuri.app.ui.kit.cover.badge.UnreadBadge
import com.sumizuri.app.ui.text.displayName
import com.sumizuri.app.ui.text.unitCount
import org.jetbrains.compose.resources.stringResource

// A title as a row on a soft card like the chapter rows: a small cover, the name, and under it the author, the status and the count of chapters. The compact row is thin and has only the name. The marks the person turned on stand at the end of the row, since a small cover has no room for them.
@Composable
internal fun ListRow(
    title: Title,
    context: TileContext,
    pick: CoverPick,
    tap: Modifier,
    hovered: Boolean,
    compact: Boolean,
) {
    Row(
        tap
            .fillMaxWidth()
            .softCard(lit = hovered || pick.picked)
            .padding(horizontal = 10.dp, vertical = if (compact) 6.dp else 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.width((if (compact) context.listCover * 0.62f else context.listCover.toFloat()).dp)) {
            TileCover(title, context, pick, nameOver = false, marks = false)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                title.displayName(),
                style = MaterialTheme.typography.bodyLarge.scaled(context.nameScale),
                fontWeight = FontWeight.SemiBold,
                maxLines = if (compact) 1 else 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (!compact) {
                val facts = listOfNotNull(
                    title.author.takeIf { it.isNotBlank() },
                    stringResource(title.status.label),
                    unitCount(title.kind, title.chapterCount).takeIf { title.chapterCount > 0 },
                )
                Text(
                    facts.joinToString(" · "),
                    style = MaterialTheme.typography.bodySmall.scaled(context.nameScale),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            if (title.sourceState != SourceState.Ready) SourceWarningBadge()
            if (title.favorite && context.favoritesEnabled &&
                context.badges.cornerOf(CoverBadgeKind.Favorite) != CoverCorner.Off
            ) {
                Icon(Icons.Filled.Star, null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.tertiary)
            }
            if (title.unread > 0 && context.badges.cornerOf(CoverBadgeKind.Unread) != CoverCorner.Off) {
                UnreadBadge(title.unread)
            }
        }
    }
}
