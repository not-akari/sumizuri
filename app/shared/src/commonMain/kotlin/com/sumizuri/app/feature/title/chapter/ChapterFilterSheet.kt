package com.sumizuri.app.feature.title.chapter

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Label
import androidx.compose.material.icons.outlined.FilterListOff
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material3.Icon
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.Facet
import com.sumizuri.app.data.model.TriFilter
import com.sumizuri.app.feature.title.FacetGroup
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_filter_all
import com.sumizuri.app.shared.resources.chapter_filter_bookmarked
import com.sumizuri.app.shared.resources.chapter_filter_clear
import com.sumizuri.app.shared.resources.chapter_filter_downloaded
import com.sumizuri.app.shared.resources.chapter_filter_facet_hint
import com.sumizuri.app.shared.resources.chapter_filter_groups
import com.sumizuri.app.shared.resources.chapter_filter_languages
import com.sumizuri.app.shared.resources.chapter_filter_none_match
import com.sumizuri.app.shared.resources.chapter_filter_only
import com.sumizuri.app.shared.resources.chapter_filter_only_this
import com.sumizuri.app.shared.resources.chapter_filter_title
import com.sumizuri.app.shared.resources.chapter_filter_unread
import com.sumizuri.app.shared.resources.chapter_filter_without
import com.sumizuri.app.shared.resources.chapter_list_duplicates
import com.sumizuri.app.shared.resources.chapter_list_duplicates_hint
import com.sumizuri.app.shared.resources.chapter_list_grid
import com.sumizuri.app.shared.resources.chapter_list_grid_hint
import com.sumizuri.app.shared.resources.chapter_list_oldest
import com.sumizuri.app.shared.resources.chapter_list_oldest_hint
import com.sumizuri.app.shared.resources.chapter_list_pictures
import com.sumizuri.app.shared.resources.chapter_list_pictures_hint
import com.sumizuri.app.shared.resources.chapter_options
import com.sumizuri.app.shared.resources.chapter_sort_hint
import com.sumizuri.app.shared.resources.chapter_sort_title
import com.sumizuri.app.shared.resources.chapter_tab_display
import com.sumizuri.app.shared.resources.chapter_tab_filter
import com.sumizuri.app.shared.resources.chapter_tab_sort
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.input.AppSwitch
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.PartTabs
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The parts of the sheet of chapter options.
private enum class OptionsTab(val label: StringResource) {
    Filter(Res.string.chapter_tab_filter),
    Sort(Res.string.chapter_tab_sort),
    Display(Res.string.chapter_tab_display),
}

// Everything about how the chapters of a title are listed, in three parts: which chapters show, what they are put in order by, and how they are laid out. A preview has no marks and keeps nothing for itself, so it has no filters.
@Composable
internal fun ChapterOptionsSheet(state: TitleState, calls: TitleCallbacks, onDismiss: () -> Unit) {
    val tabs = if (state.preview) OptionsTab.entries - OptionsTab.Filter else OptionsTab.entries
    var tab by rememberSaveable { mutableStateOf(tabs.first()) }
    AppSheet(onDismiss, spacing = 12.dp, title = stringResource(Res.string.chapter_options)) {
        PartTabs(tabs, tab, { stringResource(it.label) }) { tab = it }
        when (tab) {
            OptionsTab.Filter -> FilterPart(state, calls)
            OptionsTab.Sort -> SortPart(state, calls)
            OptionsTab.Display -> DisplayPart(state, calls)
        }
    }
}

// The marks, which hold for every title, then each way the chapters of this title differ, such as their groups and languages.
@Composable
private fun FilterPart(state: TitleState, calls: TitleCallbacks) {
    val filter = state.filter
    SettingsSection(Res.string.chapter_filter_title) {
        padded {
            ChoiceSetting(Res.string.chapter_filter_unread, TriFilter.entries, filter.unread, {
                triLabel(it)
            }) { calls.onFilter(filter.copy(unread = it)) }
        }
        if (state.canDownload) {
            padded {
                ChoiceSetting(Res.string.chapter_filter_downloaded, TriFilter.entries, filter.downloaded, {
                    triLabel(it)
                }) { calls.onFilter(filter.copy(downloaded = it)) }
            }
        }
        padded {
            ChoiceSetting(Res.string.chapter_filter_bookmarked, TriFilter.entries, filter.bookmarked, {
                triLabel(it)
            }) { calls.onFilter(filter.copy(bookmarked = it)) }
        }
    }
    state.facets.forEachIndexed { index, group ->
        FacetSection(
            group,
            state.hidden,
            calls.onHideFacets,
            explain =
            index == 0,
        )
    }
    if (state.filtering) {
        InkOutlinedButton(
            {
                calls.onFilter(ChapterFilter())
                calls.onHideFacets(emptySet())
            },
            Modifier.fillMaxWidth(),
        ) {
            Icon(Icons.Outlined.FilterListOff, null, Modifier.size(18.dp))
            Text(stringResource(Res.string.chapter_filter_clear), Modifier.padding(start = 8.dp))
        }
    }
}

// One way the chapters differ, in a card with a switch for each of its values and a quick way to keep only one. What the switches do is said once, under the first of these cards.
@Composable
private fun FacetSection(group: FacetGroup, hidden: Set<Facet>, onHide: (Set<Facet>) -> Unit, explain: Boolean) {
    val heading = when (group.kind) {
        Facet.Group -> stringResource(Res.string.chapter_filter_groups)
        Facet.Language -> stringResource(Res.string.chapter_filter_languages)
        else -> group.kind.removePrefix(Facet.TagMark)
    }
    val icon = when (group.kind) {
        Facet.Group -> Icons.Outlined.Groups
        Facet.Language -> Icons.Outlined.Translate
        else -> Icons.AutoMirrored.Outlined.Label
    }
    val all = group.values.map { Facet(group.kind, it) }
    SettingsSection(heading, if (explain) stringResource(Res.string.chapter_filter_facet_hint) else null) {
        for (facet in all) {
            row {
                val shown = facet !in hidden
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clickable {
                            onHide(if (shown) hidden + facet else hidden - facet)
                        }.padding(start = 14.dp, end = 14.dp, top = 2.dp, bottom = 2.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    SettingIcon(icon)
                    Text(
                        facetText(facet),
                        Modifier.weight(1f),
                        style = MaterialTheme.typography.bodyLarge,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        color = if (shown) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outline,
                    )
                    // Keeps only this one of its kind, leaving what is hidden of the other kinds as it is.
                    TextButton(
                        { onHide(hidden - facet + (all - facet)) },
                    ) { Text(stringResource(Res.string.chapter_filter_only_this)) }
                    AppSwitch(shown, { on -> onHide(if (on) hidden - facet else hidden + facet) })
                }
            }
        }
    }
}

// A value as the list shows it. A language is named in the language of the app, with its code beside it.
@Composable
internal fun facetText(facet: Facet): String = if (facet.kind ==
    Facet.Language
) {
    "${languageName(facet.value)} (${facet.value.uppercase()})"
} else {
    facet.value
}

@Composable
private fun SortPart(state: TitleState, calls: TitleCallbacks) {
    SettingsSection {
        padded {
            ChoiceSetting(Res.string.chapter_sort_title, ChapterSort.entries, state.sort, {
                stringResource(sortLabel(it))
            }, hint = Res.string.chapter_sort_hint, onSelect = calls.onSort)
        }
        padded {
            SwitchSetting(Res.string.chapter_list_oldest, state.oldestFirst, {
                calls.onToggleSort()
            }, Res.string.chapter_list_oldest_hint)
        }
    }
}

@Composable
private fun DisplayPart(state: TitleState, calls: TitleCallbacks) {
    SettingsSection {
        padded {
            SwitchSetting(
                Res.string.chapter_list_grid,
                state.grid,
                { calls.onToggleGrid() },
                Res.string.chapter_list_grid_hint,
            )
        }
        // Pictures need the chapters of a saved title, so a preview leaves the choice out.
        if (state.grid && !state.preview) {
            padded {
                SwitchSetting(Res.string.chapter_list_pictures, state.gridPictures, {
                    calls.onToggleGridPictures()
                }, Res.string.chapter_list_pictures_hint)
            }
        }
        padded {
            SwitchSetting(Res.string.chapter_list_duplicates, state.hideDuplicates, {
                calls.onToggleDuplicates()
            }, Res.string.chapter_list_duplicates_hint)
        }
    }
}

// What a filter of one mark does, in a few words.
@Composable
internal fun triLabel(value: TriFilter): String = stringResource(
    when (value) {
        TriFilter.Any -> Res.string.chapter_filter_all
        TriFilter.Only -> Res.string.chapter_filter_only
        TriFilter.Without -> Res.string.chapter_filter_without
    },
)

// Said in place of the list when the filters hide every chapter, with the way to show them all again.
@Composable
internal fun FilteredEmpty(onClear: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(Icons.Outlined.FilterListOff, null, Modifier.size(32.dp), tint = MaterialTheme.colorScheme.outline)
        Text(
            stringResource(Res.string.chapter_filter_none_match),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.outline,
            textAlign = TextAlign.Center,
        )
        TextButton(onClear) { Text(stringResource(Res.string.chapter_filter_clear)) }
    }
}
