package com.sumizuri.app.feature.player

import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.playback.hls.isHls
import com.sumizuri.app.source.model.SourceVideo
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

// The most lines kept, and the headers that are never written out.
private const val MaxEntries = 400
private val HiddenHeaders = setOf("cookie", "authorization", "proxy-authorization")

// One line of the log, with how long after the start it was said. A line said again straight after itself is counted and not repeated.
class LogEntry(val atMs: Long, val text: String, val problem: Boolean = false, val count: Int = 1) {
    val line: String get() = "+" + "${atMs / 1000}.${atMs % 1000 / 100}".padStart(6) + "s  $text" +
        if (count > 1) "  x$count" else ""
}

// What the player did and what went wrong, kept to be shown in a strip over the video and copied when something does not play.
class PlaybackLog {
    private val started = nowMillis()
    private val list = ArrayList<LogEntry>()
    private var dropped = 0
    private val mutable = MutableStateFlow<List<LogEntry>>(emptyList())
    val entries: StateFlow<List<LogEntry>> = mutable

    val hasProblem: Boolean get() = list.any { it.problem }

    fun add(text: String, problem: Boolean = false, similar: Boolean = false) {
        val last = list.lastOrNull()
        val now = nowMillis() - started
        if (last != null && (last.text == text || (similar && shape(last.text) == shape(text)))) {
            list[list.lastIndex] = LogEntry(now, last.text, last.problem || problem, last.count + 1)
        } else {
            if (list.size >= MaxEntries) {
                list.removeAt(0)
                dropped++
            }
            list += LogEntry(now, text, problem)
        }
        mutable.value = list.toList()
    }

    fun toText(heading: String?): String = buildString {
        appendLine("Sumizuri player log" + (heading?.let { " - $it" } ?: ""))
        if (dropped > 0) appendLine("($dropped earlier lines were dropped)")
        for (entry in list) appendLine(entry.line)
    }

    // A line with its numbers taken out, so two warnings that only differ by a number count as the same.
    private fun shape(text: String) = text.replace(Numbers, "#")
}

// A video as the log writes it: its label, what it carries, its address and its headers with the secret ones hidden.
fun describeVideo(video: SourceVideo): String {
    val headers = video.headers.entries.map { (key, value) ->
        if (key.lowercase() in
            HiddenHeaders
        ) {
            "$key: (hidden)"
        } else {
            "$key: $value"
        }
    }
    val extras = buildList {
        if (video.isHls) add("playlist")
        if (video.subtitles.isNotEmpty()) add("${video.subtitles.size} subtitle(s)")
        if (video.audioTracks.isNotEmpty()) add("${video.audioTracks.size} audio track(s)")
    }
    return (video.quality ?: "no label") + (if (extras.isEmpty()) "" else " [${extras.joinToString(", ")}]") +
        "\n    ${video.url}" + if (headers.isEmpty()) "" else "\n    headers: ${headers.joinToString("; ")}"
}

// The numbers in a log line, as hex or plain digits.
private val Numbers = Regex("0x[0-9a-fA-F]+|\\d+")
