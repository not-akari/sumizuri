package com.sumizuri.app.data.db.chapter

import androidx.room3.Dao
import androidx.room3.Insert
import androidx.room3.OnConflictStrategy
import androidx.room3.Query
import com.sumizuri.app.data.db.category.TitleTime
import kotlinx.coroutines.flow.Flow

@Dao
interface ChapterDao {
    @Query(
        """
        SELECT c.id, c.number, c.name, c.publishedAt, COALESCE(p.read, 0) AS read, c.bookmarked, p.readAt, p.position, c.season, c.seasonName, c.seasonCoverUrl, c.sourceOrder, c.scanlator, c.language, c.volume, c.tags
        FROM chapter c LEFT JOIN progress p ON p.chapterId = c.id
        WHERE c.titleId = :titleId ORDER BY c.number DESC, c.id DESC
        """,
    )
    fun observeOf(titleId: Long): Flow<List<ChapterRow>>

    // The dates of the newest chapters of each title in the library, as many as asked for each, for the schedule of the check for new chapters.
    @Query(
        """
        SELECT titleId, publishedAt AS at FROM (
            SELECT c.titleId AS titleId, c.publishedAt AS publishedAt,
                ROW_NUMBER() OVER (PARTITION BY c.titleId ORDER BY c.publishedAt DESC) AS n
            FROM chapter c JOIN title t ON t.id = c.titleId
            WHERE c.publishedAt > 0 AND t.inLibrary = 1
        ) WHERE n <= :perTitle
        """,
    )
    suspend fun recentReleases(perTitle: Int): List<ReleaseRow>

    // CROSS JOIN keeps chapters on the outside, so the date index gives the order and the loop stops at the limit.
    // Only the chapters that came out once the title was in the library are news, less a day for the sources that give the day of a chapter and not its hour; the ones it had before were never new.
    @Query(
        """
        SELECT c.titleId, c.number, c.publishedAt AS at FROM chapter c
        CROSS JOIN title t ON t.id = c.titleId
        WHERE c.publishedAt > 0 AND t.inLibrary = 1
        AND c.publishedAt >= t.addedAt - 86400000
        ORDER BY c.publishedAt DESC LIMIT :limit
        """,
    )
    fun observeUpdates(limit: Int): Flow<List<FeedRow>>

    // The newest chapters that are not read, of titles in the library whose source is installed and on. CROSS JOIN keeps chapters on the outside so the date index gives the order. The titles of a missing source are left out before the limit, so they cannot fill it with chapters the page would not show. Only the ones that came out once the title was in the library, as for the updates above.
    @Query(
        """
        SELECT c.id, c.titleId, c.number, c.name, c.publishedAt AS at FROM chapter c
        CROSS JOIN title t ON t.id = c.titleId
        WHERE c.publishedAt > 0 AND t.inLibrary = 1
        AND c.publishedAt >= t.addedAt - 86400000
        AND t.sourceId IN (SELECT id FROM source WHERE enabled = 1)
        AND NOT EXISTS (SELECT 1 FROM progress p WHERE p.chapterId = c.id AND p.read = 1)
        ORDER BY c.publishedAt DESC LIMIT :limit
        """,
    )
    fun observeUnreadUpdates(limit: Int): Flow<List<UpdateRow>>

    // How many titles of the library have chapters not read but a source that is missing or off, which the updates page leaves out.
    @Query(
        """
        SELECT COUNT(*) FROM title t
        WHERE t.inLibrary = 1 AND t.sourceId NOT IN (SELECT id FROM source WHERE enabled = 1)
        AND EXISTS (
            SELECT 1 FROM chapter c WHERE c.titleId = t.id AND c.publishedAt > 0
            AND NOT EXISTS (SELECT 1 FROM progress p WHERE p.chapterId = c.id AND p.read = 1)
        )
        """,
    )
    fun observeUnreachableUnreadTitles(): Flow<Int>

    // How many of those the updates page can show, which leaves out titles whose source is missing or off, for the badge on its tab. Only a number comes back.
    @Query(
        """
        SELECT COUNT(*) FROM (
            SELECT c.id FROM chapter c
            CROSS JOIN title t ON t.id = c.titleId
            WHERE c.publishedAt > 0 AND t.inLibrary = 1
            AND c.publishedAt >= t.addedAt - 86400000
            AND t.sourceId IN (SELECT id FROM source WHERE enabled = 1)
            AND NOT EXISTS (SELECT 1 FROM progress p WHERE p.chapterId = c.id AND p.read = 1)
            ORDER BY c.publishedAt DESC LIMIT :limit
        )
        """,
    )
    fun observeUnreadUpdateCount(limit: Int): Flow<Int>

    @Query("SELECT * FROM chapter WHERE titleId = :titleId")
    suspend fun allOf(titleId: Long): List<ChapterEntity>

    // The date of the newest chapter of each title in the library that has dates.
    @Query(
        "SELECT c.titleId, MAX(c.publishedAt) AS at FROM chapter c CROSS JOIN title t ON t.id = c.titleId WHERE t.inLibrary = 1 AND c.publishedAt > 0 GROUP BY c.titleId",
    )
    fun observeLatest(): Flow<List<TitleTime>>

    @Query("DELETE FROM chapter WHERE id IN (:ids)")
    suspend fun deleteMany(ids: List<Long>)

    @Query("UPDATE chapter SET bookmarked = :bookmarked WHERE id = :id")
    suspend fun setBookmarked(id: Long, bookmarked: Boolean)

    @Query("UPDATE chapter SET bookmarked = :bookmarked WHERE id IN (:ids)")
    suspend fun setBookmarkedMany(ids: List<Long>, bookmarked: Boolean)

    // The chapters of a title with a lower number than this one.
    @Query("SELECT id FROM chapter WHERE titleId = :titleId AND number < :number")
    suspend fun idsBelow(titleId: Long, number: Double): List<Long>

    @Query("SELECT id FROM chapter WHERE titleId = :titleId")
    suspend fun idsOf(titleId: Long): List<Long>

    @Query("SELECT id, titleId, url, number, name, season FROM chapter WHERE id = :id")
    suspend fun find(id: Long): ChapterRef?

    @Query(
        "SELECT id, number, season, sourceOrder, publishedAt, name, bookmarked, scanlator, language, tags FROM chapter WHERE titleId = :titleId",
    )
    suspend fun slotsOf(titleId: Long): List<ChapterSlot>

    // The chapters of a title that were read, bookmarked or begun, which are the copies the title page keeps when repeats are hidden.
    @Query(
        """
        SELECT c.id FROM chapter c LEFT JOIN progress p ON p.chapterId = c.id
        WHERE c.titleId = :titleId AND (c.bookmarked = 1 OR p.read = 1 OR p.position > 0)
        """,
    )
    suspend fun touchedIds(titleId: Long): List<Long>

    // The saved chapter of a title at an address.
    @Query("SELECT id FROM chapter WHERE titleId = :titleId AND url = :url LIMIT 1")
    suspend fun idOfUrl(titleId: Long, url: String): Long?

    // The season of each saved chapter of a title, so a refresh only writes the ones the source changed.
    @Query("SELECT url, season, seasonName, seasonCoverUrl FROM chapter WHERE titleId = :titleId")
    suspend fun seasonsOf(titleId: Long): List<ChapterSeason>

    @Query(
        "UPDATE chapter SET season = :season, seasonName = :seasonName, seasonCoverUrl = :seasonCoverUrl WHERE titleId = :titleId AND url = :url",
    )
    suspend fun setSeason(titleId: Long, url: String, season: String?, seasonName: String?, seasonCoverUrl: String?)

    // The group, language and volume of each saved chapter of a title, so a refresh only writes the ones the source changed.
    @Query("SELECT url, scanlator, language, volume, tags FROM chapter WHERE titleId = :titleId")
    suspend fun creditsOf(titleId: Long): List<ChapterCredits>

    @Query(
        "UPDATE chapter SET scanlator = :scanlator, language = :language, volume = :volume, tags = :tags WHERE titleId = :titleId AND url = :url",
    )
    suspend fun setCredits(
        titleId: Long,
        url: String,
        scanlator: String?,
        language: String?,
        volume: Double?,
        tags: String?,
    )

    // The addresses of the chapters a title already has with their places in the list of the source and their names.
    @Query("SELECT url, sourceOrder, name FROM chapter WHERE titleId = :titleId")
    suspend fun placesOf(titleId: Long): List<ChapterPlaceInList>

    @Query("UPDATE chapter SET sourceOrder = :sourceOrder WHERE titleId = :titleId AND url = :url")
    suspend fun setSourceOrder(titleId: Long, url: String, sourceOrder: Int)

    @Query("UPDATE chapter SET name = :name WHERE titleId = :titleId AND url = :url")
    suspend fun setName(titleId: Long, url: String, name: String?)

    // A chapter already saved for the title is kept as it is.
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(chapters: List<ChapterEntity>): List<Long>
}
