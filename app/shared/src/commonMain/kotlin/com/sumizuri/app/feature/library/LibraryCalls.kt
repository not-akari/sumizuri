package com.sumizuri.app.feature.library

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.data.model.library.LibrarySection
import com.sumizuri.app.data.model.library.SortRule

// Everything the library page can ask for, so the page is given one thing and not twenty.
internal class LibraryCalls(
    val onQuery: (String) -> Unit,
    val onKind: (Kind?) -> Unit,
    val onToggleUnreachable: () -> Unit,
    val onPrefs: ((LibraryPrefs) -> LibraryPrefs) -> Unit,
    val onShelfRule: (id: Long, rule: SortRule?, status: Status?) -> Unit,
    val onSelect: (Long) -> Unit,
    val onClearSelection: () -> Unit,
    val onSelectAll: () -> Unit,
    val onInvert: () -> Unit,
    val onMarkRead: (Boolean) -> Unit,
    val onFavorite: (Boolean) -> Unit,
    val onRemove: () -> Unit,
    val onShelves: (add: Set<Long>, remove: Set<Long>) -> Unit,
    // Puts titles on a shelf they were dragged onto.
    val onDropOnShelf: (titles: Set<Long>, shelf: Long) -> Unit,
    val onCreateShelf: suspend (String) -> Long?,
    val onOpenTitle: (Long) -> Unit,
    val onOpenShelves: () -> Unit,
    val onMove: (Long) -> Unit,
    val onMigrate: (List<Long>) -> Unit,
    val onUpdate: () -> Unit,
    val onCancelUpdate: () -> Unit,
    val onDismissFailures: () -> Unit,
    val onRandom: () -> Unit,
    // Opens the whole page a part of the library stands for.
    val onSeeAll: (LibrarySection) -> Unit,
    // Opens the page where the titles whose source is missing or off are mended.
    val onOpenMissing: () -> Unit,
    // Opens the page of the chapters saved to the device and on the way.
    val onOpenDownloads: () -> Unit,
    // Opens the search of every source for the words typed in the search of the library.
    val onSearchSources: (String) -> Unit,
    // Opens the chapter a title goes on from, as its continue button would.
    val onContinue: (Long) -> Unit,
) {
    // Opens one shelf, or all the titles for null.
    fun onShelf(id: Long?) = onPrefs { it.copy(category = id) }
}

// What can be done to the picked titles of the library.
internal class LibraryPickCalls(
    val onClose: () -> Unit,
    val onSelectAll: () -> Unit,
    val onInvert: () -> Unit,
    val onMarkRead: (Boolean) -> Unit,
    val onFavorite: (Boolean) -> Unit,
    val onShelves: () -> Unit,
    val onLists: () -> Unit,
    val onMove: () -> Unit,
    val onMigrate: () -> Unit,
    val onRemove: () -> Unit,
)
