package com.sumizuri.app.feature.sync.account

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.RestartAlt
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.data.account.BigChoice
import com.sumizuri.app.data.account.ConflictKind
import com.sumizuri.app.data.account.SyncConflict
import com.sumizuri.app.data.account.SyncLogEntry
import com.sumizuri.app.data.account.SyncRun
import com.sumizuri.app.data.account.syncReport
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.text.dateText
import com.sumizuri.app.data.text.localOffsetMillis
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.home.BigChangeCard
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_conflict_bookmark
import com.sumizuri.app.shared.resources.sync_conflict_favorite
import com.sumizuri.app.shared.resources.sync_conflict_library
import com.sumizuri.app.shared.resources.sync_conflict_list
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
import com.sumizuri.app.shared.resources.sync_report
import com.sumizuri.app.shared.resources.sync_report_copied
import com.sumizuri.app.shared.resources.sync_report_hint
import com.sumizuri.app.shared.resources.sync_scratch
import com.sumizuri.app.shared.resources.sync_scratch_confirm
import com.sumizuri.app.shared.resources.sync_scratch_hint
import com.sumizuri.app.shared.resources.sync_scratch_message
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
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
        var shown by remember { mutableStateOf<SyncLogEntry?>(null) }
        val copy = rememberCopyText()
        var copied by remember { mutableStateOf(false) }
        val waiting by model.waiting.collectAsStateWithLifecycle()
        waiting?.let {
            BigChangeCard(it, !home.busy, { model.resolve(BigChoice.KeepMine) }, { model.resolve(BigChoice.Allow) })
        }
        // Each sync says what it did, or why it failed, and the conflicts it settled under it.
        SyncRunSection(
            stringResource(Res.string.sync_history_section),
            stringResource(Res.string.sync_history_empty),
            history,
        ) { shown = it }
        // The recent syncs as text, for asking for help.
        if (history.isNotEmpty()) {
            SettingsSection {
                row {
                    SettingRow(
                        stringResource(Res.string.sync_report),
                        subtitle = if (copied) {
                            stringResource(
                                Res.string.sync_report_copied,
                            )
                        } else {
                            stringResource(Res.string.sync_report_hint)
                        },
                        leading = { SettingIcon(Icons.Outlined.ContentCopy) },
                        onClick = {
                            copy(syncReport(history, BuildInfo.Version, ::reportTime))
                            copied = true
                        },
                    )
                }
            }
        }
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
        shown?.let { entry -> SyncRunSheet(entry) { shown = null } }
        if (home.busy) Working()
        home.problem?.let { Problem(it) }
    }
}

// One conflict of a sync, as a line that says what was kept.
@Composable
internal fun conflictLine(conflict: SyncConflict): String = stringResource(
    when (conflict.kind) {
        ConflictKind.Library -> Res.string.sync_conflict_library
        ConflictKind.Favorite -> Res.string.sync_conflict_favorite
        ConflictKind.Read -> Res.string.sync_conflict_read
        ConflictKind.Place -> Res.string.sync_conflict_place
        ConflictKind.Bookmark -> Res.string.sync_conflict_bookmark
        ConflictKind.Shelves -> Res.string.sync_conflict_shelves
        ConflictKind.Source -> Res.string.sync_conflict_source
        ConflictKind.List -> Res.string.sync_conflict_list
        else -> Res.string.sync_conflict_setting
    },
    conflict.name,
)

// A time for the report, as the date and the hour and minute here.
private fun reportTime(at: Long): String {
    val minute = (at + localOffsetMillis(at)) / 60_000 % 1440
    return dateText(at) + " " + (minute / 60).toString().padStart(2, (48).toChar()) + ":" +
        (minute % 60).toString().padStart(2, (48).toChar())
}
