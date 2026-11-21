package com.sumizuri.app.feature.sync.account

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.sync.Field
import com.sumizuri.app.feature.sync.Form
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.TwoStepField
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_password_current
import com.sumizuri.app.shared.resources.sync_recovery_copy
import com.sumizuri.app.shared.resources.sync_two_step
import com.sumizuri.app.shared.resources.sync_two_step_confirm
import com.sumizuri.app.shared.resources.sync_two_step_done
import com.sumizuri.app.shared.resources.sync_two_step_hint
import com.sumizuri.app.shared.resources.sync_two_step_is_off
import com.sumizuri.app.shared.resources.sync_two_step_is_on
import com.sumizuri.app.shared.resources.sync_two_step_open_app
import com.sumizuri.app.shared.resources.sync_two_step_qr
import com.sumizuri.app.shared.resources.sync_two_step_scan
import com.sumizuri.app.shared.resources.sync_two_step_secret
import com.sumizuri.app.shared.resources.sync_two_step_setup
import com.sumizuri.app.shared.resources.sync_two_step_turn_off
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.text.NoteText
import com.sumizuri.sync.core.TwoStepSecret
import io.github.alexzhirkevich.qrose.rememberQrCodePainter
import org.jetbrains.compose.resources.stringResource

// Two-step sign in: a code from an authenticator app is asked after the password. The page sets it up with a QR code, or turns it off.
@Composable
internal fun SyncTwoStepRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_two_step, onBack, subtitle = Res.string.sync_two_step_hint) {
        val account by LocalProfiles.current.syncAccounts.account
            .collectAsStateWithLifecycle()
        val signed = account ?: return@SettingsPageFrame
        val model = rememberSyncHome(signed)
        val home by model.home.collectAsStateWithLifecycle()
        var password by remember { mutableStateOf("") }
        var code by remember { mutableStateOf("") }
        var secret by remember { mutableStateOf<TwoStepSecret?>(null) }
        var done by remember { mutableStateOf(false) }
        LaunchedEffect(model) { model.loadTwoStep() }
        val pending = secret
        when {
            home.twoStep == true -> SettingsSection {
                padded {
                    NoteText(
                        stringResource(if (done) Res.string.sync_two_step_done else Res.string.sync_two_step_is_on),
                    )
                }
                padded {
                    Form(home.busy) {
                        val ready = password.isNotEmpty() && code.isNotEmpty()
                        val submit = {
                            if (ready) {
                                model.own.turnOffTwoStep(password, code) {
                                    password = ""
                                    code = ""
                                    done = false
                                }
                            }
                        }
                        Field(password, { password = it }, Res.string.sync_password_current, secret = true)
                        TwoStepField(true, code, { code = it }, submit)
                        InkButton(
                            submit,
                            enabled = !home.busy && ready,
                        ) { Text(stringResource(Res.string.sync_two_step_turn_off)) }
                    }
                }
            }

            pending != null -> SetupSteps(pending, code, { code = it }, home.busy) {
                model.own.confirmTwoStep(code) {
                    secret = null
                    code = ""
                    done = true
                }
            }

            home.twoStep == false -> SettingsSection {
                padded { NoteText(stringResource(Res.string.sync_two_step_is_off)) }
                padded {
                    Form(home.busy) {
                        val submit = {
                            if (password.isNotEmpty()) {
                                model.own.startTwoStep(password) {
                                    secret = it
                                    password = ""
                                }
                            }
                        }
                        Field(
                            password,
                            { password = it },
                            Res.string.sync_password_current,
                            secret = true,
                            onDone = submit,
                        )
                        InkButton(submit, enabled = !home.busy && password.isNotEmpty()) {
                            Text(stringResource(Res.string.sync_two_step_setup))
                        }
                    }
                }
            }
        }
        if (home.busy || home.twoStep == null) Working()
        home.problem?.let { Problem(it) }
    }
}

// The QR code and the secret for the authenticator app, then the first code from it, which turns two-step sign in on.
@Composable
private fun SetupSteps(
    secret: TwoStepSecret,
    code: String,
    onCode: (String) -> Unit,
    busy: Boolean,
    onConfirm: () -> Unit,
) {
    val copy = rememberCopyText()
    val uri = LocalUriHandler.current
    SettingsSection(Res.string.sync_two_step_scan) {
        padded {
            Form {
                // The code is drawn dark on white whatever the theme, since scanners read that best.
                Box(Modifier.background(Color.White, RoundedCornerShape(12.dp)).padding(12.dp)) {
                    Image(
                        rememberQrCodePainter(secret.link),
                        stringResource(Res.string.sync_two_step_qr),
                        Modifier.size(200.dp),
                    )
                }
                Text(
                    stringResource(Res.string.sync_two_step_secret),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.outline,
                )
                Text(
                    secret.secret.chunked(4).joinToString(" "),
                    style = MaterialTheme.typography.titleSmall,
                    fontFamily = FontFamily.Monospace,
                    fontWeight = FontWeight.SemiBold,
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    InkOutlinedButton({ copy(secret.secret) }) { Text(stringResource(Res.string.sync_recovery_copy)) }
                    // On a phone with an authenticator app, the link opens it with the account filled in.
                    InkOutlinedButton({
                        runCatching { uri.openUri(secret.link) }
                    }) { Text(stringResource(Res.string.sync_two_step_open_app)) }
                }
            }
        }
    }
    SettingsSection {
        padded {
            Form(busy) {
                val ready = code.length == 6
                TwoStepField(true, code, onCode) { if (ready) onConfirm() }
                InkButton(
                    onConfirm,
                    enabled = !busy && ready,
                ) { Text(stringResource(Res.string.sync_two_step_confirm)) }
            }
        }
    }
}
