package com.sumizuri.app.feature.library

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.library.top.ConnectionLostNotice
import com.sumizuri.app.feature.library.top.FailuresNotice
import com.sumizuri.app.feature.library.top.LibraryControls
import com.sumizuri.app.feature.library.top.LibrarySearchRow
import com.sumizuri.app.feature.library.top.MissingSourcesNotice
import com.sumizuri.app.feature.library.top.NoticeAction
import com.sumizuri.app.feature.library.top.SearchSourcesRow
import com.sumizuri.app.feature.library.top.ShelfTabs
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.library_show_all
import com.sumizuri.app.shared.resources.library_show_them
import com.sumizuri.app.shared.resources.library_unreachable
import com.sumizuri.app.ui.motion.Unfold
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// What stands above the covers, which scrolls with them: the notes, the search, the shelves as tabs and the row of chips for the order, the kinds and the filters.
@Composable
internal fun LibraryHeader(
    state: LibraryState,
    calls: LibraryCalls,
    showSearch: Boolean,
    onSort: () -> Unit,
    onFailures: () -> Unit,
) {
    val prefs = state.prefs
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Unfold(state.unreachable > 0 && (state.unreachable > prefs.unreachableDismissed || state.onlyUnreachable)) {
            // The note leads to where the sources are mended, and can also narrow the grid to the titles it is about. Closing it keeps it away until more titles are lost.
            MissingSourcesNotice(
                pluralStringResource(Res.plurals.library_unreachable, state.unreachable, state.unreachable),
                calls.onOpenMissing,
                extra = NoticeAction(
                    stringResource(
                        if (state.onlyUnreachable) Res.string.library_show_all else Res.string.library_show_them,
                    ),
                    calls.onToggleUnreachable,
                ),
                onDismiss = if (state.onlyUnreachable) {
                    null
                } else {
                    (
                        {
                            calls.onPrefs { it.copy(unreachableDismissed = state.unreachable) }
                        }
                        )
                },
            )
        }
        Unfold(state.failures.isNotEmpty() && !state.selecting) {
            FailuresNotice(state.failures.size, onFailures, calls.onDismissFailures)
        }
        Unfold(state.unchecked > 0 && state.progress == null && !state.selecting) {
            ConnectionLostNotice(state.unchecked, calls.onUpdate, calls.onDismissFailures)
        }
        Unfold(showSearch) {
            LibrarySearchRow(state.query, calls.onQuery)
        }
        // The same words can be looked for in every source, for a title the library does not have yet.
        Unfold(showSearch && state.query.isNotBlank() && !state.selecting) {
            SearchSourcesRow(state.query) { calls.onSearchSources(state.query.trim()) }
        }
        ShelfTabs(state, calls::onShelf, calls.onOpenShelves)
        LibraryControls(state, calls, onSort)
    }
}
