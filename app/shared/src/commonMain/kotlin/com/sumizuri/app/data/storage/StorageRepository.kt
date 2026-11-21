package com.sumizuri.app.data.storage

import androidx.room3.useReaderConnection
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.download.SavedTitle
import kotlinx.coroutines.flow.Flow

// Reads how big the database is and how many titles and chapters are in it, for the storage page.
class StorageRepository(private val database: AppDatabase) {
    suspend fun use(): StorageUse = database.useReaderConnection { connection ->
        suspend fun number(sql: String): Long =
            connection.usePrepared(sql) { statement -> if (statement.step()) statement.getLong(0) else 0L }
        StorageUse(
            databaseBytes = number("PRAGMA page_count") * number("PRAGMA page_size"),
            titles = number("SELECT COUNT(*) FROM title"),
            chapters = number("SELECT COUNT(*) FROM chapter"),
        )
    }

    fun savedByTitle(): Flow<List<SavedTitle>> = database.downloads().observeSavedByTitle()

    suspend fun savedIdsOf(titleId: Long): List<Long> = database.downloads().savedIdsOf(titleId)

    // The rows of the main tables and the size of the database, read in one go for the advanced performance overlay.
    suspend fun tables(): DatabaseTables = database.useReaderConnection { connection ->
        suspend fun number(sql: String): Long =
            connection.usePrepared(sql) { statement -> if (statement.step()) statement.getLong(0) else 0L }
        DatabaseTables(
            bytes = number("PRAGMA page_count") * number("PRAGMA page_size"),
            titles = number("SELECT COUNT(*) FROM title"),
            inLibrary = number("SELECT COUNT(*) FROM title WHERE inLibrary = 1"),
            chapters = number("SELECT COUNT(*) FROM chapter"),
            marks = number("SELECT COUNT(*) FROM progress"),
            sources = number("SELECT COUNT(*) FROM source"),
            logs = number("SELECT COUNT(*) FROM log"),
        )
    }
}

// What the database of the open profile holds and how much room it takes.
data class StorageUse(val databaseBytes: Long = 0, val titles: Long = 0, val chapters: Long = 0)

// The rows of each main table of the open profile, with the size of its database.
data class DatabaseTables(
    val bytes: Long,
    val titles: Long,
    val inLibrary: Long,
    val chapters: Long,
    val marks: Long,
    val sources: Long,
    val logs: Long,
)
