package com.sumizuri.app.feature.migration.single

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.migration.MatchScoring
import com.sumizuri.app.feature.browse.asTitle
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.all
import com.sumizuri.app.shared.resources.migrate_gone
import com.sumizuri.app.shared.resources.migrate_no_results
import com.sumizuri.app.shared.resources.migrate_no_sources
import com.sumizuri.app.shared.resources.migrate_none
import com.sumizuri.app.shared.resources.migrate_same_name
import com.sumizuri.app.shared.resources.migrate_search_hint
import com.sumizuri.app.shared.resources.migrate_sources
import com.sumizuri.app.shared.resources.migrate_sources_change
import com.sumizuri.app.shared.resources.migrate_sources_count
import com.sumizuri.app.shared.resources.migrate_sources_done
import com.sumizuri.app.shared.resources.migrate_subtitle
import com.sumizuri.app.shared.resources.migrate_title
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.shownName
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.PageList
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.setting.ChipsSetting
import org.jetbrains.compose.resources.stringResource

// A result whose name is at least this close to the name of the title counts as the same name, the way the move of many titles tells a clear match.
private const val SameName = 0.85

// Searches the installed sources of the same kind for a saved title, so it can move to the entry that is picked. The sources to search fold into one line until they are changed, so the results start near the top. The results that have the same name as the title are marked and come first, and the sources that have one come before the rest.
@Composable
fun MigrateScreen(
    state: MigrateState,
    onBack: () -> Unit,
    onQuery: (String) -> Unit,
    onToggleSource: (String) -> Unit,
    onChooseAll: (Boolean) -> Unit,
    onPick: (InstalledSource, SourceEntry) -> Unit,
) {
    var choosing by rememberSaveable { mutableStateOf(false) }
    ReadableColumn {
        Column(Modifier.fillMaxSize()) {
            val title = state.title
            PageTopBar(
                stringResource(Res.string.migrate_title),
                subtitle = if (title ==
                    null
                ) {
                    null
                } else {
                    stringResource(Res.string.migrate_subtitle, title.name, state.from)
                },
                onBack = onBack,
            )
            // How close each result is to the name of the title, with the results of each source in that order and the sources by their best.
            val name = title?.name.orEmpty()
            val ranked = state.results
                .map { result ->
                    result to
                        result.entries
                            .map {
                                it to MatchScoring.titleSimilarity(
                                    name,
                                    it.title,
                                )
                            }.sortedByDescending { it.second }
                }.sortedByDescending { (_, entries) -> entries.firstOrNull()?.second ?: -1.0 }
            PageList {
                if (state.loaded && title == null) item { Note(stringResource(Res.string.migrate_gone)) }
                if (state.loaded && title != null &&
                    state.candidates.isEmpty()
                ) {
                    item { Note(stringResource(Res.string.migrate_no_sources)) }
                }
                if (state.candidates.isNotEmpty()) {
                    item {
                        AppSearchBar(
                            state.query,
                            onQuery,
                            stringResource(Res.string.migrate_search_hint),
                            historyPlace = "migrate",
                        )
                    }
                    item {
                        if (choosing) {
                            Column {
                                ChipsSetting(
                                    title = stringResource(Res.string.migrate_sources),
                                    options = state.candidates.map { it.id to it.name },
                                    selected = state.chosen,
                                    onToggle = onToggleSource,
                                )
                                Row {
                                    TextButton({ onChooseAll(true) }) { Text(stringResource(Res.string.all)) }
                                    TextButton({ onChooseAll(false) }) { Text(stringResource(Res.string.migrate_none)) }
                                    TextButton(
                                        { choosing = false },
                                    ) { Text(stringResource(Res.string.migrate_sources_done)) }
                                }
                            }
                        } else {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    stringResource(
                                        Res.string.migrate_sources_count,
                                        state.chosen.size,
                                        state.candidates.size,
                                    ),
                                    Modifier.weight(1f),
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                                TextButton(
                                    { choosing = true },
                                ) { Text(stringResource(Res.string.migrate_sources_change)) }
                            }
                        }
                    }
                }
                for ((result, entries) in ranked) {
                    if (!result.loading && result.error == null && result.entries.isEmpty()) continue
                    item { AppSectionLabel(result.source.shownName()) }
                    if (result.loading) {
                        item {
                            InkCircularProgressIndicator(
                                Modifier.padding(8.dp).size(20.dp),
                                strokeWidth = 2.dp,
                            )
                        }
                    }
                    result.error?.let { message -> item { Note(message, error = true) } }
                    items(entries.size) { index ->
                        val (entry, score) = entries[index]
                        AppListRow(
                            title = entry.title,
                            subtitle = entry.author?.takeIf { it.isNotBlank() } ?: entry.status,
                            leading = {
                                CoverArt(
                                    entry.asTitle(result.source.kind, result.source.id),
                                    Modifier.width(44.dp),
                                    letterSize = 16,
                                )
                            },
                            trailing = if (score >= SameName) ({ SameNameMark() }) else null,
                            onClick = { onPick(result.source, entry) },
                        )
                    }
                }
                if (state.results.isNotEmpty() && !state.searching && state.results.all { it.entries.isEmpty() }) {
                    item { Note(stringResource(Res.string.migrate_no_results)) }
                }
            }
        }
    }
}

// A small tinted mark on a result that has the same name as the title.
@Composable
private fun SameNameMark() {
    val colors = MaterialTheme.colorScheme
    Text(
        stringResource(Res.string.migrate_same_name),
        Modifier
            .clip(
                RoundedCornerShape(10.dp),
            ).background(colors.primary.copy(alpha = 0.14f))
            .padding(horizontal = 8.dp, vertical = 2.dp),
        style = MaterialTheme.typography.labelMedium,
        fontWeight = FontWeight.SemiBold,
        color = colors.primary,
    )
}

@Composable
private fun Note(text: String, error: Boolean = false) {
    val color = if (error) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.outline
    Text(
        text,
        Modifier.fillMaxWidth().padding(vertical = 8.dp),
        style = MaterialTheme.typography.bodyMedium,
        color = color,
    )
}
