package com.sumizuri.app.feature.sync.signin

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Dns
import androidx.compose.material.icons.outlined.SwitchAccount
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.sync.Field
import com.sumizuri.app.feature.sync.Form
import com.sumizuri.app.feature.sync.FormError
import com.sumizuri.app.feature.sync.Link
import com.sumizuri.app.feature.sync.Note
import com.sumizuri.app.feature.sync.TwoStepField
import com.sumizuri.app.feature.sync.passwordProblem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_address_help
import com.sumizuri.app.shared.resources.sync_address_label
import com.sumizuri.app.shared.resources.sync_address_section
import com.sumizuri.app.shared.resources.sync_change_server
import com.sumizuri.app.shared.resources.sync_choose_first
import com.sumizuri.app.shared.resources.sync_choose_first_hint
import com.sumizuri.app.shared.resources.sync_choose_hint
import com.sumizuri.app.shared.resources.sync_choose_later
import com.sumizuri.app.shared.resources.sync_choose_title
import com.sumizuri.app.shared.resources.sync_connect
import com.sumizuri.app.shared.resources.sync_continue
import com.sumizuri.app.shared.resources.sync_create_action
import com.sumizuri.app.shared.resources.sync_create_link
import com.sumizuri.app.shared.resources.sync_create_section
import com.sumizuri.app.shared.resources.sync_forgot_link
import com.sumizuri.app.shared.resources.sync_invite
import com.sumizuri.app.shared.resources.sync_library_make
import com.sumizuri.app.shared.resources.sync_library_name
import com.sumizuri.app.shared.resources.sync_library_new
import com.sumizuri.app.shared.resources.sync_library_tap_to_link
import com.sumizuri.app.shared.resources.sync_new_password
import com.sumizuri.app.shared.resources.sync_password
import com.sumizuri.app.shared.resources.sync_password_repeat
import com.sumizuri.app.shared.resources.sync_recover_action
import com.sumizuri.app.shared.resources.sync_recover_help
import com.sumizuri.app.shared.resources.sync_recover_section
import com.sumizuri.app.shared.resources.sync_recovery_body
import com.sumizuri.app.shared.resources.sync_recovery_copy
import com.sumizuri.app.shared.resources.sync_recovery_file_failed
import com.sumizuri.app.shared.resources.sync_recovery_file_saved
import com.sumizuri.app.shared.resources.sync_recovery_file_text
import com.sumizuri.app.shared.resources.sync_recovery_key_label
import com.sumizuri.app.shared.resources.sync_recovery_save
import com.sumizuri.app.shared.resources.sync_recovery_saved
import com.sumizuri.app.shared.resources.sync_recovery_title
import com.sumizuri.app.shared.resources.sync_server_line
import com.sumizuri.app.shared.resources.sync_setup_action
import com.sumizuri.app.shared.resources.sync_setup_code
import com.sumizuri.app.shared.resources.sync_setup_help
import com.sumizuri.app.shared.resources.sync_setup_section
import com.sumizuri.app.shared.resources.sync_signin_action
import com.sumizuri.app.shared.resources.sync_signin_link
import com.sumizuri.app.shared.resources.sync_signin_section
import com.sumizuri.app.shared.resources.sync_two_step_ask
import com.sumizuri.app.shared.resources.sync_two_step_off_by_recovery
import com.sumizuri.app.shared.resources.sync_username
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.kit.input.rememberFileSaver
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.sync.core.ServerInfo
import com.sumizuri.sync.core.SignupMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okio.FileSystem
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The name a saved recovery key file is offered under.
private const val RecoveryFileName = "Sumizuri recovery key.txt"

@Composable
internal fun AddressSection(busy: Boolean, onConnect: (String) -> Unit) {
    var address by remember { mutableStateOf("") }
    SettingsSection(Res.string.sync_address_section, Res.string.sync_address_help) {
        padded {
            Form(busy) {
                val submit = { if (address.isNotBlank()) onConnect(address) }
                Field(
                    address,
                    { address = it },
                    Res.string.sync_address_label,
                    keyboard = KeyboardType.Uri,
                    onDone = submit,
                )
                InkButton(
                    submit,
                    enabled = !busy && address.isNotBlank(),
                ) { Text(stringResource(Res.string.sync_connect)) }
            }
        }
    }
}

@Composable
internal fun ServerSection(address: String, info: ServerInfo, busy: Boolean, onChange: () -> Unit) {
    SettingsSection(Res.string.sync_address_section) {
        row {
            SettingRow(
                info.name,
                subtitle = stringResource(Res.string.sync_server_line, address, info.version),
                leading = { SettingIcon(Icons.Outlined.Dns) },
                trailing = {
                    TextButton(
                        onChange,
                        enabled = !busy,
                    ) { Text(stringResource(Res.string.sync_change_server)) }
                },
            )
        }
    }
}

// Claims a server that has no owner yet, with the code from its log.
@Composable
internal fun SetupSection(minPassword: Int, busy: Boolean, onSetup: (String, String, String) -> Unit) {
    var code by remember { mutableStateOf("") }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var repeat by remember { mutableStateOf("") }
    var tried by remember { mutableStateOf(false) }
    val problem = passwordProblem(password, repeat, minPassword)
    SettingsSection(Res.string.sync_setup_section, Res.string.sync_setup_help) {
        padded {
            Form(busy) {
                val ready = code.isNotBlank() && username.isNotBlank()
                val submit = {
                    tried = true
                    if (problem == null && ready) onSetup(code, username, password)
                }
                Field(code, { code = it }, Res.string.sync_setup_code, capitalize = true)
                Field(username, { username = it }, Res.string.sync_username)
                Field(password, { password = it }, Res.string.sync_password, secret = true)
                Field(repeat, { repeat = it }, Res.string.sync_password_repeat, secret = true, onDone = submit)
                if (tried && problem != null) FormError(problem, minPassword)
                InkButton(submit, enabled = !busy && ready) {
                    Text(stringResource(Res.string.sync_setup_action))
                }
            }
        }
    }
}

@Composable
internal fun SignInSection(
    info: ServerInfo,
    askCode: Boolean,
    busy: Boolean,
    onSignIn: (String, String, String) -> Unit,
    onChoose: (SyncMode) -> Unit,
) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    SettingsSection(Res.string.sync_signin_section) {
        padded {
            Form(busy) {
                val ready = username.isNotBlank() && password.isNotEmpty() && (!askCode || code.isNotBlank())
                val submit = { if (ready) onSignIn(username, password, code) }
                Field(username, { username = it }, Res.string.sync_username)
                Field(
                    password,
                    { password = it },
                    Res.string.sync_password,
                    secret = true,
                    onDone = if (askCode) null else submit,
                )
                // The server asks for the code only after the password was right.
                if (askCode) {
                    Note(stringResource(Res.string.sync_two_step_ask))
                    TwoStepField(true, code, { code = it }, submit)
                }
                InkButton(submit, enabled = !busy && ready) { Text(stringResource(Res.string.sync_signin_action)) }
                if (info.signupMode !=
                    SignupMode.Closed
                ) {
                    Link(Res.string.sync_create_link, busy) { onChoose(SyncMode.Create) }
                }
                Link(Res.string.sync_forgot_link, busy) { onChoose(SyncMode.Recover) }
            }
        }
    }
}

@Composable
internal fun CreateSection(
    info: ServerInfo,
    busy: Boolean,
    onCreate: (String, String, String) -> Unit,
    onChoose: (SyncMode) -> Unit,
) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var repeat by remember { mutableStateOf("") }
    var invite by remember { mutableStateOf("") }
    var tried by remember { mutableStateOf(false) }
    val problem = passwordProblem(password, repeat, info.minPassword)
    val needsInvite = info.signupMode == SignupMode.Invite
    SettingsSection(Res.string.sync_create_section) {
        padded {
            Form(busy) {
                val ready = username.isNotBlank() && (!needsInvite || invite.isNotBlank())
                val submit = {
                    tried = true
                    if (problem == null && ready) onCreate(username, password, invite)
                }
                Field(username, { username = it }, Res.string.sync_username)
                Field(password, { password = it }, Res.string.sync_password, secret = true)
                Field(repeat, {
                    repeat = it
                }, Res.string.sync_password_repeat, secret = true, onDone = if (needsInvite) null else submit)
                if (needsInvite) {
                    Field(
                        invite,
                        { invite = it },
                        Res.string.sync_invite,
                        capitalize = true,
                        onDone = submit,
                    )
                }
                if (tried && problem != null) FormError(problem, info.minPassword)
                InkButton(submit, enabled = !busy && ready) {
                    Text(stringResource(Res.string.sync_create_action))
                }
                Link(Res.string.sync_signin_link, busy) { onChoose(SyncMode.SignIn) }
            }
        }
    }
}

// Sets a new password with the recovery key when the old one is lost.
@Composable
internal fun RecoverSection(
    minPassword: Int,
    busy: Boolean,
    onRecover: (String, String, String) -> Unit,
    onChoose: (SyncMode) -> Unit,
) {
    var username by remember { mutableStateOf("") }
    var recovery by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var repeat by remember { mutableStateOf("") }
    var tried by remember { mutableStateOf(false) }
    val problem = passwordProblem(password, repeat, minPassword)
    SettingsSection(Res.string.sync_recover_section, Res.string.sync_recover_help) {
        padded {
            Form(busy) {
                val ready = username.isNotBlank() && recovery.isNotBlank()
                val submit = {
                    tried = true
                    if (problem == null && ready) onRecover(username, recovery, password)
                }
                Field(username, { username = it }, Res.string.sync_username)
                Field(recovery, { recovery = it }, Res.string.sync_recovery_key_label, capitalize = true)
                Field(password, { password = it }, Res.string.sync_new_password, secret = true)
                Field(repeat, { repeat = it }, Res.string.sync_password_repeat, secret = true, onDone = submit)
                if (tried && problem != null) FormError(problem, minPassword)
                InkButton(submit, enabled = !busy && ready) {
                    Text(stringResource(Res.string.sync_recover_action))
                }
                Link(Res.string.sync_signin_link, busy) { onChoose(SyncMode.SignIn) }
            }
        }
    }
}

// Shows the new recovery key once, to copy or keep as a file, and moves on only after the person says it is saved.
@Composable
internal fun RecoverySection(step: SyncStep.SaveRecovery, onSaved: () -> Unit) {
    var saved by remember { mutableStateOf(false) }
    var note by remember { mutableStateOf<StringResource?>(null) }
    val copy = rememberCopyText()
    val scope = rememberCoroutineScope()
    val fileText = stringResource(Res.string.sync_recovery_file_text, step.server, step.username, step.recoveryKey)
    val temporary = remember { FileSystem.SYSTEM_TEMPORARY_DIRECTORY / RecoveryFileName }
    // The file the saver copied from holds the key, so it is removed as soon as the copy is done.
    val save = rememberFileSaver { done ->
        runCatching { FileSystem.SYSTEM.delete(temporary, mustExist = false) }
        note = if (done) Res.string.sync_recovery_file_saved else Res.string.sync_recovery_file_failed
        if (done) saved = true
    }
    SettingsSection(Res.string.sync_recovery_title, Res.string.sync_recovery_body) {
        padded {
            Form {
                KeyGroups(step.recoveryKey)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    InkOutlinedButton(
                        { copy(step.recoveryKey) },
                    ) { Text(stringResource(Res.string.sync_recovery_copy)) }
                    InkOutlinedButton({
                        scope.launch {
                            val written =
                                withContext(
                                    Dispatchers.IO,
                                ) {
                                    runCatching {
                                        FileSystem.SYSTEM.write(
                                            temporary,
                                        ) { writeUtf8(fileText) }
                                    }.isSuccess
                                }
                            if (written) {
                                save(RecoveryFileName, temporary)
                            } else {
                                note =
                                    Res.string.sync_recovery_file_failed
                            }
                        }
                    }) { Text(stringResource(Res.string.sync_recovery_save)) }
                }
                note?.let {
                    Text(
                        stringResource(it),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline,
                    )
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(saved, { saved = it })
                    Text(stringResource(Res.string.sync_recovery_saved), style = MaterialTheme.typography.bodyMedium)
                }
                InkButton(onSaved, enabled = saved) { Text(stringResource(Res.string.sync_continue)) }
            }
        }
    }
}

// Asked once after signing in: which profile on the server this profile syncs with, or a new one named after this profile.
@Composable
internal fun ChooseProfileSection(
    step: SyncStep.ChooseProfile,
    busy: Boolean,
    onPick: (Long) -> Unit,
    onMake: (String) -> Unit,
    onLater: () -> Unit,
) {
    var name by remember(step.suggested) { mutableStateOf(step.suggested) }
    if (step.twoStepOff) SettingsSection { padded { Note(stringResource(Res.string.sync_two_step_off_by_recovery)) } }
    if (step.profiles.isNotEmpty()) {
        SettingsSection(Res.string.sync_choose_title, Res.string.sync_choose_hint) {
            for (profile in step.profiles) {
                row {
                    SettingRow(
                        profile.name,
                        subtitle = stringResource(Res.string.sync_library_tap_to_link),
                        leading = { SettingIcon(Icons.Outlined.SwitchAccount) },
                        onClick = if (busy) null else ({ onPick(profile.id) }),
                    )
                }
            }
        }
    }
    SettingsSection(
        if (step.profiles.isEmpty()) Res.string.sync_choose_first else Res.string.sync_library_new,
        if (step.profiles.isEmpty()) Res.string.sync_choose_first_hint else null,
    ) {
        padded {
            Form(busy) {
                val submit = { if (name.isNotBlank()) onMake(name) }
                Field(name, { name = it }, Res.string.sync_library_name, onDone = submit)
                InkButton(
                    submit,
                    enabled = !busy && name.isNotBlank(),
                ) { Text(stringResource(Res.string.sync_library_make)) }
                Link(Res.string.sync_choose_later, busy, onLater)
            }
        }
    }
}
