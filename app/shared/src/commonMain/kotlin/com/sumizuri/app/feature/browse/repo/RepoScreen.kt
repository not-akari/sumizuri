package com.sumizuri.app.feature.browse.repo

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.SystemUpdateAlt
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
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
import com.sumizuri.app.shared.resources.sources_update_all
import com.sumizuri.app.shared.resources.sources_updates_notice
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.card.CardPlace
import com.sumizuri.app.ui.kit.card.cardRow
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChipSeparator
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.chips.ToggleChip
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.LoadStatus
import com.sumizuri.app.ui.kit.page.PageList
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The sources one repo lists, a card for each language as the settings show their groups, with a choice of kind, narrowed by typing, each row with the one thing to do with it.
@Composable
fun RepoScreen(state: RepoState, actions: RepoActions) {
    val kind = state.kind
    val groups = state.groups
    val updates = state.updates
    ReadableColumn {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(state.repo.name, subtitle = state.repo.url, onBack = actions.onBack) {
                IconButton(
                    actions.onCopyAddress,
                ) { Icon(Icons.Outlined.ContentCopy, stringResource(Res.string.repo_copy_address)) }
            }
            // The rows of a language touch, as they make one card, so the room is kept under the other parts.
            PageList(gap = 0.dp) {
                item(
                    key = "status",
                ) { Box(Modifier.padding(bottom = 8.dp)) { LoadStatus(state.loading, state.error, actions.onLoad) } }
                if (state.available.isNotEmpty()) {
                    item(key = "controls") {
                        Column(Modifier.padding(bottom = 8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            AppSearchBar(state.query, actions.onQuery, stringResource(Res.string.repo_search_hint))
                            ChipRow {
                                if (state.kinds.size > 1 && kind != null) {
                                    for (each in state.kinds) {
                                        ChoiceChip(
                                            stringResource(each.label),
                                            each == kind,
                                        ) { actions.onKind(each) }
                                    }
                                    if (state.hasNsfw) ChipSeparator()
                                }
                                if (state.hasNsfw) {
                                    ToggleChip(
                                        stringResource(
                                            Res.string.repo_show_nsfw,
                                        ),
                                        state.showNsfw,
                                        {
                                            actions.onShowNsfw(!state.showNsfw)
                                        },
                                    )
                                }
                            }
                            // A repo with sources in several languages can be narrowed to one of them.
                            val languages = state.languages
                            if (languages.size > 1) {
                                ChipRow {
                                    ChoiceChip(
                                        stringResource(Res.string.all),
                                        state.language == null,
                                    ) { actions.onLanguage(null) }
                                    for (each in languages) {
                                        ChoiceChip(
                                            languageName(each),
                                            each == state.language,
                                        ) { actions.onLanguage(each) }
                                    }
                                }
                            }
                            if (updates.isNotEmpty()) {
                                AppListRow(
                                    title = pluralStringResource(
                                        Res.plurals.sources_updates_notice,
                                        updates.size,
                                        updates.size,
                                    ),
                                    leading = {
                                        Icon(
                                            Icons.Outlined.SystemUpdateAlt,
                                            null,
                                            tint = MaterialTheme.colorScheme.primary,
                                        )
                                    },
                                    trailing = {
                                        TextButton(actions.onUpdateAll, enabled = state.busy.isEmpty()) {
                                            Text(stringResource(Res.string.sources_update_all))
                                        }
                                    },
                                )
                            }
                        }
                    }
                }
                if (!state.loading && state.error == null && state.available.isEmpty()) {
                    item(key = "empty") { Message(Res.string.repo_empty) }
                } else if (state.available.isNotEmpty() && groups.isEmpty()) {
                    item(key = "filtered") { Message(Res.string.repo_filtered_empty) }
                }
                for (group in groups) {
                    item(key = "label:${group.language}") {
                        AppSectionLabel(
                            stringResource(Res.string.section_count, languageName(group.language), group.sources.size),
                            Modifier.padding(top = 14.dp, bottom = 6.dp),
                        )
                    }
                    itemsIndexed(
                        group.sources,
                        key = { _, source -> "${group.language}:${source.id}" },
                    ) { index, source ->
                        val have = state.installed[source.id]
                        RepoSourceRow(
                            source,
                            have,
                            busy = source.id in state.busy || have?.id in state.busy,
                            onInstall = { actions.onInstall(source) },
                            onRemove = { have?.let { actions.onRemove(it.id, source.name) } },
                            place = CardPlace(index, group.sources.size),
                            modifier = Modifier.animateItem(),
                        )
                    }
                }
                val obsolete = state.obsolete
                if (obsolete.isNotEmpty()) {
                    item(key = "label:obsolete") {
                        AppSectionLabel(
                            stringResource(
                                Res.string.section_count,
                                stringResource(Res.string.repo_obsolete),
                                obsolete.size,
                            ),
                            Modifier.padding(top = 14.dp, bottom = 6.dp),
                        )
                    }
                    itemsIndexed(obsolete, key = { _, have -> "obsolete:${have.id}" }) { index, have ->
                        SettingRow(
                            have.name,
                            modifier = Modifier.cardRow(CardPlace(index, obsolete.size)),
                            subtitle = stringResource(Res.string.repo_obsolete_hint),
                            leading = { SourceMark(have.iconUrl, size = 36.dp) },
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
