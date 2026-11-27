package com.sumizuri.app.data.db.lists

import androidx.room3.Dao
import androidx.room3.Insert
import androidx.room3.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface ReadingListDao {
    @Query("SELECT * FROM reading_list ORDER BY sortOrder, id")
    fun observeAll(): Flow<List<ReadingListEntity>>

    @Query("SELECT listId, COUNT(*) AS items FROM reading_list_item GROUP BY listId")
    fun observeCounts(): Flow<List<ListCount>>

    @Query("SELECT listId, matchKey FROM reading_list_item WHERE matchKey IN (:keys)")
    fun observeHolding(keys: List<String>): Flow<List<ListHolding>>

    @Query("SELECT * FROM reading_list WHERE id = :id")
    fun observe(id: Long): Flow<ReadingListEntity?>

    @Query("SELECT * FROM reading_list_item WHERE listId = :listId ORDER BY position, id")
    fun observeItems(listId: Long): Flow<List<ReadingListItemEntity>>

    // The first titles of every list, for the covers on the page of the lists. Places are kept without gaps, so the first ones are below the number.
    @Query("SELECT * FROM reading_list_item WHERE position < :count ORDER BY listId, position")
    fun observeFronts(count: Int): Flow<List<ReadingListItemEntity>>

    @Query("SELECT * FROM reading_list ORDER BY sortOrder, id")
    suspend fun all(): List<ReadingListEntity>

    // Numbers the places of a list again from nothing, closing the gaps a removal leaves.
    @Query(
        "UPDATE reading_list_item SET position = (SELECT COUNT(*) FROM reading_list_item AS earlier WHERE earlier.listId = :listId AND (earlier.position < reading_list_item.position OR (earlier.position = reading_list_item.position AND earlier.id < reading_list_item.id))) WHERE listId = :listId",
    )
    suspend fun renumber(listId: Long)

    @Query("SELECT matchKey FROM reading_list_item WHERE listId = :listId")
    suspend fun keysOf(listId: Long): List<String>

    @Query("SELECT COALESCE(MAX(position), -1) FROM reading_list_item WHERE listId = :listId")
    suspend fun lastPosition(listId: Long): Int

    @Query("SELECT COALESCE(MAX(sortOrder), -1) FROM reading_list")
    suspend fun lastOrder(): Int

    @Insert
    suspend fun insert(list: ReadingListEntity): Long

    @Insert
    suspend fun insertItems(items: List<ReadingListItemEntity>)

    @Query("UPDATE reading_list SET name = :name, about = :about, changed = :at WHERE id = :id")
    suspend fun describe(id: Long, name: String, about: String, at: Long)

    @Query("UPDATE reading_list SET changed = :at WHERE id = :id")
    suspend fun touch(id: Long, at: Long)

    @Query("UPDATE reading_list SET sortOrder = :order WHERE id = :id")
    suspend fun setOrder(id: Long, order: Int)

    @Query("DELETE FROM reading_list WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("UPDATE reading_list_item SET position = :position WHERE id = :id")
    suspend fun setPosition(id: Long, position: Int)

    @Query("UPDATE reading_list_item SET note = :note WHERE id = :id")
    suspend fun setNote(id: Long, note: String)

    @Query("DELETE FROM reading_list_item WHERE id IN (:ids)")
    suspend fun deleteItems(ids: List<Long>)

    @Query("DELETE FROM reading_list_item WHERE listId = :listId AND matchKey IN (:keys)")
    suspend fun deleteKeys(listId: Long, keys: List<String>)
}
