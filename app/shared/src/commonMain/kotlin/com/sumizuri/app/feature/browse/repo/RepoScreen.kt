package com.sumizuri.app.feature.browse.repo

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.browse.hub.UpdateNotice
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.all
import com.sumizuri.app.shared.resources.remove
import com.sumizuri.app.shared.resources.repo_copy_address
import com.sumizuri.app.shared.resources.repo_empty
import com.sumizuri.app.shared.resources.repo_filtered_empty
import com.sumizuri.app.shared.resources.repo_obsolete
import com.sumizuri.app.shared.resources.repo_obsolete_hint
import com.sumizuri.app.shared.resources.repo_search_hint
import com.sumizuri.app.shared.resources.repo_show_nsfw
import com.sumizuri.app.shared.resources.section_count
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.card.SoftGap
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChipSeparator
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.chips.ToggleChip
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.LoadStatus
import com.sumizuri.app.ui.kit.page.PageGrid
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.TileWidth
import com.sumizuri.app.ui.kit.page.fullSpan
import com.sumizuri.app.ui.kit.page.readableLine
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The sources one repo lists, under a heading for each language, with a choice of kind, narrowed by typing, each tile with the one thing to do with it. The tiles use the whole width, while what stands above them keeps a readable one.
@Composable
fun RepoScreen(state: RepoState, actions: RepoActions) {
    val kind = state.kind
    val groups = state.groups
    val updates = state.updates
    Column(Modifier.fillMaxSize()) {
        PageTopBar(state.repo.name, subtitle = state.repo.url, onBack = actions.onBack) {
            IconButton(
                actions.onCopyAddress,
            ) { Icon(Icons.Outlined.ContentCopy, stringResource(Res.string.repo_copy_address)) }
        }
        // A tile here also holds a button, so it needs a little more room than a tile of Browse.
        PageGrid(
            Modifier.weight(1f),
            gap = SoftGap + 2.dp,
            rowGap = SoftGap + 2.dp,
            columns = GridCells.Adaptive(TileWidth + 60.dp),
        ) {
            readableLine("status") { LoadStatus(state.loading, state.error, actions.onLoad) }
            if (state.available.isNotEmpty()) {
                readableLine(
                    "search",
                ) { AppSearchBar(state.query, actions.onQuery, stringResource(Res.string.repo_search_hint)) }
                // The chips use the whole width, so a long row of languages does not need a sideways scroll on a wide window.
                fullSpan("chips") {
                    Column(Modifier.animateItem(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        ChipRow {
                            if (state.kinds.size > 1 && kind != null) {
                                for (each in state.kinds) {
                                    ChoiceChip(stringResource(each.label), each == kind) { actions.onKind(each) }
                                }
                                if (state.hasNsfw) ChipSeparator()
                            }
                            if (state.hasNsfw) {
                                ToggleChip(stringResource(Res.string.repo_show_nsfw), state.showNsfw, {
                                    actions.onShowNsfw(!state.showNsfw)
                                })
                            }
                        }
                        // A repo with sources in several languages can be narrowed to one of them.
                        val languages = state.languages
                        if (languages.size > 1) {
                            // A wide window shows every language at once, a phone scrolls them sideways.
                            BoxWithConstraints { ChipRow(wrap = maxWidth >= 600.dp) {
                                ChoiceChip(
                                    stringResource(Res.string.all),
                                    state.language == null,
                                ) { actions.onLanguage(null) }
                                for (each in languages) {
                                    ChoiceChip(languageName(each), each == state.language) { actions.onLanguage(each) }
                                }
                            } }
                        }
                    }
                }
                if (updates.isNotEmpty()) {
                    readableLine("updates") { UpdateNotice(updates.size, state.busy.isEmpty(), actions.onUpdateAll) }
                }
            }
            if (!state.loading && state.error == null && state.available.isEmpty()) {
                readableLine("empty") { Message(Res.string.repo_empty) }
            } else if (state.available.isNotEmpty() && groups.isEmpty()) {
                readableLine("filtered") { Message(Res.string.repo_filtered_empty) }
            }
            for (group in groups) {
                fullSpan("label:${group.language}") {
                    AppSectionLabel(
                        stringResource(Res.string.section_count, languageName(group.language), group.sources.size),
                        Modifier.animateItem(),
                    )
                }
                items(group.sources, key = { source -> "${group.language}:${source.id}" }) { source ->
                    val have = state.installed[source.id]
                    RepoSourceRow(
                        source,
                        have,
                        busy = source.id in state.busy || have?.id in state.busy,
                        onInstall = { actions.onInstall(source) },
                        onRemove = { have?.let { actions.onRemove(it.id, source.name) } },
                        modifier = Modifier.animateItem().entrance(),
                    )
                }
            }
            val obsolete = state.obsolete
            if (obsolete.isNotEmpty()) {
                fullSpan("label:obsolete") {
                    AppSectionLabel(
                        stringResource(
                            Res.string.section_count,
                            stringResource(Res.string.repo_obsolete),
                            obsolete.size,
                        ),
                        Modifier.animateItem(),
                    )
                }
                items(obsolete, key = { have -> "obsolete:${have.id}" }) { have ->
                    SettingRow(
                        have.name,
                        modifier = Modifier.animateItem().entrance().softCard(),
                        subtitle = stringResource(Res.string.repo_obsolete_hint),
                        leading = { SourceMark(have.iconUrl, size = 40.dp) },
                        trailing = {
                            IconButton({
                                actions.onRemove(have.id, have.name)
                            }) { Icon(Icons.Outlined.DeleteOutline, stringResource(Res.string.remove)) }
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun Message(text: StringResource) {
    Text(
        stringResource(text),
        Modifier.fillMaxWidth().padding(vertical = 32.dp),
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.outline,
        textAlign = TextAlign.Center,
    )
}
