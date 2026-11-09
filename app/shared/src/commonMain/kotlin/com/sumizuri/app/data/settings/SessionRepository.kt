package com.sumizuri.app.data.settings

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.Facet
import com.sumizuri.app.data.model.TriFilter
import com.sumizuri.app.data.model.facetsFrom
import com.sumizuri.app.data.model.facetsText
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map

private const val BrowseKindKey = "session.browseKind"
private const val BrowseGroupingKey = "session.browseGrouping"
private const val BrowseListingKey = "session.browseListing"
private const val BrowsePinnedKey = "session.browsePinned"
private const val LibraryKindKey = "session.libraryKind"
private const val OldestFirstKey = "session.oldestFirst"
private const val ChapterGridKey = "session.chapterGrid"
private const val ChapterPicturesKey = "session.chapterPictures"
private const val HideDuplicatesKey = "session.hideDuplicates"
private const val ChapterSortKey = "session.chapterSort"
internal const val FilterUnreadKey = "session.filterUnread"
internal const val FilterDownloadedKey = "session.filterDownloaded"
internal const val FilterBookmarkedKey = "session.filterBookmarked"
internal const val HiddenFacetsPrefix = "session.hidden."
private const val PlaceKey = "session.place"

// Where the user was and how they had things set, so the app opens the way it was left.
class SessionRepository(private val db: AppDatabase) {
    // The kind shown on the Browse wall, below zero for every kind, or null when none was chosen yet.
    suspend fun browseKind(): Int? = db.settings().get(BrowseKindKey)?.toIntOrNull()

    suspend fun setBrowseKind(code: Int) = put(BrowseKindKey, code.toString())

    // How the Browse wall puts its sources under headings, by the name of the way, or null while none was chosen.
    suspend fun browseGrouping(): String? = db.settings().get(BrowseGroupingKey)

    suspend fun setBrowseGrouping(name: String) = put(BrowseGroupingKey, name)

    // The name of the listing, such as Popular or Latest.
    suspend fun browseListing(): String? = db.settings().get(BrowseListingKey)

    suspend fun setBrowseListing(name: String) = put(BrowseListingKey, name)

    // The sources pinned at the top of Browse, by id.
    fun browsePinned(): Flow<Set<String>> = db
        .settings()
        .observe(BrowsePinnedKey)
        .map { text ->
            text
                .orEmpty()
                .split(',')
                .filter { it.isNotBlank() }
                .toSet()
        }.distinctUntilChanged()

    suspend fun setBrowsePinned(ids: Set<String>) = put(BrowsePinnedKey, ids.sorted().joinToString(","))

    // The kind chosen in the library tabs, or null for all of them.
    suspend fun libraryKind(): Int? = db.settings().get(LibraryKindKey)?.toIntOrNull()

    suspend fun setLibraryKind(code: Int?) = if (code ==
        null
    ) {
        db.settings().delete(LibraryKindKey)
    } else {
        put(LibraryKindKey, code.toString())
    }

    suspend fun oldestFirst(): Boolean = db.settings().get(OldestFirstKey) == "true"

    suspend fun setOldestFirst(value: Boolean) = put(OldestFirstKey, value.toString())

    // Whether the chapters of a title are laid out as a grid of cells and not a list.
    suspend fun chapterGrid(): Boolean = db.settings().get(ChapterGridKey) == "true"

    suspend fun setChapterGrid(value: Boolean) = put(ChapterGridKey, value.toString())

    // Whether each cell of the grid shows a page from inside its chapter.
    suspend fun setChapterPictures(value: Boolean) = put(ChapterPicturesKey, value.toString())

    // Whether a chapter listed twice is shown once.
    suspend fun hideDuplicates(): Boolean = db.settings().get(HideDuplicatesKey) == "true"

    suspend fun setHideDuplicates(value: Boolean) = put(HideDuplicatesKey, value.toString())

    // What the chapters are put in order by: the list of the source, their numbers or their dates.
    suspend fun setChapterSort(sort: ChapterSort) = put(ChapterSortKey, sort.key)

    // Which chapters the lists show, by being unread, saved and bookmarked.
    suspend fun setChapterFilter(filter: ChapterFilter) {
        put(FilterUnreadKey, filter.unread.name)
        put(FilterDownloadedKey, filter.downloaded.name)
        put(FilterBookmarkedKey, filter.bookmarked.name)
    }

    // Takes the order, the look and the filters of the chapter lists back to how they were. The groups hidden on one title stay, as they belong to that title.
    suspend fun resetChapterLook() {
        for (key in listOf(
            OldestFirstKey,
            ChapterGridKey,
            ChapterPicturesKey,
            HideDuplicatesKey,
            ChapterSortKey,
            FilterUnreadKey,
            FilterDownloadedKey,
            FilterBookmarkedKey,
        )) {
            db.settings().delete(key)
        }
    }

    private val chapterFilter: Flow<ChapterFilter> = combine(
        db.settings().observe(FilterUnreadKey),
        db.settings().observe(FilterDownloadedKey),
        db.settings().observe(FilterBookmarkedKey),
    ) { unread, downloaded, bookmarked ->
        ChapterFilter(
            TriFilter.of(unread),
            TriFilter.of(downloaded),
            TriFilter.of(bookmarked),
        )
    }

    // The choices of the chapter lists as they change, so a page that is open follows a change made on another title or in the settings.
    val chapterLook: Flow<ChapterLook> = combine(
        db.settings().observe(OldestFirstKey),
        db.settings().observe(ChapterGridKey),
        db.settings().observe(HideDuplicatesKey),
        db.settings().observe(ChapterSortKey),
        chapterFilter,
    ) { oldest, grid, hide, sort, filter ->
        ChapterLook(
            oldest == "true",
            grid == "true",
            hide == "true",
            ChapterSort.of(sort),
            filter,
        )
    }.combine(db.settings().observe(ChapterPicturesKey)) { look, pictures -> look.copy(pictures = pictures == "true") }
        .distinctUntilChanged()

    // The groups, languages and other labels whose chapters a title hides. They are kept for each title, as each has its own.
    fun hiddenFacets(titleId: Long): Flow<Set<Facet>> = db
        .settings()
        .observe(HiddenFacetsPrefix + titleId)
        .map(::facetsFrom)
        .distinctUntilChanged()

    suspend fun setHiddenFacets(titleId: Long, hidden: Set<Facet>) = if (hidden.isEmpty()) {
        db.settings().delete(HiddenFacetsPrefix + titleId)
    } else {
        put(HiddenFacetsPrefix + titleId, facetsText(hidden))
    }

    // The tab and the pages that were open, as JSON text.
    suspend fun place(): String? = db.settings().get(PlaceKey)

    suspend fun setPlace(json: String) = put(PlaceKey, json)

    private suspend fun put(name: String, value: String) = db.settings().put(SettingEntity(name, value))
}

// How the chapters of every title are listed: the oldest first, as a grid, with a chapter listed twice shown once, in what order, and which chapters show.
data class ChapterLook(
    val oldestFirst: Boolean = false,
    val grid: Boolean = false,
    val hideDuplicates: Boolean = false,
    val sort: ChapterSort = ChapterSort.Source,
    val filter: ChapterFilter = ChapterFilter(),
    // A page from inside each chapter in its cell of the grid.
    val pictures: Boolean = false,
)
