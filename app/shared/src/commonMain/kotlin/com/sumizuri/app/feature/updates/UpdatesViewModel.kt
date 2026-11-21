package com.sumizuri.app.feature.updates

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.core.perf.timed
import com.sumizuri.app.data.db.chapter.UpdateRow
import com.sumizuri.app.data.library.CategoryRepository
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.SourceState
import com.sumizuri.app.data.model.feed.FeedPrefs
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.data.model.feed.coarseHeading
import com.sumizuri.app.data.model.feed.listHeading
import com.sumizuri.app.data.model.feed.mergeByGroup
import com.sumizuri.app.data.model.feed.mergeSameDay
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.LibraryEntry
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.data.model.library.shelf.ShelfContext
import com.sumizuri.app.data.model.library.shelf.forKind
import com.sumizuri.app.data.settings.FeedPrefsRepository
import com.sumizuri.app.data.settings.LibraryPrefsRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.sync.TitleSync
import com.sumizuri.app.data.sync.UpdateFailure
import com.sumizuri.app.data.sync.UpdateProgress
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.library.UncategorizedShelf
import com.sumizuri.app.feature.library.top.shelfTabs
import com.sumizuri.app.feature.updates.row.feed
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// The choices made on the page itself, which are not kept between runs.
private data class Look(val kind: Kind? = null, val shelf: Long? = null)

private class Content(val rows: List<UpdateRow>, val entries: List<LibraryEntry>, val sourceNames: Map<String, String>, val hidden: Int, val total: Int)

private class Around(val progress: UpdateProgress?, val failures: Pair<List<UpdateFailure>, Int>, val look: Look)

private class Settings(val shelves: List<Category>, val library: LibraryPrefs, val feed: FeedPrefs)

// The new chapters of the library that are not read, folded by day, narrowed by kind and shelf, and the marking of them as read.
class UpdatesViewModel(
    private val library: LibraryRepository,
    private val sync: TitleSync,
    private val feedPrefs: FeedPrefsRepository,
    private val libraryPrefs: LibraryPrefsRepository,
    shelves: CategoryRepository,
    sources: SourceRepository,
) : ViewModel() {
    private val look = MutableStateFlow(Look())

    private val content = combine(library.unreadUpdates, library.entries(), sources.installed, library.unreachableUnreadTitles, library.unreadUpdateCount) { rows, entries, installed, hidden, total ->
        Content(rows, entries, installed.associate { it.id to it.name }, hidden, total)
    }

    private val settings = combine(shelves.categories, libraryPrefs.prefs, feedPrefs.prefs, ::Settings)

    private val around = combine(sync.progress, combine(sync.failures, sync.unchecked, ::Pair), look, ::Around)

    val state: StateFlow<UpdatesState> = combine(content, settings, around) { now, set, besides -> timed("Updates list") { build(now, set, besides) } }
        .flowOn(Dispatchers.Default)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), UpdatesState())

    // The list of the last build with what it came from. A step of the check for new chapters changes only the progress, so the list is kept and not folded and filtered again.
    private class Listed(val now: Content, val set: Settings, val look: Look, val state: UpdatesState)
    private var listed: Listed? = null

    private fun build(now: Content, set: Settings, besides: Around): UpdatesState {
        val last = listed
        val base = if (last != null && last.now === now && last.set === set && last.look == besides.look) last.state else listFor(now, set, besides.look).also { listed = Listed(now, set, besides.look, it) }
        return base.copy(progress = besides.progress, failures = besides.failures.first, unchecked = besides.failures.second)
    }

    private fun listFor(now: Content, set: Settings, typed: Look): UpdatesState {
        val clock = nowMillis()
        val context = ShelfContext(now.sourceNames, clock)
        // Only the shelves made for the open kind show, with the ones for every kind.
        val shelves = set.shelves.forKind(typed.kind)
        val hasUncategorized = shelves.isNotEmpty() && now.entries.any { entry -> shelves.none { it.holds(entry, context) } }
        val tabs = shelfTabs(set.library, shelves, hasUncategorized).takeIf { shelves.isNotEmpty() }.orEmpty()
        // A shelf that has no tab any more, because it was deleted or its tab was hidden, falls back to the first tab.
        val shelf = typed.shelf.takeIf { it in tabs } ?: tabs.firstOrNull()
        // A title whose source cannot be reached has chapters that cannot be opened, so they are not listed as new. The rows leave those titles out already, and this keeps a title out for the moment between its source going and the rows catching up.
        val titles = now.entries.filter { it.title.sourceState == SourceState.Ready }.associate { it.title.id to it.title }
        val entryOf = now.entries.associateBy { it.title.id }
        var items = mergeSameDay(now.rows, titles)
        // A title is one row for each stretch the page has a heading for, so one that came out every week is not a row under every week's day.
        items = mergeByGroup(items, clock, if (set.feed.style.isGrid) ::coarseHeading else ::listHeading)
        val kinds = items.mapTo(HashSet()) { it.title.kind }
        items = items.filter { item ->
            (typed.kind == null || item.title.kind == typed.kind) && when (shelf) {
                null -> true
                UncategorizedShelf -> entryOf[item.title.id]?.let { entry -> set.shelves.none { it.holds(entry, context) } } ?: true
                else -> entryOf[item.title.id]?.let { entry -> set.shelves.firstOrNull { it.id == shelf }?.holds(entry, context) } == true
            }
        }
        return UpdatesState(true, items, typed.kind, shelf, tabs, shelves, set.feed, set.library, null, emptyList(), now.hidden, clock, 0, kinds, now.total)
    }

    fun onKind(kind: Kind?) = look.update { it.copy(kind = kind) }

    fun onShelf(shelf: Long?) = look.update { it.copy(shelf = shelf) }

    fun onPrefs(change: (FeedPrefs) -> FeedPrefs) {
        viewModelScope.launch { feedPrefs.update(change) }
    }

    fun onCoverSize(width: Int) {
        viewModelScope.launch { libraryPrefs.update { it.copy(cellWidth = width) } }
    }

    // Marks the chapters of the items read, or not read again for the undo.
    fun onMarkRead(items: List<UpdateItem>, read: Boolean) {
        viewModelScope.launch { for (item in items) library.setReadMany(item.title.id, item.chapterIds, read) }
    }

    fun onUpdate() {
        viewModelScope.launch { sync.refreshLibrary() }
    }

    fun onCancelUpdate() = sync.cancelRefresh()

    fun onDismissFailures() = sync.clearFailures()
}
