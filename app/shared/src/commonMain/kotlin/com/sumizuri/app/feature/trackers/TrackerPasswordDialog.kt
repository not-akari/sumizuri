package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_email
import com.sumizuri.app.shared.resources.tracker_password
import com.sumizuri.app.shared.resources.tracker_password_hide
import com.sumizuri.app.shared.resources.tracker_password_note
import com.sumizuri.app.shared.resources.tracker_password_show
import com.sumizuri.app.shared.resources.tracker_password_title
import com.sumizuri.app.shared.resources.tracker_sign_in
import com.sumizuri.app.shared.resources.tracker_token
import com.sumizuri.app.shared.resources.tracker_token_make
import com.sumizuri.app.shared.resources.tracker_token_note
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import org.jetbrains.compose.resources.stringResource
import com.sumizuri.app.ui.kit.input.AppTextField

// Asks for the email and password of a tracker that has no sign in on its site, or for a token the person made on the site of the tracker. They go to the tracker once, and only the token is kept, sealed.
@Composable
internal fun TrackerPasswordDialog(
    tracker: TrackerId,
    withToken: Boolean,
    tokenPage: String?,
    onSignIn: (String, String) -> Unit,
    onDismiss: () -> Unit,
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var shown by remember { mutableStateOf(false) }
    val uri = LocalUriHandler.current
    val ready = (withToken || email.isNotBlank()) && password.isNotBlank()
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.tracker_password_title, tracker.label)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (!withToken) AppTextField(
                    email,
                    { email = it },
                    Modifier.fillMaxWidth(),
                    label = { Text(stringResource(Res.string.tracker_email)) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, autoCorrectEnabled = false),
                )
                AppTextField(
                    password,
                    { password = it },
                    Modifier.fillMaxWidth(),
                    label = { Text(stringResource(if (withToken) Res.string.tracker_token else Res.string.tracker_password)) },
                    singleLine = true,
                    visualTransformation = if (shown) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrectEnabled = false),
                    trailingIcon = {
                        IconButton({ shown = !shown }) {
                            Icon(
                                if (shown) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility,
                                stringResource(
                                    if (shown) Res.string.tracker_password_hide else Res.string.tracker_password_show,
                                ),
                            )
                        }
                    },
                )
                if (withToken && tokenPage != null) {
                    TextButton({ runCatching { uri.openUri(tokenPage) } }) { Text(stringResource(Res.string.tracker_token_make, tracker.label)) }
                }
                Text(
                    stringResource(if (withToken) Res.string.tracker_token_note else Res.string.tracker_password_note, tracker.label),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
        confirmButton = {
            InkButton(
                { onSignIn(email.trim(), password.trim().takeIf { withToken } ?: password) },
                enabled = ready,
            ) { Text(stringResource(Res.string.tracker_sign_in)) }
        },
        dismissButton = { CancelButton(onDismiss) },
    )
}
