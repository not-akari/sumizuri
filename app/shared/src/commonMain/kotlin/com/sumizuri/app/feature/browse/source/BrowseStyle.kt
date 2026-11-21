package com.sumizuri.app.feature.browse.source

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ViewList
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.ViewAgenda
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_style
import com.sumizuri.app.shared.resources.shelf_style_cards
import com.sumizuri.app.shared.resources.shelf_style_grid
import com.sumizuri.app.shared.resources.shelf_style_list
import com.sumizuri.app.ui.kit.card.softPress
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.badge.SavedBadge
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.text.displayName
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// How the entries of a source are laid out: a grid of covers, thin rows, or cards that also show the start of the description. No cell is wider than its width, so a wide window puts rows and cards side by side.
enum class BrowseStyle(val label: StringResource, val icon: ImageVector, val cell: Dp) {
    Grid(Res.string.shelf_style_grid, Icons.Outlined.GridView, 156.dp),
    List(Res.string.shelf_style_list, Icons.AutoMirrored.Outlined.ViewList, 520.dp),
    Cards(Res.string.shelf_style_cards, Icons.Outlined.ViewAgenda, 560.dp),
}

// The button in the bar that shows the style in use and opens a menu of the others.
@Composable
internal fun BrowseStyleButton(style: BrowseStyle, onStyle: (BrowseStyle) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box {
        IconButton({ open = true }) { Icon(style.icon, stringResource(Res.string.display_style)) }
        AppMenu(open, { open = false }) {
            for (choice in BrowseStyle.entries) {
                AppMenuItem(
                    text = { Text(stringResource(choice.label)) },
                    leadingIcon = { Icon(choice.icon, null, Modifier.size(20.dp)) },
                    trailingIcon = { if (choice == style) Icon(Icons.Outlined.Check, null, Modifier.size(18.dp)) },
                    onClick = {
                        open = false
                        onStyle(choice)
                    },
                )
            }
        }
    }
}

// An entry as a row: a small cover, the name, and under it the author and the status.
@Composable
internal fun BrowseLine(
    title: Title,
    saved: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    onLongClick: (() -> Unit)? = null,
) {
    Row(
        modifier.fillMaxWidth().softPress(onClick, onLongClick).padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        EntryCover(title, saved, 52.dp, letterSize = 14)
        Column(Modifier.weight(1f)) {
            Text(
                title.displayName(),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            EntryFacts(title)
        }
    }
}

// An entry as a card: a bigger cover, the name, the author and the status, the first genres and the start of the description.
@Composable
internal fun BrowseCard(
    title: Title,
    saved: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    onLongClick: (() -> Unit)? = null,
) {
    Row(
        modifier.fillMaxWidth().softPress(onClick, onLongClick).padding(10.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        EntryCover(title, saved, 96.dp, letterSize = 24)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                title.displayName(),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            EntryFacts(title)
            if (title.genres.isNotEmpty()) {
                Text(
                    title.genres.take(4).joinToString(" · "),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            if (title.summary.isNotBlank()) {
                Text(
                    title.summary,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 4,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

// A cover of the given width with the mark of an entry already in the library.
@Composable
private fun EntryCover(title: Title, saved: Boolean, width: Dp, letterSize: Int) {
    Box(Modifier.width(width)) {
        CoverArt(title, Modifier.fillMaxWidth(), letterSize = letterSize)
        if (saved) SavedBadge(Modifier.align(Alignment.TopStart).padding(4.dp))
    }
}

// The author and the status, which a list of a source often leaves out, so the line is left out with them.
@Composable
private fun EntryFacts(title: Title) {
    val status = if (title.status == Status.Unknown) null else stringResource(title.status.label)
    val facts = listOfNotNull(title.author.takeIf { it.isNotBlank() }, status)
    if (facts.isNotEmpty()) {
        Text(
            facts.joinToString(", "),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.outline,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
