package com.sumizuri.app.feature.tv.library

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.library.LibraryEntry
import com.sumizuri.app.data.model.library.LibrarySortField
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.source.SourceManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

// How many titles a row holds at most, so a big library does not lay out hundreds of cards in one row.
private const val RowMax = 40

// How many genres get a row, and how many titles a genre needs for one.
private const val GenreRows = 8
private const val GenreMin = 2

// How many of those genres the sources are asked for.
private const val FoundGenres = 3

// What one row of the TV library is: the continue row, the new episodes, a genre with its name, or every title.
internal sealed interface TvRowKind {
    data object Continue : TvRowKind

    data object New : TvRowKind

    data class Genre(val name: String) : TvRowKind

    data object All : TvRowKind
}

// One row of the TV library, with the titles in it and when each was last watched.
internal class TvRow(val kind: TvRowKind, val entries: List<LibraryEntry>) {
    val key: String = when (kind) {
        TvRowKind.Continue -> "continue"
        TvRowKind.New -> "new"
        is TvRowKind.Genre -> "genre:" + kind.name
        TvRowKind.All -> "all"
    }
}

// The rows of the library as a TV shows them, with only the videos in it, or null while they are read.
internal class TvLibraryModel(
    library: LibraryRepository,
    private val sources: SourceRepository,
    private val manager: SourceManager,
) : ViewModel() {
    val rows: StateFlow<List<TvRow>?> = library
        .entries(
            setOf(LibrarySortField.LastRead, LibrarySortField.LatestChapter),
        ).map { entries ->
            val videos = entries.filter { it.title.kind == Kind.Anime }
            buildList {
                // Begun and with episodes left, the last watched first.
                val going = videos.filter { it.lastRead > 0 && it.title.unread > 0 }.sortedByDescending { it.lastRead }
                if (going.isNotEmpty()) add(TvRow(TvRowKind.Continue, going.take(RowMax)))
                // With episodes not watched yet, the newest first.
                val fresh = videos.filter { it.title.unread > 0 && it !in going }.sortedByDescending { it.latest }
                if (fresh.isNotEmpty()) add(TvRow(TvRowKind.New, fresh.take(RowMax)))
                // The genres the library has most, each with its titles, the last watched first.
                for ((genre, held) in genreGroups(videos)) {
                    add(
                        TvRow(
                            TvRowKind.Genre(genre),
                            held
                                .sortedWith(
                                    compareByDescending<LibraryEntry> {
                                        it.lastRead
                                    }.thenBy { it.title.name.lowercase() },
                                ).take(RowMax),
                        ),
                    )
                }
                add(TvRow(TvRowKind.All, videos.sortedBy { it.title.name.lowercase() }))
            }.filter { it.entries.isNotEmpty() }
        }.flowOn(Dispatchers.Default)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    // What the video sources offer that the library does not have, asked once the library is read, with the genres it has most.
    val found: StateFlow<List<FoundRow>> = flow {
        val read = rows.filterNotNull().first()
        val owned = read.flatMap { it.entries }.map { it.title.name.lowercase() }.toSet()
        val genres = read.mapNotNull { (it.kind as? TvRowKind.Genre)?.name }.take(FoundGenres)
        emitAll(discoverRows(manager, sources.installed.first(), genres, owned))
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(60_000), emptyList())
}

// How far through a title the person is, from 0 to 1, by the episodes watched out of all of them.
internal fun watchedShare(title: Title): Float = if (title.chapterCount <=
    0
) {
    0f
} else {
    ((title.chapterCount - title.unread).toFloat() / title.chapterCount).coerceIn(0f, 1f)
}

// The genres most titles share, each with its titles. Names are matched without case, and the first way a source wrote a name is the one shown.
private fun genreGroups(videos: List<LibraryEntry>): List<Pair<String, List<LibraryEntry>>> {
    val shown = mutableMapOf<String, String>()
    val byGenre = mutableMapOf<String, MutableList<LibraryEntry>>()
    for (entry in videos) {
        for (genre in entry.title.genres
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinctBy { it.lowercase() }) {
            val key = genre.lowercase()
            shown.getOrPut(key) { genre }
            byGenre.getOrPut(key) { mutableListOf() }.add(entry)
        }
    }
    return byGenre.entries
        .filter { it.value.size >= GenreMin }
        .sortedByDescending { it.value.size }
        .take(GenreRows)
        .map { shown.getValue(it.key) to it.value }
}
