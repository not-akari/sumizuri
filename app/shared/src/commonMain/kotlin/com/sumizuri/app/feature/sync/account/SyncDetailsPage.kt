package com.sumizuri.app.feature.sync.account

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.RestartAlt
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.account.ConflictKind
import com.sumizuri.app.data.account.SyncConflict
import com.sumizuri.app.data.account.SyncRun
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_conflict_bookmark
import com.sumizuri.app.shared.resources.sync_conflict_favorite
import com.sumizuri.app.shared.resources.sync_conflict_library
import com.sumizuri.app.shared.resources.sync_conflict_place
import com.sumizuri.app.shared.resources.sync_conflict_read
import com.sumizuri.app.shared.resources.sync_conflict_setting
import com.sumizuri.app.shared.resources.sync_conflict_shelves
import com.sumizuri.app.shared.resources.sync_conflict_source
import com.sumizuri.app.shared.resources.sync_details
import com.sumizuri.app.shared.resources.sync_details_hint
import com.sumizuri.app.shared.resources.sync_history_empty
import com.sumizuri.app.shared.resources.sync_history_kept
import com.sumizuri.app.shared.resources.sync_history_section
import com.sumizuri.app.shared.resources.sync_history_sent
import com.sumizuri.app.shared.resources.sync_scratch
import com.sumizuri.app.shared.resources.sync_scratch_confirm
import com.sumizuri.app.shared.resources.sync_scratch_hint
import com.sumizuri.app.shared.resources.sync_scratch_message
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.sync.RunLogRow
import com.sumizuri.app.ui.kit.sync.RunLogSection
import org.jetbrains.compose.resources.stringResource

// The syncs of this profile, newest first, with what each did or why it failed, and the way to sync again from scratch.
@Composable
internal fun SyncDetailsRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_details, onBack, subtitle = Res.string.sync_details_hint) {
        val account by LocalProfiles.current.syncAccounts.account
            .collectAsStateWithLifecycle()
        val signed = account ?: return@SettingsPageFrame
        val model = rememberSyncHome(signed)
        val home by model.home.collectAsStateWithLifecycle()
        val run by model.syncRun.collectAsStateWithLifecycle()
        val history by model.syncHistory.collectAsStateWithLifecycle(emptyList())
        var asking by remember { mutableStateOf(false) }
        // Each sync says what it did, or why it failed, and the conflicts it settled under it.
        RunLogSection(
            stringResource(Res.string.sync_history_section),
            stringResource(Res.string.sync_history_empty),
            history.map { entry ->
                val head = when {
                    !entry.ok -> entry.message

                    entry.sent -> stringResource(
                        Res.string.sync_history_sent,
                        entry.changedHere,
                        (entry.bytes / 1024).toInt(),
                    )

                    else -> stringResource(Res.string.sync_history_kept, entry.changedHere)
                }
                RunLogRow(entry.at, entry.ok, listOf(head) + entry.conflicts.map { conflictLine(it) })
            },
        )
        SettingsSection {
            row {
                SettingRow(
                    stringResource(Res.string.sync_scratch),
                    subtitle = stringResource(Res.string.sync_scratch_hint),
                    leading = { SettingIcon(Icons.Outlined.RestartAlt) },
                    onClick = if (run == SyncRun.Running || home.busy) null else ({ asking = true }),
                )
            }
        }
        if (asking) {
            ConfirmDialog(
                stringResource(Res.string.sync_scratch),
                stringResource(Res.string.sync_scratch_message),
                stringResource(Res.string.sync_scratch_confirm),
                onConfirm = {
                    asking = false
                    model.syncFromScratch()
                },
                onDismiss = { asking = false },
            )
        }
        if (home.busy) Working()
        home.problem?.let { Problem(it) }
    }
}

// One conflict of a sync, as a line that says what was kept.
@Composable
private fun conflictLine(conflict: SyncConflict): String = stringResource(
    when (conflict.kind) {
        ConflictKind.Library -> Res.string.sync_conflict_library
        ConflictKind.Favorite -> Res.string.sync_conflict_favorite
        ConflictKind.Read -> Res.string.sync_conflict_read
        ConflictKind.Place -> Res.string.sync_conflict_place
        ConflictKind.Bookmark -> Res.string.sync_conflict_bookmark
        ConflictKind.Shelves -> Res.string.sync_conflict_shelves
        ConflictKind.Source -> Res.string.sync_conflict_source
        else -> Res.string.sync_conflict_setting
    },
    conflict.name,
)
