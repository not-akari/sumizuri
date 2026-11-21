package com.sumizuri.app.feature.settings.look

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.DashboardCustomize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.OpeningStyle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.navigation.bar.NavLabels
import com.sumizuri.app.navigation.bar.NavStyle
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.layout_group_lists
import com.sumizuri.app.shared.resources.layout_group_motion
import com.sumizuri.app.shared.resources.layout_group_navigation
import com.sumizuri.app.shared.resources.opening_style
import com.sumizuri.app.shared.resources.page_motion
import com.sumizuri.app.shared.resources.page_stagger
import com.sumizuri.app.shared.resources.page_stagger_hint
import com.sumizuri.app.shared.resources.settings_compact_lists
import com.sumizuri.app.shared.resources.settings_compact_lists_hint
import com.sumizuri.app.shared.resources.settings_home_parts
import com.sumizuri.app.shared.resources.settings_home_parts_hint
import com.sumizuri.app.shared.resources.settings_language
import com.sumizuri.app.shared.resources.settings_language_system
import com.sumizuri.app.shared.resources.settings_layout
import com.sumizuri.app.shared.resources.settings_layout_hint
import com.sumizuri.app.shared.resources.settings_nav_labels
import com.sumizuri.app.shared.resources.settings_nav_style
import com.sumizuri.app.shared.resources.settings_nav_swipe
import com.sumizuri.app.shared.resources.settings_nav_swipe_hint
import com.sumizuri.app.shared.resources.settings_reduce_motion
import com.sumizuri.app.shared.resources.settings_reduce_motion_hint
import com.sumizuri.app.shared.resources.settings_reopen_place
import com.sumizuri.app.shared.resources.settings_reopen_place_hint
import com.sumizuri.app.shared.resources.settings_title_split
import com.sumizuri.app.shared.resources.settings_title_split_hint
import com.sumizuri.app.shared.resources.web_in_app
import com.sumizuri.app.shared.resources.web_in_app_hint
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.language.AppLanguage
import com.sumizuri.app.ui.motion.PageMotion
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The page for how the app looks and moves, in four groups: the language, how dense lists are, where the tabs are and a way to the sections at the top of the library, and whether the app animates.
@Composable
fun LayoutRoute(onBack: () -> Unit, onOpenLibraryDisplay: () -> Unit) {
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val compact by settings.compactLists.collectAsStateWithLifecycle()
    val motion by settings.reduceMotion.collectAsStateWithLifecycle()
    val nav by settings.navStyle.collectAsStateWithLifecycle()
    val labels by settings.navLabels.collectAsStateWithLifecycle()
    val swipe by settings.navSwipe.collectAsStateWithLifecycle()
    val pageMotion by settings.pageMotion.collectAsStateWithLifecycle()
    val opening by remember(container) { container.settings.text(SettingKey.Opening) }.collectAsStateWithLifecycle(null)
    val stagger by settings.stagger.collectAsStateWithLifecycle()
    val language by settings.language.collectAsStateWithLifecycle()
    val webInApp by remember(container) {
        container.settings.flag(SettingKey.WebInApp, true)
    }.collectAsStateWithLifecycle(true)
    val reopen by remember(container) {
        container.settings.flag(SettingKey.ReopenPlace, false)
    }.collectAsStateWithLifecycle(false)
    val split by remember(container) {
        container.settings.flag(SettingKey.TitleSplit, true)
    }.collectAsStateWithLifecycle(true)
    val scope = rememberCoroutineScope()
    SettingsPageFrame(Res.string.settings_layout, onBack, subtitle = Res.string.settings_layout_hint, onReset = {
        container.settings.resetInterface()
    }) {
        SettingsSection(Res.string.settings_language) {
            padded {
                ChoiceSetting(Res.string.settings_language, AppLanguage.entries, language, {
                    it.nativeName
                        ?: stringResource(Res.string.settings_language_system)
                }) { settings.onLanguage(it) }
            }
        }
        SettingsSection(Res.string.layout_group_lists) {
            padded {
                SwitchSetting(
                    Res.string.settings_compact_lists,
                    compact,
                    settings::onCompactLists,
                    Res.string.settings_compact_lists_hint,
                )
            }
            padded {
                SwitchSetting(Res.string.settings_title_split, split, { on ->
                    scope.launch { container.settings.setFlag(SettingKey.TitleSplit, on) }
                }, Res.string.settings_title_split_hint)
            }
        }
        SettingsSection(Res.string.layout_group_navigation) {
            padded {
                ChoiceSetting(Res.string.settings_nav_style, NavStyle.entries, nav, {
                    stringResource(it.label)
                }) { settings.onNavStyle(it) }
            }
            padded {
                ChoiceSetting(Res.string.settings_nav_labels, NavLabels.entries, labels, {
                    stringResource(it.label)
                }) { settings.onNavLabels(it) }
            }
            padded {
                SwitchSetting(
                    Res.string.settings_nav_swipe,
                    swipe,
                    settings::onNavSwipe,
                    Res.string.settings_nav_swipe_hint,
                )
            }
            padded {
                SwitchSetting(Res.string.settings_reopen_place, reopen, { on ->
                    scope.launch {
                        container.settings.setFlag(SettingKey.ReopenPlace, on)
                    }
                }, Res.string.settings_reopen_place_hint)
            }
            padded {
                SwitchSetting(Res.string.web_in_app, webInApp, { on ->
                    scope.launch {
                        container.settings.setFlag(SettingKey.WebInApp, on)
                    }
                }, Res.string.web_in_app_hint)
            }
            row {
                SettingRow(
                    stringResource(Res.string.settings_home_parts),
                    leading = { SettingIcon(Icons.Outlined.DashboardCustomize) },
                    subtitle = stringResource(Res.string.settings_home_parts_hint),
                    trailing = { ListChevron() },
                    onClick = onOpenLibraryDisplay,
                )
            }
        }
        SettingsSection(Res.string.layout_group_motion) {
            padded {
                ChoiceSetting(Res.string.opening_style, OpeningStyle.entries, OpeningStyle.of(opening), {
                    stringResource(it.label)
                }) { scope.launch { container.settings.setText(SettingKey.Opening, it.key) } }
            }
            padded {
                ChoiceSetting(Res.string.page_motion, PageMotion.entries, pageMotion, {
                    stringResource(it.label)
                }) { settings.onPageMotion(it) }
            }
            if (!motion && pageMotion != PageMotion.None) padded { MotionPreview(pageMotion) }
            padded {
                SwitchSetting(
                    Res.string.page_stagger,
                    stagger,
                    settings::onStagger,
                    Res.string.page_stagger_hint,
                )
            }
            padded {
                SwitchSetting(
                    Res.string.settings_reduce_motion,
                    motion,
                    settings::onReduceMotion,
                    Res.string.settings_reduce_motion_hint,
                )
            }
        }
    }
}
