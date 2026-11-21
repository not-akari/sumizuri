package com.sumizuri.app.feature.backup

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.backup.BackupCompression
import com.sumizuri.app.data.backup.BackupPart
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.backup_compression
import com.sumizuri.app.shared.resources.backup_compression_fast
import com.sumizuri.app.shared.resources.backup_compression_none
import com.sumizuri.app.shared.resources.backup_compression_small
import com.sumizuri.app.shared.resources.backup_create_action
import com.sumizuri.app.shared.resources.backup_create_parts
import com.sumizuri.app.shared.resources.backup_create_title
import com.sumizuri.app.shared.resources.backup_not_saved
import com.sumizuri.app.shared.resources.backup_part_library
import com.sumizuri.app.shared.resources.backup_part_logins
import com.sumizuri.app.shared.resources.backup_part_logins_hint
import com.sumizuri.app.shared.resources.backup_part_settings
import com.sumizuri.app.shared.resources.backup_part_source_settings
import com.sumizuri.app.shared.resources.backup_part_sources
import com.sumizuri.app.shared.resources.backup_password_mismatch
import com.sumizuri.app.shared.resources.backup_password_optional
import com.sumizuri.app.shared.resources.backup_password_repeat
import com.sumizuri.app.shared.resources.backup_password_warning
import com.sumizuri.app.shared.resources.backup_saved
import com.sumizuri.app.shared.resources.backup_stop
import com.sumizuri.app.shared.resources.backup_write_failed
import com.sumizuri.app.shared.resources.backup_writing
import com.sumizuri.app.shared.resources.ok
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.input.CheckRow
import com.sumizuri.app.ui.kit.input.rememberFileSaver
import org.jetbrains.compose.resources.stringResource

// The window where a backup is set up: what goes in, how much it is squeezed, and an optional password typed twice.
@Composable
internal fun MakeBackupDialog(choices: MakeChoices, onMake: (MakeChoices, String?) -> Unit, onDismiss: () -> Unit) {
    var parts by remember(choices) { mutableStateOf(choices.parts) }
    var compression by remember(choices) { mutableStateOf(choices.compression) }
    var password by remember { mutableStateOf("") }
    var repeat by remember { mutableStateOf("") }
    val matches = password.isEmpty() || password == repeat
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.backup_create_title)) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                AppSectionLabel(Res.string.backup_create_parts)
                CheckRow(stringResource(Res.string.backup_part_library), checked = true, onChange = {}, enabled = false)
                for ((part, label) in listOf(
                    BackupPart.Sources to Res.string.backup_part_sources,
                    BackupPart.SourceSettings to Res.string.backup_part_source_settings,
                    BackupPart.Settings to Res.string.backup_part_settings,
                    BackupPart.Logins to Res.string.backup_part_logins,
                )) {
                    CheckRow(stringResource(label), part in parts, { on ->
                        parts =
                            if (on) parts + part else parts - part
                    })
                }
                if (BackupPart.Logins in
                    parts
                ) {
                    Text(
                        stringResource(Res.string.backup_part_logins_hint),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
                Spacer(Modifier.height(8.dp))
                AppSectionLabel(Res.string.backup_compression)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    for ((choice, label) in listOf(
                        BackupCompression.None to Res.string.backup_compression_none,
                        BackupCompression.Fast to Res.string.backup_compression_fast,
                        BackupCompression.Small to Res.string.backup_compression_small,
                    )) {
                        SoftChip(compression == choice, { compression = choice }, { Text(stringResource(label)) })
                    }
                }
                Spacer(Modifier.height(8.dp))
                AppTextField(password, {
                    password = it
                }, Modifier.fillMaxWidth(), singleLine = true, label = {
                    Text(stringResource(Res.string.backup_password_optional))
                }, visualTransformation = PasswordVisualTransformation())
                if (password.isNotEmpty()) {
                    AppTextField(
                        repeat,
                        { repeat = it },
                        Modifier.fillMaxWidth(),
                        singleLine = true,
                        label = { Text(stringResource(Res.string.backup_password_repeat)) },
                        visualTransformation = PasswordVisualTransformation(),
                        isError = repeat.isNotEmpty() && !matches,
                        supportingText = {
                            Text(
                                stringResource(
                                    if (repeat.isNotEmpty() &&
                                        !matches
                                    ) {
                                        Res.string.backup_password_mismatch
                                    } else {
                                        Res.string.backup_password_warning
                                    },
                                ),
                            )
                        },
                    )
                }
            }
        },
        confirmButton = {
            InkButton({
                onMake(
                    MakeChoices(parts, compression),
                    password.ifEmpty {
                        null
                    },
                )
            }, enabled = matches) { Text(stringResource(Res.string.backup_create_action)) }
        },
        dismissButton = { CancelButton(onDismiss) },
    )
}

// What the making of a backup says while it goes: the count of titles written, the place to save it, and how it ended.
@Composable
internal fun MakeDialogs(make: MakeState, calls: BackupCalls) {
    val save = rememberFileSaver(calls.onSaved)
    when (make) {
        MakeState.Idle -> Unit

        is MakeState.Writing -> AppDialog(
            onDismissRequest = {},
            confirmButton = {},
            text = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    InkCircularProgressIndicator(Modifier.padding(end = 16.dp))
                    Text(stringResource(Res.string.backup_writing, make.done, make.total))
                }
            },
            dismissButton = { InkOutlinedButton(calls.onStopMaking) { Text(stringResource(Res.string.backup_stop)) } },
        )

        // The window to pick where the file goes opens once, as soon as the file is made.
        is MakeState.Ready -> LaunchedEffect(make) { save(make.name, make.file) }

        is MakeState.Saved -> Ended(
            stringResource(Res.string.backup_saved, make.summary.titles, make.summary.chapters, make.summary.shelves),
            calls.onMakeDismiss,
        )

        MakeState.NotSaved -> Ended(stringResource(Res.string.backup_not_saved), calls.onMakeDismiss)

        MakeState.Failed -> Ended(stringResource(Res.string.backup_write_failed), calls.onMakeDismiss)
    }
}

@Composable
private fun Ended(text: String, onDismiss: () -> Unit) {
    AppDialog(onDismissRequest = onDismiss, text = {
        Text(text)
    }, confirmButton = { InkButton(onDismiss) { Text(stringResource(Res.string.ok)) } })
}
