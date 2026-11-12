package com.sumizuri.app.feature.reader

import com.sumizuri.app.data.download.Downloader
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.net.SiteKinds
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.reader.novel.paragraphsOf
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_no_pages
import com.sumizuri.app.source.Source
import com.sumizuri.app.source.SourceError
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourcePage

// What came of asking a source for the pages of one chapter.
sealed interface ChapterLoad {
    data class Pages(val pages: List<ReaderPage>) : ChapterLoad

    // The address of the site is given when a bot check was what stopped it.
    data class Failed(val message: ReaderMessage, val challengeUrl: String? = null) : ChapterLoad
}

// The page lists asked for lately, such as the chapter after the open one read ahead, so opening it does not wait for the source. They go after a few minutes, as some sites give page addresses that stop working. It is used from the main thread only.
private object RecentPageLists {
    private const val KeepMs = 8 * 60 * 1000L
    private const val MaxLists = 12
    private val lists = LinkedHashMap<String, Pair<Long, List<ReaderPage>>>()

    fun get(url: String): List<ReaderPage>? {
        val (at, pages) = lists[url] ?: return null
        if (nowMillis() - at > KeepMs) {
            lists.remove(url)
            return null
        }
        return pages
    }

    fun put(url: String, pages: List<ReaderPage>) {
        lists.remove(url)
        lists[url] = nowMillis() to pages
        while (lists.size > MaxLists) lists.remove(lists.keys.first())
    }
}

// Asks the source for the pages of a chapter and puts them in order. Words are cut into paragraphs, so a chapter in one block can still be scrolled and counted.
internal suspend fun loadChapterPages(
    source: Source,
    url: String,
    kind: Kind,
    sourceId: String? = null,
    books: Boolean = true,
): ChapterLoad {
    RecentPageLists.get(url)?.let { return ChapterLoad.Pages(it) }
    val pages = when (val result = source.pages(SourceChapter(url = url, title = ""), books)) {
        is SourceResult.Err -> return ChapterLoad.Failed(
            ReaderMessage.Detail(result.error.message),
            (result.error as? SourceError.Challenge)?.url,
        )

        is SourceResult.Ok -> result.value
    }
    // The hosts of the pictures take the way of the kind of the title.
    pages.forEach { page -> page.imageUrl?.let { SiteKinds.mark(it, kind, sourceId) } }
    val shown = readerPagesOf(pages)
    if (shown.isEmpty()) return ChapterLoad.Failed(ReaderMessage.Fixed(Res.string.reader_no_pages))
    RecentPageLists.put(url, shown)
    return ChapterLoad.Pages(shown)
}

// The pages of a chapter saved to the device, in the same shape, or null when it is not saved or its files are gone.
internal suspend fun savedChapterPages(downloads: Downloader, titleId: Long, chapterId: Long): List<ReaderPage>? =
    downloads.savedPages(titleId, chapterId)?.let(::readerPagesOf)?.takeIf { it.isNotEmpty() }

// The pages in order, with the ones that have nothing in them left out and words cut into paragraphs.
private fun readerPagesOf(pages: List<SourcePage>): List<ReaderPage> {
    val kept = pages
        .sortedBy {
            it.index
        }.filter { it.imageUrl != null || !it.text.isNullOrBlank() }
        .map { ReaderPage(it.imageUrl, it.text, it.descramble) }
    return if (kept.firstOrNull()?.imageUrl == null) paragraphsOf(kept) else kept
}

// The stretch of the pages that belongs to one chapter. A scroll that goes on into the next chapter has one for each chapter it holds, with the pages of the chapter from its start page on.
data class ReaderSegment(
    val chapterId: Long,
    val start: Int,
    val count: Int,
    val name: String?,
    val number: Double,
    val previousId: Long?,
    val nextId: Long?,
    // The address of the chapter on the website of its source, or null when it cannot be worked out.
    val webUrl: String?,
)

// The chapter a page belongs to, which is the last one that starts at or before it.
fun List<ReaderSegment>.at(page: Int): ReaderSegment? = lastOrNull { page >= it.start } ?: firstOrNull()
