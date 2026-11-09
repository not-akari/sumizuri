package com.sumizuri.app.feature.title

import com.sumizuri.app.data.db.download.DownloadEntity
import com.sumizuri.app.data.model.Chapter
import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.Facet
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.source.SourceError

// A chapter that was read this far is counted as finished.
private const val Finished = 0.99

// The choices of the person for this page that are not in the database row of the title.
internal data class Look(
    val oldestFirst: Boolean = false,
    val grid: Boolean = false,
    val pictures: Boolean = false,
    val hideDuplicates: Boolean = false,
    val sort: ChapterSort = ChapterSort.Source,
    val filter: ChapterFilter = ChapterFilter(),
    val hidden: Set<Facet> = emptySet(),
    val selected: Set<Long> = emptySet(),
    val focus: Pair<Float, Float>? = null,
)

// How the asking of the source went, and the switch between chapters and volumes.
internal data class PageStatus(
    val loading: Boolean,
    val error: SourceError?,
    val sourceName: String?,
    val volumeSwitch: Boolean?,
)

// What the page shows beside the title and its chapters, put together so the page is worked out once when any of it changes.
internal data class PageExtras(
    val look: Look,
    val favorites: Boolean,
    val comments: CommentsTarget?,
    val downloads: Map<Long, DownloadEntity>,
    val seasonCovers: Map<String, String>,
)

// A chapter of the database as a row of the list, with how far it was read when it was started and not finished.
internal fun Chapter.toItem() = ChapterItem(
    key = "c$id",
    id = id,
    number = number,
    name = name?.takeIf { it.isNotBlank() },
    at = publishedAt,
    read = read,
    bookmarked = bookmarked,
    readAt = readAt,
    progress = position?.takeIf { !read && it > 0 && it < Finished }?.toFloat(),
    season = season,
    seasonName = seasonName,
    seasonCoverUrl = seasonCoverUrl,
    sourceOrder = sourceOrder,
    scanlator = scanlator,
    language = language,
    volume = volume,
    tags = tags,
)
