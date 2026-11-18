package com.sumizuri.app.data.db.tracker

import androidx.room3.Dao
import androidx.room3.Entity
import androidx.room3.ForeignKey
import androidx.room3.Index
import androidx.room3.Insert
import androidx.room3.OnConflictStrategy
import androidx.room3.Query
import com.sumizuri.app.data.db.title.TitleEntity
import kotlinx.coroutines.flow.Flow

// A title of the library linked to its entry on a tracker. The values are what this device holds now, and the agreed ones what both sides held after the last sync, so a sync can tell which side changed what.
@Entity(
    tableName = "tracker_link",
    primaryKeys = ["titleId", "tracker"],
    foreignKeys = [
        ForeignKey(
            TitleEntity::class,
            parentColumns = ["id"],
            childColumns = ["titleId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("tracker")],
)
data class TrackerLinkEntity(
    val titleId: Long,
    val tracker: String,
    // The title on the tracker: its id, its name, its cover, its page and how many chapters or episodes it has when that is known.
    val remoteId: Long,
    val remoteName: String,
    val remoteCover: String? = null,
    val remoteUrl: String? = null,
    val remoteTotal: Int? = null,
    val kind: Int = 0,
    // The id of the entry in the list of the person, once the tracker has one.
    val entryId: Long? = null,
    // The status as the tracker names it, such as CURRENT, the chapters or episodes done, and the score out of 100, where 0 is no score.
    val status: String,
    val progress: Int,
    val score: Int = 0,
    val agreedStatus: String? = null,
    val agreedProgress: Int? = null,
    val agreedScore: Int? = null,
    // When this device last changed the values, when the tracker last changed its entry, and when the two last agreed, in epoch milliseconds.
    val changedAt: Long = 0,
    val remoteAt: Long = 0,
    val syncedAt: Long = 0,
    // The entry was on the tracker once and is gone now, which the person decides about.
    val gone: Boolean = false,
)

// A title of the library with no link to a tracker yet.
data class LibraryTitle(val id: Long, val name: String, val kind: Int, val coverUrl: String?)

// The highest chapter or episode read of a linked title.
data class ReadMark(val titleId: Long, val number: Double)

// The chapter or episode of a linked title read last, and when.
data class LastRead(val titleId: Long, val number: Double, val at: Long)

@Dao
interface TrackerLinkDao {
    @Query("SELECT * FROM tracker_link WHERE tracker = :tracker ORDER BY remoteName COLLATE NOCASE")
    fun observeAll(tracker: String): Flow<List<TrackerLinkEntity>>

    @Query("SELECT * FROM tracker_link WHERE titleId = :titleId")
    fun observeOf(titleId: Long): Flow<List<TrackerLinkEntity>>

    @Query("SELECT * FROM tracker_link WHERE tracker = :tracker")
    suspend fun allOf(tracker: String): List<TrackerLinkEntity>

    @Query(
        "SELECT id, name, kind, coverUrl FROM title WHERE inLibrary = 1 AND id NOT IN " +
            "(SELECT titleId FROM tracker_link WHERE tracker = :tracker) ORDER BY name COLLATE NOCASE",
    )
    fun observeUnlinked(tracker: String): Flow<List<LibraryTitle>>

    @Query(
        "SELECT id, name, kind, coverUrl FROM title WHERE inLibrary = 1 AND id NOT IN " +
            "(SELECT titleId FROM tracker_link WHERE tracker = :tracker)",
    )
    suspend fun unlinked(tracker: String): List<LibraryTitle>

    @Query("SELECT * FROM tracker_link")
    suspend fun everything(): List<TrackerLinkEntity>

    @Query("SELECT * FROM tracker_link WHERE titleId IN (:titleIds)")
    suspend fun ofTitles(titleIds: List<Long>): List<TrackerLinkEntity>

    @Query("SELECT * FROM tracker_link WHERE titleId = :titleId AND tracker = :tracker")
    suspend fun get(titleId: Long, tracker: String): TrackerLinkEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun put(link: TrackerLinkEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun putAll(links: List<TrackerLinkEntity>)

    @Query("DELETE FROM tracker_link WHERE titleId = :titleId AND tracker = :tracker")
    suspend fun delete(titleId: Long, tracker: String)

    // Another account knows nothing of what this one agreed with the tracker, so signing out forgets it and keeps the links.
    @Query(
        "UPDATE tracker_link SET entryId = NULL, agreedStatus = NULL, agreedProgress = NULL, agreedScore = NULL, " +
            "syncedAt = 0, gone = 0 WHERE tracker = :tracker",
    )
    suspend fun forgetAgreed(tracker: String)

    @Query(
        "SELECT p.titleId AS titleId, MAX(c.number) AS number FROM progress p JOIN chapter c ON c.id = p.chapterId " +
            "WHERE p.read = 1 AND p.titleId IN (SELECT titleId FROM tracker_link) GROUP BY p.titleId",
    )
    suspend fun readMarks(): List<ReadMark>

    @Query(
        "SELECT MAX(c.number) FROM progress p JOIN chapter c ON c.id = p.chapterId WHERE p.read = 1 AND p.titleId = :titleId",
    )
    suspend fun readMarkOf(titleId: Long): Double?

    @Query(
        "SELECT p.titleId AS titleId, c.number AS number, p.readAt AS at FROM progress p JOIN chapter c ON c.id = p.chapterId " +
            "WHERE p.read = 1 AND p.readAt IS NOT NULL AND p.titleId IN (SELECT titleId FROM tracker_link) " +
            "AND p.readAt = (SELECT MAX(q.readAt) FROM progress q WHERE q.titleId = p.titleId AND q.read = 1)",
    )
    suspend fun lastReads(): List<LastRead>
}
