package com.sumizuri.app.feature.library.display

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.library.CoverBadgeKind
import com.sumizuri.app.data.model.library.CoverCorner
import com.sumizuri.app.data.model.library.LibraryDisplayStyle
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.feature.library.top.LibraryTopEditor
import com.sumizuri.app.feature.settings.JumpSection
import com.sumizuri.app.feature.settings.LocalPageJumps
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_collapsible_search
import com.sumizuri.app.shared.resources.display_collapsible_search_hint
import com.sumizuri.app.shared.resources.display_cover_size
import com.sumizuri.app.shared.resources.display_favorites
import com.sumizuri.app.shared.resources.display_gap
import com.sumizuri.app.shared.resources.display_group_corners
import com.sumizuri.app.shared.resources.display_group_covers
import com.sumizuri.app.shared.resources.display_group_layout
import com.sumizuri.app.shared.resources.display_group_search
import com.sumizuri.app.shared.resources.display_group_tabs
import com.sumizuri.app.shared.resources.display_group_top
import com.sumizuri.app.shared.resources.display_hide_all_tab
import com.sumizuri.app.shared.resources.display_hide_no_shelf_tab
import com.sumizuri.app.shared.resources.display_home_cover
import com.sumizuri.app.shared.resources.display_list_cover
import com.sumizuri.app.shared.resources.display_name_size
import com.sumizuri.app.shared.resources.display_panorama
import com.sumizuri.app.shared.resources.display_progress
import com.sumizuri.app.shared.resources.display_style
import com.sumizuri.app.shared.resources.display_wide
import com.sumizuri.app.ui.kit.chips.FilterTabs
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.percentText
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// The groups of choices: on the page of the settings all of them one under the other with pills that jump to each, and in the sheet over the library one at a time under plain tabs.
private enum class Group(val label: StringResource) {
    Layout(Res.string.display_group_layout),
    Covers(Res.string.display_group_covers),
    Top(Res.string.display_group_top),
    Tabs(Res.string.display_group_tabs),
}

// Everything that sets how the library looks, as the sheet over the library and the page in the settings both show it. The choices are in four groups: the layout and its sizes, what is on the covers, the parts at the top of the page, and the tabs, shelves and search. Each choice is saved as it is made.
@Composable
internal fun LibraryDisplayBody(prefs: LibraryPrefs, onChange: ((LibraryPrefs) -> LibraryPrefs) -> Unit) {
    val one: @Composable (Group) -> Unit = { group ->
        when (group) {
            Group.Layout -> LayoutGroup(prefs, onChange)
            Group.Covers -> CoversGroup(prefs, onChange)
            Group.Top -> TopGroup(prefs, onChange)
            Group.Tabs -> TabsGroup(prefs, onChange)
        }
    }
    if (LocalPageJumps.current != null) {
        for (group in Group.entries) JumpSection(stringResource(group.label)) { one(group) }
        return
    }
    var group by remember { mutableStateOf(Group.Layout) }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        FilterTabs(Group.entries.map { it to stringResource(it.label) }, group, { group = it })
        Column(Modifier.heightIn(min = 340.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) { one(group) }
    }
}

// The names of the groups, for the pills of the page.
@Composable
internal fun displayJumps(): List<String> = Group.entries.map { stringResource(it.label) }

@Composable
private fun LayoutGroup(prefs: LibraryPrefs, onChange: ((LibraryPrefs) -> LibraryPrefs) -> Unit) {
    SettingsSection {
        padded {
            ChoiceSetting(Res.string.display_style, LibraryDisplayStyle.entries, prefs.style, {
                stringResource(it.label)
            }) { style -> onChange { it.copy(style = style) } }
        }
        if (prefs.style.isGrid) {
            // The slider is the widest a cover may be, so moving it up makes the covers bigger and the columns fewer.
            padded {
                SliderSetting(Res.string.display_cover_size, prefs.cellWidth.toFloat(), LibraryPrefs.CellRange, {
                    "${it.roundToInt()} dp"
                }) { size -> onChange { it.copy(cellWidth = size.roundToInt()) } }
            }
            padded {
                SliderSetting(Res.string.display_gap, prefs.gridGap.toFloat(), LibraryPrefs.GapRange, {
                    "${it.roundToInt()} dp"
                }) { gap -> onChange { it.copy(gridGap = gap.roundToInt()) } }
            }
        }
        if (prefs.style == LibraryDisplayStyle.PanoramaGrid) {
            padded {
                SliderSetting(Res.string.display_panorama, prefs.panoramaAspect, LibraryPrefs.PanoramaRange, {
                    stringResource(Res.string.display_wide, oneDecimal(it))
                }) { shape -> onChange { it.copy(panoramaAspect = shape) } }
            }
        }
        if (!prefs.style.isGrid) {
            padded {
                SliderSetting(Res.string.display_list_cover, prefs.listCover.toFloat(), LibraryPrefs.ListCoverRange, {
                    "${it.roundToInt()} dp"
                }) { size -> onChange { it.copy(listCover = size.roundToInt()) } }
            }
        }
        padded {
            SliderSetting(Res.string.display_name_size, prefs.nameScale, LibraryPrefs.NameScaleRange, {
                percentText(it)
            }) { scale -> onChange { it.copy(nameScale = scale) } }
        }
    }
}

@Composable
private fun CoversGroup(prefs: LibraryPrefs, onChange: ((LibraryPrefs) -> LibraryPrefs) -> Unit) {
    SettingsSection {
        padded {
            SwitchSetting(
                Res.string.display_progress,
                prefs.showProgress,
                { on -> onChange { it.copy(showProgress = on) } },
            )
        }
        padded {
            SwitchSetting(Res.string.display_favorites, prefs.favoritesEnabled, { on ->
                onChange {
                    it.copy(favoritesEnabled = on)
                }
            })
        }
    }
    SettingsSection(Res.string.display_group_corners) {
        for (kind in CoverBadgeKind.entries) {
            padded {
                ChoiceSetting(kind.label, CoverCorner.entries, prefs.badges.cornerOf(kind), {
                    stringResource(it.label)
                }) { corner -> onChange { it.copy(badges = it.badges.with(kind, corner)) } }
            }
        }
    }
}

@Composable
private fun TopGroup(prefs: LibraryPrefs, onChange: ((LibraryPrefs) -> LibraryPrefs) -> Unit) {
    SettingsSection {
        padded {
            SliderSetting(Res.string.display_home_cover, prefs.homeCover.toFloat(), LibraryPrefs.HomeCoverRange, {
                "${it.roundToInt()} dp"
            }) { size -> onChange { it.copy(homeCover = size.roundToInt()) } }
        }
    }
    LibraryTopEditor(prefs, onChange)
}

@Composable
private fun TabsGroup(prefs: LibraryPrefs, onChange: ((LibraryPrefs) -> LibraryPrefs) -> Unit) {
    SettingsSection {
        padded {
            SwitchSetting(
                Res.string.display_hide_all_tab,
                prefs.hideAllTab,
                { on -> onChange { it.copy(hideAllTab = on) } },
            )
        }
        padded {
            SwitchSetting(Res.string.display_hide_no_shelf_tab, prefs.hideNoShelfTab, { on ->
                onChange {
                    it.copy(hideNoShelfTab = on)
                }
            })
        }
    }
    SettingsSection(Res.string.display_group_search) {
        padded {
            SwitchSetting(Res.string.display_collapsible_search, prefs.collapsibleSearch, { on ->
                onChange {
                    it.copy(collapsibleSearch = on)
                }
            }, Res.string.display_collapsible_search_hint)
        }
    }
}

// A number with one digit after the point.
private fun oneDecimal(value: Float): String = ((value * 10).roundToInt() / 10f).toString()
