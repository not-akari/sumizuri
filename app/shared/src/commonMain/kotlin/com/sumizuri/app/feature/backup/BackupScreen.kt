package com.sumizuri.app.feature.backup

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Save
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.backup_cancelling
import com.sumizuri.app.shared.resources.backup_confirm_action
import com.sumizuri.app.shared.resources.backup_confirm_message
import com.sumizuri.app.shared.resources.backup_confirm_title
import com.sumizuri.app.shared.resources.backup_create_hint
import com.sumizuri.app.shared.resources.backup_create_section
import com.sumizuri.app.shared.resources.backup_create_title
import com.sumizuri.app.shared.resources.backup_done_added
import com.sumizuri.app.shared.resources.backup_done_failed
import com.sumizuri.app.shared.resources.backup_done_matched
import com.sumizuri.app.shared.resources.backup_done_title
import com.sumizuri.app.shared.resources.backup_matching
import com.sumizuri.app.shared.resources.backup_migrate_ask
import com.sumizuri.app.shared.resources.backup_migrate_later
import com.sumizuri.app.shared.resources.backup_migrate_now
import com.sumizuri.app.shared.resources.backup_password_label
import com.sumizuri.app.shared.resources.backup_password_title
import com.sumizuri.app.shared.resources.backup_problem_password
import com.sumizuri.app.shared.resources.backup_progress
import com.sumizuri.app.shared.resources.backup_reading
import com.sumizuri.app.shared.resources.backup_restore_settings
import com.sumizuri.app.shared.resources.backup_section
import com.sumizuri.app.shared.resources.backup_stopped_title
import com.sumizuri.app.shared.resources.backup_unlock
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.ok
import com.sumizuri.app.shared.resources.settings_backup
import com.sumizuri.app.shared.resources.settings_backup_hint
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.input.CheckRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.progressTimeText
import org.jetbrains.compose.resources.stringResource

// The page where a library is brought back from a backup: one row that opens a file, whose kind the app reads from the file itself.
@Composable
internal fun BackupScreen(state: BackupState, make: MakeState, choices: MakeChoices, calls: BackupCalls) {
    var making by remember { mutableStateOf(false) }
    SettingsPageFrame(Res.string.settings_backup, calls.onBack, subtitle = Res.string.settings_backup_hint) {
        SettingsSection(Res.string.backup_create_section) {
            row {
                BackupRow(Res.string.backup_create_title, Res.string.backup_create_hint, Icons.Outlined.Save) {
                    making =
                        true
                }
            }
        }
        AutoBackupSections(onRestore = { calls.onPicked(it.path) })
        SettingsSection(Res.string.backup_section) {
            row { RestoreRow(calls.onPicked) }
        }
    }
    if (making) {
        MakeBackupDialog(choices, { picked, password ->
            making = false
            calls.onMake(picked, password)
        }, { making = false })
    }
    MakeDialogs(make, calls)
    BackupDialogs(state, calls)
}

// What the restore says while it goes: the file is read, a password is asked, the backup is shown for a yes, the count of titles, and the end.
@Composable
internal fun BackupDialogs(state: BackupState, calls: BackupCalls) {
    when (state) {
        BackupState.Idle -> Unit

        BackupState.Reading -> AppDialog(
            onDismissRequest = {},
            confirmButton = {},
            text = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    InkCircularProgressIndicator(Modifier.padding(end = 16.dp))
                    Text(stringResource(Res.string.backup_reading))
                }
            },
        )

        is BackupState.Password -> {
            var password by remember { mutableStateOf("") }
            AppDialog(
                onDismissRequest = calls.onDismiss,
                title = { Text(stringResource(Res.string.backup_password_title)) },
                text = {
                    Column {
                        AppTextField(password, {
                            password = it
                        }, Modifier.fillMaxWidth(), singleLine = true, label = {
                            Text(stringResource(Res.string.backup_password_label))
                        }, visualTransformation = PasswordVisualTransformation())
                        if (state.wrong) {
                            Text(
                                stringResource(Res.string.backup_problem_password),
                                Modifier.padding(top = 8.dp),
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                    }
                },
                confirmButton = {
                    InkButton({
                        calls.onPassword(password)
                    }, enabled = password.isNotEmpty()) { Text(stringResource(Res.string.backup_unlock)) }
                },
                dismissButton = { CancelButton(calls.onDismiss) },
            )
        }

        is BackupState.Confirm -> {
            // A backup that carries app settings asks whether they should replace the ones here.
            var withSettings by remember { mutableStateOf(true) }
            AppDialog(
                onDismissRequest = calls.onDismiss,
                title = { Text(stringResource(Res.string.backup_confirm_title)) },
                text = {
                    Column {
                        Text(stringResource(Res.string.backup_confirm_message, state.titles, state.shelves))
                        if (state.settings > 0) {
                            CheckRow(
                                stringResource(Res.string.backup_restore_settings),
                                withSettings,
                                { withSettings = it },
                                Modifier.padding(top = 8.dp),
                            )
                        }
                    }
                },
                confirmButton = {
                    InkButton(
                        { calls.onConfirm(withSettings) },
                    ) { Text(stringResource(Res.string.backup_confirm_action)) }
                },
                dismissButton = { CancelButton(calls.onDismiss) },
            )
        }

        is BackupState.Running -> AppDialog(
            onDismissRequest = {},
            confirmButton = {},
            text = {
                Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                    InkCircularProgressIndicator(progress = {
                        if (state.total >
                            0
                        ) {
                            state.done.toFloat() / state.total
                        } else {
                            0f
                        }
                    })
                    Spacer(Modifier.height(16.dp))
                    Text(
                        stringResource(
                            if (state.matching) Res.string.backup_matching else Res.string.backup_progress,
                            state.done,
                            state.total,
                        ),
                    )
                    // How long it has run and about how long it has left, guessed from how fast it went so far.
                    progressTimeText(state.done, state.total)?.let {
                        Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
                    }
                    TextButton(calls.onCancel, enabled = !state.cancelling) {
                        Text(stringResource(if (state.cancelling) Res.string.backup_cancelling else Res.string.cancel))
                    }
                }
            },
        )

        is BackupState.Done -> AppDialog(
            onDismissRequest = calls.onDismiss,
            title = {
                Text(
                    stringResource(
                        if (state.result.cancelled) Res.string.backup_stopped_title else Res.string.backup_done_title,
                    ),
                )
            },
            text = {
                Column(
                    verticalArrangement = androidx.compose.foundation.layout.Arrangement
                        .spacedBy(8.dp),
                ) {
                    Text(stringResource(Res.string.backup_done_added, state.result.added, state.result.skipped))
                    if (state.result.failed >
                        0
                    ) {
                        Text(stringResource(Res.string.backup_done_failed, state.result.failed))
                    }
                    state.matched?.let { Text(stringResource(Res.string.backup_done_matched, it)) }
                    if (state.waiting.isNotEmpty()) {
                        Text(
                            stringResource(Res.string.backup_migrate_ask, state.waiting.size),
                        )
                    }
                }
            },
            confirmButton = {
                if (state.waiting.isEmpty()) {
                    TextButton(calls.onDismiss) { Text(stringResource(Res.string.ok)) }
                } else {
                    TextButton({
                        calls.onDismiss()
                        calls.onMigrate(state.waiting)
                    }) { Text(stringResource(Res.string.backup_migrate_now)) }
                }
            },
            dismissButton = if (state.waiting.isEmpty()) {
                null
            } else {
                (
                    {
                        TextButton(calls.onDismiss) { Text(stringResource(Res.string.backup_migrate_later)) }
                    }
                    )
            },
        )

        is BackupState.Failed -> AppDialog(
            onDismissRequest = calls.onDismiss,
            text = { Text(stringResource(state.problem.text)) },
            confirmButton = { InkButton(calls.onDismiss) { Text(stringResource(Res.string.ok)) } },
        )
    }
}
