package com.sumizuri.app.feature.reader

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.download.AutoDownloads
import com.sumizuri.app.data.download.Downloader
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.data.settings.ReaderSettingsRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.feature.reader.novel.hasWords
import com.sumizuri.app.feature.reader.novel.wordCount
import com.sumizuri.app.feature.reader.view.looksLikeStrip
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_chapter_gone
import com.sumizuri.app.shared.resources.reader_source_missing
import com.sumizuri.app.shared.resources.reader_source_off
import com.sumizuri.app.source.Source
import com.sumizuri.app.source.SourceError
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.browser.ChallengeSolver
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.source.repo.pictureHeaders
import com.sumizuri.app.source.valueOrNull
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import kotlin.math.roundToInt

// A position this close to the end counts as finished, so opening the chapter again starts from the top.
private const val FinishedAt = 0.99

// The place in a chapter is saved at most this often while reading, and at once when a chapter is finished or the reader is left. Every save makes the lists that watch reading work themselves out again, which can hitch the page while it scrolls.
private const val SaveEveryMs = 5_000L

// This close to the end of a chapter, the pages of the next one are asked for, so turning to it does not wait for the source.
private const val ReadNextWithin = 3

class ReaderViewModel(
    private val chapterId: Long,
    private val library: LibraryRepository,
    private val reading: ReaderSettingsRepository,
    private val sources: SourceRepository,
    private val manager: SourceManager,
    private val solver: ChallengeSolver,
    private val downloads: Downloader,
    private val auto: AutoDownloads,
) : ViewModel() {
    private val mutableState = MutableStateFlow(ReaderState())
    val state: StateFlow<ReaderState> = mutableState

    private var place: ChapterPlace? = null
    private var source: Source? = null
    private var installed: InstalledSource? = null

    // The page last kept for each chapter in this visit, and the chapters whose last page has been on the screen.
    private val kept = mutableMapOf<Long, Int>()
    private val finished = mutableSetOf<Long>()
    private var appending = false

    // The chapters whose next chapter was asked for early already.
    private val readAhead = mutableSetOf<Long>()
    private var chapterList: Job? = null
    private var settingsJob: Job? = null

    // The furthest place reached that is not saved yet. Every save makes the lists that show reading work themselves out again, so the place is saved at most once in a while, and at once when a chapter is finished or left.
    private class PendingSave(val titleId: Long, val chapterId: Long, val position: Double)
    private var pending: PendingSave? = null
    private var saveJob: Job? = null

    private fun flushProgress() {
        val save = pending ?: return
        pending = null
        saveJob?.cancel()
        saveJob = null
        viewModelScope.launch { library.saveProgress(save.titleId, save.chapterId, save.position, finished = false) }
    }

    // Called when the reader leaves the screen, so the place is saved before the title page reads it.
    fun onLeave() {
        flushProgress()
        auto.onReaderLeft()
    }

    // Called each time the reader is shown. The model outlives the page, so it forgets the last visit and reads the saved place again.
    fun open() {
        flushProgress()
        kept.clear()
        finished.clear()
        appending = false
        mutableState.value = ReaderState()
        chapterList?.cancel()
        settingsJob?.cancel()
        viewModelScope.launch { load() }
    }

    // The shapes of some pages of the chapter, which tell a long strip from pages. None when they could not be read, so it is tried again with the next chapter.
    fun onAspects(aspects: List<Double>) {
        val here = place ?: return
        viewModelScope.launch {
            val strip = looksLikeStrip(aspects)
            if (aspects.isNotEmpty()) reading.setModeChecked(here.titleId)
            if (strip) reading.setTitleMode(here.titleId, ReaderMode.Continuous)
            mutableState.update {
                it.copy(
                    modeKnown = true,
                    settings = if (strip) it.settings.copy(titleMode = ReaderMode.Continuous) else it.settings,
                )
            }
        }
    }

    // The mode picked on the reader, kept for this title.
    fun onMode(mode: ReaderMode) {
        val here = place ?: return
        viewModelScope.launch { reading.setTitleMode(here.titleId, mode) }
    }

    fun onDefaultMode(mode: ReaderMode) {
        viewModelScope.launch { reading.setDefaultMode(mode) }
    }

    // Opens the site for a person to pass the bot check, then reads the chapter again.
    fun onSolve() {
        val url = mutableState.value.challengeUrl ?: return
        viewModelScope.launch {
            solver.solve(url)
            onRetry()
        }
    }

    // Puts a bookmark on the chapter that is being read, or takes it off.
    fun onBookmark() {
        val now = mutableState.value
        val marked = now.chapters.firstOrNull { it.id == now.chapterId }?.bookmarked ?: return
        viewModelScope.launch { library.setBookmarked(now.chapterId, !marked) }
    }

    // Makes the picture of a page the cover of the title.
    fun onSetCover(url: String) {
        val here = place ?: return
        viewModelScope.launch { library.setCustomCover(here.titleId, url) }
    }

    fun onSettings(settings: ReaderSettings) {
        val here = place ?: return
        viewModelScope.launch {
            reading.save(here.titleId, settings)
            reading.saveGlobal(settings)
        }
    }

    fun onRetry() {
        mutableState.update { it.copy(loading = true, message = null, challengeUrl = null) }
        viewModelScope.launch { load() }
    }

    // Called with the page in view and the furthest page on the screen. The place kept is the page in view, so going back a few pages and leaving opens there next time. A chapter is read once its last page has been on the screen.
    fun onProgress(shown: Int, reached: Int, count: Int) {
        readNextAhead(reached, count)
        val now = mutableState.value
        val titleId = place?.titleId ?: return
        if (now.settings.incognito) return
        // One chapter on the screen, as in the turned pages, counts its pages the way the viewer does. A scroll over several chapters knows each chapter's own count.
        val many = now.segments.size > 1
        fun segmentOf(index: Int) = if (many) now.segments.at(index) else now.segments.firstOrNull()
        fun localOf(index: Int, segment: ReaderSegment) = if (many) index - segment.start else index
        fun totalOf(segment: ReaderSegment) = if (many) segment.count else count
        segmentOf(reached)?.let { segment ->
            val total = totalOf(segment)
            if (total > 0 && localOf(reached, segment) >= total - 1 && finished.add(segment.chapterId)) {
                viewModelScope.launch {
                    library.saveProgress(titleId, segment.chapterId, 1.0, finished = true)
                    auto.onFinished(titleId, segment.chapterId)
                }
            }
        }
        val segment = segmentOf(shown) ?: return
        val total = totalOf(segment)
        val local = localOf(shown, segment)
        if (total == 0 || kept[segment.chapterId] == local) return
        kept[segment.chapterId] = local
        val last = total - 1
        val position = if (last <= 0) 1.0 else (local.toDouble() / last).coerceIn(0.0, 1.0)
        // A place in another chapter saves the one before at once.
        if (pending?.chapterId != segment.chapterId) flushProgress()
        pending = PendingSave(titleId, segment.chapterId, position)
        if (saveJob?.isActive != true) {
            saveJob = viewModelScope.launch {
                delay(SaveEveryMs)
                saveJob = null
                flushProgress()
            }
        }
    }

    // Called with the page in view. When the scroll has gone on into another chapter, that chapter becomes the one the bars talk about.
    fun onActive(page: Int) {
        val now = mutableState.value
        val segment = now.segments.at(page) ?: return
        if (segment.chapterId == now.chapterId) return
        place?.let { auto.onOpened(it.titleId, segment.chapterId) }
        mutableState.update {
            it.activate(segment)
        }
    }

    // Near the end of a chapter the page list of the next one is asked for once and kept a while, so opening it is at once. A chapter saved to the device needs nothing.
    private fun readNextAhead(index: Int, count: Int) {
        val now = mutableState.value
        val many = now.segments.size > 1
        val segment = (if (many) now.segments.at(index) else now.segments.firstOrNull()) ?: return
        val local = if (many) index - segment.start else index
        val total = if (many) segment.count else count
        val next = segment.nextId ?: return
        val opened = source ?: return
        if (total - 1 - local > ReadNextWithin || !readAhead.add(segment.chapterId)) return
        viewModelScope.launch {
            val here = library.chapterPlace(next) ?: return@launch
            if (savedChapterPages(downloads, here.titleId, here.id) != null) return@launch
            loadChapterPages(opened, here.url, here.kind, here.sourceId)
        }
    }

    // Called when the pages in view are the last few that are loaded. The chapter after the last one is read in and added to the scroll.
    fun onNearEnd() {
        val now = mutableState.value
        val next = now.segments.lastOrNull()?.nextId ?: return
        if (appending || !now.settings.inlineNext || now.mode != ReaderMode.Continuous) return
        appending = true
        viewModelScope.launch {
            try {
                append(next)
            } finally {
                appending = false
            }
        }
    }

    private suspend fun append(id: Long) {
        val here = library.chapterPlace(id) ?: return
        val base = installed?.baseUrl.orEmpty()
        // A saved chapter comes from the device, and one that is not saved from the source.
        val loaded = savedChapterPages(downloads, here.titleId, here.id)?.let { ChapterLoad.Pages(it) }
            ?: source?.let { opened ->
                loadChapterPages(
                    opened,
                    here.url,
                    here.kind,
                    here.sourceId,
                ) as? ChapterLoad.Pages
            }
            ?: return
        mutableState.update {
            // Pictures and words do not mix in one scroll.
            if (hasWords(loaded.pages) != it.isText) return@update it
            it.copy(
                pages = it.pages + loaded.pages,
                segments = it.segments + segmentOf(here, it.pages.size, loaded.pages.size, base),
            )
        }
    }

    private suspend fun load() {
        val here = library.chapterPlace(chapterId) ?: return fail(fixed(Res.string.reader_chapter_gone))
        place = here
        auto.onOpened(here.titleId, here.id)
        settingsJob?.cancel()
        settingsJob = viewModelScope.launch {
            reading.observe(here.titleId).collect { saved -> mutableState.update { it.copy(settings = saved) } }
        }
        chapterList?.cancel()
        chapterList = viewModelScope.launch {
            // The reader only shows which chapters are read and bookmarked. The place in each is left out, so saving the place while reading does not change the state and draw the whole reader again.
            library
                .chaptersInOrder(here.titleId)
                .map { all -> all.map { it.copy(position = null, readAt = null) } }
                .distinctUntilChanged()
                .collect { all -> mutableState.update { it.copy(chapters = all) } }
        }
        mutableState.update {
            it.copy(
                chapterId = here.id,
                titleId = here.titleId,
                titleName = here.titleName,
                coverUrl = here.coverUrl,
                sourceId = here.sourceId,
                kind = here.kind,
                chapterName = here.name?.takeIf { name -> name.isNotBlank() },
                chapterNumber = here.number,
                previousId = here.previousId,
                nextId = here.nextId,
            )
        }
        val found = sources.find(here.sourceId)
        installed = found
        found?.let { mutableState.update { state -> state.copy(webUrl = webAddress(here.url, it.baseUrl)) } }
        // A chapter saved to the device is read from it, with no connection and even with its source gone. The source is still opened, quietly, for its comments and the chapter after.
        val offline = savedChapterPages(downloads, here.titleId, here.id)
        if (offline != null) {
            show(here, offline, found?.baseUrl.orEmpty(), emptyMap())
            if (found != null &&
                found.enabled
            ) {
                manager.open(found).valueOrNull()?.let { opened -> useSource(here, found, opened) }
            }
            return
        }
        if (found == null) return fail(fixed(Res.string.reader_source_missing))
        if (!found.enabled) return fail(fixed(Res.string.reader_source_off))
        val opened = when (val result = manager.open(found)) {
            is SourceResult.Err -> return fail(
                ReaderMessage.Detail(result.error.message),
                (result.error as? SourceError.Challenge)?.url,
            )

            is SourceResult.Ok -> result.value
        }
        useSource(here, found, opened)
        val shown = when (val loaded = loadChapterPages(opened, here.url, here.kind, here.sourceId)) {
            is ChapterLoad.Failed -> return fail(loaded.message, loaded.challengeUrl)
            is ChapterLoad.Pages -> loaded.pages
        }
        show(here, shown, found.baseUrl, pictureHeaders(found))
    }

    // Keeps the source for the chapters after this one, and offers the comments of the chapter when the code of the source has them.
    private fun useSource(here: ChapterPlace, found: InstalledSource, opened: Source) {
        source = opened
        if (opened.info.hasChapterComments) {
            val name = here.name?.takeIf { it.isNotBlank() }
            mutableState.update {
                it.copy(
                    comments = CommentsTarget(found.id, here.url, here.titleName, here.url, name),
                )
            }
        }
    }

    // Shows the pages of the chapter, from the place the reader left it.
    private suspend fun show(here: ChapterPlace, shown: List<ReaderPage>, base: String, headers: Map<String, String>) {
        val saved = here.position?.takeIf { it < FinishedAt } ?: 0.0
        val needsLook = shown.first().imageUrl != null &&
            reading.titleMode(here.titleId) == null && !reading.modeChecked(here.titleId)
        mutableState.update {
            it.copy(
                loading = false,
                pages = shown,
                segments = listOf(segmentOf(here, 0, shown.size, base)),
                modeKnown = !needsLook,
                imageHeaders = headers,
                startIndex = (saved * (shown.size - 1)).roundToInt(),
                startFraction = saved,
                words = if (hasWords(shown)) wordCount(shown) else 0,
            )
        }
    }

    private fun fixed(text: StringResource) = ReaderMessage.Fixed(text)

    private fun fail(message: ReaderMessage, challengeUrl: String? = null) = mutableState.update {
        it.copy(loading = false, message = message, challengeUrl = challengeUrl)
    }
}
