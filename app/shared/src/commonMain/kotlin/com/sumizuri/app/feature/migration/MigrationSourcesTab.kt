package com.sumizuri.app.feature.migration

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DragHandle
import androidx.compose.material3.Checkbox
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.MigrationState
import com.sumizuri.app.data.migration.SourceChoice
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_drag
import com.sumizuri.app.shared.resources.mig_exclude_shown
import com.sumizuri.app.shared.resources.mig_gave_up
import com.sumizuri.app.shared.resources.mig_include_shown
import com.sumizuri.app.shared.resources.mig_source_stats
import com.sumizuri.app.shared.resources.mig_sources_empty
import com.sumizuri.app.shared.resources.mig_sources_filter
import com.sumizuri.app.shared.resources.mig_sources_hint
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.card.softPress
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.SoftActionChip
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.kit.cover.shownName
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.PageList
import com.sumizuri.app.ui.kit.scroll.DragReorderColumn
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.stringResource

// The sources that are searched, in the order they are tried in. A tick puts one in or leaves it out, and the handle moves it. With a word typed only the sources with it in their name are shown, and the buttons act on those.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun MigrationSourcesTab(state: MigrationState, session: MigrationSession) {
    var query by remember { mutableStateOf("") }
    val shown = remember(state.sources, query) {
        state.sources.filter {
            query.isBlank() ||
                it.source.name.contains(query.trim(), ignoreCase = true)
        }
    }
    PageList {
        item {
            Text(
                stringResource(Res.string.mig_sources_hint),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline,
            )
        }
        item { AppSearchBar(query, { query = it }, stringResource(Res.string.mig_sources_filter)) }
        item {
            ChipRow(wrap = true) {
                val ids = shown.map { it.source.id }.toSet()
                SoftActionChip(
                    { session.setSourcesIncluded(ids, true) },
                    { Text(stringResource(Res.string.mig_include_shown)) },
                )
                SoftActionChip(
                    { session.setSourcesIncluded(ids, false) },
                    { Text(stringResource(Res.string.mig_exclude_shown)) },
                )
            }
        }
        if (state.sources.isEmpty()) {
            item {
                Text(stringResource(Res.string.mig_sources_empty), color = MaterialTheme.colorScheme.outline)
            }
        }
        if (shown.isNotEmpty()) {
            item {
                DragReorderColumn(shown, {
                    it.source.id
                }, { ordered ->
                    session.setSourceOrder(
                        withOrder(
                            state.sources,
                            ordered.map {
                                it.source.id
                            },
                        ),
                    )
                }) { choice, lifted, handle, rowModifier ->
                    SourceCard(
                        choice,
                        lifted,
                        handle,
                        { session.setSourceIncluded(choice.source.id, !choice.included) },
                        rowModifier,
                    )
                }
            }
        }
    }
}

// The order of every source when the ones that are shown are put in the order given, which takes the places the shown ones had and leaves the others where they are.
private fun withOrder(all: List<SourceChoice>, shown: List<String>): List<String> {
    val places = shown.toMutableList()
    val here = shown.toSet()
    return all.map { if (it.source.id in here) places.removeAt(0) else it.source.id }
}

// One source with a tick, its mark and name, the language, how the run has gone with it, and a handle to drag it by.
@Composable
private fun SourceCard(
    choice: SourceChoice,
    lifted: Boolean,
    handle: Modifier,
    onToggle: () -> Unit,
    modifier: Modifier,
) {
    val colors = MaterialTheme.colorScheme
    Box(
        modifier
            .fillMaxWidth()
            .shadow(if (lifted) 6.dp else 0.dp, MaterialTheme.shapes.small)
            .softPress(onToggle)
            .then(if (lifted) Modifier.softCard(strong = true) else Modifier),
    ) {
        Row(
            Modifier.padding(6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Checkbox(choice.included, null)
            SourceMark(choice.source.iconUrl, size = 32.dp, sourceId = choice.source.id)
            Column(Modifier.weight(1f)) {
                Text(
                    choice.source.shownName(),
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                val stats = if (choice.asked >
                    0
                ) {
                    " · " +
                        stringResource(Res.string.mig_source_stats, choice.asked, choice.matched, choice.failures)
                } else {
                    ""
                }
                Text(
                    languageName(choice.source.lang) + stats +
                        if (choice.gaveUp) " · " + stringResource(Res.string.mig_gave_up) else "",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (choice.gaveUp) colors.error else colors.outline,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Box(Modifier.padding(8.dp).then(handle)) {
                Icon(Icons.Filled.DragHandle, stringResource(Res.string.display_drag), tint = colors.outline)
            }
        }
    }
}
