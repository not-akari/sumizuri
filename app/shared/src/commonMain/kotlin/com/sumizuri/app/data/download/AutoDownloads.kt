package com.sumizuri.app.data.download

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.library.CategoryRepository
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Chapter
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.SettingsRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

private const val Tag = "downloads"

// What saving chapters does on its own, as the choices of the downloads say: saving the new chapters a check finds, saving the next chapters while one is read, and taking read chapters off the device. Only titles in the library are touched.
class AutoDownloads(
    private val library: LibraryRepository,
    private val shelves: CategoryRepository,
    private val downloads: Downloader,
    settings: SettingsRepository,
    private val scope: CoroutineScope,
) {
    val prefs: Flow<DownloadPrefs> = settings.downloadPrefs()

    // The last chapter finished in the reader of each title, whose older read chapters go when the reader is left. Taking them off while the reader still shows them could pull pages from under it.
    private val finished = HashMap<Long, Long>()
    private val lock = Mutex()

    // New chapters a check of the library found for a title. They are saved in reading order, the earliest first, up to the most the person allows for one title.
    suspend fun onNewChapters(titleId: Long, chapterIds: List<Long>) {
        val now = prefs.first()
        if (!now.newChapters || chapterIds.isEmpty() || !inLibrary(titleId)) return
        if (now.skipShelves.isNotEmpty() && shelves.categoriesOf(titleId).any { it in now.skipShelves }) return
        val order = library.chaptersInOrder(titleId).first()
        if (now.newOnlyStarted && order.none { it.read }) return
        val fresh = chapterIds.toHashSet()
        val picked = order.filter { it.id in fresh && !it.read }.map { it.id }
        val kept = if (now.newLimit > 0) picked.take(now.newLimit) else picked
        if (kept.isEmpty()) return
        AppLog.info(Tag, "title $titleId queued ${kept.size} new chapters")
        downloads.queue(titleId, kept)
    }

    // A chapter was opened in the reader. The unread chapters after it are saved, as many as the person chose.
    fun onOpened(titleId: Long, chapterId: Long) {
        scope.launch {
            val now = prefs.first()
            if (now.ahead <= 0 || !inLibrary(titleId)) return@launch
            if (now.aheadOnlySaved && chapterId !in downloads.savedIds(titleId)) return@launch
            val order = library.chaptersInOrder(titleId).first()
            val at = order.indexOfFirst { it.id == chapterId }
            if (at < 0) return@launch
            val next = order
                .drop(at + 1)
                .filter { !it.read }
                .take(now.ahead)
                .map { it.id }
            if (next.isNotEmpty()) downloads.queue(titleId, next)
        }
    }

    // A chapter was read to its end. Its older read chapters are taken off the device once the reader is left.
    fun onFinished(titleId: Long, chapterId: Long) {
        scope.launch { lock.withLock { finished[titleId] = chapterId } }
    }

    // The reader was left: the read chapters that are further behind the last one finished than the person keeps are taken off the device.
    fun onReaderLeft() {
        scope.launch {
            val done = lock.withLock { HashMap(finished).also { finished.clear() } }
            val now = prefs.first()
            if (now.deleteAfter < 0) return@launch
            for ((titleId, chapterId) in done) {
                val order = library.chaptersInOrder(titleId).first()
                val at = order.indexOfFirst { it.id == chapterId }
                if (at < 0) continue
                val behind = order.take((at + 1 - now.deleteAfter).coerceAtLeast(0))
                remove(titleId, behind.filter { it.read }, now)
            }
        }
    }

    // Chapters were marked read by hand, which takes them off the device when the person chose so.
    fun onMarkedRead(titleId: Long, chapterIds: Collection<Long>) {
        if (chapterIds.isEmpty()) return
        scope.launch {
            val now = prefs.first()
            if (!now.deleteOnMark) return@launch
            val ids = chapterIds.toHashSet()
            remove(titleId, library.chaptersInOrder(titleId).first().filter { it.id in ids }, now)
        }
    }

    private suspend fun remove(titleId: Long, chapters: List<Chapter>, now: DownloadPrefs) {
        val saved = downloads.savedIds(titleId)
        val gone = chapters.filter { it.id in saved && !(now.keepBookmarked && it.bookmarked) }.map { it.id }
        if (gone.isEmpty()) return
        AppLog.info(Tag, "title $titleId removed ${gone.size} read chapters")
        downloads.remove(gone)
    }

    private suspend fun inLibrary(titleId: Long): Boolean {
        val title = library.title(titleId).first() ?: return false
        // ponytail: episodes are only saved when asked, as one takes hundreds of megabytes; a choice of their own if wanted.
        return title.inLibrary && title.kind != Kind.Anime && canBeSaved(title.kind, title.sourceId)
    }
}
