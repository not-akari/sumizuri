package com.sumizuri.app.feature.sync.account

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.RadioButtonUnchecked
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.account.SyncAccount
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.sync.Field
import com.sumizuri.app.feature.sync.Form
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.home.SyncHomeModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_after_reading
import com.sumizuri.app.shared.resources.sync_after_reading_hint
import com.sumizuri.app.shared.resources.sync_background
import com.sumizuri.app.shared.resources.sync_background_hint
import com.sumizuri.app.shared.resources.sync_charging
import com.sumizuri.app.shared.resources.sync_charging_hint
import com.sumizuri.app.shared.resources.sync_every
import com.sumizuri.app.shared.resources.sync_every_hint
import com.sumizuri.app.shared.resources.sync_every_hours
import com.sumizuri.app.shared.resources.sync_every_hours_minutes
import com.sumizuri.app.shared.resources.sync_every_manual
import com.sumizuri.app.shared.resources.sync_every_minutes
import com.sumizuri.app.shared.resources.sync_library_hint
import com.sumizuri.app.shared.resources.sync_library_linked
import com.sumizuri.app.shared.resources.sync_library_make
import com.sumizuri.app.shared.resources.sync_library_name
import com.sumizuri.app.shared.resources.sync_library_new
import com.sumizuri.app.shared.resources.sync_library_none
import com.sumizuri.app.shared.resources.sync_library_section
import com.sumizuri.app.shared.resources.sync_library_tap_to_link
import com.sumizuri.app.shared.resources.sync_link_title
import com.sumizuri.app.shared.resources.sync_on_open
import com.sumizuri.app.shared.resources.sync_on_open_hint
import com.sumizuri.app.shared.resources.sync_signed_out_note
import com.sumizuri.app.shared.resources.sync_triggers_section
import com.sumizuri.app.shared.resources.sync_what_hint
import com.sumizuri.app.shared.resources.sync_what_progress
import com.sumizuri.app.shared.resources.sync_what_progress_hint
import com.sumizuri.app.shared.resources.sync_what_section
import com.sumizuri.app.shared.resources.sync_what_settings
import com.sumizuri.app.shared.resources.sync_what_settings_hint
import com.sumizuri.app.shared.resources.sync_what_shelves
import com.sumizuri.app.shared.resources.sync_what_shelves_hint
import com.sumizuri.app.shared.resources.sync_what_sources
import com.sumizuri.app.shared.resources.sync_what_sources_hint
import com.sumizuri.app.shared.resources.sync_when_conditions
import com.sumizuri.app.shared.resources.sync_when_hint
import com.sumizuri.app.shared.resources.sync_when_title
import com.sumizuri.app.shared.resources.sync_wifi_only
import com.sumizuri.app.shared.resources.sync_wifi_only_hint
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.kit.text.NoteText
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// The longest the interval of syncing goes, six hours, in minutes. Nothing means only when asked.
internal const val MaxSyncMinutes = 360f

// The same signed in sync page state every sync page shares, so a choice on one page shows on the others at once.
@Composable
internal fun rememberSyncHome(account: SyncAccount): SyncHomeModel {
    val profiles = LocalProfiles.current
    val container = LocalAppContainer.current
    return viewModel(key = "sync-${account.userId}-${account.deviceId}") {
        SyncHomeModel(account, profiles.syncAccounts, container.settings, container.librarySync)
    }
}

// A sync page needs a signed in account. Signed out, it says so and leaves the rest out.
@Composable
internal fun SignedIn(content: @Composable (SyncAccount) -> Unit) {
    val account by LocalProfiles.current.syncAccounts.account
        .collectAsStateWithLifecycle()
    account?.let { content(it) }
        ?: SettingsSection { padded { NoteText(stringResource(Res.string.sync_signed_out_note)) } }
}

// The profile on the server this profile syncs with, and a new one to make.
@Composable
internal fun SyncLinkRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_link_title, onBack, subtitle = Res.string.sync_library_hint) {
        SignedIn { account ->
            val model = rememberSyncHome(account)
            val home by model.home.collectAsStateWithLifecycle()
            val prefs = LocalAppContainer.current.settings
            val linked by remember(prefs) { prefs.text(SettingKey.SyncLibraryId) }.collectAsStateWithLifecycle(null)
            var name by remember { mutableStateOf("") }
            SettingsSection(Res.string.sync_library_section) {
                val libraries = home.libraries.orEmpty()
                if (home.libraries != null &&
                    libraries.isEmpty()
                ) {
                    padded { NoteText(stringResource(Res.string.sync_library_none)) }
                }
                for (library in libraries) {
                    val on = linked == library.id.toString()
                    row {
                        SettingRow(
                            library.name,
                            subtitle = stringResource(
                                if (on) Res.string.sync_library_linked else Res.string.sync_library_tap_to_link,
                            ),
                            leading = {
                                SettingIcon(
                                    if (on) Icons.Outlined.CheckCircle else Icons.Outlined.RadioButtonUnchecked,
                                )
                            },
                            onClick = if (on) null else ({ model.link(library.id) }),
                        )
                    }
                }
            }
            SettingsSection(Res.string.sync_library_new) {
                padded {
                    Form(home.busy) {
                        val submit = {
                            if (name.isNotBlank()) {
                                model.makeLibrary(name)
                                name = ""
                            }
                        }
                        Field(name, { name = it }, Res.string.sync_library_name, onDone = submit)
                        InkOutlinedButton(submit, enabled = !home.busy && name.isNotBlank()) {
                            Text(stringResource(Res.string.sync_library_make))
                        }
                    }
                }
            }
            if (home.busy) Working()
            home.problem?.let { Problem(it) }
        }
    }
}

// What this profile sends and takes. Each kind is its own switch.
@Composable
internal fun SyncWhatRoute(onBack: () -> Unit) {
    val prefs = LocalAppContainer.current.settings
    SettingsPageFrame(Res.string.sync_what_section, onBack, subtitle = Res.string.sync_what_hint, onReset = {
        prefs.reset("sync.what.")
    }) {
        SettingsSection {
            for ((key, title, hint) in WhatSyncs) padded { FlagSwitch(key, true, title, hint) }
        }
    }
}

// When this device syncs: any interval up to six hours, the moments it syncs at, and what it waits for when it syncs on its own.
@Composable
internal fun SyncWhenRoute(onBack: () -> Unit) {
    val prefs = LocalAppContainer.current.settings
    val scope = rememberCoroutineScope()
    val every by remember(prefs) {
        prefs.number(SettingKey.SyncEveryMinutes, DefaultSyncMinutes)
    }.collectAsStateWithLifecycle(DefaultSyncMinutes)
    val background by remember(prefs) { prefs.flag(SettingKey.SyncBackground, true) }.collectAsStateWithLifecycle(true)
    SettingsPageFrame(Res.string.sync_when_title, onBack, subtitle = Res.string.sync_when_hint, onReset = {
        prefs.reset("sync.when.")
    }) {
        SettingsSection {
            padded {
                SliderSetting(Res.string.sync_every, every.toFloat(), 0f..MaxSyncMinutes, {
                    intervalText(it.roundToInt())
                }, hint = Res.string.sync_every_hint) {
                    scope.launch { prefs.setNumber(SettingKey.SyncEveryMinutes, it.roundToInt()) }
                }
            }
            padded {
                FlagSwitch(
                    SettingKey.SyncBackground,
                    true,
                    Res.string.sync_background,
                    Res.string.sync_background_hint,
                    enabled =
                    every > 0,
                )
            }
        }
        SettingsSection(Res.string.sync_triggers_section) {
            padded { FlagSwitch(SettingKey.SyncOnOpen, true, Res.string.sync_on_open, Res.string.sync_on_open_hint) }
            padded {
                FlagSwitch(
                    SettingKey.SyncAfterReading,
                    true,
                    Res.string.sync_after_reading,
                    Res.string.sync_after_reading_hint,
                )
            }
        }
        // The conditions only matter while the device syncs on its own.
        SettingsSection(Res.string.sync_when_conditions) {
            padded {
                FlagSwitch(
                    SettingKey.SyncWifiOnly,
                    false,
                    Res.string.sync_wifi_only,
                    Res.string.sync_wifi_only_hint,
                    enabled =
                    every > 0 && background,
                )
            }
            padded {
                FlagSwitch(
                    SettingKey.SyncCharging,
                    false,
                    Res.string.sync_charging,
                    Res.string.sync_charging_hint,
                    enabled =
                    every > 0 && background,
                )
            }
        }
    }
}

// The kinds of data that can sync, each with its setting, name and line.
internal val WhatSyncs = listOf(
    Triple(SettingKey.SyncProgress, Res.string.sync_what_progress, Res.string.sync_what_progress_hint),
    Triple(SettingKey.SyncShelves, Res.string.sync_what_shelves, Res.string.sync_what_shelves_hint),
    Triple(SettingKey.SyncSources, Res.string.sync_what_sources, Res.string.sync_what_sources_hint),
    Triple(SettingKey.SyncSettings, Res.string.sync_what_settings, Res.string.sync_what_settings_hint),
)

internal const val DefaultSyncMinutes = 15

// An on or off sync option kept in this profile's settings.
@Composable
private fun FlagSwitch(
    key: String,
    fallback: Boolean,
    title: StringResource,
    hint: StringResource,
    enabled: Boolean = true,
) {
    val prefs = LocalAppContainer.current.settings
    val scope = rememberCoroutineScope()
    val on by remember(prefs, key) { prefs.flag(key, fallback) }.collectAsStateWithLifecycle(fallback)
    SwitchSetting(title, on, { value -> scope.launch { prefs.setFlag(key, value) } }, hint, enabled = enabled)
}

// An interval of syncing in words: only when asked, minutes, or hours and minutes.
@Composable
internal fun intervalText(minutes: Int): String = when {
    minutes <= 0 -> stringResource(Res.string.sync_every_manual)
    minutes < 60 -> stringResource(Res.string.sync_every_minutes, minutes)
    minutes % 60 == 0 -> stringResource(Res.string.sync_every_hours, minutes / 60)
    else -> stringResource(Res.string.sync_every_hours_minutes, minutes / 60, minutes % 60)
}
