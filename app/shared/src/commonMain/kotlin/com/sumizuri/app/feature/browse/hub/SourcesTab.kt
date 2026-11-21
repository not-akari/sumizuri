package com.sumizuri.app.feature.browse.hub

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ViewList
import androidx.compose.material.icons.outlined.ArrowDropDown
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Storefront
import androidx.compose.material.icons.outlined.SystemUpdateAlt
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_all_sources
import com.sumizuri.app.shared.resources.browse_by_hand
import com.sumizuri.app.shared.resources.browse_by_language
import com.sumizuri.app.shared.resources.browse_by_repo
import com.sumizuri.app.shared.resources.browse_empty_sources
import com.sumizuri.app.shared.resources.browse_find_source
import com.sumizuri.app.shared.resources.browse_jump_back
import com.sumizuri.app.shared.resources.browse_no_groups
import com.sumizuri.app.shared.resources.browse_no_match
import com.sumizuri.app.shared.resources.browse_search_all_for
import com.sumizuri.app.shared.resources.browse_turned_off
import com.sumizuri.app.shared.resources.extensions_add_file
import com.sumizuri.app.shared.resources.extensions_add_repo
import com.sumizuri.app.shared.resources.local_on_device
import com.sumizuri.app.shared.resources.section_count
import com.sumizuri.app.shared.resources.sources_update_all
import com.sumizuri.app.shared.resources.sources_updates_notice
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.card.SoftGap
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChipSeparator
import com.sumizuri.app.ui.kit.chips.KindChips
import com.sumizuri.app.ui.kit.chips.SoftActionChip
import com.sumizuri.app.ui.kit.input.ActionButton
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.kit.page.PageGrid
import com.sumizuri.app.ui.kit.page.TileWidth
import com.sumizuri.app.ui.kit.page.fullSpan
import com.sumizuri.app.ui.kit.page.readableLine
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The installed sources: a field that finds one by name, the kind and the grouping as chips, a notice of updates, a row of pinned and lately used ones, then each group as tiles, and the turned off ones at the end. The tiles use the whole width, while what stands above them keeps a readable one.
@Composable
internal fun SourcesTab(state: BrowseHubState, actions: BrowseHubActions) {
    val searching = state.query.isNotBlank()
    PageGrid(gap = SoftGap + 2.dp, rowGap = SoftGap + 2.dp, columns = GridCells.Adaptive(TileWidth)) {
        readableLine(
            "search",
        ) { AppSearchBar(state.query, actions.onQuery, stringResource(Res.string.browse_find_source)) }
        // The words typed can also be looked for inside every source.
        if (searching) {
            readableLine("search_all") {
                AppListRow(
                    stringResource(Res.string.browse_search_all_for, state.query.trim()),
                    leading = { Icon(Icons.Outlined.Search, null, tint = MaterialTheme.colorScheme.primary) },
                    onClick = { actions.onOpenSearch(state.query.trim()) },
                )
            }
        }
        // The chips use the whole width, so a long row does not need a sideways scroll on a wide window.
        fullSpan("chips") { Box(Modifier.animateItem()) { Chips(state, actions) } }
        if (state.updateCount > 0 && !searching) {
            readableLine("updates") {
                UpdateNotice(
                    state.updateCount,
                    !state.updating,
                    actions.onUpdateAll,
                ) { actions.onTab(BrowseTab.Extensions) }
            }
        }
        if (state.loaded && state.sourceCount == 0 && state.off.isEmpty() &&
            !searching
        ) {
            readableLine("none") { NoSources(actions) }
        }
        if (searching && state.groups.isEmpty() && state.off.isEmpty()) {
            readableLine("no_match") {
                Text(
                    stringResource(Res.string.browse_no_match),
                    Modifier.padding(vertical = 16.dp),
                    color = MaterialTheme.colorScheme.outline,
                )
            }
        }
        if (state.jump.isNotEmpty()) {
            fullSpan("jump") {
                Column(Modifier.animateItem(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    AppSectionLabel(Res.string.browse_jump_back)
                    JumpRow(state.jump, state.pinned, actions.onOpenSource)
                }
            }
        }
        for (group in state.groups) {
            val mixed = state.grouping != SourceGrouping.Language && group.sources.mapTo(HashSet()) { it.lang }.size > 1
            tiles("group:${group.key}", {
                stringResource(Res.string.section_count, groupTitle(group.name), group.sources.size)
            }, group.sources, state, actions, mixed)
        }
        if (state.off.isNotEmpty()) {
            tiles("off", {
                stringResource(Res.string.section_count, stringResource(Res.string.browse_turned_off), state.off.size)
            }, state.off, state, actions, false)
        }
    }
}

// The heading of a group, then each of its sources as its own tile, so a tile that comes or goes makes the others slide.
private fun LazyGridScope.tiles(
    key: String,
    title: @Composable () -> String,
    sources: List<InstalledSource>,
    state: BrowseHubState,
    actions: BrowseHubActions,
    showLanguage: Boolean,
) {
    fullSpan(key) { AppSectionLabel(title(), Modifier.animateItem()) }
    items(sources, key = { "$key:${it.id}" }) { source ->
        SourceTile(
            source,
            source.id in state.pinned,
            source.id in state.updateIds,
            showLanguage,
            actions,
            Modifier.animateItem().entrance(),
        )
    }
}

// The words of a heading of the sources.
@Composable
private fun groupTitle(name: GroupName): String = when (name) {
    is GroupName.Repo -> name.name
    is GroupName.Language -> languageName(name.code)
    GroupName.ByHand -> stringResource(Res.string.browse_by_hand)
    GroupName.Device -> stringResource(Res.string.local_on_device)
    GroupName.All -> stringResource(Res.string.browse_all_sources)
}

// The kinds as chips when there is more than one, then one chip that says how the sources are grouped and opens the choices.
@Composable
private fun Chips(state: BrowseHubState, actions: BrowseHubActions) {
    ChipRow {
        if (state.kinds.size > 1) {
            KindChips(state.kind, state.kinds, actions.onKind)
            ChipSeparator()
        }
        GroupChip(state.grouping, actions.onGrouping)
    }
}

@Composable
private fun GroupChip(grouping: SourceGrouping, onGrouping: (SourceGrouping) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box {
        SoftActionChip(
            onClick = { open = true },
            label = { Text(groupingLabel(grouping)) },
            leadingIcon = { Icon(groupingIcon(grouping), null, Modifier.size(18.dp)) },
            trailingIcon = { Icon(Icons.Outlined.ArrowDropDown, null, Modifier.size(18.dp)) },
        )
        AppMenu(open, { open = false }) {
            for (each in SourceGrouping.entries) {
                AppMenuItem(
                    text = { Text(groupingLabel(each)) },
                    leadingIcon = { Icon(groupingIcon(each), null, Modifier.size(20.dp)) },
                    trailingIcon = { if (each == grouping) Icon(Icons.Outlined.Check, null, Modifier.size(18.dp)) },
                    onClick = {
                        open = false
                        onGrouping(each)
                    },
                )
            }
        }
    }
}

@Composable
private fun groupingLabel(grouping: SourceGrouping): String = stringResource(
    when (grouping) {
        SourceGrouping.Repo -> Res.string.browse_by_repo
        SourceGrouping.Language -> Res.string.browse_by_language
        SourceGrouping.None -> Res.string.browse_no_groups
    },
)

private fun groupingIcon(grouping: SourceGrouping) = when (grouping) {
    SourceGrouping.Repo -> Icons.Outlined.Storefront
    SourceGrouping.Language -> Icons.Outlined.Translate
    SourceGrouping.None -> Icons.AutoMirrored.Outlined.ViewList
}

// How many sources have a newer version, with a button that updates them all here. Browse and a repo both show it.
@Composable
internal fun UpdateNotice(count: Int, enabled: Boolean, onUpdateAll: () -> Unit, onClick: (() -> Unit)? = null) {
    Row(
        Modifier
            .fillMaxWidth()
            .softCard()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(start = 14.dp, end = 6.dp, top = 6.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(Icons.Outlined.SystemUpdateAlt, null, tint = MaterialTheme.colorScheme.primary)
        Text(
            pluralStringResource(Res.plurals.sources_updates_notice, count, count),
            Modifier.weight(1f),
            style = MaterialTheme.typography.bodyLarge,
        )
        TextButton(
            onUpdateAll,
            enabled = enabled,
        ) { Text(stringResource(Res.string.sources_update_all)) }
    }
}

// With no source yet, the ways to get one.
@Composable
private fun NoSources(actions: BrowseHubActions) {
    Column(
        Modifier.fillMaxWidth().padding(vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            stringResource(Res.string.browse_empty_sources),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ActionButton(Res.string.extensions_add_repo, actions.onAddRepo)
            ActionButton(Res.string.extensions_add_file, actions.onAddFile)
        }
    }
}
