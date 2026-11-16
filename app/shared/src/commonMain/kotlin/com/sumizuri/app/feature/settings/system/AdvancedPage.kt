package com.sumizuri.app.feature.settings.system

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.FileUpload
import androidx.compose.material.icons.outlined.RestartAlt
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.settings.exportData
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.share.ShareDialog
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.advanced_group_developer
import com.sumizuri.app.shared.resources.advanced_reset_action
import com.sumizuri.app.shared.resources.advanced_reset_library
import com.sumizuri.app.shared.resources.advanced_reset_library_hint
import com.sumizuri.app.shared.resources.advanced_reset_look
import com.sumizuri.app.shared.resources.advanced_reset_look_hint
import com.sumizuri.app.shared.resources.advanced_reset_message
import com.sumizuri.app.shared.resources.advanced_reset_reader
import com.sumizuri.app.shared.resources.advanced_reset_reader_hint
import com.sumizuri.app.shared.resources.advanced_reset_title
import com.sumizuri.app.shared.resources.perf_details
import com.sumizuri.app.shared.resources.perf_details_hint
import com.sumizuri.app.shared.resources.perf_level_advanced
import com.sumizuri.app.shared.resources.perf_level_basic
import com.sumizuri.app.shared.resources.perf_overlay
import com.sumizuri.app.shared.resources.perf_overlay_hint
import com.sumizuri.app.shared.resources.perf_overlay_level
import com.sumizuri.app.shared.resources.settings_advanced
import com.sumizuri.app.shared.resources.settings_advanced_hint
import com.sumizuri.app.shared.resources.settings_export
import com.sumizuri.app.shared.resources.settings_export_hint
import com.sumizuri.app.shared.resources.settings_file_hint
import com.sumizuri.app.shared.resources.settings_file_title
import com.sumizuri.app.shared.resources.settings_import
import com.sumizuri.app.shared.resources.settings_import_hint
import com.sumizuri.app.shared.resources.share_kind_settings
import com.sumizuri.app.shared.resources.share_title
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonObject
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// What a reset takes back.
private enum class Reset(val title: StringResource, val hint: StringResource) {
    Look(Res.string.advanced_reset_look, Res.string.advanced_reset_look_hint),
    Library(Res.string.advanced_reset_library, Res.string.advanced_reset_library_hint),
    Reader(Res.string.advanced_reset_reader, Res.string.advanced_reset_reader_hint),
}

private suspend fun SettingsRepository.apply(reset: Reset) = when (reset) {
    Reset.Look -> {
        resetLook()
        resetInterface()
    }

    // The pages saved for one title stay, since they are not a setting of the app.
    Reset.Reader -> reset("reader.", except = "reader.title.")

    Reset.Library -> reset("library.")
}

// The page of what is rarely needed: keeping the settings in a file and bringing them back, taking the choices of a part of the app back to how they were, and the tools that measure the app. Titles, shelves and reading progress are never touched.
@Composable
fun AdvancedRoute(onBack: () -> Unit, onPerformance: () -> Unit, onImport: () -> Unit) {
    val settings = LocalAppContainer.current.settings
    val scope = rememberCoroutineScope()
    var asked by remember { mutableStateOf<Reset?>(null) }
    // The settings being shared, once they are read.
    var sharing by remember { mutableStateOf<JsonObject?>(null) }
    val overlay by remember(
        settings,
    ) { settings.flag(SettingKey.PerfOverlay, false) }.collectAsStateWithLifecycle(false)
    val level by remember(settings) { settings.text(SettingKey.PerfOverlayLevel) }.collectAsStateWithLifecycle(null)
    sharing?.let { data ->
        ShareDialog(
            stringResource(Res.string.share_title, stringResource(Res.string.share_kind_settings)),
            "Sumizuri settings",
            ShareKind.Settings,
            data,
        ) {
            sharing =
                null
        }
    }
    SettingsPageFrame(Res.string.settings_advanced, onBack, subtitle = Res.string.settings_advanced_hint) {
        // Every choice in one small file, to keep or to carry to another device. The lock, the place in the app and what titles chose for themselves stay out.
        SettingsSection(
            stringResource(Res.string.settings_file_title),
            stringResource(Res.string.settings_file_hint),
        ) {
            row {
                SettingRow(
                    stringResource(Res.string.settings_export),
                    subtitle = stringResource(Res.string.settings_export_hint),
                    leading = { SettingIcon(Icons.Outlined.FileUpload) },
                    onClick = { scope.launch { sharing = settings.exportData() } },
                )
            }
            row {
                SettingRow(
                    stringResource(Res.string.settings_import),
                    subtitle = stringResource(Res.string.settings_import_hint),
                    leading = { SettingIcon(Icons.Outlined.FileDownload) },
                    onClick = onImport,
                )
            }
        }
        SettingsSection(Res.string.advanced_reset_title) {
            for (reset in Reset.entries) {
                row {
                    SettingRow(
                        stringResource(reset.title),
                        subtitle = stringResource(reset.hint),
                        leading = { SettingIcon(Icons.Outlined.RestartAlt) },
                        onClick = { asked = reset },
                    )
                }
            }
        }
        // How the app is doing: a live box over the window, and a page of measurements.
        SettingsSection(Res.string.advanced_group_developer) {
            padded {
                SwitchSetting(Res.string.perf_overlay, overlay, { on ->
                    scope.launch {
                        settings.setFlag(SettingKey.PerfOverlay, on)
                    }
                }, Res.string.perf_overlay_hint)
            }
            // How much the box shows: the frames, memory and processor, or also the database and what runs right now.
            if (overlay) {
                padded {
                    ChoiceSetting(
                        Res.string.perf_overlay_level,
                        listOf("basic", "advanced"),
                        level ?: "basic",
                        {
                            stringResource(
                                if (it ==
                                    "advanced"
                                ) {
                                    Res.string.perf_level_advanced
                                } else {
                                    Res.string.perf_level_basic
                                },
                            )
                        },
                    ) { picked -> scope.launch { settings.setText(SettingKey.PerfOverlayLevel, picked) } }
                }
            }
            row {
                SettingRow(
                    stringResource(Res.string.perf_details),
                    subtitle = stringResource(Res.string.perf_details_hint),
                    leading = { SettingIcon(Icons.Outlined.Speed) },
                    trailing = { ListChevron() },
                    onClick = onPerformance,
                )
            }
        }
    }
    asked?.let { reset ->
        ConfirmDialog(
            stringResource(reset.title),
            stringResource(Res.string.advanced_reset_message),
            stringResource(Res.string.advanced_reset_action),
            onConfirm = {
                scope.launch { settings.apply(reset) }
                asked = null
            },
            onDismiss = { asked = null },
        )
    }
}
