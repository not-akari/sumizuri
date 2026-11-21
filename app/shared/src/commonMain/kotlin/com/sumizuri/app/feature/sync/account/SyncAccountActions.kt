package com.sumizuri.app.feature.sync.account

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.sync.Field
import com.sumizuri.app.feature.sync.Form
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.TwoStepField
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.signin.RecoverySection
import com.sumizuri.app.feature.sync.signin.SyncStep
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_delete_account
import com.sumizuri.app.shared.resources.sync_delete_account_hint
import com.sumizuri.app.shared.resources.sync_delete_account_message
import com.sumizuri.app.shared.resources.sync_delete_confirm
import com.sumizuri.app.shared.resources.sync_delete_owner
import com.sumizuri.app.shared.resources.sync_password_current
import com.sumizuri.app.shared.resources.sync_recovery_done
import com.sumizuri.app.shared.resources.sync_recovery_make
import com.sumizuri.app.shared.resources.sync_recovery_new
import com.sumizuri.app.shared.resources.sync_recovery_new_hint
import com.sumizuri.app.shared.resources.sync_username_change
import com.sumizuri.app.shared.resources.sync_username_change_hint
import com.sumizuri.app.shared.resources.sync_username_done
import com.sumizuri.app.shared.resources.sync_username_new
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.text.NoteText
import com.sumizuri.sync.core.Role
import org.jetbrains.compose.resources.stringResource

// A new username for this account. The password proves it is you.
@Composable
internal fun SyncUsernameRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_username_change, onBack, subtitle = Res.string.sync_username_change_hint) {
        val account by LocalProfiles.current.syncAccounts.account
            .collectAsStateWithLifecycle()
        val signed = account ?: return@SettingsPageFrame
        val model = rememberSyncHome(signed)
        val home by model.home.collectAsStateWithLifecycle()
        var name by remember { mutableStateOf(signed.username) }
        var password by remember { mutableStateOf("") }
        var code by remember { mutableStateOf("") }
        LaunchedEffect(model) { model.loadTwoStep() }
        var done by remember { mutableStateOf(false) }
        val ready =
            name.isNotBlank() && name.trim() != signed.username && password.isNotEmpty() &&
                (!home.askCode || code.isNotEmpty())
        val submit = {
            if (ready) {
                model.own.changeUsername(password, name, code) {
                    done = true
                    password = ""
                    code = ""
                }
            }
        }
        SettingsSection {
            padded {
                Form(home.busy) {
                    Field(name, {
                        name = it
                        done = false
                    }, Res.string.sync_username_new)
                    Field(password, {
                        password = it
                        done = false
                    }, Res.string.sync_password_current, secret = true, onDone = if (home.askCode) null else submit)
                    TwoStepField(home.askCode, code, { code = it }, submit)
                    InkButton(
                        submit,
                        enabled = !home.busy && ready,
                    ) { Text(stringResource(Res.string.sync_username_change)) }
                    if (done) NoteText(stringResource(Res.string.sync_username_done))
                }
            }
        }
        if (home.busy) Working()
        home.problem?.let { Problem(it) }
    }
}

// A new recovery key for this account, shown once to be kept, after which the old key stops working.
@Composable
internal fun SyncRecoveryRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_recovery_new, onBack, subtitle = Res.string.sync_recovery_new_hint) {
        val account by LocalProfiles.current.syncAccounts.account
            .collectAsStateWithLifecycle()
        val signed = account ?: return@SettingsPageFrame
        val model = rememberSyncHome(signed)
        val home by model.home.collectAsStateWithLifecycle()
        var password by remember { mutableStateOf("") }
        var key by remember { mutableStateOf<String?>(null) }
        var code by remember { mutableStateOf("") }
        LaunchedEffect(model) { model.loadTwoStep() }
        var done by remember { mutableStateOf(false) }
        val made = key
        if (made != null) {
            RecoverySection(SyncStep.SaveRecovery(made, signed.server, signed.username)) {
                key = null
                done = true
            }
        } else {
            val ready = password.isNotEmpty() && (!home.askCode || code.isNotEmpty())
            val submit = {
                if (ready) {
                    model.own.newRecoveryKey(password, code) {
                        key = it
                        password = ""
                        code = ""
                    }
                }
            }
            SettingsSection {
                padded {
                    Form(home.busy) {
                        Field(password, {
                            password = it
                            done = false
                        }, Res.string.sync_password_current, secret = true, onDone = if (home.askCode) null else submit)
                        TwoStepField(home.askCode, code, { code = it }, submit)
                        InkButton(
                            submit,
                            enabled = !home.busy && ready,
                        ) { Text(stringResource(Res.string.sync_recovery_make)) }
                        if (done) NoteText(stringResource(Res.string.sync_recovery_done))
                    }
                }
            }
        }
        if (home.busy) Working()
        home.problem?.let { Problem(it) }
    }
}

// Deletes this account on the server, asking once more first. The owner keeps the server, so the page only says why the owner cannot.
@Composable
internal fun SyncDeleteRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_delete_account, onBack, subtitle = Res.string.sync_delete_account_hint) {
        val account by LocalProfiles.current.syncAccounts.account
            .collectAsStateWithLifecycle()
        val signed = account ?: return@SettingsPageFrame
        val model = rememberSyncHome(signed)
        val home by model.home.collectAsStateWithLifecycle()
        var password by remember { mutableStateOf("") }
        var asking by remember { mutableStateOf(false) }
        var code by remember { mutableStateOf("") }
        LaunchedEffect(model) { model.loadTwoStep() }
        val ready = password.isNotEmpty() && (!home.askCode || code.isNotEmpty())
        SettingsSection {
            if (signed.role == Role.Owner) {
                padded { NoteText(stringResource(Res.string.sync_delete_owner)) }
            } else {
                padded { NoteText(stringResource(Res.string.sync_delete_account_message)) }
                padded {
                    Form(home.busy) {
                        Field(
                            password,
                            { password = it },
                            Res.string.sync_password_current,
                            secret = true,
                            onDone = if (home.askCode) {
                                null
                            } else {
                                (
                                    {
                                        if (ready) {
                                            asking =
                                                true
                                        }
                                    }
                                    )
                            },
                        )
                        TwoStepField(home.askCode, code, { code = it }, { if (ready) asking = true })
                        InkButton(
                            { asking = true },
                            enabled = !home.busy && ready,
                        ) { Text(stringResource(Res.string.sync_delete_account)) }
                    }
                }
            }
        }
        if (asking) {
            ConfirmDialog(
                stringResource(Res.string.sync_delete_account),
                stringResource(Res.string.sync_delete_account_message),
                stringResource(Res.string.sync_delete_confirm),
                onConfirm = {
                    asking = false
                    model.own.deleteAccount(password, code, onBack)
                },
                onDismiss = { asking = false },
            )
        }
        if (home.busy) Working()
        home.problem?.let { Problem(it) }
    }
}
