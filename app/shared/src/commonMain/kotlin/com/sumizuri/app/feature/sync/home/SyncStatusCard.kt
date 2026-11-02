package com.sumizuri.app.feature.sync.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CloudDone
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.account.LibrarySyncer
import com.sumizuri.app.data.account.SyncRun
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_last_at
import com.sumizuri.app.shared.resources.sync_last_changes
import com.sumizuri.app.shared.resources.sync_last_failed
import com.sumizuri.app.shared.resources.sync_last_never
import com.sumizuri.app.shared.resources.sync_now
import com.sumizuri.app.shared.resources.sync_running
import com.sumizuri.app.shared.resources.sync_state_failed
import com.sumizuri.app.shared.resources.sync_state_never
import com.sumizuri.app.shared.resources.sync_state_ok
import com.sumizuri.app.shared.resources.sync_state_running
import com.sumizuri.app.shared.resources.sync_state_unlinked
import com.sumizuri.app.shared.resources.sync_status_checking
import com.sumizuri.app.shared.resources.sync_status_offline
import com.sumizuri.app.shared.resources.sync_status_online
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.AppCard
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
    val colors = MaterialTheme.colorScheme
    val failed = run is SyncRun.Failed
    val title = when {
        !linked -> stringResource(Res.string.sync_state_unlinked)
        run == SyncRun.Running -> stringResource(Res.string.sync_state_running)
        failed -> stringResource(Res.string.sync_state_failed)
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
    val server = when (status) {
        is ServerStatus.Online -> stringResource(Res.string.sync_status_online, status.version)
        is ServerStatus.Offline -> stringResource(Res.string.sync_status_offline)
        ServerStatus.Checking -> stringResource(Res.string.sync_status_checking)
    }
    AppCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                // A round mark that says the state at a glance: a turning circle while it syncs.
                Box(
                    Modifier
                        .size(
                            52.dp,
                        ).background(
                            if (failed) colors.errorContainer else colors.primary.copy(alpha = 0.14f),
                            CircleShape,
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    if (run == SyncRun.Running) {
                        InkCircularProgressIndicator(Modifier.size(26.dp), strokeWidth = 3.dp)
                    } else {
                        Icon(
                            if (failed) Icons.Outlined.ErrorOutline else Icons.Outlined.Sync,
                            null,
                            Modifier.size(26.dp),
                            tint = if (failed) colors.onErrorContainer else colors.primary,
                        )
                    }
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    if (linked &&
                        run != SyncRun.Running
                    ) {
                        Text(line, style = MaterialTheme.typography.bodySmall, color = colors.onSurfaceVariant)
                    }
                }
            }
            // The server in one quiet line with a dot, which a tap asks again when it does not answer.
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(
                        MaterialTheme.shapes.small,
                    ).clickable(enabled = status is ServerStatus.Offline, onClick = onCheck),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    if (status is ServerStatus.Offline) Icons.Outlined.CloudOff else Icons.Outlined.CloudDone,
                    null,
                    Modifier.size(16.dp),
                    tint = if (status is ServerStatus.Offline) colors.error else colors.outline,
                )
                Box(Modifier.width(8.dp))
                Text(server, Modifier.weight(1f), style = MaterialTheme.typography.labelMedium, color = colors.outline)
            }
            InkButton(
                onSyncNow,
                Modifier.fillMaxWidth().height(46.dp),
                enabled = linked && run != SyncRun.Running && home.down == null,
            ) {
                Icon(Icons.Outlined.Sync, null, Modifier.size(18.dp))
                Box(Modifier.width(8.dp))
                Text(stringResource(Res.string.sync_now))
            }
        }
    }
}
