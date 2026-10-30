package com.sumizuri.app.data.download

import com.sumizuri.app.playback.hls.HlsPlaylist
import com.sumizuri.app.playback.hls.isHls
import com.sumizuri.app.source.model.SourceVideo
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.prepareGet
import io.ktor.client.statement.bodyAsChannel
import io.ktor.client.statement.bodyAsText
import io.ktor.http.contentLength
import io.ktor.client.statement.readRawBytes
import io.ktor.http.HttpStatusCode
import io.ktor.http.isSuccess
import io.ktor.utils.io.readAvailable
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import okio.buffer

// How many times a part of a video that fails is asked for again.
private const val PartTries = 3

// How many times a plain file that is cut is taken up again from where it stopped.
private const val ResumeTries = 5

// A server that sends less than this over the window below, once the window has passed, is left for the next one: some hand a whole file over at a few kilobytes a second.
private const val SlowBytesPerSecond = 200L * 1024
private const val SlowWindowMs = 20_000L

// The words every HLS playlist starts with, to tell one by what it holds when its address does not end in .m3u8.
private const val HlsMark = "#EXTM3U"

// A server too slow to save from, so the next one is tried.
class TooSlow(message: String) : Exception(message)

// The bytes saved so far, read by the watch on the speed while the saving writes it.
private class Meter {
    var bytes = 0L
}

// The client videos are saved with. A whole file may take minutes, so only a stalled connection gives up.
private val http = lazy { HttpClient { install(HttpTimeout) { socketTimeoutMillis = 60_000 } } }

// The address of a file on the device as the players take it, with the slashes of Windows turned around.
internal fun fileAddress(path: String): String = "file:///" + path.replace('\\', '/').removePrefix("/")

// One file of a stream to fetch and the name it is kept under next to its playlist.
internal class StreamPart(val url: String, val name: String)

// A media playlist of HLS made to play from the device: every segment, key and map in it points at a file beside it, named with the prefix given, and the list of what to fetch for that. Segments are named .ts, or .m4s when the stream has a map, whatever the site called them, as a player picks the reader of a local segment by its name.
internal fun localPlaylist(text: String, base: String, prefix: String): Pair<String, List<StreamPart>> {
    val parts = LinkedHashMap<String, StreamPart>()
    val segment = if (text.contains("#EXT-X-MAP")) "m4s" else "ts"
    fun local(reference: String, extension: String): String {
        val url = HlsPlaylist.resolve(base, reference)
        return parts.getOrPut(url) { StreamPart(url, "$prefix${parts.size.toString().padStart(5, '0')}.$extension") }.name
    }
    val address = Regex("URI=\"([^\"]*)\"")
    val lines = text.lines().map { it.trim() }.map { line ->
        when {
            line.isEmpty() -> line
            line.startsWith("#EXT-X-KEY") -> address.replace(line) { "URI=\"${local(it.groupValues[1], "key")}\"" }
            line.startsWith("#EXT-X-MAP") -> address.replace(line) { "URI=\"${local(it.groupValues[1], "mp4")}\"" }
            line.startsWith("#") -> line
            else -> local(line, segment)
        }
    }
    return lines.joinToString("\n") to parts.values.toList()
}

// Saves a video of an episode into the folder given: a plain file is written as it arrives, and an HLS stream as its parts with a playlist that points at them, its separate sound too. Subtitles are kept beside it. Progress counts the files done, with their bytes.
internal suspend fun saveVideo(
    video: SourceVideo,
    folder: Path,
    atOnce: Int,
    progress: suspend (done: Int, total: Int, bytes: Long) -> Unit,
): SavedVideo = coroutineScope {
    val meter = Meter()
    // Gives up on the server when it sends too little over a window, so the episode is asked of the next one.
    val watch = launch {
        var before = 0L
        while (true) {
            delay(SlowWindowMs)
            val sent = meter.bytes - before
            before = meter.bytes
            if (sent < SlowBytesPerSecond * SlowWindowMs / 1000) throw TooSlow("${hostOf(video.url)} sent ${sent / 1024} KB in ${SlowWindowMs / 1000} s")
        }
    }
    try {
        saveWatched(video, folder, atOnce, meter, progress)
    } finally {
        watch.cancel()
    }
}

private suspend fun saveWatched(
    video: SourceVideo,
    folder: Path,
    atOnce: Int,
    meter: Meter,
    progress: suspend (done: Int, total: Int, bytes: Long) -> Unit,
): SavedVideo {
    val fs = FileSystem.SYSTEM
    val headers = video.headers
    val subtitles = video.subtitles.mapIndexed { index, track ->
        val extension = extensionIn(track.url, "vtt")
        StreamPart(track.url, "sub$index.$extension") to SavedTrack("sub$index.$extension", track.label, track.language)
    }
    // An address that does not end in .m3u8 may still give a playlist, which is then saved as HLS from what came.
    var given: String? = null
    if (!video.isHls) {
        val name = "video." + extensionIn(video.url, "mp4")
        var total = 0L
        stream(video.url, headers, folder / name, meter) { bytes ->
            total = bytes
            progress(0, 1, bytes)
        }
        val start = withContext(Dispatchers.IO) { fs.read(folder / name) { readUtf8(minOf(HlsMark.length.toLong(), total)) } }
        if (start != HlsMark) {
            // ponytail: a separate sound kept as a plain file is not saved; HLS sound is, below. Add it if a source sends one.
            fetchAll(subtitles.map { it.first }, headers, folder, atOnce, meter) { _, _ -> }
            progress(1, 1, total)
            return SavedVideo(name, subtitles.map { it.second })
        }
        given = withContext(Dispatchers.IO) { fs.read(folder / name) { readUtf8() }.also { fs.delete(folder / name) } }
    }
    var mediaUrl = video.url
    var soundUrl = video.pairedAudio?.url
    var text = given ?: text(mediaUrl, headers)
    if (HlsPlaylist.isMaster(text)) {
        // The quality was not picked from the master, so the one with the most bits is kept.
        val master = HlsPlaylist.parseMaster(text, mediaUrl)
        val best = master.variants.maxByOrNull { it.bandwidth ?: 0 } ?: throw DownloadProblem("The stream lists no quality")
        mediaUrl = best.uri
        soundUrl = soundUrl ?: HlsPlaylist.audioFor(master, best)?.uri
        text = text(mediaUrl, headers)
    }
    val (playlist, parts) = localPlaylist(text, mediaUrl, "v")
    val sound = soundUrl?.let { url -> localPlaylist(text(url, headers), url, "a") }
    val all = parts + sound?.second.orEmpty() + subtitles.map { it.first }
    var bytes = 0L
    fetchAll(all, headers, folder, atOnce, meter) { done, size ->
        bytes += size
        progress(done, all.size, bytes)
    }
    withContext(Dispatchers.IO) {
        fs.write(folder / "index.m3u8") { writeUtf8(playlist) }
        sound?.let { fs.write(folder / "audio.m3u8") { writeUtf8(it.first) } }
    }
    return SavedVideo("index.m3u8", subtitles.map { it.second }, audio = sound?.let { "audio.m3u8" })
}

// Fetches small files a few at once, each asked for again a few times, and writes them to the folder.
private suspend fun fetchAll(
    parts: List<StreamPart>,
    headers: Map<String, String>,
    folder: Path,
    atOnce: Int,
    meter: Meter,
    done: suspend (count: Int, size: Int) -> Unit,
) {
    val gate = Semaphore(atOnce)
    // The parts finish on several threads, so the count is kept under a lock.
    val counting = Mutex()
    var count = 0
    coroutineScope {
        parts.map { part ->
            async {
                gate.withPermit {
                    val bytes = bytes(part.url, headers)
                    withContext(Dispatchers.IO) { FileSystem.SYSTEM.write(folder / part.name) { write(bytes) } }
                    counting.withLock {
                        meter.bytes += bytes.size
                        done(++count, bytes.size)
                    }
                }
            }
        }.awaitAll()
    }
}

private suspend fun text(url: String, headers: Map<String, String>): String = tried(url) {
    val response = http.value.get(url) { headers.forEach { (name, value) -> header(name, value) } }
    if (!response.status.isSuccess()) error("$url answered ${response.status.value}")
    response.bodyAsText()
}

private suspend fun bytes(url: String, headers: Map<String, String>): ByteArray = tried(url) {
    val response = http.value.get(url) { headers.forEach { (name, value) -> header(name, value) } }
    if (!response.status.isSuccess()) error("$url answered ${response.status.value}")
    response.readRawBytes()
}

// Writes a big file as it arrives, never whole in memory, telling the bytes so far every megabyte. When the server cuts it, it is asked again from the byte it stopped at, and from the start when the server cannot do that.
private suspend fun stream(url: String, headers: Map<String, String>, file: Path, meter: Meter, told: suspend (Long) -> Unit) {
    val fs = FileSystem.SYSTEM
    var done = 0L
    var cuts = 0
    while (true) {
        try {
            http.value.prepareGet(url) {
                headers.forEach { (name, value) -> header(name, value) }
                if (done > 0) header("Range", "bytes=$done-")
            }.execute { response ->
                if (!response.status.isSuccess()) throw DownloadProblem("The video answered ${response.status.value}")
                // A server that sends the whole file again instead of the rest has it written from the start.
                val resumed = done > 0 && response.status == HttpStatusCode.PartialContent
                if (!resumed) done = 0
                // The size the server says it sends, to tell a file it closed early from one that is whole.
                val expected = response.contentLength()?.let { it + done }
                val channel = response.bodyAsChannel()
                val buffer = ByteArray(64 * 1024)
                var shown = done
                withContext(Dispatchers.IO) {
                    (if (resumed) fs.appendingSink(file) else fs.sink(file)).buffer().use { sink ->
                        while (true) {
                            val read = channel.readAvailable(buffer, 0, buffer.size)
                            if (read == -1) break
                            if (read == 0) continue
                            sink.write(buffer, 0, read)
                            done += read
                            meter.bytes += read
                            if (done - shown >= 1024 * 1024) {
                                shown = done
                                told(done)
                            }
                        }
                    }
                }
                // Some servers end a file early as if it were whole, so a short one is taken as cut.
                if (expected != null && done < expected) error("the server sent ${done / 1024 / 1024} of ${expected / 1024 / 1024} MB")
            }
            told(done)
            return
        } catch (error: CancellationException) {
            throw error
        } catch (error: DownloadProblem) {
            throw error
        } catch (error: Throwable) {
            if (++cuts > ResumeTries) throw DownloadProblem(error.message ?: url)
            delay(1_000L * cuts)
        }
    }
}

// A call asked for again a few times, as a site may drop one now and then.
private suspend fun <T> tried(url: String, block: suspend () -> T): T {
    var last: Throwable? = null
    repeat(PartTries) { attempt ->
        try {
            return block()
        } catch (error: CancellationException) {
            throw error
        } catch (error: Throwable) {
            last = error
            delay(500L * (attempt + 1))
        }
    }
    throw DownloadProblem(last?.message ?: url)
}

// The ending of the file in an address, when it is a short word, or the one given.
private fun extensionIn(url: String, otherwise: String): String = url
    .substringBefore('?')
    .substringBefore('#')
    .substringAfterLast('/')
    .substringAfterLast('.', "")
    .lowercase()
    .takeIf { it.length in 2..4 && it.all(Char::isLetterOrDigit) } ?: otherwise

// The site part of an address, which tells one server from another.
internal fun hostOf(url: String): String = url.substringAfter("://").substringBefore('/').substringBefore(':').lowercase()
