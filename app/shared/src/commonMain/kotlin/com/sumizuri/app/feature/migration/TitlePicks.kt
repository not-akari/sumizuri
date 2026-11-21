package com.sumizuri.app.feature.migration

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.MigrationState
import com.sumizuri.app.data.migration.MigrationStatus
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.all
import com.sumizuri.app.shared.resources.mig_filter_shelf
import com.sumizuri.app.shared.resources.mig_pick_label
import com.sumizuri.app.shared.resources.mig_pick_lost
import com.sumizuri.app.shared.resources.mig_pick_none
import com.sumizuri.app.shared.resources.mig_pick_unread
import com.sumizuri.app.shared.resources.mig_picked_only
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.input.MenuButton
import com.sumizuri.app.ui.kit.setting.SettingsHeading
import org.jetbrains.compose.resources.stringResource

// Chips that pick a whole kind of title in one tap: all, none, those whose source is lost, and those with chapters left to read. The one that matches what is picked now is lit.
@Composable
internal fun QuickPicks(state: MigrationState, session: MigrationSession) {
    val sets = remember(state.items) {
        val open = state.items.filter { it.status != MigrationStatus.Moved }
        PickSets(
            every = open.map { it.id }.toSet(),
            picked = open.filter { it.included }.map { it.id }.toSet(),
            lost = open.filter { it.lost }.map { it.id }.toSet(),
            unread = open.filter { it.title.unread > 0 }.map { it.id }.toSet(),
        )
    }
    fun pick(ids: Set<Long>) {
        session.setIncluded(sets.every - ids, false)
        session.setIncluded(ids, true)
    }
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        SettingsHeading(stringResource(Res.string.mig_pick_label))
        ChipRow(wrap = true) {
            PickChip(stringResource(Res.string.all), sets.every.size, sets.picked == sets.every) { pick(sets.every) }
            PickChip(stringResource(Res.string.mig_pick_none), null, sets.picked.isEmpty()) { pick(emptySet()) }
            if (sets.lost.isNotEmpty()) {
                PickChip(
                    stringResource(Res.string.mig_pick_lost),
                    sets.lost.size,
                    sets.picked == sets.lost,
                ) { pick(sets.lost) }
            }
            if (sets.unread.isNotEmpty()) {
                PickChip(stringResource(Res.string.mig_pick_unread), sets.unread.size, sets.picked == sets.unread) {
                    pick(sets.unread)
                }
            }
        }
    }
}

private class PickSets(val every: Set<Long>, val picked: Set<Long>, val lost: Set<Long>, val unread: Set<Long>)

// A chip with a name and, when given, how many titles it stands for.
@Composable
private fun PickChip(label: String, count: Int?, selected: Boolean, onClick: () -> Unit) {
    SoftChip(selected, onClick, {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(label)
            if (count != null) {
                Text(
                    count.toString(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
        }
    })
}

// What narrows the list: a chip for each kind when there are several, the shelf, and only the picked titles.
@Composable
internal fun TitleFilters(
    state: MigrationState,
    shelves: List<Category>,
    filter: TitleFilter,
    onChange: (TitleFilter) -> Unit,
) {
    val kinds = remember(state.items) { state.items.map { it.title.kind }.distinct() }
    val usedShelves = remember(state.items, shelves) {
        shelves.filter { shelf ->
            state.items.any {
                shelf.id in
                    it.shelves
            }
        }
    }
    ChipRow(wrap = true) {
        if (kinds.size > 1) {
            for (kind in kinds) {
                SoftChip(filter.kind == kind, {
                    onChange(filter.copy(kind = if (filter.kind == kind) null else kind))
                }, { Text(stringResource(kind.label)) })
            }
        }
        SoftChip(filter.pickedOnly, { onChange(filter.copy(pickedOnly = !filter.pickedOnly)) }, {
            Text(stringResource(Res.string.mig_picked_only))
        })
        if (usedShelves.isNotEmpty()) {
            MenuButton(listOf<Long?>(null) + usedShelves.map { it.id }, filter.shelf, { id ->
                usedShelves.firstOrNull { it.id == id }?.name ?: stringResource(Res.string.mig_filter_shelf)
            }) { onChange(filter.copy(shelf = it)) }
        }
    }
}
