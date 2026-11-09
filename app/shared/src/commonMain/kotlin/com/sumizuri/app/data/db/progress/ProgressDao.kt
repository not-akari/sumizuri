package com.sumizuri.app.data.db.progress

import androidx.room3.Dao
import androidx.room3.Insert
import androidx.room3.OnConflictStrategy
import androidx.room3.Query
import com.sumizuri.app.data.db.category.TitleTime
import com.sumizuri.app.data.db.chapter.FeedRow
import com.sumizuri.app.data.db.chapter.UpdateRow
import kotlinx.coroutines.flow.Flow

@Dao
interface ProgressDao {
    // Newest reads first, straight off the readAt index. A chapter that was begun counts as well as one that was finished, since it has a time from when it was opened.
    @Query(
        """
        SELECT p.titleId, c.number, p.readAt AS at FROM progress p
        CROSS JOIN chapter c ON c.id = p.chapterId
        WHERE p.readAt IS NOT NULL
        ORDER BY p.readAt DESC LIMIT :limit
        """,
    )
    fun observeHistory(limit: Int): Flow<List<FeedRow>>

    // The same reads with the chapter that was read, newest first, as rows the feed folds by day.
    @Query(
        """
        SELECT p.chapterId AS id, p.titleId, c.number, NULL AS name, p.readAt AS at FROM progress p
        CROSS JOIN chapter c ON c.id = p.chapterId
        WHERE p.readAt IS NOT NULL
        ORDER BY p.readAt DESC LIMIT :limit
        """,
    )
    fun observeReadings(limit: Int): Flow<List<UpdateRow>>

    @Query("SELECT * FROM progress WHERE chapterId = :chapterId")
    suspend fun get(chapterId: Long): ProgressEntity?

    // Sets or clears the time a chapter was read. A chapter without one is still read, it only leaves the history.
    @Query("UPDATE progress SET readAt = :at WHERE chapterId = :chapterId")
    suspend fun setReadAt(chapterId: Long, at: Long?)

    @Query("UPDATE progress SET readAt = NULL WHERE chapterId IN (:chapterIds)")
    suspend fun clearReadAtMany(chapterIds: List<Long>)

    @Query("SELECT * FROM progress WHERE titleId = :titleId")
    suspend fun allOf(titleId: Long): List<ProgressEntity>

    // When each title was read last, for the titles that were read at all.
    @Query("SELECT titleId, MAX(readAt) AS at FROM progress WHERE readAt IS NOT NULL GROUP BY titleId")
    fun observeLastRead(): Flow<List<TitleTime>>

    // Every chapter that was read, with its title and the time, for the statistics of the profile.
    @Query("SELECT titleId, readAt AS at FROM progress WHERE read = 1 AND readAt IS NOT NULL")
    fun observeReadStamps(): Flow<List<TitleTime>>

    @Query("SELECT position FROM progress WHERE chapterId = :chapterId")
    suspend fun position(chapterId: Long): Double?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun put(progress: ProgressEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun putAll(progress: List<ProgressEntity>)

    @Query("DELETE FROM progress WHERE chapterId = :chapterId")
    suspend fun clear(chapterId: Long)

    @Query("DELETE FROM progress WHERE chapterId IN (:chapterIds)")
    suspend fun clearMany(chapterIds: List<Long>)
}
