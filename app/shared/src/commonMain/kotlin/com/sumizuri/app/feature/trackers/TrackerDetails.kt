package com.sumizuri.app.feature.trackers

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.tracker.TrackerConflict
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.data.tracker.TrackerLogEntry
import com.sumizuri.app.data.tracker.TrackerProblem
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_history_empty
import com.sumizuri.app.shared.resources.tracker_conflict_here
import com.sumizuri.app.shared.resources.tracker_conflict_there
import com.sumizuri.app.shared.resources.tracker_details_hint
import com.sumizuri.app.shared.resources.tracker_details_title
import com.sumizuri.app.shared.resources.tracker_field_progress
import com.sumizuri.app.shared.resources.tracker_field_score
import com.sumizuri.app.shared.resources.tracker_field_status
import com.sumizuri.app.shared.resources.tracker_log_done
import com.sumizuri.app.shared.resources.tracker_log_gone
import com.sumizuri.app.ui.kit.sync.RunLogRow
import com.sumizuri.app.ui.kit.sync.RunLogSection
import org.jetbrains.compose.resources.stringResource

// The past syncs of each tracker this profile is signed in to, newest first, in the same list as the details of sync.
@Composable
internal fun TrackerDetailsRoute(onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val accounts by remember(container) { container.trackers.signedIn }.collectAsStateWithLifecycle(emptyMap())
    SettingsPageFrame(Res.string.tracker_details_title, onBack, subtitle = Res.string.tracker_details_hint) {
        for (tracker in TrackerId.entries.filter { it in accounts }) {
            val log by remember(tracker) { container.trackerSync.log(tracker) }.collectAsStateWithLifecycle(emptyList())
            RunLogSection(
                tracker.label,
                stringResource(Res.string.sync_history_empty),
                log.map { trackerLogRow(it, tracker) },
            )
        }
    }
}

// What one sync did: how many titles changed here and were sent, the entries removed on the tracker, and each conflict with the side that was kept.
@Composable
private fun trackerLogRow(entry: TrackerLogEntry, tracker: TrackerId): RunLogRow {
    if (!entry.ok) {
        return RunLogRow(
            entry.at,
            false,
            listOf(problemText(TrackerProblem.of(entry.message), tracker, signedIn = true)),
        )
    }
    val lines = listOf(stringResource(Res.string.tracker_log_done, entry.changedHere, entry.sent)) +
        (if (entry.gone > 0) listOf(stringResource(Res.string.tracker_log_gone, entry.gone)) else emptyList()) +
        entry.conflicts.map { conflictLine(it) }
    return RunLogRow(entry.at, true, lines)
}

@Composable
private fun conflictLine(conflict: TrackerConflict): String {
    val field = stringResource(
        when (conflict.field) {
            "progress" -> Res.string.tracker_field_progress
            "score" -> Res.string.tracker_field_score
            else -> Res.string.tracker_field_status
        },
    )
    return stringResource(
        if (conflict.keptHere) Res.string.tracker_conflict_here else Res.string.tracker_conflict_there,
        conflict.name,
        field,
    )
}
