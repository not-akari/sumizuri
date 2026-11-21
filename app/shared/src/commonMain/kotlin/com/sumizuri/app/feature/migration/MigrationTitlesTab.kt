package com.sumizuri.app.feature.migration

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyItemScope
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material3.Checkbox
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TriStateCheckbox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.migration.MigrationItem
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.MigrationState
import com.sumizuri.app.data.migration.MigrationStatus
import com.sumizuri.app.data.model.SourceState
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_filter_title
import com.sumizuri.app.shared.resources.mig_group_count
import com.sumizuri.app.shared.resources.mig_group_lost
import com.sumizuri.app.shared.resources.mig_unread
import com.sumizuri.app.ui.kit.card.softPress
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.PageList
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.text.displayName
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource

// Whether the source of a title is gone or broken, which makes it the first thing to move.
internal val MigrationItem.lost: Boolean get() = title.sourceState != SourceState.Ready

// The first step: which titles are in the work. Quick picks choose a whole kind of title at once, filters narrow the list, and the titles are grouped under the source they come from now, the lost sources first. A group folds and is picked or left out in one tap.
@Composable
internal fun MigrationTitlesTab(state: MigrationState, shelves: List<Category>, session: MigrationSession) {
    var filter by remember { mutableStateOf(TitleFilter()) }
    var folded by remember { mutableStateOf(emptySet<String>()) }
    val shown = remember(state.items, filter) { state.items.filter { filter.matches(it) } }
    val groups = remember(shown) {
        shown
            .groupBy { it.fromName }
            .entries
            .sortedWith(compareBy({ entry -> entry.value.none { it.lost } }, { it.key.lowercase() }))
    }
    PageList {
        item {
            AppSearchBar(
                filter.query,
                { filter = filter.copy(query = it) },
                stringResource(Res.string.mig_filter_title),
            )
        }
        item { QuickPicks(state, session) }
        item { TitleFilters(state, shelves, filter) { filter = it } }
        for ((name, rows) in groups) {
            val open = name !in folded
            item(key = "group:$name") {
                GroupHeader(name, rows, open, animateRow(), {
                    folded = if (open) folded + name else folded - name
                }) { on -> session.setIncluded(rows.map { it.id }.toSet(), on) }
            }
            if (open) {
                items(rows, key = { it.id }) { item ->
                    TitleRow(item, animateRow()) { session.setIncluded(setOf(item.id), !item.included) }
                }
            }
        }
    }
}

// Rows slide into their new places and fade in and out as groups fold, unless motion is turned down.
@Composable
private fun LazyItemScope.animateRow(): Modifier = if (LocalReduceMotion.current) {
    Modifier
} else {
    Modifier.animateItem(
        fadeInSpec = tween(motionMs(AppMotion.Medium)),
        placementSpec = tween(motionMs(AppMotion.Medium)),
        fadeOutSpec = tween(motionMs(AppMotion.Fast)),
    )
}

// The name of an old source with a tick for all of its titles, how many are picked, a mark when the source is lost, and an arrow that folds it.
@Composable
private fun GroupHeader(
    name: String,
    rows: List<MigrationItem>,
    open: Boolean,
    modifier: Modifier,
    onFold: () -> Unit,
    onPick: (Boolean) -> Unit,
) {
    val picked = rows.count { it.included }
    val tick = when (picked) {
        0 -> ToggleableState.Off
        rows.size -> ToggleableState.On
        else -> ToggleableState.Indeterminate
    }
    val turn by animateFloatAsState(if (open) 0f else -90f, tween(motionMs(AppMotion.Fast)), label = "fold")
    Row(
        modifier
            .fillMaxWidth()
            .padding(top = 8.dp)
            .clip(MaterialTheme.shapes.small)
            .clickable(onClick = onFold),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        TriStateCheckbox(tick, { onPick(picked < rows.size) })
        Column(Modifier.weight(1f)) {
            Text(
                name,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            val lost = rows.any { it.lost }
            Text(
                stringResource(Res.string.mig_group_count, picked, rows.size) +
                    if (lost) ", " + stringResource(Res.string.mig_group_lost) else "",
                style = MaterialTheme.typography.bodySmall,
                color = if (lost) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.outline,
            )
        }
        Icon(
            Icons.Outlined.ExpandMore,
            null,
            Modifier.padding(end = 10.dp).rotate(turn),
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

// One title as a soft row with a tick, a small cover, its name, how much is unread, and its state once the work has touched it.
@Composable
private fun TitleRow(item: MigrationItem, modifier: Modifier, onToggle: () -> Unit) {
    Row(
        modifier
            .fillMaxWidth()
            .padding(start = 12.dp)
            .softPress(onToggle)
            .padding(end = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Checkbox(item.included, null, Modifier.padding(start = 4.dp))
        CoverArt(item.title, Modifier.width(30.dp).padding(vertical = 6.dp), letterSize = 11)
        Column(Modifier.weight(1f)) {
            Text(
                item.title.displayName(),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (item.title.unread > 0) {
                Text(
                    stringResource(Res.string.mig_unread, item.title.unread),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                    maxLines = 1,
                )
            }
        }
        if (item.status != MigrationStatus.Queued) {
            Text(
                stringResource(item.status.label()),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.primary,
            )
        }
    }
}
