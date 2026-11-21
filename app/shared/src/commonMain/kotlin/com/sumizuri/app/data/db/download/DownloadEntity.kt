package com.sumizuri.app.data.db.download

import androidx.room3.Embedded
import androidx.room3.Entity
import androidx.room3.ForeignKey
import androidx.room3.Index
import androidx.room3.PrimaryKey
import com.sumizuri.app.data.db.chapter.ChapterEntity

// A chapter that is waiting to be saved to the device, is being saved, was saved or failed. The pages are the files of the chapter, of which saved are on the device so far. The row goes with its chapter.
@Entity(
    tableName = "download",
    foreignKeys = [
        ForeignKey(
            ChapterEntity::class,
            parentColumns = ["id"],
            childColumns = ["chapterId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("titleId"), Index("state")],
)
data class DownloadEntity(
    @PrimaryKey val chapterId: Long,
    val titleId: Long,
    val state: Int,
    val pages: Int = 0,
    val saved: Int = 0,
    val bytes: Long = 0,
    val error: String? = null,
    val queuedAt: Long,
    // When the chapter was saved. Databases of version 15 already have this column, so it stays.
    val finishedAt: Long? = null,
)

// Where a download is. The numbers are what the database keeps.
enum class DownloadState(val code: Int) {
    Queued(0),
    Running(1),
    Done(2),
    Failed(3),
    ;

    companion object {
        fun of(code: Int): DownloadState = entries.firstOrNull { it.code == code } ?: Queued
    }
}

val DownloadEntity.status: DownloadState get() = DownloadState.of(state)

// How far a download is, from 0 to 1, or 0 while its pages are not known yet.
val DownloadEntity.progress: Float get() = if (pages > 0) saved.toFloat() / pages else 0f

// The saved chapters of one title and the room they take.
data class SavedTitle(val titleId: Long, val chapters: Int, val bytes: Long)

// One line of the page of downloads: the download with the names of its title and chapter.
data class DownloadRow(
    @Embedded val download: DownloadEntity,
    val titleName: String,
    val chapterName: String?,
    val number: Double,
)
