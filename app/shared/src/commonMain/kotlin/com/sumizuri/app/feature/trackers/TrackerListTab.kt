package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.tracker.OnTracker
import com.sumizuri.app.data.tracker.TrackStatus
import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.data.tracker.TrackerProblem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_on_count
import com.sumizuri.app.shared.resources.tracker_on_empty
import com.sumizuri.app.shared.resources.tracker_on_hint
import com.sumizuri.app.shared.resources.tracker_on_loading
import com.sumizuri.app.ui.kit.text.NoteText
import com.sumizuri.app.ui.kit.text.WorkingRow
import kotlinx.coroutines.CancellationException
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The entries of the list of the person on the tracker that no title here is linked to. Each can be looked for in the sources, and its page on the tracker opens with a tap. The list is read when the tab opens.
@Composable
internal fun OnTrackerTab(tracker: TrackerId, account: TrackerAccount) {
    val sync = LocalAppContainer.current.trackerSync
    var entries by remember(tracker, account.userId) { mutableStateOf<List<OnTracker>?>(null) }
    var problem by remember { mutableStateOf<TrackerProblem?>(null) }
    var open by remember { mutableStateOf<OnTracker?>(null) }
    val tools = rememberTitleTools(tracker)
    LaunchedEffect(tracker, account.userId) {
        problem = null
        entries = try {
            sync.unlinkedOn(tracker)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            problem = TrackerProblem.from(error)
            emptyList()
        }
    }
    // A list that could not be read says why and nothing else, so it never looks empty.
    problem?.let {
        ProblemLine(it, tracker)
        return
    }
    val all = entries
    if (all == null) {
        WorkingRow(stringResource(Res.string.tracker_on_loading))
        return
    }
    if (all.isEmpty()) {
        NoteText(stringResource(Res.string.tracker_on_empty, tracker.label))
        return
    }
    NoteText(stringResource(Res.string.tracker_on_hint, tracker.label))
    val shown = remember(all, tools.key) { tools.entries(all) }
    TitleToolsBar(tools, all.map { it.kind }.toSet(), statusCounts(all.map { it.entry.status }), TitleSort.entries)
    NoteText(pluralStringResource(Res.plurals.tracker_on_count, shown.size, shown.size))
    TitleGrid(shown, "only on") { item ->
        GridItem(
            item.media.id,
            item.media.name,
            item.kind,
            item.media.cover,
            entryLine(item),
            onClick = { open = item },
        )
    }
    // An entry linked or removed in its sheet leaves the list.
    open?.let { item ->
        OnTrackerSheet(tracker, item, onDone = {
            entries = entries?.filter { it !== item }
            open = null
        }, onDismiss = { open = null })
    }
}

// How an entry stands on the tracker: its status and how far it is.
@Composable
internal fun entryLine(item: OnTracker): String = statusLabel(TrackStatus.of(item.entry.status), item.kind) + " · " +
    progressText(item.entry.progress, item.media.total, item.kind)
