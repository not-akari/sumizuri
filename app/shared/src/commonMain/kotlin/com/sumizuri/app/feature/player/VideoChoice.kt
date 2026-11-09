package com.sumizuri.app.feature.player

import com.sumizuri.app.data.model.player.AudioPreference
import com.sumizuri.app.data.model.player.QualityMode
import com.sumizuri.app.playback.PlayerTrack
import com.sumizuri.app.source.model.SourceTrack
import com.sumizuri.app.source.model.SourceVideo

// Picks among the videos and the subtitles of an episode by what the person prefers.
object VideoChoice {
    private val dub = Regex("(^|[^a-z])dub(bed)?($|[^a-z])", RegexOption.IGNORE_CASE)
    private val sub = Regex("(^|[^a-z])(soft|hard)?sub(bed)?($|[^a-z])", RegexOption.IGNORE_CASE)

    fun isDub(video: SourceVideo): Boolean = dub.containsMatchIn(video.quality.orEmpty())

    fun isSub(video: SourceVideo): Boolean = sub.containsMatchIn(video.quality.orEmpty())

    // The height in pixels a quality label stands for, such as 1080p, 4k or a bare 720, or null for a label that says none.
    fun height(label: String?): Int? {
        if (label == null) return null
        val text = label.lowercase()
        Pixels.find(text)?.let { return it.groupValues[1].toInt() }
        if (FourK.containsMatchIn(text)) return 2160
        if (TwoK.containsMatchIn(text)) return 1440
        return BareHeight
            .find(text)
            ?.groupValues
            ?.get(2)
            ?.toInt()
    }

    // The video to start with. The audio preference narrows the list when any video has it, then the quality mode takes the one that was remembered, the tallest or the shortest.
    fun pick(videos: List<SourceVideo>, remembered: String?, mode: QualityMode, audio: AudioPreference): SourceVideo? {
        if (videos.isEmpty()) return null
        val pool = narrowed(videos, audio)
        return when (mode) {
            QualityMode.Remember -> pool.firstOrNull { remembered != null && it.quality == remembered } ?: pool.first()

            QualityMode.Best ->
                pool
                    .mapNotNull { video ->
                        height(video.quality)?.let {
                            video to it
                        }
                    }.maxByOrNull { it.second }
                    ?.first
                    ?: pool.first()

            QualityMode.Lowest ->
                pool
                    .mapNotNull { video ->
                        height(video.quality)?.let {
                            video to it
                        }
                    }.minByOrNull { it.second }
                    ?.first
                    ?: pool.first()
        }
    }

    private fun narrowed(videos: List<SourceVideo>, audio: AudioPreference): List<SourceVideo> {
        if (audio == AudioPreference.Any) return videos
        val matching = videos.filter { if (audio == AudioPreference.Dub) isDub(it) else isSub(it) }
        return matching.ifEmpty { videos }
    }

    // The subbed and the dubbed version to switch between, each at the quality nearest to the one that plays, or null when the source does not offer both.
    fun versions(videos: List<SourceVideo>, current: SourceVideo?): Pair<SourceVideo, SourceVideo>? {
        val subs = videos.filter { isSub(it) }
        val dubs = videos.filter { isDub(it) }
        if (subs.isEmpty() || dubs.isEmpty()) return null
        val height = height(current?.quality)
        fun closest(pool: List<SourceVideo>) = pool.firstOrNull { height(it.quality) == height } ?: pool.first()
        return closest(subs) to closest(dubs)
    }

    // The subtitle in the language asked for, from the tracks of the video and then from the files of the source, or null when none is in it.
    fun subtitle(embedded: List<PlayerTrack>, files: List<SourceTrack>, language: String): SubtitleChoice? {
        val wanted = language.trim().lowercase()
        if (wanted.isEmpty()) return null
        embedded.firstOrNull { matches(wanted, it.language, it.label) }?.let { return SubtitleChoice(it, null) }
        files.firstOrNull { matches(wanted, it.language, it.label) }?.let { return SubtitleChoice(null, it) }
        return null
    }

    // The subtitle to show when subtitles are on: the language asked for, else English, else the first there is.
    fun alwaysOn(embedded: List<PlayerTrack>, files: List<SourceTrack>, language: String): SubtitleChoice? =
        subtitle(embedded, files, language) ?: subtitle(embedded, files, "en")
            ?: embedded.firstOrNull()?.let { SubtitleChoice(it, null) }
            ?: files.firstOrNull()?.let { SubtitleChoice(null, it) }

    private fun matches(wanted: String, code: String?, title: String?): Boolean {
        fun hit(value: String?): Boolean {
            if (value.isNullOrBlank()) return false
            val v = value.trim().lowercase()
            if (v == wanted) return true
            if (wanted.length >= 2 && v.length >= 2 && (v.startsWith(wanted) || wanted.startsWith(v))) return true
            return v.contains(wanted) && wanted.length >= 3
        }
        return hit(code) || hit(title)
    }
}

// What a subtitle was picked from: a track the video carries, or a file the source gave.
class SubtitleChoice(val track: PlayerTrack?, val file: SourceTrack?)

// The ways a quality label says its height: 1080p, 4k or uhd, 2k, or a bare common height.
private val Pixels = Regex("(\\d{3,4})\\s*p")
private val FourK = Regex("(^|[^a-z0-9])(4k|uhd)($|[^a-z0-9])")
private val TwoK = Regex("(^|[^a-z0-9])2k($|[^a-z0-9])")
private val BareHeight = Regex("(^|[^0-9])(2160|1440|1080|720|576|480|360|240)($|[^0-9])")
