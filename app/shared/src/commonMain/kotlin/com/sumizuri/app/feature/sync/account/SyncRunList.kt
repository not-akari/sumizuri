package com.sumizuri.app.feature.sync.account

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.North
import androidx.compose.material.icons.outlined.South
import androidx.compose.material.icons.outlined.SyncProblem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.account.SyncLogEntry
import com.sumizuri.app.data.account.SyncWhy
import com.sumizuri.app.data.account.durationText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_history_kept
import com.sumizuri.app.shared.resources.sync_history_sent
import com.sumizuri.app.shared.resources.sync_run_inout
import com.sumizuri.app.shared.resources.sync_run_nothing
import com.sumizuri.app.shared.resources.sync_run_repeated
import com.sumizuri.app.shared.resources.sync_run_when
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.agoText
import org.jetbrains.compose.resources.stringResource

// The syncs of this profile, newest first. Each says what started it, or why it failed, with when and how long under it, and how many titles came in and went out on the right. A tap opens it in full.
@Composable
internal fun SyncRunSection(title: String, empty: String, entries: List<SyncLogEntry>, onOpen: (SyncLogEntry) -> Unit) {
    SettingsSection(title) {
        if (entries.isEmpty()) {
            padded {
                Text(
                    empty,
                    Modifier.fillMaxWidth().padding(vertical = 4.dp),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
        }
        for (entry in entries) {
            row {
                SettingRow(
                    runTitle(entry),
                    subtitle = runWhen(entry),
                    subtitleLines = 1,
                    leading = { SettingIcon(runIcon(entry)) },
                    trailing = if (entry.ok && entry.why != SyncWhy.Unknown) ({ InOut(entry) }) else null,
                    onClick = { onOpen(entry) },
                )
            }
        }
    }
}

// What a sync was about in one line: what started it, why it failed, or the plain line of an entry kept before the details were.
@Composable
internal fun runTitle(entry: SyncLogEntry): String = when {
    !entry.ok -> entry.message
    entry.why != SyncWhy.Unknown -> whyText(entry.why)
    entry.sent -> stringResource(Res.string.sync_history_sent, entry.changedHere, (entry.bytes / 1024).toInt())
    else -> stringResource(Res.string.sync_history_kept, entry.changedHere)
}

// When a sync ran and how long it took, with how often a failure came again and whether nothing changed.
@Composable
internal fun runWhen(entry: SyncLogEntry): String {
    if (entry.why == SyncWhy.Unknown) return agoText(entry.at)
    val base = stringResource(Res.string.sync_run_when, agoText(entry.at), durationText(entry.tookMs))
    return when {
        !entry.ok && entry.times > 1 -> whyText(entry.why) + ", " +
            stringResource(Res.string.sync_run_repeated, entry.times, agoText(entry.lastAt))

        !entry.ok -> whyText(entry.why) + ", " + base

        entry.here.empty && entry.there.empty -> base + ", " + stringResource(Res.string.sync_run_nothing).lowercase()

        else -> base
    }
}

private fun runIcon(entry: SyncLogEntry): ImageVector = when {
    !entry.ok -> Icons.Outlined.ErrorOutline
    entry.conflicts.isNotEmpty() -> Icons.Outlined.SyncProblem
    else -> Icons.Outlined.CheckCircle
}

// How many titles came in and went out, as two small counts with arrows.
@Composable
private fun InOut(entry: SyncLogEntry) {
    val came = entry.here.titleCount + entry.here.lists
    val went = entry.there.titleCount + entry.there.lists
    if (came == 0 && went == 0) return
    val said = stringResource(Res.string.sync_run_inout, came, went)
    Row(Modifier.semantics { contentDescription = said }, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Count(Icons.Outlined.South, came)
        Count(Icons.Outlined.North, went)
    }
}

@Composable
private fun Count(icon: ImageVector, count: Int) {
    val colors = MaterialTheme.colorScheme
    Row(
        Modifier
            .background(colors.surfaceContainerHighest, CircleShape)
            .padding(horizontal = 8.dp, vertical = 3.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        Icon(icon, null, Modifier.size(13.dp), tint = if (count > 0) colors.primary else colors.outline)
        Text(
            count.toString(),
            style = MaterialTheme.typography.labelMedium,
            color = if (count >
                0
            ) {
                colors.onSurface
            } else {
                colors.outline
            },
        )
    }
}
