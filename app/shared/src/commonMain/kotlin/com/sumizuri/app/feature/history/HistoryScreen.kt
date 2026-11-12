package com.sumizuri.app.feature.history

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.feature.updates.FeedDisplaySheet
import com.sumizuri.app.feature.updates.row.FeedAction
import com.sumizuri.app.feature.updates.row.FeedDayHeading
import com.sumizuri.app.feature.updates.row.Readable
import com.sumizuri.app.feature.updates.row.feed
import com.sumizuri.app.feature.updates.row.groupByHeading
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_history_title
import com.sumizuri.app.shared.resources.history_empty
import com.sumizuri.app.shared.resources.history_removed
import com.sumizuri.app.shared.resources.history_search_hint
import com.sumizuri.app.shared.resources.history_title
import com.sumizuri.app.shared.resources.library_display
import com.sumizuri.app.shared.resources.library_search
import com.sumizuri.app.shared.resources.undo
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.KindChips
import com.sumizuri.app.ui.kit.chips.hasKindChoice
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.LocalBottomClearance
import com.sumizuri.app.ui.kit.page.PageGrid
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableWhen
import com.sumizuri.app.ui.kit.page.fullSpan
import com.sumizuri.app.ui.motion.entrance
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The history page as in the Flutter app, built like the updates page: a bar on top with a search and the display choices, the kinds as chips, and what was read under a heading for each day. A row is taken out of the history by its button or a swipe, with a way to take that back for a moment.
@Composable
internal fun HistoryScreen(state: HistoryState, calls: HistoryCalls) {
    var displayOpen by remember { mutableStateOf(false) }
    var searchOpen by remember { mutableStateOf(false) }
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val removedText = stringResource(Res.string.history_removed)
    val undo = stringResource(Res.string.undo)
    val prefs = state.prefs
    val grid = prefs.style.isGrid
    val showSearch = !state.library.collapsibleSearch || searchOpen || state.query.isNotEmpty()

    // Takes the items out of the history and offers to bring them back.
    fun remove(items: List<UpdateItem>) {
        calls.onRemove(items)
        scope.launch {
            snackbar.currentSnackbarData?.dismiss()
            if (snackbar.showSnackbar(removedText, undo) == SnackbarResult.ActionPerformed) calls.onUndo()
        }
    }

    Box(Modifier.fillMaxSize()) {
        ReadableWhen(!grid) {
            Column(Modifier.fillMaxSize()) {
                PageTopBar(stringResource(Res.string.history_title)) {
                    if (state.library.collapsibleSearch) {
                        IconButton({
                            searchOpen = !searchOpen
                            if (!searchOpen) calls.onQuery("")
                        }) { Icon(if (searchOpen) Icons.Outlined.SearchOff else Icons.Outlined.Search, stringResource(Res.string.library_search)) }
                    }
                    IconButton({ displayOpen = true }) { Icon(Icons.Outlined.GridView, stringResource(Res.string.library_display)) }
                }
                PageGrid(Modifier.weight(1f), maxCell = state.library.cellWidth.dp) {
                    fullSpan { Header(state, calls, showSearch) }
                    if (state.loaded && state.items.isEmpty()) {
                        fullSpan { Text(stringResource(Res.string.history_empty), Modifier.entrance().fillMaxWidth().padding(32.dp), color = MaterialTheme.colorScheme.outline) }
                    }
                    for ((heading, group) in groupByHeading(state.items, grid, state.now)) {
                        fullSpan { Readable(!grid) { FeedDayHeading(heading, group.first().at, group.size, onMarkAllRead = null) } }
                        feed(group, prefs.style, prefs.rowStyle, !grid, FeedAction.Remove, calls.onOpenTitle, ::remove)
                    }
                }
            }
        }
        SnackbarHost(snackbar, Modifier.align(Alignment.BottomCenter).padding(bottom = LocalBottomClearance.current))
    }
    if (displayOpen) FeedDisplaySheet(Res.string.display_history_title, prefs, state.library.cellWidth, calls.onPrefs, calls.onCoverSize, { displayOpen = false })
}

// What stands above the feed and scrolls with it: the search when it is open, and the kinds as chips when what was read is of more than one kind.
@Composable
private fun Header(state: HistoryState, calls: HistoryCalls, showSearch: Boolean) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (showSearch) AppSearchBar(state.query, calls.onQuery, stringResource(Res.string.history_search_hint), pauseMs = 150, historyPlace = "history")
        if (hasKindChoice(state.kinds, state.kind)) ChipRow { KindChips(state.kind, state.kinds, calls.onKind) }
    }
}
