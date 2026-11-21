package com.sumizuri.app.feature.updates

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.feed.FeedPrefs
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.data.sync.UpdateFailure
import com.sumizuri.app.data.sync.UpdateProgress

// The updates page: the new chapters that are not read, narrowed by kind and shelf, with how the page is set.
data class UpdatesState(
    val loaded: Boolean = false,
    val items: List<UpdateItem> = emptyList(),
    val kind: Kind? = null,
    // The shelf that is open, as the tabs have it: null for all the titles.
    val shelf: Long? = null,
    // The tabs of the shelves in order, which is empty when there are no shelves.
    val tabs: List<Long?> = emptyList(),
    val shelves: List<Category> = emptyList(),
    val prefs: FeedPrefs = FeedPrefs(),
    val library: LibraryPrefs = LibraryPrefs(),
    val progress: UpdateProgress? = null,
    val failures: List<UpdateFailure> = emptyList(),
    // How many titles have new chapters but are left out, because their source is not installed or is switched off.
    val hidden: Int = 0,
    // The time the page was worked out at, for the headings.
    val now: Long = 0,
    // How many titles the last check left unchecked because the connection was lost and did not come back.
    val unchecked: Int = 0,
    // The kinds the new chapters are of, before the kind is narrowed, so the kinds are only offered when there is a choice.
    val kinds: Set<Kind> = emptySet(),
    // How many new chapters are not read in all, which can be more than the page lists.
    val total: Int = 0,
)

// What the updates page can ask for.
class UpdatesCalls(
    val onOpenTitle: (Long) -> Unit,
    val onKind: (Kind?) -> Unit,
    val onShelf: (Long?) -> Unit,
    val onPrefs: ((FeedPrefs) -> FeedPrefs) -> Unit,
    val onCoverSize: (Int) -> Unit,
    val onMarkRead: (List<UpdateItem>, Boolean) -> Unit,
    val onUpdate: () -> Unit,
    val onCancelUpdate: () -> Unit,
    val onDismissFailures: () -> Unit,
    val onOpenMissing: () -> Unit,
)
