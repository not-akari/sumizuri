package com.sumizuri.app.playback

import com.sumizuri.app.data.model.player.SubtitleBackground
import com.sumizuri.app.data.net.Network
import com.sumizuri.app.data.net.hostOf
import com.sun.jna.Pointer
import java.util.Locale
import kotlin.math.roundToInt

// How mpv plays inside the app: drawn by the app, with no window, keys or scripts of its own, kept open at the end so the last frame stays, and a little louder at most than usual. It keeps about five minutes of a stream ahead and a minute behind, where its own default holds 200 MB.
internal val MpvPlayOptions: List<Pair<String, String>> = listOf(
    "vo" to "libmpv",
    "hwdec" to "auto-copy-safe",
    "terminal" to "no",
    "config" to "no",
    "load-scripts" to "no",
    "osc" to "no",
    "input-default-bindings" to "no",
    "input-vo-keyboard" to "no",
    "ytdl" to "no",
    "idle" to "yes",
    "keep-open" to "yes",
    "sub-auto" to "no",
    "volume-max" to "200",
    "cache" to "yes",
    "demuxer-max-bytes" to "64MiB",
    "demuxer-max-back-bytes" to "16MiB",
    "network-timeout" to "30",
    // Some sources name the pieces of a stream as pictures or pages, such as .png, .html or .txt, which the newer ffmpeg turns away by their name. The name is not checked, and the content says what a piece is.
    "demuxer-lavf-o" to "extension_picky=0,allowed_segment_extensions=ALL",
)

// How high mpv takes the picture to be when it measures the subtitles.
private const val ScriptHeight = 720

// The look of the subtitles mpv draws, from the choices of the person. mpv measures its letters for a picture 720 high, so the size and the room under them are scaled to that.
internal fun subtitleOptions(style: SubtitleStyle, lifted: Float): List<Pair<String, String>> = buildList {
    add("sub-font-size" to (style.sizeSp * 8 / 5).toString())
    add("sub-color" to String.format(Locale.ROOT, "#%06X", style.color and 0xFFFFFF))
    add("sub-bold" to if (style.bold) "yes" else "no")
    when (style.background) {
        SubtitleBackground.Outline -> {
            add("sub-border-style" to "outline-and-shadow")
            add("sub-border-size" to "3")
            add("sub-shadow-offset" to "1")
        }

        SubtitleBackground.Box -> {
            add("sub-border-style" to "background-box")
            add("sub-back-color" to "#B3000000")
        }

        SubtitleBackground.None -> {
            add("sub-border-style" to "outline-and-shadow")
            add("sub-border-size" to "0")
            add("sub-shadow-offset" to "0")
        }
    }
    add("sub-margin-y" to subtitleMargin(style, lifted))
}

// The room under the subtitles, raised further while the controls show so they never cover the words.
internal fun subtitleMargin(style: SubtitleStyle, lifted: Float): String {
    val clearance = (lifted.coerceIn(0f, 0.5f) * ScriptHeight).roundToInt()
    return (SubtitleStyle.RaiseDp[style.raise.coerceIn(0, 2)] + clearance).toString()
}

internal fun MpvApi.command(here: Pointer, vararg args: String) {
    mpv_command(here, arrayOf(*args, null))
}

// A property of mpv as text, freed again once read.
internal fun MpvApi.text(here: Pointer, name: String): String? {
    val value = mpv_get_property_string(here, name) ?: return null
    return try {
        value.getString(0)
    } finally {
        mpv_free(value)
    }
}

internal fun MpvApi.number(here: Pointer, name: String): Double? = text(here, name)?.toDoubleOrNull()

// A time in milliseconds as the seconds mpv takes.
internal fun seconds(ms: Long): String = String.format(Locale.ROOT, "%.3f", ms / 1000.0)

// The subtitle and audio tracks mpv knows, with the one chosen of each.
internal class MpvTracks(
    val subtitles: List<PlayerTrack>,
    val audios: List<PlayerTrack>,
    val subtitle: String?,
    val audio: String?,
)

// Reads the tracks mpv lists, with the names the video or the source gave them.
internal fun MpvApi.tracks(here: Pointer, count: Int): MpvTracks {
    val subtitles = mutableListOf<PlayerTrack>()
    val audios = mutableListOf<PlayerTrack>()
    var chosenSubtitle: String? = null
    var chosenAudio: String? = null
    for (index in 0 until count) {
        val type = text(here, "track-list/$index/type")
        val id = text(here, "track-list/$index/id") ?: continue
        val language = text(here, "track-list/$index/lang")
        val label = TrackNames.label(text(here, "track-list/$index/title"), language)
        val on = text(here, "track-list/$index/selected") == "yes"
        when (type) {
            "sub" -> {
                subtitles += PlayerTrack(id, label, language, ordinal = subtitles.size + 1)
                if (on) chosenSubtitle = id
            }

            "audio" -> {
                audios += PlayerTrack(id, label, language, ordinal = audios.size + 1)
                if (on) chosenAudio = id
            }
        }
    }
    return MpvTracks(subtitles, audios, chosenSubtitle, chosenAudio)
}

// Follows the log of mpv for a secure connection cut as it started: the cut is seen first, and then the address it could not open names the server.
internal fun cutAfter(text: String, now: String?): String? = when {
    "SSL connect error" in text -> now ?: ""
    now == "" && text.startsWith("Failed to open ") -> hostOf(text.removePrefix("Failed to open "))
    else -> now
}

internal fun cutReason(host: String): String = if (host.isEmpty()) "SSL connect error" else "SSL connect error at $host"

// The router of the app as libcurl reads it, or nothing while the app goes straight. The h has the router look up the names of sites, so it can tell which way each one takes.
internal fun routerForVideo(): String = Network.routerPort?.let { "socks5h://127.0.0.1:$it" }.orEmpty()

// The headers the site of a video wants, and the router of the app. Those of the last video are taken back first, so a site never gets the headers of another.
internal fun MpvApi.useHeaders(here: Pointer, headers: Map<String, String>) {
    command(here, "change-list", "http-header-fields", "clr", "")
    mpv_set_property_string(here, "user-agent", "libmpv")
    mpv_set_property_string(here, "referrer", "")
    mpv_set_property_string(here, "http-proxy", routerForVideo())
    for ((name, value) in headers) {
        when (name.lowercase()) {
            "user-agent" -> mpv_set_property_string(here, "user-agent", value)
            "referer" -> mpv_set_property_string(here, "referrer", value)
            else -> command(here, "change-list", "http-header-fields", "append", "$name: $value")
        }
    }
}

// Words of mpv that say the stream itself cannot be read, as when a source locks its video in a way no player opens.
private val UnreadableSigns = listOf("treating it as fatal error", "Could not find codec parameters")

// What the log of mpv said about the video now playing: the server whose secure connection was cut as it started, and the first line that says the stream cannot be read.
internal class LogSigns {
    @Volatile var cutAt: String? = null
        private set

    @Volatile private var unreadable = false

    // Reads one line of the log, and says whether it is the first sign that the stream cannot be read.
    fun read(text: String): Boolean {
        cutAt = cutAfter(text, cutAt)
        if (unreadable || UnreadableSigns.none { it in text }) return false
        unreadable = true
        return true
    }

    fun clear() {
        cutAt = null
        unreadable = false
    }
}
