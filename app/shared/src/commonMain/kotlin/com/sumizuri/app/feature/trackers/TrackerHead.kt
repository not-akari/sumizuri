package com.sumizuri.app.feature.trackers

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.data.tracker.TrackerProblem
import com.sumizuri.app.data.tracker.TrackerRun
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_last_failed
import com.sumizuri.app.shared.resources.sync_last_never
import com.sumizuri.app.shared.resources.sync_state_failed
import com.sumizuri.app.shared.resources.sync_state_never
import com.sumizuri.app.shared.resources.sync_state_ok
import com.sumizuri.app.shared.resources.sync_state_running
import com.sumizuri.app.shared.resources.tracker_last_done
import com.sumizuri.app.ui.kit.sync.SyncHeadCard
import com.sumizuri.app.ui.kit.sync.SyncMark
import com.sumizuri.app.ui.text.agoText
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource
// How the sync with the tracker stands, when it last ran and what it did, and the button that syncs now.
@Composable
internal fun TrackerHead(tracker: TrackerId, account: TrackerAccount) {
    val sync = LocalAppContainer.current.trackerSync
    val scope = rememberCoroutineScope()
    val runs by sync.run.collectAsStateWithLifecycle()
    val log by remember(tracker) { sync.log(tracker) }.collectAsStateWithLifecycle(emptyList())
    val run = runs[tracker] ?: TrackerRun.Idle
    val last = log.firstOrNull()
    val title = when {
        run == TrackerRun.Running -> stringResource(Res.string.sync_state_running)

        run is TrackerRun.Failed || (run == TrackerRun.Idle && last?.ok == false) -> stringResource(
            Res.string.sync_state_failed,
        )

        last != null -> stringResource(Res.string.sync_state_ok)

        else -> stringResource(Res.string.sync_state_never)
    }
    val line = when {
        run is TrackerRun.Failed -> stringResource(
            Res.string.sync_last_failed,
            problemText(run.problem, tracker, signedIn = true),
        )

        last == null -> stringResource(Res.string.sync_last_never)

        !last.ok -> stringResource(
            Res.string.sync_last_failed,
            problemText(TrackerProblem.of(last.message), tracker, signedIn = true),
        )

        else -> stringResource(Res.string.tracker_last_done, agoText(last.at), last.changedHere, last.sent)
    }
    SyncHeadCard(
        title = title,
        line = line,
        mark = when {
            run == TrackerRun.Running -> SyncMark.Running
            run is TrackerRun.Failed || (run == TrackerRun.Idle && last?.ok == false) -> SyncMark.Failed
            else -> SyncMark.Ready
        },
        other = null,
        canSync = true,
        onSync = { scope.launch { runCatching { sync.sync(tracker, whole = true) } } },
    )
}
