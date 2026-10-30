package com.sumizuri.app.data.download

import com.sumizuri.app.StartQuietMs
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.download.DownloadEntity
import com.sumizuri.app.data.db.download.DownloadRow
import com.sumizuri.app.data.db.download.DownloadState
import com.sumizuri.app.data.db.download.status
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.local.LocalSources
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.PlayerPrefsRepository
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.data.work.BusyHandle
import com.sumizuri.app.data.work.BusyKind
import com.sumizuri.app.data.work.BusyWork
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.download_err_kind
import com.sumizuri.app.shared.resources.download_err_no_pages
import com.sumizuri.app.shared.resources.download_err_no_video
import com.sumizuri.app.shared.resources.download_err_page
import com.sumizuri.app.shared.resources.download_err_source
import com.sumizuri.app.shared.resources.download_save_failed
import com.sumizuri.app.feature.player.VideoChoice
import com.sumizuri.app.playback.hls.expandHlsMasters
import com.sumizuri.app.source.Source
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourcePage
import com.sumizuri.app.source.model.SourceVideo
import com.sumizuri.app.source.repo.pictureHeaders
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.updateAndGet
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import org.jetbrains.compose.resources.getString
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeSource

// How many times a page that fails is asked for again. How many pages are fetched at once is a choice of the person.
private const val PageTries = 3

// How often the queue looks again whether the device is on Wi-Fi, while it waits for it.
private const val NetworkCheckMs = 30_000L

// Progress reaches the database at most this often, as each write redraws every page that shows it.
private const val ProgressEveryMs = 500L

// Why a chapter could not be saved, in words for the page of downloads.
class DownloadProblem(message: String) : Exception(message)

// Whether the chapters of a title can be saved to the device. Files that are on the device already need no saving.
fun canBeSaved(kind: Kind, sourceId: String?): Boolean = !LocalSources.isLocal(sourceId)

// Saves chapters to the device so they can be read with no connection. Chapters wait in a queue and are saved one at a time, a few pages at once. The queue is kept in the database, so it goes on after the app is opened again, and a chapter that was being saved when it closed starts over.
class Downloader(
    private val db: AppDatabase,
    private val library: LibraryRepository,
    private val sources: SourceRepository,
    private val manager: SourceManager,
    private val settings: SettingsRepository,
    private val files: DownloadFiles,
    private val scope: CoroutineScope,
    private val playerPrefs: PlayerPrefsRepository,
) {
    private val wake = Channel<Unit>(Channel.CONFLATED)
    private val lock = Mutex()
    private var running: Pair<Long, Job>? = null

    val paused: Flow<Boolean> = settings.flag(SettingKey.DownloadsPaused, false)

    private val prefs = settings.downloadPrefs()

    // True while chapters wait because only Wi-Fi may be used and the device is on another connection.
    private val mutableWaitingForWifi = MutableStateFlow(false)
    val waitingForWifi: StateFlow<Boolean> = mutableWaitingForWifi

    // How many chapters wait or are being saved.
    val active: Flow<Int> = db.downloads().observeActive()

    fun observeAll(): Flow<List<DownloadRow>> = db.downloads().observeAll()

    // The downloads of a title by chapter, for the marks on its chapters.
    fun observeOf(titleId: Long): Flow<Map<Long, DownloadEntity>> =
        db.downloads().observeOf(titleId).map { rows -> rows.associateBy { it.chapterId } }

    // Starts the queue once the first screen of the app has loaded, putting back chapters that were being saved when the app closed and clearing folders the library no longer has.
    fun start() {
        scope.launch(Dispatchers.IO) {
            delay(StartQuietMs)
            db.downloads().requeueRunning()
            sweep()
            work()
        }
    }

    // Puts chapters of a title in the queue, in the order given. A chapter saved or waiting already is left as it is, and one that failed is asked for again.
    suspend fun queue(titleId: Long, chapterIds: List<Long>) {
        if (chapterIds.isEmpty()) return
        val now = nowMillis()
        val known = db.downloads().getMany(chapterIds).mapTo(HashSet()) { it.chapterId }
        db.downloads().insertAll(
            chapterIds.filter { it !in known }.mapIndexed { index, id ->
                DownloadEntity(
                    id,
                    titleId,
                    DownloadState.Queued.code,
                    queuedAt =
                    now + index,
                )
            },
        )
        db.downloads().requeueFailed(chapterIds, now)
        wake.trySend(Unit)
    }

    // Takes chapters out of the queue and off the device, stopping the one being saved when it is one of them.
    suspend fun remove(chapterIds: List<Long>) {
        if (chapterIds.isEmpty()) return
        val rows = db.downloads().getMany(chapterIds)
        lock.withLock {
            val current = running
            if (current != null && current.first in chapterIds) current.second.cancel()
        }
        db.downloads().deleteMany(chapterIds)
        withContext(Dispatchers.IO) { for (row in rows) files.delete(row.titleId, row.chapterId) }
    }

    // Asks again for every chapter that failed.
    suspend fun retryFailed() {
        db.downloads().requeueFailed(nowMillis())
        wake.trySend(Unit)
    }

    // Stops saving, putting the chapter being saved back in the queue, until resumed. The choice is kept for the next time the app opens.
    suspend fun pause() {
        settings.setFlag(SettingKey.DownloadsPaused, true)
        lock.withLock { running?.second?.cancel() }
    }

    suspend fun resume() {
        settings.setFlag(SettingKey.DownloadsPaused, false)
        wake.trySend(Unit)
    }

    // Looks at the queue again at once, such as after the choice of Wi-Fi only changed.
    fun nudge() {
        wake.trySend(Unit)
    }

    // The chapters of a title that are saved on the device.
    suspend fun savedIds(titleId: Long): Set<Long> = db
        .downloads()
        .observeOf(titleId)
        .first()
        .filter { it.status == DownloadState.Done }
        .mapTo(HashSet()) { it.chapterId }

    // The pages of a saved chapter, with its pictures as addresses on the device, or null when it is not saved.
    suspend fun savedPages(titleId: Long, chapterId: Long): List<SourcePage>? {
        if (db.downloads().get(chapterId)?.status != DownloadState.Done) return null
        return withContext(Dispatchers.IO) { files.read(titleId, chapterId) }
    }

    // The saved video of an episode, played from the device, or null when it is not saved.
    suspend fun savedVideo(titleId: Long, chapterId: Long): SourceVideo? {
        if (db.downloads().get(chapterId)?.status != DownloadState.Done) return null
        return withContext(Dispatchers.IO) { files.readVideo(titleId, chapterId) }
    }

    // While chapters are being saved the app stays awake in the background, with a notice of how many are done out of the ones in the queue. Its stop button pauses the queue.
    private var busy: BusyHandle? = null
    private var savedThisRun = 0
    private var leftInQueue = 0

    private fun idle() {
        busy?.end()
        busy = null
    }

    private suspend fun work() {
        while (true) {
            if (paused.first()) {
                idle()
                wake.receive()
                continue
            }
            val next = db.downloads().nextQueued()
            if (next == null) {
                mutableWaitingForWifi.value = false
                idle()
                wake.receive()
                continue
            }
            // On a metered connection with Wi-Fi only chosen, the queue waits and looks again now and then.
            if (prefs.first().wifiOnly && !onUnmeteredNetwork()) {
                mutableWaitingForWifi.value = true
                idle()
                withTimeoutOrNull(NetworkCheckMs) { wake.receive() }
                continue
            }
            mutableWaitingForWifi.value = false
            leftInQueue = active.first()
            if (busy == null) {
                savedThisRun = 0
                busy =
                    BusyWork.begin(
                        BusyKind.Downloads,
                        { savedThisRun to savedThisRun + leftInQueue },
                        { scope.launch { pause() } },
                    )
            }
            coroutineScope {
                val job = launch { save(next) }
                lock.withLock { running = next.chapterId to job }
                job.join()
                lock.withLock { running = null }
                savedThisRun++
            }
        }
    }

    private suspend fun save(item: DownloadEntity) {
        val place = library.chapterPlace(item.chapterId)
        if (place == null) {
            db.downloads().deleteMany(listOf(item.chapterId))
            return
        }
        db.downloads().setState(item.chapterId, DownloadState.Running.code)
        try {
            if (!canBeSaved(place.kind, place.sourceId)) throw DownloadProblem(getString(Res.string.download_err_kind))
            val installed = sources.find(place.sourceId)?.takeIf { it.enabled }
                ?: throw DownloadProblem(getString(Res.string.download_err_source))
            val source = when (val opened = manager.open(installed)) {
                is SourceResult.Err -> throw DownloadProblem(opened.error.message)
                is SourceResult.Ok -> opened.value
            }
            if (place.kind == Kind.Anime) return saveEpisode(item, place, source)
            val pages = when (val got = source.pages(SourceChapter(url = place.url, title = ""))) {
                is SourceResult.Err -> throw DownloadProblem(got.error.message)
                is SourceResult.Ok -> got.value
            }.sortedBy { it.index }.filter { it.imageUrl != null || !it.text.isNullOrBlank() }
            if (pages.isEmpty()) throw DownloadProblem(getString(Res.string.download_err_no_pages))
            val headers = pictureHeaders(installed)
            val part = withContext(Dispatchers.IO) { files.begin(place.titleId, place.id) }
            val progress = MutableStateFlow(0 to 0L)
            val clock = TimeSource.Monotonic.markNow()
            val written = MutableStateFlow(Duration.ZERO)
            val gate = Semaphore(prefs.first().pagesAtOnce)
            db.downloads().setProgress(item.chapterId, pages.size, 0, 0)
            val saved = coroutineScope {
                pages
                    .mapIndexed { index, page ->
                        async {
                            gate.withPermit {
                                val url = page.imageUrl ?: return@withPermit SavedPage(text = page.text)
                                val bytes = fetch(url, headers)
                                val name = (index + 1).toString().padStart(4, '0') + "." + extensionOf(bytes)
                                withContext(Dispatchers.IO) { files.write(part, name, bytes) }
                                val (count, size) = progress.updateAndGet { (count, size) ->
                                    count + 1 to
                                        size + bytes.size
                                }
                                val now = clock.elapsedNow()
                                if (now - written.value >= ProgressEveryMs.milliseconds) {
                                    written.value = now
                                    db.downloads().setProgress(item.chapterId, pages.size, count, size)
                                }
                                SavedPage(file = name, descramble = page.descramble)
                            }
                        }
                    }.awaitAll()
            }
            withContext(Dispatchers.IO) { files.finish(place.titleId, place.id, part, SavedChapter(saved)) }
            db.downloads().setDone(item.chapterId, pages.size, progress.value.second, nowMillis())
            AppLog.info(
                Tag,
                "saved ${place.titleName} ${place.number}, ${pages.size} pages, ${progress.value.second / 1024} KB",
            )
        } catch (error: CancellationException) {
            // Paused or taken out: what was saved so far goes, and a paused chapter waits again at the front.
            withContext(NonCancellable) {
                files.abandon(place.titleId, place.id)
                if (db.downloads().get(item.chapterId) !=
                    null
                ) {
                    db.downloads().setState(item.chapterId, DownloadState.Queued.code)
                }
            }
            throw error
        } catch (error: Throwable) {
            withContext(NonCancellable) { files.abandon(place.titleId, place.id) }
            val message = error.message ?: getString(Res.string.download_save_failed)
            AppLog.warn(Tag, "could not save ${place.titleName} ${place.number}, $message")
            db.downloads().setState(item.chapterId, DownloadState.Failed.code, message)
        }
    }

    // Saves the video of an episode that the player would pick, with the quality and sound the person likes.
    private suspend fun saveEpisode(item: DownloadEntity, place: ChapterPlace, source: Source) {
        val listed = when (val got = source.videos(SourceChapter(url = place.url, title = ""))) {
            is SourceResult.Err -> throw DownloadProblem(got.error.message)
            is SourceResult.Ok -> got.value
        }
        val liked = playerPrefs.prefs.first()
        val video = VideoChoice.pick(expandHlsMasters(listed), liked.preferredQuality, liked.qualityMode, liked.audioPreference)
            ?: throw DownloadProblem(getString(Res.string.download_err_no_video))
        val part = withContext(Dispatchers.IO) { files.begin(place.titleId, place.id) }
        val clock = TimeSource.Monotonic.markNow()
        var written = Duration.ZERO
        var parts = 1
        var size = 0L
        val saved = saveVideo(video, part, prefs.first().pagesAtOnce) { done, total, bytes ->
            parts = total
            size = bytes
            val now = clock.elapsedNow()
            if (now - written >= ProgressEveryMs.milliseconds) {
                written = now
                db.downloads().setProgress(item.chapterId, total, done, bytes)
            }
        }
        withContext(Dispatchers.IO) { files.finish(place.titleId, place.id, part, SavedChapter(video = saved)) }
        db.downloads().setDone(item.chapterId, parts, size, nowMillis())
        AppLog.info(Tag, "saved ${place.titleName} ${place.number}, ${video.quality ?: "video"}, ${size / 1024 / 1024} MB")
    }

    // A page, asked for again a few times, as a site may drop one now and then.
    private suspend fun fetch(url: String, headers: Map<String, String>): ByteArray {
        var last: Throwable? = null
        repeat(PageTries) { attempt ->
            try {
                return manager.images.load(url, headers)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Throwable) {
                last = error
                delay(500L * (attempt + 1))
            }
        }
        throw DownloadProblem(getString(Res.string.download_err_page, last?.message ?: url))
    }

    // Folders of chapters that are no longer saved, such as those of a title that was deleted, are cleared.
    private suspend fun sweep() {
        val kept = db.downloads().doneIds().toHashSet()
        val gone = files.saved().filter { (_, chapterId) -> chapterId !in kept }
        for ((titleId, chapterId) in gone) files.delete(titleId, chapterId)
        if (gone.isNotEmpty()) AppLog.info(Tag, "cleared ${gone.size} saved chapters the library no longer has")
    }

    private companion object {
        const val Tag = "downloads"
    }
}

// The kind of picture by its first bytes, for the name of its file.
internal fun extensionOf(bytes: ByteArray): String {
    fun at(index: Int) = bytes.getOrNull(index)?.toInt()?.and(0xFF) ?: -1
    fun text(from: Int, length: Int) = if (bytes.size >=
        from + length
    ) {
        bytes.decodeToString(from, from + length)
    } else {
        ""
    }
    return when {
        at(0) == 0xFF && at(1) == 0xD8 -> "jpg"
        at(0) == 0x89 && text(1, 3) == "PNG" -> "png"
        text(0, 4) == "GIF8" -> "gif"
        text(0, 4) == "RIFF" && text(8, 4) == "WEBP" -> "webp"
        text(4, 4) == "ftyp" && (text(8, 4) == "avif" || text(8, 4) == "avis") -> "avif"
        text(4, 4) == "ftyp" && text(8, 3) == "hei" -> "heic"
        text(0, 2) == "BM" -> "bmp"
        else -> "img"
    }
}
