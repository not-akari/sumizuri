package com.sumizuri.app.data.db.title

// A title without its counts, so the library list loads fast.
data class TitleRow(
    val id: Long,
    val name: String,
    val kind: Int,
    val coverUrl: String?,
    val status: Int,
    val summary: String,
    val author: String,
    val genres: String,
    val inLibrary: Boolean,
    val sourceId: String,
    val rating: Double?,
    val webUrl: String?,
    val addedAt: Long,
    val favorite: Boolean,
)

// Where a title came from, which is what a refresh needs to ask the source again.
data class TitleOrigin(val sourceId: String, val externalId: String)

// The name of a saved title and its source, to find a title saved twice.
data class TitleName(val id: Long, val name: String, val kind: Int, val sourceId: String)

// How many titles of the library one source holds.
data class SourceCount(val sourceId: String, val count: Int)

// A saved title with the source it came from, to tell which ones a source can still reach.
data class TitleKey(val id: Long, val sourceId: String, val externalId: String)

// The unread chapters of one title and how many chapters it has, worked out apart from the titles.
data class UnreadCount(val titleId: Long, val unread: Int, val total: Int)
