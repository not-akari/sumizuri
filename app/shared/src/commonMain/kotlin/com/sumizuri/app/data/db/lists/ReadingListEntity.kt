package com.sumizuri.app.data.db.lists

import androidx.room3.ColumnInfo
import androidx.room3.Entity
import androidx.room3.ForeignKey
import androidx.room3.Index
import androidx.room3.PrimaryKey

// A list the person made of titles to share or keep, such as the best of a year. It holds names and kinds only, never a source.
@Entity(tableName = "reading_list")
data class ReadingListEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    @ColumnInfo(defaultValue = "") val about: String = "",
    val sortOrder: Int,
    val made: Long,
    val changed: Long,
)

// One title on a list, by its name and kind, with a note of the person and its place in the list.
@Entity(
    tableName = "reading_list_item",
    foreignKeys = [
        ForeignKey(
            entity = ReadingListEntity::class,
            parentColumns = ["id"],
            childColumns = ["listId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("listId"), Index("matchKey")],
)
data class ReadingListItemEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val listId: Long,
    val title: String,
    val kind: Int,
    @ColumnInfo(defaultValue = "") val note: String = "",
    val position: Int,
    // The name folded with the kind, so the same title written a little differently is found as one.
    @ColumnInfo(defaultValue = "") val matchKey: String = "",
)

// How many titles a list holds.
data class ListCount(val listId: Long, val items: Int)

// Which list holds a title, by the key of the title.
data class ListHolding(val listId: Long, val matchKey: String)
