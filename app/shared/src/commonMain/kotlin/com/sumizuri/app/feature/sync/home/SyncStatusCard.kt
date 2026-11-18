package com.sumizuri.app.feature.sync.home

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CloudDone
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.account.LibrarySyncer
import com.sumizuri.app.data.account.SyncRun
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_last_at
import com.sumizuri.app.shared.resources.sync_last_changes
import com.sumizuri.app.shared.resources.sync_last_failed
import com.sumizuri.app.shared.resources.sync_last_never
import com.sumizuri.app.shared.resources.sync_running
import com.sumizuri.app.shared.resources.sync_state_failed
import com.sumizuri.app.shared.resources.sync_state_never
import com.sumizuri.app.shared.resources.sync_state_ok
import com.sumizuri.app.shared.resources.sync_state_running
import com.sumizuri.app.shared.resources.sync_state_unlinked
import com.sumizuri.app.shared.resources.sync_status_checking
import com.sumizuri.app.shared.resources.sync_status_offline
import com.sumizuri.app.shared.resources.sync_status_online
import com.sumizuri.app.ui.kit.sync.SyncHeadCard
import com.sumizuri.app.ui.kit.sync.SyncMark
import com.sumizuri.app.ui.kit.sync.SyncOther
import com.sumizuri.app.ui.text.agoText
import kotlinx.coroutines.flow.StateFlow
import org.jetbrains.compose.resources.stringResource

// The head of the sync page: how this profile stands with the server in a few words, when it last synced, whether the server answers, and the button that syncs now.
@Composable
internal fun SyncStatusCard(
    home: SyncHome,
    linked: Boolean,
    syncRun: StateFlow<SyncRun>,
    onSyncNow: () -> Unit,
    onCheck: () -> Unit,
) {
    val prefs = LocalAppContainer.current.settings
    val run by syncRun.collectAsStateWithLifecycle()
    val lastAt by remember(prefs) { prefs.text(LibrarySyncer.LastAtKey) }.collectAsStateWithLifecycle(null)
    val title = when {
        !linked -> stringResource(Res.string.sync_state_unlinked)
        run == SyncRun.Running -> stringResource(Res.string.sync_state_running)
        run is SyncRun.Failed -> stringResource(Res.string.sync_state_failed)
        run is SyncRun.Done || lastAt != null -> stringResource(Res.string.sync_state_ok)
        else -> stringResource(Res.string.sync_state_never)
    }
    val line = when (val now = run) {
        SyncRun.Running -> stringResource(Res.string.sync_running)

        is SyncRun.Done -> stringResource(Res.string.sync_last_changes, agoText(now.at), now.changedHere)

        is SyncRun.Failed -> stringResource(Res.string.sync_last_failed, now.problem.message.orEmpty())

        SyncRun.Idle -> lastAt?.toLongOrNull()?.let { stringResource(Res.string.sync_last_at, agoText(it)) }
            ?: stringResource(Res.string.sync_last_never)
    }
    val status = home.status
    val offline = status is ServerStatus.Offline
    val server = when (status) {
        is ServerStatus.Online -> stringResource(Res.string.sync_status_online, status.version)
        is ServerStatus.Offline -> stringResource(Res.string.sync_status_offline)
        ServerStatus.Checking -> stringResource(Res.string.sync_status_checking)
    }
    SyncHeadCard(
        title = title,
        line = line.takeIf { linked },
        mark = when (run) {
            SyncRun.Running -> SyncMark.Running
            is SyncRun.Failed -> SyncMark.Failed
            else -> SyncMark.Ready
        },
        // The server in one quiet line, which a tap asks again when it does not answer.
        other = SyncOther(if (offline) Icons.Outlined.CloudOff else Icons.Outlined.CloudDone, server, alert = offline, onClick = onCheck.takeIf { offline }),
        canSync = linked && home.down == null,
        onSync = onSyncNow,
    )
}
