package com.sumizuri.app.feature.sync.admin

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.sync.Form
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.account.rememberSyncHome
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_server_settings
import com.sumizuri.app.shared.resources.sync_server_settings_hint
import com.sumizuri.app.shared.resources.sync_setting_idle
import com.sumizuri.app.shared.resources.sync_setting_idle_hint
import com.sumizuri.app.shared.resources.sync_setting_min_password
import com.sumizuri.app.shared.resources.sync_setting_min_password_hint
import com.sumizuri.app.shared.resources.sync_setting_name
import com.sumizuri.app.shared.resources.sync_setting_name_hint
import com.sumizuri.app.shared.resources.sync_setting_pinned
import com.sumizuri.app.shared.resources.sync_setting_range
import com.sumizuri.app.shared.resources.sync_setting_save
import com.sumizuri.app.shared.resources.sync_setting_signup
import com.sumizuri.app.shared.resources.sync_setting_signup_hint
import com.sumizuri.app.shared.resources.sync_setting_storage
import com.sumizuri.app.shared.resources.sync_setting_storage_hint
import com.sumizuri.app.shared.resources.sync_setting_wrong_tries
import com.sumizuri.app.shared.resources.sync_setting_wrong_tries_hint
import com.sumizuri.app.shared.resources.sync_signup_closed
import com.sumizuri.app.shared.resources.sync_signup_invite
import com.sumizuri.app.shared.resources.sync_signup_open
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.sync.core.Role
import com.sumizuri.sync.core.ServerSettingEntry
import com.sumizuri.sync.core.ServerSettings
import com.sumizuri.sync.core.SettingKind
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import com.sumizuri.app.ui.kit.input.AppTextField

// The live settings of the server, each in its own section with its name, what it does, and a typed value or a choice. A setting the server's .env sets is shown locked.
@Composable
internal fun SyncAdminSettingsRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_server_settings, onBack, subtitle = Res.string.sync_server_settings_hint) {
        val account by LocalProfiles.current.syncAccounts.account
            .collectAsStateWithLifecycle()
        val signed = account?.takeIf { it.role == Role.Owner || it.role == Role.Admin } ?: return@SettingsPageFrame
        val model = rememberSyncHome(signed)
        val home by model.home.collectAsStateWithLifecycle()
        for (entry in home.serverSettings.orEmpty()) {
            val (title, hint) = settingWords(entry.key)
            SettingsSection(title, if (entry.pinned) Res.string.sync_setting_pinned else hint) {
                padded { SettingEditor(entry, title, home.busy) { value -> model.setServerSetting(entry.key, value) } }
            }
        }
        if (home.busy) Working()
        home.problem?.let { Problem(it) }
    }
}

// One setting: a choice for a few fixed words, otherwise a typed value with a Save button that only works once the value changed and fits.
@Composable
private fun SettingEditor(entry: ServerSettingEntry, title: StringResource, busy: Boolean, onSave: (String) -> Unit) {
    if (entry.kind == SettingKind.Choice) {
        ChoiceSetting(title, entry.options, entry.value, { signupWord(it) }, icon = null) { if (!entry.pinned && !busy) onSave(it) }
        return
    }
    var typed by remember(entry.value) { mutableStateOf(entry.value) }
    val fits = ServerSettings.problem(entry.key, typed) == null
    Form(busy) {
        AppTextField(
            typed,
            { text -> typed = if (entry.kind == SettingKind.Number) text.filter(Char::isDigit).take(9) else text.take(64) },
            Modifier.fillMaxWidth(),
            enabled = !entry.pinned && !busy,
            label = { Text(stringResource(title)) },
            supportingText = if (entry.kind == SettingKind.Number) ({ Text(stringResource(Res.string.sync_setting_range, entry.min ?: 0, entry.max ?: 0, entry.default)) }) else null,
            isError = !fits,
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = if (entry.kind == SettingKind.Number) KeyboardType.Number else KeyboardType.Text),
        )
        if (!entry.pinned) InkOutlinedButton({ onSave(typed) }, enabled = fits && typed.trim() != entry.value && !busy) { Text(stringResource(Res.string.sync_setting_save)) }
    }
}

// The name and the line of each live setting.
private fun settingWords(key: String): Pair<StringResource, StringResource> = when (key) {
    ServerSettings.Name -> Res.string.sync_setting_name to Res.string.sync_setting_name_hint
    ServerSettings.SignupMode -> Res.string.sync_setting_signup to Res.string.sync_setting_signup_hint
    ServerSettings.MinPassword -> Res.string.sync_setting_min_password to Res.string.sync_setting_min_password_hint
    ServerSettings.WrongTries -> Res.string.sync_setting_wrong_tries to Res.string.sync_setting_wrong_tries_hint
    ServerSettings.IdleDeviceDays -> Res.string.sync_setting_idle to Res.string.sync_setting_idle_hint
    else -> Res.string.sync_setting_storage to Res.string.sync_setting_storage_hint
}

@Composable
private fun signupWord(option: String): String = stringResource(
    when (option) {
        "open" -> Res.string.sync_signup_open
        "closed" -> Res.string.sync_signup_closed
        else -> Res.string.sync_signup_invite
    },
)
