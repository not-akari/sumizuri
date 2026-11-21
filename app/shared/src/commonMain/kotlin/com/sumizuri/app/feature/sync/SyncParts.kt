package com.sumizuri.app.feature.sync

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardActions
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
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.account.SyncProblem
import com.sumizuri.app.feature.sync.home.SyncHomeModel
import com.sumizuri.app.feature.sync.signin.SyncViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_error_bad_address
import com.sumizuri.app.shared.resources.sync_error_bad_answer
import com.sumizuri.app.shared.resources.sync_error_bad_recovery_key
import com.sumizuri.app.shared.resources.sync_error_code_needed
import com.sumizuri.app.shared.resources.sync_error_disabled
import com.sumizuri.app.shared.resources.sync_error_invite_needed
import com.sumizuri.app.shared.resources.sync_error_key_mismatch
import com.sumizuri.app.shared.resources.sync_error_needs_https
import com.sumizuri.app.shared.resources.sync_error_no_library
import com.sumizuri.app.shared.resources.sync_error_not_allowed
import com.sumizuri.app.shared.resources.sync_error_not_found
import com.sumizuri.app.shared.resources.sync_error_setup_done
import com.sumizuri.app.shared.resources.sync_error_signed_out
import com.sumizuri.app.shared.resources.sync_error_signup_closed
import com.sumizuri.app.shared.resources.sync_error_too_large
import com.sumizuri.app.shared.resources.sync_error_too_new
import com.sumizuri.app.shared.resources.sync_error_unreachable
import com.sumizuri.app.shared.resources.sync_error_username_taken
import com.sumizuri.app.shared.resources.sync_error_wrong_code
import com.sumizuri.app.shared.resources.sync_error_wrong_recovery
import com.sumizuri.app.shared.resources.sync_error_wrong_sign_in
import com.sumizuri.app.shared.resources.sync_error_wrong_two_step
import com.sumizuri.app.shared.resources.sync_hide_password
import com.sumizuri.app.shared.resources.sync_password_mismatch
import com.sumizuri.app.shared.resources.sync_password_short
import com.sumizuri.app.shared.resources.sync_role_admin
import com.sumizuri.app.shared.resources.sync_role_owner
import com.sumizuri.app.shared.resources.sync_role_user
import com.sumizuri.app.shared.resources.sync_show_password
import com.sumizuri.app.shared.resources.sync_two_step_code
import com.sumizuri.app.shared.resources.sync_working
import com.sumizuri.sync.core.Role
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.text.WorkingRow

// The small parts the sync page is built from: the fields of its forms, what it says while it works and what went wrong.
@Composable
internal fun Working() = WorkingRow(stringResource(Res.string.sync_working), Modifier.padding(horizontal = 16.dp, vertical = 8.dp))

// What went wrong, in the app's words where the reason is known, and the server's words otherwise.
@Composable
internal fun Problem(problem: SyncProblem) {
    val known = when (problem.code) {
        SyncProblem.Unreachable -> Res.string.sync_error_unreachable
        SyncProblem.BadAddress -> Res.string.sync_error_bad_address
        SyncProblem.NeedsHttps -> Res.string.sync_error_needs_https
        SyncProblem.TooNew -> Res.string.sync_error_too_new
        SyncProblem.BadAnswer -> Res.string.sync_error_bad_answer
        SyncViewModel.KeyMismatch -> Res.string.sync_error_key_mismatch
        SyncViewModel.BadRecoveryKey -> Res.string.sync_error_bad_recovery_key
        "wrong_code" -> Res.string.sync_error_wrong_code
        "setup_done" -> Res.string.sync_error_setup_done
        "username_taken" -> Res.string.sync_error_username_taken
        "signup_closed" -> Res.string.sync_error_signup_closed
        "invite_needed" -> Res.string.sync_error_invite_needed
        "wrong_sign_in" -> Res.string.sync_error_wrong_sign_in
        "wrong_recovery" -> Res.string.sync_error_wrong_recovery
        "account_disabled" -> Res.string.sync_error_disabled
        "signed_out" -> Res.string.sync_error_signed_out
        "not_allowed" -> Res.string.sync_error_not_allowed
        "not_found" -> Res.string.sync_error_not_found
        "too_large" -> Res.string.sync_error_too_large
        "code_needed" -> Res.string.sync_error_code_needed
        "wrong_two_step" -> Res.string.sync_error_wrong_two_step
        SyncHomeModel.NoLibrary -> Res.string.sync_error_no_library
        else -> null
    }
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(known?.let { stringResource(it) } ?: problem.message.orEmpty(), color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium)
        // For a server that could not be reached, the cause helps find what is wrong.
        if ((problem.code == SyncProblem.Unreachable || problem.code == SyncProblem.BadAnswer) && !problem.message.isNullOrBlank()) {
            Text(problem.message.orEmpty(), color = MaterialTheme.colorScheme.outline, style = MaterialTheme.typography.bodySmall)
        }
    }
}

// The fields of a form are locked while the app works on what was sent.
internal val LocalFormOpen = compositionLocalOf { true }

@Composable
internal fun Form(busy: Boolean = false, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalFormOpen provides !busy) {
        Column(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) { content() }
    }
}

// One line of a form. Enter moves to the next field, or sends the form from the last one, and a password can be shown while it is typed.
@Composable
internal fun Field(
    value: String,
    onChange: (String) -> Unit,
    label: StringResource,
    secret: Boolean = false,
    capitalize: Boolean = false,
    keyboard: KeyboardType = KeyboardType.Text,
    onDone: (() -> Unit)? = null,
) {
    var shown by remember { mutableStateOf(false) }
    AppTextField(
        value,
        onChange,
        Modifier.fillMaxWidth(),
        enabled = LocalFormOpen.current,
        label = { Text(stringResource(label)) },
        singleLine = true,
        visualTransformation = if (secret && !shown) PasswordVisualTransformation() else VisualTransformation.None,
        trailingIcon = if (!secret) {
            null
        } else {
            (
                {
                    IconButton({ shown = !shown }) {
                        Icon(if (shown) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility, stringResource(if (shown) Res.string.sync_hide_password else Res.string.sync_show_password))
                    }
                }
                )
        },
        keyboardOptions = KeyboardOptions(
            capitalization = if (capitalize) KeyboardCapitalization.Characters else KeyboardCapitalization.None,
            autoCorrectEnabled = false,
            keyboardType = if (secret) KeyboardType.Password else keyboard,
            imeAction = if (onDone != null) ImeAction.Done else ImeAction.Next,
        ),
        keyboardActions = KeyboardActions(onDone = { onDone?.invoke() }),
    )
}

// The code of two-step sign in, asked beside the password when the account has it. Only digits are taken.
@Composable
internal fun TwoStepField(shown: Boolean, code: String, onCode: (String) -> Unit, onDone: (() -> Unit)? = null) {
    if (shown) Field(code, { typed -> onCode(typed.filter(Char::isDigit).take(6)) }, Res.string.sync_two_step_code, keyboard = KeyboardType.NumberPassword, onDone = onDone)
}

@Composable
internal fun FormError(problem: StringResource, minPassword: Int) {
    val text = if (problem == Res.string.sync_password_short) stringResource(problem, minPassword) else stringResource(problem)
    Text(text, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
}

@Composable
internal fun Link(label: StringResource, busy: Boolean, onClick: () -> Unit) {
    TextButton(onClick, enabled = !busy) { Text(stringResource(label)) }
}

// The password is checked here, since the server never sees it.
internal fun passwordProblem(password: String, repeat: String, minPassword: Int): StringResource? = when {
    password.length < minPassword -> Res.string.sync_password_short
    password != repeat -> Res.string.sync_password_mismatch
    else -> null
}

internal fun roleLabel(role: Role): StringResource = when (role) {
    Role.Owner -> Res.string.sync_role_owner
    Role.Admin -> Res.string.sync_role_admin
    Role.User -> Res.string.sync_role_user
}

// Two parts of a page beside each other on a wide window, the first a little narrower, and one under the other on a narrow one.
@Composable
internal fun SideBySide(wide: Boolean, first: @Composable () -> Unit, second: @Composable () -> Unit) {
    if (wide) {
        Row(horizontalArrangement = Arrangement.spacedBy(20.dp)) {
            Column(Modifier.weight(0.42f), verticalArrangement = Arrangement.spacedBy(14.dp)) { first() }
            Column(Modifier.weight(0.58f), verticalArrangement = Arrangement.spacedBy(14.dp)) { second() }
        }
    } else {
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            first()
            second()
        }
    }
}
