package com.sumizuri.app.feature.player

import com.sumizuri.app.source.model.SourceVideo

// The videos of an episode that did not start, and the next server to open in their place.
internal class ServerFallback {
    private val failed = mutableSetOf<SourceVideo>()

    fun clear() = failed.clear()

    // Keeps the video as one that failed and gives the next one not tried yet, from another site than those that failed when there is one, as the other qualities of a server that failed often fail the same way.
    fun next(video: SourceVideo, videos: List<SourceVideo>): SourceVideo? {
        failed += video
        val left = videos.filter { it !in failed }
        val failedHosts = failed.map { hostOf(it.url) }.toSet()
        return left.firstOrNull { hostOf(it.url) !in failedHosts } ?: left.firstOrNull()
    }
}

// The site part of the address of a video, which tells one server from another.
private fun hostOf(url: String): String = url.substringAfter("://").substringBefore('/').lowercase()
