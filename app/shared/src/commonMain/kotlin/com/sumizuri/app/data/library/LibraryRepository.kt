package com.sumizuri.app.data.library

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.chapter.FeedRow
import com.sumizuri.app.data.db.chapter.UpdateRow
import com.sumizuri.app.data.db.progress.ProgressEntity
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.db.title.SourceCount
import com.sumizuri.app.data.db.title.TitleEntity
import com.sumizuri.app.data.db.title.TitleKey
import com.sumizuri.app.data.db.title.TitleOrigin
import com.sumizuri.app.data.db.title.TitleRow
import com.sumizuri.app.data.db.title.UnreadCount
import com.sumizuri.app.data.model.Chapter
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.FeedItem
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.OrderKey
import com.sumizuri.app.data.model.SourceState
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.chapterTags
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.LibraryEntry
import com.sumizuri.app.data.model.library.LibrarySortField
import com.sumizuri.app.data.model.library.shelf.ShelfConditions
import com.sumizuri.app.data.model.library.shelf.ShelfContext
import com.sumizuri.app.data.model.readingOrder
import com.sumizuri.app.data.model.sourceStateOf
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.data.text.statusFromText
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourceEntry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.shareIn

private const val FeedLimit = 40

// The setting that hides repeated chapters, which the counts follow.
internal const val HideRepeatsKey = "session.hideDuplicates"
internal const val ChapterSortKey = "session.chapterSort"

// How many reads the history page looks at.
private const val ReadingsLimit = 400

// Ids are sent to the database in parts, since a query takes only so many.
private const val BulkChunk = 500

// How many chapters the updates page reads, before the ones of a day are folded together.
private const val UpdatesLimit = 200

// A chapter opened again after this long counts as read again, and moves up the history.
private const val ReadAgainMs = 30 * 60 * 1000L

class LibraryRepository(private val db: AppDatabase, private val scope: CoroutineScope) {
    private val writer = ChapterWriter(db)
    private val places = ChapterPlaces(db)

    // Titles load alone and the unread counts join in later, so the grid never waits for the counts. With repeated chapters hidden, each chapter number counts once, so the numbers on the covers match the list on the title page.
    @OptIn(ExperimentalCoroutinesApi::class)
    private val unread: Flow<Map<Long, UnreadCount>> =
        db
            .settings()
            .observe(HideRepeatsKey)
            .map { it == "true" }
            .distinctUntilChanged()
            .flatMapLatest { once -> if (once) db.titles().observeUnreadCountsOnce() else db.titles().observeUnreadCounts() }
            .map { counts -> counts.associateBy { it.titleId } }
            .shareHere()

    // Which installed sources are switched on, so a title can tell when its source is off or gone.
    private val sourcesOn: Flow<Map<String, Boolean>> =
        db
            .sources()
            .observeAll()
            .map { rows -> rows.associate { it.id to it.enabled } }
            .shareHere()

    // Which shelves each title is on, shared by every screen that shows shelves.
    private val memberships: Flow<Map<Long, Set<Long>>> =
        db
            .categories()
            .observeMemberships()
            .map { rows -> rows.groupBy({ it.titleId }, { it.categoryId }).mapValues { it.value.toSet() } }
            .shareHere()

    // The titles of the library with the shelves each is on, and the times of the last read and of the newest chapter when one of the fields is ordered by them, since they take a grouped query each.
    fun entries(fields: Set<LibrarySortField> = emptySet()): Flow<List<LibraryEntry>> {
        val read: Flow<Map<Long, Long>> = if (LibrarySortField.LastRead in fields) db.progress().observeLastRead().map { rows -> rows.associate { it.titleId to it.at } } else flowOf(emptyMap())
        val newest: Flow<Map<Long, Long>> = if (LibrarySortField.LatestChapter in fields) db.chapters().observeLatest().map { rows -> rows.associate { it.titleId to it.at } } else flowOf(emptyMap())
        val shelves = memberships
        return combine(library, shelves, read, newest) { titles, on, last, latest -> titles.map { LibraryEntry(it, on[it.id].orEmpty(), last[it.id] ?: 0L, latest[it.id] ?: 0L) } }
    }

    // The sources of the library that are not installed or are switched off, with how many titles each holds.
    val unreachableSources: Flow<List<SourceCount>> = combine(db.titles().observeSourceCounts(), sourcesOn) { counts, on ->
        counts.filter { sourceStateOf(it.sourceId, on) != SourceState.Ready }
    }

    // The titles of those sources.
    @OptIn(ExperimentalCoroutinesApi::class)
    fun unreachableTitles(): Flow<List<Title>> = unreachableSources.flatMapLatest { groups ->
        combine(db.titles().observeLibraryOfSources(groups.map { it.sourceId }), sourcesOn) { rows, on -> rows.map { toTitle(it, null, on) } }
    }

    // The titles the person asked to leave out of the check for new chapters: the finished ones, the ones not started, and the ones with chapters still to read.
    suspend fun leftOutOfUpdate(completed: Boolean, notStarted: Boolean, unread: Boolean = false): Set<Long> = buildSet {
        if (completed) addAll(db.titles().libraryIdsWithStatus(Status.Completed.code))
        if (notStarted) addAll(db.titles().libraryIdsNeverRead())
        if (unread) addAll(db.titles().libraryIdsWithUnread())
    }

    // The titles whose next chapter is not expected yet, by the rhythm of their past chapters.
    suspend fun notDueForUpdate(): Set<Long> = titlesNotDue(db.chapters().recentReleases(SmartSample).groupBy({ it.titleId }, { it.at }), nowMillis())

    // The titles of the library with the day their next chapter is expected, the soonest first. A title whose chapter is already late is expected today.
    suspend fun upcoming(): List<UpcomingTitle> {
        val now = nowMillis()
        val expected = nextReleases(db.chapters().recentReleases(SmartSample).groupBy({ it.titleId }, { it.at }), now)
        if (expected.isEmpty()) return emptyList()
        return library.first().mapNotNull { title -> expected[title.id]?.let { UpcomingTitle(title, maxOf(it, now)) } }.sortedBy { it.at }
    }

    // The days the titles of the library came out lately and the rhythm they keep, for the calendar of releases.
    suspend fun releasePlans(): List<ReleasePlan> =
        releasePlans(library.first(), db.chapters().recentReleases(SmartSample).groupBy({ it.titleId }, { it.at }), nowMillis())

    // The titles on a shelf that is left out of the check for new chapters.
    suspend fun excludedFromUpdate(): Set<Long> {
        val manual = db.categories().excludedTitles().toSet()
        val smart = db
            .categories()
            .all()
            .filter { it.excludeFromUpdate && it.conditions.isNotBlank() }
            .map { Category(it.id, it.name, true, 0, conditions = ShelfConditions.decode(it.conditions), matchAll = it.matchAll) }
            .filter { it.isSmart }
        if (smart.isEmpty()) return manual
        val context = ShelfContext(
            db
                .sources()
                .observeAll()
                .first()
                .associate { it.id to it.name },
            nowMillis(),
        )
        return manual + library.first().filter { title -> smart.any { it.matches(title, context) } }.map { it.id }
    }

    suspend fun setFavorite(ids: Collection<Long>, favorite: Boolean) {
        for (part in ids.chunked(BulkChunk)) db.titles().setFavoriteMany(part, favorite)
    }

    // Takes the titles out of the library. Their chapters and marks stay until the title is removed from the app.
    suspend fun removeFromLibrary(ids: Collection<Long>) {
        val now = nowMillis()
        for (part in ids.chunked(BulkChunk)) db.titles().setInLibraryMany(part, false, now)
    }

    // The titles the user has added.
    private val sharedLibrary = withCounts(db.titles().observeLibrary()).shareIn(scope, SharingStarted.WhileSubscribed(ShareKeepMs), replay = 1)
    val library: Flow<List<Title>> = sharedLibrary

    // A title of the library as the list last had it, read at once without the database, so its page can show it on the first frame. Null when the list is not loaded or the title is not in the library.
    fun cachedTitle(id: Long): Title? = sharedLibrary.replayCache.firstOrNull()?.firstOrNull { it.id == id }

    val updates: Flow<List<FeedItem>> = feed(db.chapters().observeUpdates(FeedLimit))

    // The newest chapters that are not read, for the updates page, of the titles whose source can be asked.
    val unreadUpdates: Flow<List<UpdateRow>> = db.chapters().observeUnreadUpdates(UpdatesLimit)

    // How many titles with chapters not read the updates page leaves out, because their source is missing or off.
    val unreachableUnreadTitles: Flow<Int> = db.chapters().observeUnreachableUnreadTitles()

    // The number for the badge of the updates tab, counted the way the page shows them.
    val unreadUpdateCount: Flow<Int> = db.chapters().observeUnreadUpdateCount(UpdatesLimit).shareHere()

    val history: Flow<List<FeedItem>> = feed(db.progress().observeHistory(FeedLimit))

    // The chapters that were read, newest first, for the history page.
    val readings: Flow<List<UpdateRow>> = db.progress().observeReadings(ReadingsLimit)

    // Those reads with the titles they were read in, whether the titles are in the library or were only opened to read a chapter, so the history shows every read and not only the ones of the library.
    @OptIn(ExperimentalCoroutinesApi::class)
    val readingTitles: Flow<Pair<List<UpdateRow>, List<Title>>> = readings.flatMapLatest { rows ->
        combine(db.titles().observeByIds(rows.map { it.titleId }.distinct()), sourcesOn) { titleRows, on -> rows to titleRows.map { toTitle(it, null, on) } }
    }

    // Takes chapters out of the history without making them unread, and puts them back with the times they had.
    suspend fun forgetReadings(chapterIds: List<Long>) {
        for (part in chapterIds.chunked(BulkChunk)) db.progress().clearReadAtMany(part)
    }

    suspend fun restoreReadings(times: Map<Long, Long>) {
        for ((id, at) in times) db.progress().setReadAt(id, at)
    }

    fun title(id: Long): Flow<Title?> = combine(db.titles().observe(id), db.titles().observeUnreadCount(id), sourcesOn) { row, count, on -> row?.let { toTitle(it, count, on) } }

    fun chapters(titleId: Long): Flow<List<Chapter>> = db.chapters().observeOf(titleId).map { rows ->
        rows.map { Chapter(it.id, it.number, it.name, it.publishedAt, it.read, it.bookmarked, it.readAt, it.position, it.season, it.seasonName, it.seasonCoverUrl, it.sourceOrder, it.scanlator, it.language, it.volume, chapterTags(it.tags)) }
    }

    // The chapters of a title in the order they are read, by the order the person chose for every title, so the reader and the player list them as the title page does.
    fun chaptersInOrder(titleId: Long): Flow<List<Chapter>> = combine(
        chapters(titleId),
        db
            .settings()
            .observe(ChapterSortKey)
            .map { ChapterSort.of(it) }
            .distinctUntilChanged(),
    ) { all, sort ->
        readingOrder(all, sort) { OrderKey(it.id, it.number, it.sourceOrder, it.publishedAt, it.season, it.name) }
    }

    // The id of a title already saved from this source entry, or null when there is none.
    suspend fun savedId(sourceId: String, entry: SourceEntry): Long? = db.titles().findId(sourceId, entry.url)

    // The id of the title of this source entry when it is in the library. A title saved only to read a chapter of it does not count.
    suspend fun libraryId(sourceId: String, entry: SourceEntry): Long? = db.titles().findLibraryId(sourceId, entry.url)

    // Saves a source entry with its chapters into the library. Saving it again only adds what is new. One saved only to read a chapter stays out of the library, and one already in it stays there.
    suspend fun addFromSource(sourceId: String, kind: Kind, entry: SourceEntry, chapters: List<SourceChapter>, inLibrary: Boolean = true): Long {
        val now = nowMillis()
        val existing = db.titles().findId(sourceId, entry.url)
        val id = existing ?: db.titles().insert(
            TitleEntity(
                sourceId = sourceId,
                externalId = entry.url,
                name = entry.title.ifBlank { entry.url },
                kind = kind.code,
                coverUrl = entry.coverUrl,
                status = statusFromText(entry.status).code,
                summary = entry.description.orEmpty(),
                author = entry.author.orEmpty(),
                genres = entry.genres.joinToString("\n"),
                inLibrary = inLibrary,
                addedAt = now,
                updatedAt = now,
                rating = entry.rating,
                webUrl = entry.webUrl,
                volumesId = entry.volumesId,
            ),
        )
        if (existing != null && inLibrary) db.titles().setInLibrary(id, true, now)
        addChapters(id, chapters)
        return id
    }

    // Saves the chapters a source lists. Gives the ids of the new ones.
    suspend fun addChapters(titleId: Long, chapters: List<SourceChapter>): List<Long> = writer.add(titleId, chapters)

    // Makes a picture the cover of a title, and keeps it there when the source says its own cover again.
    suspend fun setCustomCover(titleId: Long, url: String) {
        db.titles().setCover(titleId, url, nowMillis())
        db.settings().put(SettingEntity(customCoverKey(titleId), "true"))
    }

    private fun customCoverKey(titleId: Long) = "cover.custom.$titleId"

    // Takes in what a source says about a title it already has. A cover the person chose is not replaced.
    suspend fun applyDetails(titleId: Long, entry: SourceEntry) = db.titles().updateDetails(
        id = titleId,
        coverUrl = if (db.settings().get(customCoverKey(titleId)) == "true") null else entry.coverUrl,
        status = statusFromText(entry.status).code,
        summary = entry.description.orEmpty(),
        author = entry.author.orEmpty(),
        genres = entry.genres.joinToString("\n"),
        rating = entry.rating,
        webUrl = entry.webUrl,
        volumesId = entry.volumesId,
        now = nowMillis(),
    )

    // The id of the same title by volume, while the source offers one.
    fun volumesIdOf(titleId: Long): Flow<String?> = db.titles().observeVolumesId(titleId)

    // The saved title a list of volumes belongs to, or null when it is not saved.
    suspend fun mainOfVolumes(sourceId: String, volumesId: String): Long? = db.titles().mainOf(sourceId, volumesId)

    // How many titles, saved or not, came from this source.
    suspend fun countOf(sourceId: String): Int = db.titles().countOf(sourceId)

    suspend fun origin(titleId: Long): TitleOrigin? = db.titles().origin(titleId)

    suspend fun lacksDetails(titleId: Long): Boolean = db.titles().lacksDetails(titleId) ?: false

    suspend fun nameOf(titleId: Long): String = db.titles().nameOf(titleId).orEmpty()

    // The cover of a title, for the notice of its new chapters.
    suspend fun coverOf(titleId: Long): String? = db.titles().get(titleId)?.coverUrl?.takeIf { it.isNotBlank() }

    // The addresses of the entries of one source that are in the library.
    fun savedKeys(sourceId: String): Flow<Set<String>> = db.titles().observeSavedKeys(sourceId).map { it.toSet() }

    // A chapter with its title, its neighbours and the place the reader left it, or null when it is gone.
    suspend fun chapterPlace(chapterId: Long): ChapterPlace? = places.of(chapterId)

    // Keeps how far a chapter was read. A chapter that was read to its end stays read when it is opened again. The time it was read is when it was finished, or for a chapter still being read, when it was opened, so the history shows it from the start. While the chapter is read the time stays as it is, so the lists that watch reading are not worked out again at every save, and it is set again only when the chapter is finished or opened after a long while.
    suspend fun saveProgress(titleId: Long, chapterId: Long, position: Double, finished: Boolean) {
        val now = nowMillis()
        val was = db.progress().get(chapterId)
        val read = finished || was?.read == true
        val kept = was?.readAt?.takeIf { now - it < ReadAgainMs }
        val readAt = if (finished && was?.read != true) now else kept ?: now
        db.progress().put(ProgressEntity(chapterId, titleId, read = read, readAt = readAt, position = position))
        onReading?.invoke()
    }

    // Told each time a place in a chapter is kept, so sync can follow reading.
    var onReading: (() -> Unit)? = null

    suspend fun libraryKeys(): List<TitleKey> = db.titles().libraryKeys()

    suspend fun chapterIdOf(titleId: Long, url: String): Long? = db.chapters().idOfUrl(titleId, url)

    suspend fun setInLibrary(id: Long, inLibrary: Boolean) = db.titles().setInLibrary(id, inLibrary, nowMillis())

    suspend fun setBookmarked(chapterId: Long, bookmarked: Boolean) = db.chapters().setBookmarked(chapterId, bookmarked)

    suspend fun setBookmarkedMany(chapterIds: Collection<Long>, bookmarked: Boolean) = chapterIds.chunked(BulkChunk).forEach { db.chapters().setBookmarkedMany(it, bookmarked) }

    // Marks many chapters read or unread at once. Unread forgets the place in the chapter too.
    suspend fun setReadMany(titleId: Long, chapterIds: Collection<Long>, read: Boolean) {
        val now = nowMillis()
        for (part in chapterIds.chunked(BulkChunk)) {
            if (read) {
                db.progress().putAll(part.map { ProgressEntity(it, titleId, read = true, readAt = now, position = null) })
            } else {
                db.progress().clearMany(part)
            }
        }
    }

    // Marks every chapter with a lower number than this one as read.
    suspend fun markBelowRead(titleId: Long, number: Double) = setReadMany(titleId, db.chapters().idsBelow(titleId, number), true)

    suspend fun chapterIds(titleId: Long): List<Long> = db.chapters().idsOf(titleId)

    suspend fun setRead(titleId: Long, chapterId: Long, read: Boolean) {
        if (read) {
            db.progress().put(ProgressEntity(chapterId, titleId, read = true, readAt = nowMillis(), position = null))
        } else {
            db.progress().clear(chapterId)
        }
    }

    private fun <T> Flow<T>.shareHere(): Flow<T> = shareIn(scope, SharingStarted.WhileSubscribed(ShareKeepMs), replay = 1)

    private fun withCounts(rows: Flow<List<TitleRow>>): Flow<List<Title>> = combine(rows, unread, sourcesOn) { titles, counts, on -> titles.map { toTitle(it, counts[it.id], on) } }

    @OptIn(ExperimentalCoroutinesApi::class)
    private fun feed(rows: Flow<List<FeedRow>>): Flow<List<FeedItem>> = rows.flatMapLatest { feedRows ->
        combine(db.titles().observeByIds(feedRows.map { it.titleId }.distinct()), sourcesOn) { titleRows, on ->
            val byId = titleRows.associateBy { it.id }
            feedRows.mapNotNull { row ->
                val title = byId[row.titleId]?.let { toTitle(it, null, on) } ?: return@mapNotNull null
                FeedItem(title, row.number, row.at)
            }
        }
    }

    private fun toTitle(row: TitleRow, count: UnreadCount?, on: Map<String, Boolean>) = Title(
        id = row.id,
        name = row.name,
        kind = Kind.fromCode(row.kind),
        coverUrl = row.coverUrl,
        unread = count?.unread ?: 0,
        chapterCount = count?.total ?: 0,
        favorite = row.favorite,
        status = Status.fromCode(row.status),
        summary = row.summary,
        author = row.author,
        genres = row.genres.split("\n").filter { it.isNotBlank() },
        inLibrary = row.inLibrary,
        sourceId = row.sourceId,
        sourceState = sourceStateOf(row.sourceId, on),
        rating = row.rating,
        webUrl = row.webUrl,
        addedAt = row.addedAt,
    )
}

// Keeps a list running once for every screen that watches it, and for a few seconds after the last one leaves, so going back and forth between screens does not ask the database again.
private const val ShareKeepMs = 5_000L
