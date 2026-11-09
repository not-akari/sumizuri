package com.sumizuri.app.feature.title.chapter

import com.sumizuri.app.data.download.Downloader
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.feature.reader.ChapterLoad
import com.sumizuri.app.feature.reader.ReaderPage
import com.sumizuri.app.feature.reader.loadChapterPages
import com.sumizuri.app.feature.reader.savedChapterPages
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.repo.pictureHeaders
import com.sumizuri.app.source.valueOrNull
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.sync.withPermit
import kotlin.random.Random

// How many chapters are asked for their pages at once, so a grid coming into view does not flood the source.
private const val AtOnce = 2

// The first pages of a chapter are often a cover and credits, and the last one an end card, so the picture comes from between them.
private const val SkipStart = 2
private const val SkipEnd = 1

// A page from inside a chapter for its cell of the grid, with the headers its address wants and the source it comes through.
data class ChapterPicture(val url: String, val headers: Map<String, String>, val sourceId: String)

// Finds a page from inside each chapter of a saved title, from its saved files or else from its source, and keeps what it found while the app runs.
class ChapterPictures(
    private val library: LibraryRepository,
    private val sources: SourceRepository,
    private val manager: SourceManager,
    private val downloads: Downloader,
) {
    private val found = HashMap<Long, ChapterPicture?>()
    private val lock = Mutex()
    private val gate = Semaphore(AtOnce)

    // The picture of a chapter by its row id, or null when it has none, such as a chapter of words or a video.
    suspend fun of(chapterId: Long): ChapterPicture? {
        lock.withLock { if (chapterId in found) return found[chapterId] }
        val picture = gate.withPermit { look(chapterId) }
        lock.withLock { found[chapterId] = picture }
        return picture
    }

    private suspend fun look(chapterId: Long): ChapterPicture? {
        val place = library.chapterPlace(chapterId) ?: return null
        if (place.kind == Kind.Anime || place.kind == Kind.Novel) return null
        val installed = sources.find(place.sourceId) ?: return null
        val pages = savedChapterPages(downloads, place.titleId, chapterId)
            ?: manager.open(installed).valueOrNull()?.let { source ->
                (loadChapterPages(source, place.url, place.kind, place.sourceId) as? ChapterLoad.Pages)?.pages
            }
            ?: return null
        val page = pickPage(pages.filter { it.imageUrl != null && it.descramble == null }, chapterId) ?: return null
        return ChapterPicture(page.imageUrl ?: return null, pictureHeaders(installed), place.sourceId)
    }
}

// A page picked at random from after the first pages and before the last, the same one each time for the same chapter. A short chapter gives its middle page.
internal fun pickPage(pages: List<ReaderPage>, seed: Long): ReaderPage? {
    if (pages.isEmpty()) return null
    val last = pages.lastIndex - SkipEnd
    if (last < SkipStart) return pages[pages.size / 2]
    return pages[Random(seed).nextInt(SkipStart, last + 1)]
}
