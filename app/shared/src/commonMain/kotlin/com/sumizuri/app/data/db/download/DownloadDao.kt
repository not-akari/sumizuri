package com.sumizuri.app.data.db.download

import androidx.room3.Dao
import androidx.room3.Insert
import androidx.room3.OnConflictStrategy
import androidx.room3.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface DownloadDao {
    // The downloads of one title, for the marks on its chapters.
    @Query("SELECT * FROM download WHERE titleId = :titleId")
    fun observeOf(titleId: Long): Flow<List<DownloadEntity>>

    // Every download with the names it is shown by: the one being saved, then the ones still to do in the order they were asked for, then the saved ones by title and number.
    @Query(
        """
        SELECT d.*, t.name AS titleName, c.name AS chapterName, c.number
        FROM download d JOIN chapter c ON c.id = d.chapterId JOIN title t ON t.id = d.titleId
        ORDER BY CASE d.state WHEN 1 THEN 0 WHEN 2 THEN 2 ELSE 1 END, CASE WHEN d.state = 2 THEN t.name END COLLATE NOCASE, d.queuedAt, c.number
        """,
    )
    fun observeAll(): Flow<List<DownloadRow>>

    // How many are waiting or being saved, for the mark on the button of the page of downloads.
    @Query("SELECT COUNT(*) FROM download WHERE state IN (0, 1)")
    fun observeActive(): Flow<Int>

    @Query("SELECT * FROM download WHERE state = 0 ORDER BY queuedAt, chapterId LIMIT 1")
    suspend fun nextQueued(): DownloadEntity?

    @Query("SELECT * FROM download WHERE chapterId = :chapterId")
    suspend fun get(chapterId: Long): DownloadEntity?

    @Query("SELECT * FROM download WHERE chapterId IN (:chapterIds)")
    suspend fun getMany(chapterIds: List<Long>): List<DownloadEntity>

    @Query("SELECT chapterId FROM download WHERE state = 2")
    suspend fun doneIds(): List<Long>

    // How much is saved for each title, the biggest first, for the storage page.
    @Query(
        "SELECT titleId, COUNT(*) AS chapters, SUM(bytes) AS bytes FROM download WHERE state = 2 GROUP BY titleId ORDER BY SUM(bytes) DESC",
    )
    fun observeSavedByTitle(): Flow<List<SavedTitle>>

    @Query("SELECT chapterId FROM download WHERE titleId = :titleId AND state = 2")
    suspend fun savedIdsOf(titleId: Long): List<Long>

    // A chapter that was asked for already keeps its place.
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(downloads: List<DownloadEntity>)

    @Query("UPDATE download SET state = :state, error = :error WHERE chapterId = :chapterId")
    suspend fun setState(chapterId: Long, state: Int, error: String? = null)

    @Query("UPDATE download SET pages = :pages, saved = :saved, bytes = :bytes WHERE chapterId = :chapterId")
    suspend fun setProgress(chapterId: Long, pages: Int, saved: Int, bytes: Long)

    @Query(
        "UPDATE download SET state = 2, pages = :pages, saved = :pages, bytes = :bytes, error = NULL, finishedAt = :at WHERE chapterId = :chapterId",
    )
    suspend fun setDone(chapterId: Long, pages: Int, bytes: Long, at: Long)

    // Downloads that were being saved when the app last closed wait to be saved again.
    @Query("UPDATE download SET state = 0 WHERE state = 1")
    suspend fun requeueRunning()

    // Failed downloads wait again, at the end of the queue: all of them, or those of the chapters given.
    @Query("UPDATE download SET state = 0, error = NULL, queuedAt = :at WHERE state = 3")
    suspend fun requeueFailed(at: Long)

    @Query("UPDATE download SET state = 0, error = NULL, queuedAt = :at WHERE state = 3 AND chapterId IN (:chapterIds)")
    suspend fun requeueFailed(chapterIds: List<Long>, at: Long)

    @Query("DELETE FROM download WHERE chapterId IN (:chapterIds)")
    suspend fun deleteMany(chapterIds: List<Long>)
}
