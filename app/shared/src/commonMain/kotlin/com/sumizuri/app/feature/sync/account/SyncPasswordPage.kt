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
import com.sumizuri.app.feature.sync.FormError
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.TwoStepField
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.passwordProblem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_new_password
import com.sumizuri.app.shared.resources.sync_password_change
import com.sumizuri.app.shared.resources.sync_password_change_hint
import com.sumizuri.app.shared.resources.sync_password_current
import com.sumizuri.app.shared.resources.sync_password_done
import com.sumizuri.app.shared.resources.sync_password_repeat
import com.sumizuri.app.shared.resources.sync_password_sign_out_others
import com.sumizuri.app.shared.resources.sync_password_sign_out_others_hint
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.kit.text.NoteText
import org.jetbrains.compose.resources.stringResource

// A new password for this account. The current one proves it is you, and your synced data stays readable since only the lock on the account key changes.
@Composable
internal fun SyncPasswordRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_password_change, onBack, subtitle = Res.string.sync_password_change_hint) {
        val account by LocalProfiles.current.syncAccounts.account
            .collectAsStateWithLifecycle()
        val signed = account ?: return@SettingsPageFrame
        val model = rememberSyncHome(signed)
        val home by model.home.collectAsStateWithLifecycle()
        val minPassword = home.info?.minPassword ?: 10
        var current by remember { mutableStateOf("") }
        var code by remember { mutableStateOf("") }
        LaunchedEffect(model) { model.loadTwoStep() }
        var password by remember { mutableStateOf("") }
        var repeat by remember { mutableStateOf("") }
        var signOutOthers by remember { mutableStateOf(false) }
        var tried by remember { mutableStateOf(false) }
        var done by remember { mutableStateOf(false) }
        val problem = passwordProblem(password, repeat, minPassword)
        SettingsSection {
            padded {
                Form(home.busy) {
                    val submit = {
                        tried = true
                        if (problem == null && current.isNotEmpty() && (!home.askCode || code.isNotEmpty())) {
                            model.own.changePassword(current, password, signOutOthers, code) {
                                done = true
                                current = ""
                                code = ""
                                password = ""
                                repeat = ""
                                tried = false
                            }
                        }
                    }
                    Field(current, {
                        current = it
                        done = false
                    }, Res.string.sync_password_current, secret = true)
                    TwoStepField(home.askCode, code, { code = it })
                    Field(password, {
                        password = it
                        done = false
                    }, Res.string.sync_new_password, secret = true)
                    Field(repeat, {
                        repeat = it
                        done = false
                    }, Res.string.sync_password_repeat, secret = true, onDone = submit)
                    if (tried && problem != null) FormError(problem, minPassword)
                    SwitchSetting(Res.string.sync_password_sign_out_others, signOutOthers, {
                        signOutOthers = it
                    }, Res.string.sync_password_sign_out_others_hint)
                    InkButton(submit, enabled = !home.busy && current.isNotEmpty() && password.isNotEmpty()) {
                        Text(stringResource(Res.string.sync_password_change))
                    }
                    if (done) NoteText(stringResource(Res.string.sync_password_done))
                }
            }
        }
        if (home.busy) Working()
        home.problem?.let { Problem(it) }
    }
}
