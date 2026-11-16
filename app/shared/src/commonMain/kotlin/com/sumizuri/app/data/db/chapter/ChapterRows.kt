package com.sumizuri.app.data.db.chapter

// What the reader needs to ask the source for a chapter's pages.
data class ChapterRef(
    val id: Long,
    val titleId: Long,
    val url: String,
    val number: Double,
    val name: String?,
    val season: String? = null,
)

// A chapter of one title with its read mark, for the chapter list.
data class ChapterRow(
    val id: Long,
    val number: Double,
    val name: String?,
    val publishedAt: Long,
    val read: Boolean,
    val bookmarked: Boolean,
    // When the chapter was marked read, and how far the reader got in it.
    val readAt: Long?,
    val position: Double?,
    val season: String?,
    val seasonName: String?,
    val seasonCoverUrl: String?,
    val sourceOrder: Int,
    val scanlator: String?,
    val language: String?,
    val volume: Double?,
    val tags: String?,
)

// One line of the updates or history list, before it is joined to its title.
data class FeedRow(val titleId: Long, val number: Double, val at: Long)

// The day a chapter of a title in the library came out, for working out when the next one is due.
data class ReleaseRow(val titleId: Long, val at: Long)

// A chapter that came out and is not read, for the updates page.
data class UpdateRow(val id: Long, val titleId: Long, val number: Double, val name: String?, val at: Long)

// The group, language, volume and other labels of a saved chapter, by its address.
data class ChapterCredits(
    val url: String,
    val scanlator: String?,
    val language: String?,
    val volume: Double?,
    val tags: String?,
)

// The season a saved chapter is in, by its address.
data class ChapterSeason(val url: String, val season: String?, val seasonName: String?, val seasonCoverUrl: String?)

// Where a chapter sits among the seasons of its title.
data class ChapterSlot(
    val id: Long,
    val number: Double,
    val season: String?,
    val sourceOrder: Int,
    val publishedAt: Long,
    val name: String?,
    val bookmarked: Boolean = false,
    val scanlator: String? = null,
    val language: String? = null,
    val tags: String? = null,
)

// The place a saved chapter has in the list of its source, its name and its number, by its address.
data class ChapterPlaceInList(val url: String, val sourceOrder: Int, val name: String?, val number: Double)
