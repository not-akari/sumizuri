package com.sumizuri.app.data.download

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.download.DownloadEntity
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.net.hostOf
import com.sumizuri.app.data.settings.PlayerPrefsRepository
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.player.VideoChoice
import com.sumizuri.app.playback.hls.expandHlsMasters
import com.sumizuri.app.playback.hls.isHls
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.download_err_no_video
import com.sumizuri.app.source.Source
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.model.SourceChapter
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.getString
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeSource

// How many parts of a stream are fetched at once at most, whatever is set for pages, as a video server blocks many at once sooner than a picture server.
private const val SegmentsAtOnce = 3

// Saves the video of an episode that the player would pick, with the quality and sound the person likes.
internal class EpisodeSaver(
    private val db: AppDatabase,
    private val files: DownloadFiles,
    private val playerPrefs: PlayerPrefsRepository,
    private val prefs: Flow<DownloadPrefs>,
) {
    suspend fun save(item: DownloadEntity, place: ChapterPlace, source: Source) {
        val listed = when (val got = source.videos(SourceChapter(url = place.url, title = ""))) {
            is SourceResult.Err -> throw DownloadProblem(got.error.message)
            is SourceResult.Ok -> got.value
        }
        val liked = playerPrefs.prefs.first()
        val videos = expandHlsMasters(listed)
        val first = VideoChoice.pick(videos, liked.preferredQuality, liked.qualityMode, liked.audioPreference)
            ?: throw DownloadProblem(getString(Res.string.download_err_no_video))
        // The pick of the player first, then the rest, with the HLS streams ahead: they come in small parts a few at once, while a plain file is often sent slowly or cut.
        val tries = (listOf(first) + (videos - first)).sortedBy { !it.isHls }
        val failedHosts = mutableSetOf<String>()
        var last: Throwable? = null
        val atOnce = minOf(prefs.first().pagesAtOnce, SegmentsAtOnce)
        for (video in tries) {
            // Another quality of a server that failed fails the same way, so the next server is tried.
            if (hostOf(video.url) in failedHosts) continue
            val part = withContext(Dispatchers.IO) { files.begin(place.titleId, place.id) }
            val clock = TimeSource.Monotonic.markNow()
            var written = Duration.ZERO
            var parts = 1
            var size = 0L
            val saved = try {
                saveVideo(video, part, atOnce) { done, total, bytes ->
                    parts = total
                    size = bytes
                    val now = clock.elapsedNow()
                    if (now - written >= ProgressEveryMs.milliseconds) {
                        written = now
                        db.downloads().setProgress(item.chapterId, total, done, bytes)
                    }
                }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (error: Throwable) {
                last = error
                failedHosts += hostOf(video.url)
                AppLog.warn(
                    Tag,
                    "could not save ${place.titleName} ${place.number} from ${hostOf(
                        video.url,
                    )}, ${error.message}; trying the next server",
                )
                continue
            }
            withContext(Dispatchers.IO) { files.finish(place.titleId, place.id, part, SavedChapter(video = saved)) }
            db.downloads().setDone(item.chapterId, parts, size, nowMillis())
            AppLog.info(
                Tag,
                "saved ${place.titleName} ${place.number} from ${hostOf(
                    video.url,
                )}, ${video.quality ?: "video"}, ${size / 1024 / 1024} MB",
            )
            return
        }
        throw DownloadProblem(last?.message ?: getString(Res.string.download_err_no_video))
    }

    private companion object {
        const val Tag = "downloads"
    }
}
