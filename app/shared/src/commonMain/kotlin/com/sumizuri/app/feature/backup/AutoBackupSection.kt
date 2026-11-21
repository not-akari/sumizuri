package com.sumizuri.app.feature.backup

import androidx.compose.foundation.layout.Column
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Backup
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.backup.AutoBackups
import com.sumizuri.app.data.backup.SavedBackup
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.backup_auto_days
import com.sumizuri.app.shared.resources.backup_auto_every
import com.sumizuri.app.shared.resources.backup_auto_hint
import com.sumizuri.app.shared.resources.backup_auto_keep
import com.sumizuri.app.shared.resources.backup_auto_now
import com.sumizuri.app.shared.resources.backup_auto_now_hint
import com.sumizuri.app.shared.resources.backup_auto_off
import com.sumizuri.app.shared.resources.backup_auto_open
import com.sumizuri.app.shared.resources.backup_auto_section
import com.sumizuri.app.shared.resources.backup_auto_weekly
import com.sumizuri.app.shared.resources.backup_delete_confirm
import com.sumizuri.app.shared.resources.backup_delete_message
import com.sumizuri.app.shared.resources.backup_saved_delete
import com.sumizuri.app.shared.resources.backup_saved_empty
import com.sumizuri.app.shared.resources.backup_saved_line
import com.sumizuri.app.shared.resources.backup_saved_restore
import com.sumizuri.app.shared.resources.backup_saved_save
import com.sumizuri.app.shared.resources.backup_saved_section
import com.sumizuri.app.shared.resources.backup_stop
import com.sumizuri.app.shared.resources.backup_writing
import com.sumizuri.app.ui.kit.canOpenFolders
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.input.rememberFileSaver
import com.sumizuri.app.ui.kit.openFolder
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// How often the app may back up by itself, in days. Zero is never.
private val DayChoices = listOf(0, 1, 3, 7)

// How many backups the app may keep.
private val KeepChoices = listOf(3, 5, 10, 20)

// The backups the app makes by itself: how often and how many it keeps, one made now, and the list of the ones it kept, each of which can be restored, saved somewhere else or deleted.
@Composable
internal fun AutoBackupSections(onRestore: (SavedBackup) -> Unit) {
    val container = LocalAppContainer.current
    val backups = container.autoBackups
    val settings = container.settings
    val scope = rememberCoroutineScope()
    val days by remember(settings) { settings.number(SettingKey.AutoBackupDays, 0) }.collectAsStateWithLifecycle(0)
    val keep by remember(settings) {
        settings.number(SettingKey.AutoBackupKeep, AutoBackups.DefaultKeep)
    }.collectAsStateWithLifecycle(AutoBackups.DefaultKeep)
    val saved by backups.saved.collectAsStateWithLifecycle()
    val making by backups.making.collectAsStateWithLifecycle()
    var open by remember { mutableStateOf<SavedBackup?>(null) }
    var deleting by remember { mutableStateOf<SavedBackup?>(null) }
    val save = rememberFileSaver { }
    LaunchedEffect(backups) { backups.refresh() }

    SettingsSection(Res.string.backup_auto_section, Res.string.backup_auto_hint) {
        padded {
            ChoiceSetting(
                Res.string.backup_auto_every,
                DayChoices,
                days.takeIf { it in DayChoices } ?: DayChoices.first(),
                { daysWords(it) },
                icon = Icons.Outlined.Schedule,
            ) { picked ->
                scope.launch { settings.setNumber(SettingKey.AutoBackupDays, picked) }
            }
        }
        padded {
            ChoiceSetting(
                Res.string.backup_auto_keep,
                KeepChoices,
                keep.takeIf { it in KeepChoices } ?: AutoBackups.DefaultKeep,
                { it.toString() },
                icon = Icons.Outlined.Inventory2,
            ) { picked ->
                scope.launch { settings.setNumber(SettingKey.AutoBackupKeep, picked) }
            }
        }
        row {
            val progress = making
            SettingRow(
                stringResource(Res.string.backup_auto_now),
                subtitle =
                progress?.let { (done, total) -> stringResource(Res.string.backup_writing, done, total) }
                    ?: stringResource(Res.string.backup_auto_now_hint),
                leading = { SettingIcon(Icons.Outlined.Backup) },
                trailing = progress?.let {
                    {
                        TextButton(
                            backups::stop,
                        ) { Text(stringResource(Res.string.backup_stop)) }
                    }
                },
                onClick = if (progress == null) ({ scope.launch { backups.makeNow() } }) else null,
            )
        }
        // A computer can show the folder, where the backups can also be copied by hand.
        if (canOpenFolders()) {
            row {
                SettingRow(
                    stringResource(
                        Res.string.backup_auto_open,
                    ),
                    subtitle = backups.folder.toString(),
                    leading = {
                        SettingIcon(Icons.Outlined.FolderOpen)
                    },
                    onClick = { openFolder(backups.folder.toString()) },
                )
            }
        }
    }

    SettingsSection(Res.string.backup_saved_section) {
        if (saved.isEmpty()) padded { Text(stringResource(Res.string.backup_saved_empty)) }
        for (backup in saved) {
            row {
                SettingRow(
                    backup.name,
                    subtitle = stringResource(
                        Res.string.backup_saved_line,
                        agoText(backup.at),
                        byteSizeText(backup.bytes),
                    ),
                    leading = { SettingIcon(Icons.Outlined.History) },
                    onClick = { open = backup },
                )
            }
        }
    }

    open?.let { backup ->
        AppDialog(
            onDismissRequest = { open = null },
            title = { Text(backup.name) },
            // The actions sit one under the other, so they never wrap on a phone.
            text = {
                Column {
                    Text(stringResource(Res.string.backup_saved_line, agoText(backup.at), byteSizeText(backup.bytes)))
                    TextButton({
                        open = null
                        onRestore(backup)
                    }) { Text(stringResource(Res.string.backup_saved_restore)) }
                    TextButton({
                        open = null
                        save(backup.name, backup.path)
                    }) { Text(stringResource(Res.string.backup_saved_save)) }
                    TextButton({
                        open = null
                        deleting = backup
                    }) { Text(stringResource(Res.string.backup_saved_delete)) }
                }
            },
            confirmButton = {},
            dismissButton = { CancelButton({ open = null }) },
        )
    }
    deleting?.let { backup ->
        ConfirmDialog(
            stringResource(Res.string.backup_saved_delete),
            stringResource(Res.string.backup_delete_message, backup.name),
            stringResource(Res.string.backup_delete_confirm),
            onConfirm = {
                deleting = null
                scope.launch { backups.delete(backup) }
            },
            onDismiss = { deleting = null },
        )
    }
}

@Composable
private fun daysWords(days: Int): String = when (days) {
    0 -> stringResource(Res.string.backup_auto_off)
    7 -> stringResource(Res.string.backup_auto_weekly)
    else -> pluralStringResource(Res.plurals.backup_auto_days, days, days)
}
