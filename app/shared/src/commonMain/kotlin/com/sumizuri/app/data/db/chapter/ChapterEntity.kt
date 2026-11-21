package com.sumizuri.app.data.db.chapter

import androidx.room3.ColumnInfo
import androidx.room3.Entity
import androidx.room3.ForeignKey
import androidx.room3.Index
import androidx.room3.PrimaryKey
import com.sumizuri.app.data.db.title.TitleEntity

// A chapter as the source lists it. Read marks live in the progress table, and a publishedAt of 0 means unknown.
@Entity(
    tableName = "chapter",
    foreignKeys = [
        ForeignKey(
            TitleEntity::class,
            parentColumns = ["id"],
            childColumns = ["titleId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index("titleId", "url", unique = true),
        Index("titleId", "number"),
        Index("publishedAt"),
        // Lets the count of new chapters read only the chapters of each title that came after it was added.
        Index("titleId", "publishedAt"),
    ],
)
data class ChapterEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val titleId: Long,
    val url: String,
    val number: Double,
    val name: String?,
    val publishedAt: Long,
    val bookmarked: Boolean,
    // The season an episode belongs to as the source names it, with its name and picture. Null when the source has no seasons.
    val season: String? = null,
    val seasonName: String? = null,
    val seasonCoverUrl: String? = null,
    // Where the chapter is in the list of the source, from 0 at its top, or -1 when the source does not list it, such as a chapter brought from a backup.
    @ColumnInfo(defaultValue = "-1") val sourceOrder: Int = -1,
    // The group that put the chapter out, such as a scanlation team, when the source names one.
    val scanlator: String? = null,
    // The language of the chapter as a code such as en, and the volume it is in, when the source names them.
    val language: String? = null,
    val volume: Double? = null,
    // Any other labels the source gives, such as an edition or a quality, kept as text by chapterTagsText.
    val tags: String? = null,
)
