package com.sumizuri.app.feature.backup

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.SettingsBackupRestore
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.backup_restore_hint
import com.sumizuri.app.shared.resources.backup_restore_title
import com.sumizuri.app.ui.kit.input.rememberFilePicker
import com.sumizuri.app.ui.kit.setting.SettingLinkRow
import okio.Path
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The one row that restores a library: it opens the file chooser, and what kind of backup the file is gets read from the file itself.
@Composable
internal fun RestoreRow(onPicked: (Path) -> Unit) {
    val pick = rememberFilePicker(onPicked = onPicked)
    BackupRow(Res.string.backup_restore_title, Res.string.backup_restore_hint, Icons.Outlined.SettingsBackupRestore) {
        pick()
    }
}

// One way to make or bring back a backup: its icon, what it does, and an arrow.
@Composable
internal fun BackupRow(title: StringResource, hint: StringResource, icon: ImageVector, onClick: () -> Unit) =
    SettingLinkRow(icon, stringResource(title), stringResource(hint), onClick)
