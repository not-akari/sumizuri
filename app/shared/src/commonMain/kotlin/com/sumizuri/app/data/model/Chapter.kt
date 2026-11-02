package com.sumizuri.app.data.model

// A chapter of a saved title. The position is how far the reader got, from 0 to 1, and readAt is when it was marked read.
data class Chapter(
    val id: Long,
    val number: Double,
    val name: String?,
    val publishedAt: Long,
    val read: Boolean,
    val bookmarked: Boolean,
    val readAt: Long? = null,
    val position: Double? = null,
    val season: String? = null,
    val seasonName: String? = null,
    val seasonCoverUrl: String? = null,
    // Where the chapter is in the list of the source, or -1 when it is not listed.
    val sourceOrder: Int = -1,
    // The group that put it out, such as a scanlation team, when the source names one.
    val scanlator: String? = null,
    // Its language as a code such as en, and its volume, when the source names them.
    val language: String? = null,
    val volume: Double? = null,
    // Other labels the source gave, by name.
    val tags: Map<String, String> = emptyMap(),
)

// Where a chapter sits in its title and what the reader needs to open it, with the ids of its neighbours.
data class ChapterPlace(
    val id: Long,
    val titleId: Long,
    val url: String,
    val number: Double,
    val name: String?,
    val titleName: String,
    val kind: Kind,
    val sourceId: String,
    // The cover of the title, which the reader shows while the chapter comes in.
    val coverUrl: String? = null,
    val previousId: Long?,
    val nextId: Long?,
    // How far the reader got, from 0 to 1, or null when the chapter was not opened before.
    val position: Double?,
)

// One line of Updates or History, with the time as a number so the screen can put it into words.
data class FeedItem(val title: Title, val number: Double, val at: Long)
