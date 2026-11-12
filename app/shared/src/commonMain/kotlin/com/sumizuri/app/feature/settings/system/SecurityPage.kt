package com.sumizuri.app.feature.settings.system

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.LockClock
import androidx.compose.material.icons.outlined.Password
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.security.DeviceUnlock
import com.sumizuri.app.data.security.LockAfterChoices
import com.sumizuri.app.data.security.LockPrefs
import com.sumizuri.app.data.security.SecureScreen
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.GlobalReaderViewModel
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.incognito_mode
import com.sumizuri.app.shared.resources.incognito_mode_hint
import com.sumizuri.app.shared.resources.lock_after
import com.sumizuri.app.shared.resources.lock_after_hour
import com.sumizuri.app.shared.resources.lock_after_minutes
import com.sumizuri.app.shared.resources.lock_after_now
import com.sumizuri.app.shared.resources.lock_after_start
import com.sumizuri.app.shared.resources.lock_change_pin
import com.sumizuri.app.shared.resources.lock_no_system
import com.sumizuri.app.shared.resources.lock_now
import com.sumizuri.app.shared.resources.lock_now_hint
import com.sumizuri.app.shared.resources.lock_on
import com.sumizuri.app.shared.resources.lock_on_pin_hint
import com.sumizuri.app.shared.resources.lock_on_system_hint
import com.sumizuri.app.shared.resources.lock_pin_forgot
import com.sumizuri.app.shared.resources.lock_pin_mismatch
import com.sumizuri.app.shared.resources.lock_pin_new
import com.sumizuri.app.shared.resources.lock_pin_repeat
import com.sumizuri.app.shared.resources.lock_pin_set
import com.sumizuri.app.shared.resources.lock_pin_short
import com.sumizuri.app.shared.resources.lock_prompt
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.shared.resources.search_history
import com.sumizuri.app.shared.resources.search_history_hint
import com.sumizuri.app.shared.resources.secure_screen
import com.sumizuri.app.shared.resources.secure_screen_always
import com.sumizuri.app.shared.resources.secure_screen_incognito
import com.sumizuri.app.shared.resources.secure_screen_off
import com.sumizuri.app.shared.resources.security_group_lock
import com.sumizuri.app.shared.resources.security_group_privacy
import com.sumizuri.app.shared.resources.security_privacy_hint
import com.sumizuri.app.shared.resources.settings_security
import com.sumizuri.app.shared.resources.settings_security_hint
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.security.PinMaxLength
import com.sumizuri.app.ui.security.rememberSystemUnlock
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The shortest PIN the app takes.
private const val PinMinLength = 4

// The page of the lock and of privacy: the lock of the app and how soon it comes back, the screen hidden from screenshots, and reading incognito. On a phone the lock is the one of the phone, and elsewhere a PIN of the app.
@Composable
fun SecurityRoute(onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val lock = container.lock
    val scope = rememberCoroutineScope()
    val prefs by lock.prefs.collectAsStateWithLifecycle(LockPrefs())
    val reader = viewModel { GlobalReaderViewModel(container.reading) }
    val reading by reader.settings.collectAsStateWithLifecycle()
    val searchHistory by container.searchHistory.on.collectAsStateWithLifecycle(true)
    var pinDialog by remember { mutableStateOf(false) }
    var noSystemLock by remember { mutableStateOf(false) }
    // The lock of the phone is asked for once before it is turned on, so it is known to work.
    val confirm = rememberSystemUnlock(stringResource(Res.string.lock_prompt)) {
        lock.unlock()
        scope.launch { lock.setOn(true) }
    }
    SettingsPageFrame(Res.string.settings_security, onBack, subtitle = Res.string.settings_security_hint) {
        SettingsSection(
            Res.string.security_group_lock,
            hint = if (DeviceUnlock.usesSystem) null else Res.string.lock_pin_forgot,
        ) {
            padded {
                SwitchSetting(Res.string.lock_on, prefs.on, { on ->
                    when {
                        !on -> scope.launch { lock.setOn(false) }

                        !DeviceUnlock.usesSystem -> pinDialog = true

                        DeviceUnlock.available() -> {
                            noSystemLock = false
                            lock.onPrompt()
                            confirm()
                        }

                        else -> noSystemLock = true
                    }
                }, if (DeviceUnlock.usesSystem) Res.string.lock_on_system_hint else Res.string.lock_on_pin_hint)
            }
            if (noSystemLock &&
                !prefs.on
            ) {
                padded {
                    Text(
                        stringResource(Res.string.lock_no_system),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            }
            if (prefs.on) {
                padded {
                    ChoiceSetting(Res.string.lock_after, LockAfterChoices, prefs.afterSeconds, {
                        lockAfterLabel(it)
                    }) { seconds -> scope.launch { lock.setAfter(seconds) } }
                }
                if (!DeviceUnlock.usesSystem) {
                    row {
                        SettingRow(
                            stringResource(
                                Res.string.lock_change_pin,
                            ),
                            leading = { SettingIcon(Icons.Outlined.Password) },
                            onClick = {
                                pinDialog =
                                    true
                            },
                        )
                    }
                }
                row {
                    SettingRow(
                        stringResource(
                            Res.string.lock_now,
                        ),
                        subtitle = stringResource(Res.string.lock_now_hint),
                        leading = {
                            SettingIcon(Icons.Outlined.LockClock)
                        },
                        onClick = lock::lockNow,
                    )
                }
            }
        }
        SettingsSection(
            Res.string.security_group_privacy,
            hint = if (DeviceUnlock.canHideScreen) Res.string.security_privacy_hint else null,
        ) {
            if (DeviceUnlock.canHideScreen) {
                padded {
                    ChoiceSetting(Res.string.secure_screen, SecureScreen.entries, prefs.secureScreen, {
                        secureScreenLabel(it)
                    }) { mode -> scope.launch { lock.setSecureScreen(mode) } }
                }
            }
            padded {
                SwitchSetting(Res.string.incognito_mode, reading.incognito, { on ->
                    reader.update {
                        it.copy(incognito = on)
                    }
                }, Res.string.incognito_mode_hint)
            }
            // Turning the history off also forgets what it kept.
            padded {
                SwitchSetting(Res.string.search_history, searchHistory, { on ->
                    scope.launch {
                        container.settings.setFlag(SettingKey.SearchHistory, on)
                        if (!on) container.searchHistory.clearAll()
                    }
                }, Res.string.search_history_hint)
            }
        }
    }
    if (pinDialog) {
        PinDialog(onDismiss = { pinDialog = false }) { pin ->
            pinDialog = false
            scope.launch {
                lock.setPin(pin)
                lock.setOn(true)
            }
        }
    }
}

// How soon the lock comes back once the app is away.
@Composable
internal fun lockAfterLabel(seconds: Int): String = when {
    seconds < 0 -> stringResource(Res.string.lock_after_start)
    seconds == 0 -> stringResource(Res.string.lock_after_now)
    seconds >= 3600 -> stringResource(Res.string.lock_after_hour)
    else -> pluralStringResource(Res.plurals.lock_after_minutes, seconds / 60, seconds / 60)
}

@Composable
internal fun secureScreenLabel(mode: SecureScreen): String = stringResource(
    when (mode) {
        SecureScreen.Off -> Res.string.secure_screen_off
        SecureScreen.Incognito -> Res.string.secure_screen_incognito
        SecureScreen.Always -> Res.string.secure_screen_always
    },
)

// Asks for a new PIN twice. It takes digits only, at least four of them, and both must match.
@Composable
private fun PinDialog(onDismiss: () -> Unit, onSet: (String) -> Unit) {
    var pin by remember { mutableStateOf("") }
    var again by remember { mutableStateOf("") }
    var tried by remember { mutableStateOf(false) }
    val problem = when {
        pin.length < PinMinLength -> Res.string.lock_pin_short
        pin != again -> Res.string.lock_pin_mismatch
        else -> null
    }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.lock_pin_set)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                PinField(pin, Res.string.lock_pin_new) { pin = it }
                PinField(again, Res.string.lock_pin_repeat) { again = it }
                if (tried &&
                    problem != null
                ) {
                    Text(
                        stringResource(problem),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            }
        },
        confirmButton = {
            InkButton({
                if (problem ==
                    null
                ) {
                    onSet(pin)
                } else {
                    tried = true
                }
            }) { Text(stringResource(Res.string.save)) }
        },
        dismissButton = { InkOutlinedButton(onDismiss) { Text(stringResource(Res.string.cancel)) } },
    )
}

@Composable
private fun PinField(value: String, label: StringResource, onChange: (String) -> Unit) {
    OutlinedTextField(
        value,
        { typed -> onChange(typed.filter(Char::isDigit).take(PinMaxLength)) },
        label = { Text(stringResource(label)) },
        singleLine = true,
        visualTransformation = PasswordVisualTransformation(),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
    )
}
