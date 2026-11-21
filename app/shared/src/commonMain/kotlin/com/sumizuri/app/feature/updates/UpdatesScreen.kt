package com.sumizuri.app.feature.updates

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.ExperimentalMaterial3Api
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
import com.sumizuri.app.data.model.feed.UpcomingSide
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.feature.library.top.UpdateFailuresSheet
import com.sumizuri.app.feature.library.top.swipeShelves
import com.sumizuri.app.feature.updates.row.FeedAction
import com.sumizuri.app.feature.updates.row.feed
import com.sumizuri.app.feature.updates.row.feedHeading
import com.sumizuri.app.feature.updates.row.groupByHeading
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_updates_title
import com.sumizuri.app.shared.resources.selection_mark_read
import com.sumizuri.app.shared.resources.undo
import com.sumizuri.app.shared.resources.updates_empty
import com.sumizuri.app.shared.resources.updates_mark_all_message
import com.sumizuri.app.shared.resources.updates_mark_all_title
import com.sumizuri.app.shared.resources.updates_marked
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.page.ListWithSide
import com.sumizuri.app.ui.kit.page.LocalBottomClearance
import com.sumizuri.app.ui.kit.page.PageGrid
import com.sumizuri.app.ui.kit.page.fullSpan
import com.sumizuri.app.ui.kit.page.sideFits
import com.sumizuri.app.ui.kit.scroll.PullRefresh
import com.sumizuri.app.ui.motion.entrance
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The windows the page can open over itself.
private enum class Window { None, Display, Failures, MarkAll, Upcoming }

// The updates page as in the Flutter app. A bar on top, then the note about titles that could not be checked, the kinds and the shelves as tabs, and the new chapters that are not read, under a heading for each day. A list keeps a readable column with what comes next beside it when there is room, and a grid uses the whole width. Pulling the page down checks the library for new chapters, and a sideways swipe changes the shelf unless a swipe is set to mark a row read.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun UpdatesScreen(state: UpdatesState, calls: UpdatesCalls) {
    var window by remember { mutableStateOf(Window.None) }
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val marked = stringResource(Res.string.updates_marked)
    val undo = stringResource(Res.string.undo)
    val prefs = state.prefs
    val grid = prefs.style.isGrid
    // With nothing to swipe between, rows keep their swipe to mark read.
    val rowSwipe = prefs.swipeMarksRead || state.tabs.size < 2

    // Marks the items read and offers to take that back for a moment.
    fun markRead(items: List<UpdateItem>) {
        calls.onMarkRead(items, true)
        scope.launch {
            snackbar.currentSnackbarData?.dismiss()
            if (snackbar.showSnackbar(marked, undo) == SnackbarResult.ActionPerformed) calls.onMarkRead(items, false)
        }
    }

    BoxWithConstraints(Modifier.fillMaxSize()) {
        // A list on a wide window leaves room on its right, where what comes next is shown instead of behind a button.
        val room = maxWidth
        val side = !grid && prefs.upcomingSide != UpcomingSide.Off && sideFits(room)
        // The bar shows how far the check has got, so the pull has no spinner of its own. The bar sits in the middle with the list and its panel, and spans the window over a grid.
        ListWithSide(!grid, side, room, Modifier.fillMaxSize(), top = {
            UpdatesTopBar(
                state,
                onUpcoming = if (side) {
                    null
                } else {
                    { window = Window.Upcoming }
                },
                onMarkAll = {
                    window = Window.MarkAll
                },
                onUpdate = calls.onUpdate,
                onCancelUpdate = calls.onCancelUpdate,
                onDisplay = {
                    window =
                        Window.Display
                },
            )
        }, panel = { place ->
            UpcomingPanel(
                calls.onOpenTitle,
                state.total,
                // The view picked in the panel is kept, so it opens the same next time.
                prefs.upcomingSide != UpcomingSide.List,
                { month ->
                    calls.onPrefs {
                        it.copy(
                            upcomingSide = if (month) UpcomingSide.Calendar else UpcomingSide.List,
                        )
                    }
                },
                place,
            )
        }) {
            PullRefresh(state.progress != null, calls.onUpdate, Modifier.fillMaxSize()) {
                Box(Modifier.fillMaxSize().swipeShelves(state.tabs, state.shelf, !rowSwipe, calls.onShelf)) {
                    // Rows keep their own room, so the line of the timeline runs on from one row to the next.
                    PageGrid(maxCell = state.library.cellWidth.dp, rowGap = if (grid) 14.dp else 0.dp) {
                        fullSpan("header") { UpdatesHeader(state, calls) { window = Window.Failures } }
                        if (state.loaded && state.items.isEmpty()) {
                            fullSpan("empty") {
                                Text(
                                    stringResource(Res.string.updates_empty),
                                    Modifier
                                        .animateItem()
                                        .entrance()
                                        .fillMaxWidth()
                                        .padding(32.dp),
                                    color = MaterialTheme.colorScheme.outline,
                                )
                            }
                        }
                        for ((heading, group) in groupByHeading(state.items, grid, state.now)) {
                            // Every style can mark a whole day or week read from its heading.
                            feedHeading(heading, group, !grid) { markRead(group) }
                            feed(
                                group,
                                prefs.style,
                                prefs.rowStyle,
                                rowSwipe,
                                FeedAction.MarkRead,
                                calls.onOpenTitle,
                                ::markRead,
                            )
                        }
                    }
                }
            }
        }
        SnackbarHost(snackbar, Modifier.align(Alignment.BottomCenter).padding(bottom = LocalBottomClearance.current))
    }
    val close = { window = Window.None }
    when (window) {
        Window.None -> Unit

        Window.Display -> FeedDisplaySheet(
            Res.string.display_updates_title,
            prefs,
            state.library.cellWidth,
            calls.onPrefs,
            calls.onCoverSize,
            close,
            swipeSwitch = true,
        )

        Window.Failures -> UpdateFailuresSheet(state.failures, calls.onOpenTitle, close)

        Window.Upcoming -> UpcomingSheet({ id ->
            close()
            calls.onOpenTitle(id)
        }, close)

        Window.MarkAll -> ConfirmDialog(
            stringResource(Res.string.updates_mark_all_title),
            stringResource(Res.string.updates_mark_all_message),
            stringResource(Res.string.selection_mark_read),
            onConfirm = {
                markRead(state.items)
                close()
            },
            onDismiss = close,
        )
    }
}
