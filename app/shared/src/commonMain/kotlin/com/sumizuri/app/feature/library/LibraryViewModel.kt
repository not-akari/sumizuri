package com.sumizuri.app.feature.library

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.core.flow.atMostEvery
import com.sumizuri.app.core.perf.timed
import com.sumizuri.app.data.library.CategoryRepository
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.FeedItem
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.SourceState
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.LibraryEntry
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.data.model.library.LibrarySearch
import com.sumizuri.app.data.model.library.LibrarySection
import com.sumizuri.app.data.model.library.QuickFilter
import com.sumizuri.app.data.model.library.SearchTarget
import com.sumizuri.app.data.model.library.SortRule
import com.sumizuri.app.data.model.library.SourceBrief
import com.sumizuri.app.data.model.library.shelf.ShelfContext
import com.sumizuri.app.data.model.library.shelf.forKind
import com.sumizuri.app.data.settings.LibraryPrefsRepository
import com.sumizuri.app.data.settings.SessionRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.sync.TitleSync
import com.sumizuri.app.data.sync.UpdateFailure
import com.sumizuri.app.data.sync.UpdateProgress
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.library.top.settled
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlin.random.Random

// The library is ordered again at most this often while its titles keep changing, as they do for each title a check for new chapters saves.
private const val ReorderGapMs = 500L

// What the page knows besides the library itself.
private class Around(
    val sources: Map<String, SourceBrief>,
    val progress: UpdateProgress?,
    val failures: List<UpdateFailure>,
    val history: List<FeedItem>,
    val updates: List<FeedItem>,
    // How many titles the last check left unchecked because the connection was lost.
    val unchecked: Int,
)

// The choices and the shelves as they are now, with the titles of the library.
private class Shown(val prefs: LibraryPrefs, val categories: List<Category>, val entries: List<LibraryEntry>)

// What the person typed and picked on the page itself, which is not kept between runs, except the kind.
private data class Look(
    val query: String = "",
    val kind: Kind? = null,
    val onlyUnreachable: Boolean = false,
    val selected: Set<Long> = emptySet(),
)

// The library: the titles the person saved, narrowed by kind, shelf, quick filters and a search, put in the order chosen, with the rows above them and the picking of titles for bulk actions.
@OptIn(ExperimentalCoroutinesApi::class)
class LibraryViewModel(
    private val library: LibraryRepository,
    private val session: SessionRepository,
    private val prefsRepository: LibraryPrefsRepository,
    private val shelves: CategoryRepository,
    sources: SourceRepository,
    private val sync: TitleSync,
) : ViewModel() {
    private val look = MutableStateFlow(Look())

    // A number for the random order, new each time the library is opened.
    private val seed = Random.nextLong()

    // The shelf that is open can order its titles in its own way, and then the times for that order are the ones to read.
    private val shown = combine(
        prefsRepository.prefs,
        shelves.categories,
        ::Pair,
    ).flatMapLatest { (saved, categories) ->
        val prefs = saved.settled(categories)
        library.entries(fieldsInUse(prefs, categories)).atMostEvery(ReorderGapMs).map { Shown(prefs, categories, it) }
    }

    private val around =
        combine(
            sources.installed,
            sync.progress,
            combine(sync.failures, sync.unchecked, ::Pair),
            library.history,
            library.updates,
        ) { installed, progress, (failures, unchecked), history, updates ->
            Around(
                installed.associate { it.id to SourceBrief(it.name, it.lang) },
                progress,
                failures,
                history,
                updates,
                unchecked,
            )
        }

    val state: StateFlow<LibraryState> = combine(shown, around, look) { now, besides, typed ->
        timed("Library list") {
            build(now, besides, typed)
        }
    }
        // Filtering and ordering tens of thousands of titles must not take the time of the screen, so it is done off the main thread.
        .flowOn(Dispatchers.Default)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), LibraryState())

    init {
        viewModelScope.launch {
            look.update {
                it.copy(
                    kind = session.libraryKind()?.let { code -> Kind.fromCode(code) },
                )
            }
        }
    }

    // The filtered and ordered titles of the last build, with what they were worked out from. Picking titles or a step of the check for new chapters changes the state but not the list, so the list is kept and not filtered and ordered again.
    private class Listing(
        val shown: Shown,
        val sources: Map<String, SourceBrief>,
        val query: String,
        val kind: Kind?,
        val onlyUnreachable: Boolean,
        val titles: List<Title>,
        val here: Set<Long>,
        val unreachable: Int,
        val hasUncategorized: Boolean,
        val kinds: Set<Kind>,
    )

    private var listing: Listing? = null

    // What a search looks in for each title, made once for the titles and sources it was made from and kept while typing.
    private var targets: Triple<Shown, Map<String, SourceBrief>, Map<Long, SearchTarget>>? = null

    private fun searchTargets(
        now: Shown,
        sources: Map<String, SourceBrief>,
        shelfNames: Map<Long, String>,
        sourceNames: Map<String, String>,
    ): Map<Long, SearchTarget> {
        targets?.let { (shown, from, made) -> if (shown === now && from == sources) return made }
        val made = now.entries.associate { it.title.id to searchTargetOf(it, shelfNames, sourceNames) }
        targets = Triple(now, sources, made)
        return made
    }

    private fun listingFor(
        now: Shown,
        besides: Around,
        typed: Look,
        categories: List<Category>,
        prefs: LibraryPrefs,
        rule: SortRule,
    ): Listing {
        listing?.let { last ->
            if (last.shown === now && last.sources == besides.sources && last.query == typed.query &&
                last.kind == typed.kind &&
                last.onlyUnreachable == typed.onlyUnreachable
            ) {
                return last
            }
        }
        val entries = now.entries
        val shelfNames = now.categories.associate { it.id to it.name.lowercase() }
        val search = LibrarySearch.parse(typed.query)
        // Titles are on a shelf when they were put there and when they meet its conditions.
        val context = ShelfContext.of(besides.sources.mapValues { it.value.name }, nowMillis(), entries)
        val only = categories.firstOrNull { it.id == prefs.category }?.status
        val sourceNames = besides.sources.mapValues { it.value.name.lowercase() }
        val here = HashSet<Long>()
        val shownEntries = entries.filter { entry ->
            val title = entry.title
            val inPlace =
                (typed.kind == null || title.kind == typed.kind) &&
                    isOnShelf(prefs.category, entry, now.categories, context)
            if (inPlace) here += title.id
            inPlace &&
                (!typed.onlyUnreachable || title.sourceState != SourceState.Ready) &&
                (only == null || title.status == only) &&
                prefs.filters.all { passesFilter(it, title, prefs.favoritesEnabled) } &&
                (
                    search.isEmpty ||
                        search.matches(searchTargets(now, besides.sources, shelfNames, sourceNames).getValue(title.id))
                    )
        }
        val order = OrderContext(besides.sources.mapValues { it.value.name }, seed, prefs.pinFavorites, prefs.pinUnread)
        return Listing(
            shown = now,
            sources = besides.sources,
            query = typed.query,
            kind = typed.kind,
            onlyUnreachable = typed.onlyUnreachable,
            titles = shownEntries.orderedBy(rule, order).map { it.title },
            here = here,
            unreachable = entries.count { it.title.sourceState != SourceState.Ready },
            hasUncategorized =
            categories.isNotEmpty() && entries.any { entry -> categories.none { it.holds(entry, context) } },
            kinds = entries.mapTo(HashSet()) { it.title.kind },
        ).also { listing = it }
    }

    private fun build(now: Shown, besides: Around, typed: Look): LibraryState {
        // Only the shelves made for the open kind show, with the ones for every kind.
        val categories = now.categories.forKind(typed.kind)
        val prefs = now.prefs.settled(categories)
        val entries = now.entries
        val rule = effectiveRule(prefs, typed.kind, categories.firstOrNull { it.id == prefs.category })
        val list = listingFor(now, besides, typed, categories, prefs, rule)
        val here = list.here
        val picked = if (typed.selected.isEmpty()) emptyList() else entries.filter { it.title.id in typed.selected }
        // The shelves the picked titles can all go on: the ones for their kind, or for every kind when they are of several kinds.
        val pickedKinds = picked.map { it.title.kind }.toSet()
        val pickShelves = now.categories.filter { it.kind == null || pickedKinds.all { kind -> kind == it.kind } }
        return LibraryState(
            loaded = true,
            query = typed.query,
            kind = typed.kind,
            titles = list.titles,
            rule = rule,
            total = entries.size,
            unreachable = list.unreachable,
            onlyUnreachable = typed.onlyUnreachable,
            prefs = prefs,
            categories = categories,
            pickShelves = pickShelves,
            pickKind = pickedKinds.singleOrNull(),
            hasUncategorized = list.hasUncategorized,
            kinds = list.kinds,
            selected = typed.selected,
            selectedShelves = picked.flatMap { it.categories }.groupingBy { it }.eachCount(),
            progress = besides.progress,
            failures = besides.failures,
            unchecked = besides.unchecked,
            recent = libraryRowOf(besides.history, here, prefs.countOf(LibrarySection.Continue)),
            updates = libraryRowOf(besides.updates, here, prefs.countOf(LibrarySection.Updates)),
            history = libraryRowOf(besides.history, here, prefs.countOf(LibrarySection.History)),
            sources = besides.sources,
        )
    }

    // Checks the library for new chapters, or only the titles shown when a shelf is open.
    fun onUpdate() {
        val only = state.value
            .takeIf { it.prefs.category != null }
            ?.titles
            ?.map { it.id }
            ?.toSet()
        viewModelScope.launch { sync.refreshLibrary(only) }
    }

    fun onCancelUpdate() = sync.cancelRefresh()

    fun onDismissFailures() = sync.clearFailures()

    // The id of a title picked by chance from the ones shown, or null when there are none.
    fun randomTitle(): Long? = state.value.titles
        .randomOrNull()
        ?.id

    fun onQuery(text: String) = look.update { it.copy(query = text) }

    fun onKind(value: Kind?) {
        look.update { it.copy(kind = value) }
        viewModelScope.launch {
            session.setLibraryKind(value?.code)
            // A shelf of another kind that was open falls back to one this kind has.
            val visible = shelves.categories.first().forKind(value)
            prefsRepository.update { it.settled(visible) }
        }
    }

    fun onToggleUnreachable() = look.update { it.copy(onlyUnreachable = !it.onlyUnreachable) }

    // Changes any of the choices about the look and the order, which are saved.
    fun onPrefs(change: (LibraryPrefs) -> LibraryPrefs) {
        viewModelScope.launch { prefsRepository.update(change) }
    }

    // What the open shelf is ordered by and shows, with a null rule for the order of the library.
    fun onShelfRule(id: Long, rule: SortRule?, status: Status?) {
        viewModelScope.launch { shelves.setRule(id, rule, status) }
    }

    fun onSelect(id: Long) = look.update {
        it.copy(
            selected = if (id in
                it.selected
            ) {
                it.selected - id
            } else {
                it.selected + id
            },
        )
    }

    fun onClearSelection() = look.update { it.copy(selected = emptySet()) }

    // Picks every title shown, or none when all of them are picked already.
    fun onSelectAll() {
        val ids = state.value.titles
            .map { it.id }
            .toSet()
        look.update { it.copy(selected = if (it.selected == ids) emptySet() else ids) }
    }

    fun onInvertSelection() {
        val ids = state.value.titles
            .map { it.id }
            .toSet()
        look.update { it.copy(selected = ids - it.selected) }
    }

    fun onMarkRead(read: Boolean) {
        val ids = look.value.selected
        viewModelScope.launch {
            for (id in ids) library.setReadMany(id, library.chapterIds(id), read)
            onClearSelection()
        }
    }

    fun onFavorite(favorite: Boolean) {
        val ids = look.value.selected
        viewModelScope.launch {
            library.setFavorite(ids, favorite)
            onClearSelection()
        }
    }

    fun onRemove() {
        val ids = look.value.selected
        viewModelScope.launch {
            library.removeFromLibrary(ids)
            onClearSelection()
        }
    }

    // Puts the picked titles on the shelves to add and takes them off the shelves to remove.
    fun onShelves(add: Set<Long>, remove: Set<Long>) {
        val ids = look.value.selected
        viewModelScope.launch {
            shelves.change(ids, add, remove)
            onClearSelection()
        }
    }

    // Puts titles dragged onto a shelf there, and lets the picked ones go.
    fun onDropOnShelf(titles: Set<Long>, shelf: Long) {
        viewModelScope.launch {
            shelves.change(titles, setOf(shelf), emptySet())
            onClearSelection()
        }
    }

    // Makes a shelf, and gives its id so the dialog can tick it, or null when the name is not usable.
    suspend fun onCreateShelf(name: String): Long? = shelves.add(name, state.value.pickKind)
}
