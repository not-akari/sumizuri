package com.sumizuri.app.source.model

import kotlinx.serialization.Serializable

data class SourceVideo(
    val url: String,
    val quality: String? = null,
    val headers: Map<String, String> = emptyMap(),
    val subtitles: List<SourceTrack> = emptyList(),
    val audioTracks: List<SourceTrack> = emptyList(),
    val intro: TimeRange? = null,
    val outro: TimeRange? = null,
    // The sound that goes with this video when it is kept in a playlist of its own, as an HLS quality often has it.
    val pairedAudio: SourceTrack? = null,
)

// One page of a manga, or one block of text in a novel.
data class SourcePage(
    val index: Int,
    val imageUrl: String? = null,
    val text: String? = null,
    val descramble: Descramble? = null,
)

// A PDF or an EPUB a chapter points at, with the headers its address wants.
data class SourceBook(val url: String, val headers: Map<String, String> = emptyMap())

// An image cut into cols by rows tiles that must be put back in this order.
@Serializable
data class Descramble(val cols: Int, val rows: Int, val order: List<Int>)

// A subtitle or an audio track of a video.
data class SourceTrack(val url: String, val label: String, val language: String? = null)

// A stretch of an episode in milliseconds, such as the intro.
data class TimeRange(val startMs: Long, val endMs: Long)
