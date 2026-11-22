package com.sumizuri.app.feature.tv.library

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.browse.asTitle
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.source.valueOrNull
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull

// How long one source may take for one list before it is left out, and how many titles a row of it holds.
private const val AskMs = 20_000L
private const val FoundMax = 30

// A title a source offers that is not in the library yet, with the source it came from.
internal class Found(val source: InstalledSource, val entry: SourceEntry) {
    val key: String = source.id + "|" + entry.url
    val title: Title = entry.asTitle(Kind.Anime, source.id)
}

// What one row of discovery is: the popular titles of a source, or titles of one of the genres the library has most.
internal sealed interface FoundKind {
    data class Popular(val source: String) : FoundKind

    data class Genre(val name: String) : FoundKind
}

internal class FoundRow(val kind: FoundKind, val items: List<Found>) {
    val key: String = when (kind) {
        is FoundKind.Popular -> "popular:" + kind.source
        is FoundKind.Genre -> "more:" + kind.name
    }
}

// Asks every video source that is on for its popular titles, and for the lists it offers that are named like the genres given, and sends the rows again each time one source answers. The genre rows come first and gather titles from every source. Titles whose name is already in the library are left out, and a source that fails or is slow is skipped.
internal fun discoverRows(
    manager: SourceManager,
    sources: List<InstalledSource>,
    genres: List<String>,
    owned: Set<String>,
): Flow<List<FoundRow>> = channelFlow {
    val lock = Mutex()
    val popular = mutableListOf<FoundRow>()
    val byGenre = linkedMapOf<String, MutableList<Found>>()
    genres.forEach { byGenre[it] = mutableListOf() }

    suspend fun publish() {
        val rows = lock.withLock {
            byGenre
                .filterValues {
                    it.isNotEmpty()
                }.map { (name, items) ->
                    FoundRow(
                        FoundKind.Genre(name),
                        items
                            .distinctBy {
                                it.title.name.lowercase()
                            }.take(FoundMax),
                    )
                } +
                popular
        }
        send(rows)
    }

    fun fresh(source: InstalledSource, entries: List<SourceEntry>?): List<Found> =
        entries.orEmpty().filter { it.title.lowercase() !in owned }.map { Found(source, it) }

    for (installed in sources.filter { it.enabled && it.kind == Kind.Anime }) {
        launch {
            val source = withTimeoutOrNull(AskMs) { manager.open(installed).valueOrNull() } ?: return@launch
            val top = fresh(installed, withTimeoutOrNull(AskMs) { source.popular(1).valueOrNull() }).take(FoundMax)
            if (top.isNotEmpty()) {
                lock.withLock { popular += FoundRow(FoundKind.Popular(installed.name), top) }
                publish()
            }
            if (genres.isEmpty()) return@launch
            val catalogs = withTimeoutOrNull(AskMs) { source.catalogs().valueOrNull() }.orEmpty()
            for (genre in genres) {
                val list = catalogs.firstOrNull { it.name.trim().equals(genre, ignoreCase = true) } ?: continue
                val got = fresh(installed, withTimeoutOrNull(AskMs) { source.catalog(list.id, 1).valueOrNull() })
                if (got.isEmpty()) continue
                lock.withLock { byGenre.getValue(genre) += got }
                publish()
            }
        }
    }
    awaitClose()
}
