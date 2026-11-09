package com.sumizuri.app.data.library

import androidx.room3.withWriteTransaction
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.chapter.ChapterEntity
import com.sumizuri.app.data.db.chapter.ChapterPlaceInList
import com.sumizuri.app.data.migration.chapterNumbers
import com.sumizuri.app.data.model.chapterTagsText
import com.sumizuri.app.source.model.SourceChapter
import kotlinx.coroutines.flow.map

// Writes the chapters a source lists for a title, adding the new ones and bringing the saved ones up to date.
internal class ChapterWriter(private val db: AppDatabase) {
    // A chapter with no number takes its place in the list, counted from the end. Chapters already saved are kept, with their place in the list of the source brought up to date. Only the new ones and the places that moved are written, so a title with nothing new changes nothing and the lists that watch the chapters are not worked out again. Gives the ids of the new ones.
    suspend fun add(titleId: Long, chapters: List<SourceChapter>): List<Long> {
        if (chapters.isEmpty()) return emptyList()
        val numbers = chapterNumbers(chapters)
        val rows = db.chapters().placesOf(titleId)
        val places = rows.associate { it.url to it.sourceOrder }
        val saved = places.keys
        val fresh = chapters.indices.filter { chapters[it].url !in saved }
        if (chapters.any { it.season != null }) keepSeasons(titleId, chapters, saved)
        if (chapters.any {
                groupOf(it) != null || it.language != null || it.volume != null || it.tags.isNotEmpty()
            }
        ) {
            keepCredits(titleId, chapters, saved)
        }
        keepPlaces(titleId, chapters, places)
        keepNames(titleId, chapters, rows)
        if (fresh.isEmpty()) return emptyList()
        val added = db.chapters().insertAll(
            fresh.map { index ->
                val chapter = chapters[index]
                ChapterEntity(
                    titleId = titleId,
                    url = chapter.url,
                    number = numbers[index],
                    name = chapter.title.takeIf { it.isNotBlank() },
                    publishedAt = chapter.uploadedAt ?: 0,
                    bookmarked = false,
                    season = chapter.season,
                    seasonName = chapter.seasonName,
                    seasonCoverUrl = chapter.seasonCoverUrl,
                    sourceOrder = index,
                    scanlator = groupOf(chapter),
                    language = chapter.language,
                    volume = chapter.volume,
                    tags = chapterTagsText(chapter.tags),
                )
            },
        )
        return added.filter { it != -1L }
    }

    // Saved chapters take the place the source lists them at now, which is how the list is put in the order of the site. Only the places that moved are written, together, so a long list that changed is one write.
    private suspend fun keepPlaces(titleId: Long, chapters: List<SourceChapter>, places: Map<String, Int>) {
        val now = HashMap<String, Int>()
        chapters.forEachIndexed { index, chapter -> if (chapter.url !in now) now[chapter.url] = index }
        val moved = now.filter { (url, place) -> url in places && places[url] != place }
        if (moved.isEmpty()) return
        db.withWriteTransaction { for ((url, place) in moved) db.chapters().setSourceOrder(titleId, url, place) }
    }

    // Saved chapters take the name the source gives now, such as after the site renamed one or an older version of the app kept HTML codes for marks in it, and only the names that changed are written, together.
    private suspend fun keepNames(titleId: Long, chapters: List<SourceChapter>, rows: List<ChapterPlaceInList>) {
        val was = rows.associate { it.url to it.name }
        val renamed = chapters
            .mapNotNull { chapter ->
                val name = chapter.title.takeIf { it.isNotBlank() } ?: return@mapNotNull null
                if (chapter.url in was && was[chapter.url] != name) chapter.url to name else null
            }.toMap()
        if (renamed.isEmpty()) return
        db.withWriteTransaction { for ((url, name) in renamed) db.chapters().setName(titleId, url, name) }
    }

    // Chapters saved before their source gave seasons, or whose season moved, take the season the source gives now. Only the ones that differ are written.
    private suspend fun keepSeasons(titleId: Long, chapters: List<SourceChapter>, saved: Set<String>) {
        val now = db.chapters().seasonsOf(titleId).associateBy { it.url }
        for (chapter in chapters) {
            if (chapter.url !in saved) continue
            val was = now[chapter.url] ?: continue
            if (was.season == chapter.season && was.seasonName == chapter.seasonName &&
                was.seasonCoverUrl == chapter.seasonCoverUrl
            ) {
                continue
            }
            db.chapters().setSeason(titleId, chapter.url, chapter.season, chapter.seasonName, chapter.seasonCoverUrl)
        }
    }

    // Chapters saved before their source named their group, language or volume, or whose ones changed, take the ones the source gives now. Only the ones that differ are written.
    private suspend fun keepCredits(titleId: Long, chapters: List<SourceChapter>, saved: Set<String>) {
        val now = db.chapters().creditsOf(titleId).associateBy { it.url }
        val changed = chapters.filter { chapter ->
            val was = now[chapter.url] ?: return@filter false
            chapter.url in saved &&
                (
                    was.scanlator != groupOf(
                        chapter,
                    ) || was.language != chapter.language || was.volume != chapter.volume ||
                        was.tags != chapterTagsText(chapter.tags)
                    )
        }
        if (changed.isEmpty()) return
        db.withWriteTransaction {
            for (chapter in changed) {
                db.chapters().setCredits(
                    titleId,
                    chapter.url,
                    groupOf(chapter),
                    chapter.language,
                    chapter.volume,
                    chapterTagsText(chapter.tags),
                )
            }
        }
    }

    private fun groupOf(chapter: SourceChapter): String? = chapter.scanlator?.trim()?.takeIf { it.isNotEmpty() }
}
