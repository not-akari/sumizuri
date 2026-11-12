package com.sumizuri.app.data.db.title

import androidx.room3.Dao
import androidx.room3.Insert
import androidx.room3.Query
import kotlinx.coroutines.flow.Flow

private const val TITLE_ROW = "SELECT id, name, kind, coverUrl, status, summary, author, genres, inLibrary, sourceId, rating, webUrl, addedAt, favorite FROM title"

// The same without the summary, which is the longest text of a title and which no list shows. A library of tens of thousands of titles would otherwise hold it all in memory.
private const val LIST_ROW = "SELECT id, name, kind, coverUrl, status, '' AS summary, author, genres, inLibrary, sourceId, rating, webUrl, addedAt, favorite FROM title"

@Dao
interface TitleDao {
    // Every title, saved or not, for a backup.
    @Query("SELECT * FROM title ORDER BY id")
    suspend fun everything(): List<TitleEntity>

    @Query("$LIST_ROW WHERE inLibrary = 1 ORDER BY name")
    fun observeLibrary(): Flow<List<TitleRow>>

    @Query("SELECT sourceId, COUNT(*) AS count FROM title WHERE inLibrary = 1 GROUP BY sourceId")
    fun observeSourceCounts(): Flow<List<SourceCount>>

    @Query("$LIST_ROW WHERE inLibrary = 1 AND sourceId IN (:sourceIds) ORDER BY name")
    fun observeLibraryOfSources(sourceIds: List<String>): Flow<List<TitleRow>>

    @Query("$LIST_ROW WHERE id IN (:ids)")
    fun observeByIds(ids: List<Long>): Flow<List<TitleRow>>

    @Query("$TITLE_ROW WHERE id = :id")
    fun observe(id: Long): Flow<TitleRow?>

    // Both counts come straight from indexes, without reading any chapter row.
    @Query(
        """
        SELECT t.id AS titleId,
            (SELECT COUNT(*) FROM chapter c WHERE c.titleId = t.id)
            - (SELECT COUNT(*) FROM progress p WHERE p.titleId = t.id AND p.read = 1) AS unread,
            (SELECT COUNT(*) FROM chapter c WHERE c.titleId = t.id) AS total
        FROM title t
        WHERE t.inLibrary = 1
        """,
    )
    fun observeUnreadCounts(): Flow<List<UnreadCount>>

    // The same counts with each chapter number of a season counted once, for when repeated chapters are hidden. A number counts as read when any of its copies was read, as the page keeps the read copy. Numbers that agree to the third decimal are one, as the page counts them.
    @Query(
        """
        SELECT t.id AS titleId,
            (SELECT COUNT(DISTINCT IFNULL(c.season, '') || '|' || ROUND(c.number, 3)) FROM chapter c WHERE c.titleId = t.id
                AND NOT EXISTS (SELECT 1 FROM chapter r JOIN progress p ON p.chapterId = r.id
                    WHERE r.titleId = t.id AND r.number BETWEEN c.number - 0.0005 AND c.number + 0.0005 AND r.season IS c.season AND p.read = 1)) AS unread,
            (SELECT COUNT(DISTINCT IFNULL(c.season, '') || '|' || ROUND(c.number, 3)) FROM chapter c WHERE c.titleId = t.id) AS total
        FROM title t
        WHERE t.inLibrary = 1
        """,
    )
    fun observeUnreadCountsOnce(): Flow<List<UnreadCount>>

    // The same counts for one title, for its own page, so reading a chapter does not count every title again.
    @Query(
        """
        SELECT :id AS titleId,
            (SELECT COUNT(*) FROM chapter c WHERE c.titleId = :id)
            - (SELECT COUNT(*) FROM progress p WHERE p.titleId = :id AND p.read = 1) AS unread,
            (SELECT COUNT(*) FROM chapter c WHERE c.titleId = :id) AS total
        """,
    )
    fun observeUnreadCount(id: Long): Flow<UnreadCount>

    @Query("SELECT id, sourceId, externalId FROM title WHERE inLibrary = 1")
    suspend fun libraryKeys(): List<TitleKey>

    // The titles of the library with one status, for leaving them out of the check for new chapters.
    @Query("SELECT id FROM title WHERE inLibrary = 1 AND status = :status")
    suspend fun libraryIdsWithStatus(status: Int): List<Long>

    // The titles of the library of which no chapter is read.
    @Query("SELECT id FROM title t WHERE inLibrary = 1 AND NOT EXISTS (SELECT 1 FROM progress p WHERE p.titleId = t.id AND p.read = 1)")
    suspend fun libraryIdsNeverRead(): List<Long>

    // The titles of the library with a chapter that is not read yet.
    @Query("SELECT id FROM title t WHERE inLibrary = 1 AND EXISTS (SELECT 1 FROM chapter c LEFT JOIN progress p ON p.chapterId = c.id WHERE c.titleId = t.id AND COALESCE(p.read, 0) = 0)")
    suspend fun libraryIdsWithUnread(): List<Long>

    @Query("SELECT COUNT(*) FROM title WHERE sourceId = :sourceId")
    suspend fun countOf(sourceId: String): Int

    // Moves the titles of one source to another that reads the same site. A title whose address the other source already has stays where it is, so nothing is doubled. Gives how many moved.
    @Query("UPDATE OR IGNORE title SET sourceId = :to, updatedAt = :now WHERE sourceId = :from")
    suspend fun moveSource(from: String, to: String, now: Long): Int

    @Query("SELECT * FROM title WHERE id = :id")
    suspend fun get(id: Long): TitleEntity?

    @Query("DELETE FROM title WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("UPDATE title SET favorite = :favorite WHERE id IN (:ids)")
    suspend fun setFavoriteMany(ids: List<Long>, favorite: Boolean)

    @Query("UPDATE title SET inLibrary = :inLibrary, updatedAt = :now WHERE id IN (:ids)")
    suspend fun setInLibraryMany(ids: List<Long>, inLibrary: Boolean, now: Long)

    @Query("UPDATE title SET inLibrary = :inLibrary, updatedAt = :now WHERE id = :id")
    suspend fun setInLibrary(id: Long, inLibrary: Boolean, now: Long)

    // Gives a title the time it was added, for a title that moved to another source and keeps its place among the newest.
    @Query("UPDATE title SET addedAt = :at WHERE id = :id")
    suspend fun setAddedAt(id: Long, at: Long)

    @Query("SELECT sourceId, externalId FROM title WHERE id = :id")
    suspend fun origin(id: Long): TitleOrigin?

    // The names of the library, to warn before the same title is saved twice.
    @Query("SELECT id, name, kind, sourceId FROM title WHERE inLibrary = 1")
    suspend fun libraryNames(): List<TitleName>

    // The entries of one source that are in the library, read from the index alone.
    @Query("SELECT externalId FROM title WHERE sourceId = :sourceId AND inLibrary = 1")
    fun observeSavedKeys(sourceId: String): Flow<List<String>>

    // The picture the person chose for the cover.
    @Query("UPDATE title SET coverUrl = :coverUrl, updatedAt = :now WHERE id = :id")
    suspend fun setCover(id: Long, coverUrl: String, now: Long)

    // What the source did not give is kept as it was.
    @Query(
        """
        UPDATE title SET
            coverUrl = COALESCE(:coverUrl, coverUrl),
            status = CASE WHEN :status = 0 THEN status ELSE :status END,
            summary = CASE WHEN :summary = '' THEN summary ELSE :summary END,
            author = CASE WHEN :author = '' THEN author ELSE :author END,
            genres = CASE WHEN :genres = '' THEN genres ELSE :genres END,
            rating = COALESCE(:rating, rating),
            webUrl = COALESCE(:webUrl, webUrl),
            volumesId = COALESCE(:volumesId, volumesId),
            updatedAt = :now
        WHERE id = :id AND (
            coverUrl IS NOT COALESCE(:coverUrl, coverUrl)
            OR status IS NOT CASE WHEN :status = 0 THEN status ELSE :status END
            OR summary IS NOT CASE WHEN :summary = '' THEN summary ELSE :summary END
            OR author IS NOT CASE WHEN :author = '' THEN author ELSE :author END
            OR genres IS NOT CASE WHEN :genres = '' THEN genres ELSE :genres END
            OR rating IS NOT COALESCE(:rating, rating)
            OR webUrl IS NOT COALESCE(:webUrl, webUrl)
            OR volumesId IS NOT COALESCE(:volumesId, volumesId)
        )
        """,
    )
    suspend fun updateDetails(id: Long, coverUrl: String?, status: Int, summary: String, author: String, genres: String, rating: Double?, webUrl: String?, volumesId: String?, now: Long)

    // True when a title has no cover or no description yet, so the check asks the source for its details even without new chapters.
    @Query("SELECT (coverUrl IS NULL OR coverUrl = '' OR summary IS NULL OR summary = '') FROM title WHERE id = :id")
    suspend fun lacksDetails(id: Long): Boolean?

    // Gives a title another source, for one that was imported without a source and has found it.
    @Query("UPDATE title SET sourceId = :sourceId WHERE id = :id")
    suspend fun setSource(id: Long, sourceId: String)

    @Query("UPDATE title SET sourceId = :sourceId, externalId = :externalId WHERE id = :id")
    suspend fun setOrigin(id: Long, sourceId: String, externalId: String)

    @Query("SELECT name FROM title WHERE id = :id")
    suspend fun nameOf(id: Long): String?

    @Query("SELECT id FROM title WHERE sourceId = :sourceId AND externalId = :externalId")
    suspend fun findId(sourceId: String, externalId: String): Long?

    @Query("SELECT id FROM title WHERE sourceId = :sourceId AND externalId = :externalId AND inLibrary = 1")
    suspend fun findLibraryId(sourceId: String, externalId: String): Long?

    // The id of the same title by volume, which follows the source as it learns of one.
    @Query("SELECT volumesId FROM title WHERE id = :id")
    fun observeVolumesId(id: Long): Flow<String?>

    // The title that a list of volumes belongs to, found by its volumes id.
    @Query("SELECT id FROM title WHERE sourceId = :sourceId AND volumesId = :volumesId LIMIT 1")
    suspend fun mainOf(sourceId: String, volumesId: String): Long?

    @Insert
    suspend fun insert(title: TitleEntity): Long
}
