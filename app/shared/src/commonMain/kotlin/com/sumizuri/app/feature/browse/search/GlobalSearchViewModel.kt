package com.sumizuri.app.feature.browse.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withTimeoutOrNull

// How long the typing must pause before the sources are asked, how many sources are asked at once, and how many results of each are shown.
private const val PauseMs = 500L
private const val AtOnce = 8

// A source slower than this is left out of the search, so one dead site does not hold the others back.
private const val WaitMs = 20_000L
private const val PerSource = 12

// Searches every installed source that is on for the words, of every kind or of one, a few sources at once, and shows each answer as it comes. The sources used last are asked first.
class GlobalSearchViewModel(
    initial: String,
    private val sources: SourceRepository,
    private val manager: SourceManager,
    private val library: LibraryRepository,
) : ViewModel() {
    private val mutable = MutableStateFlow(GlobalSearchState(query = initial))
    val state: StateFlow<GlobalSearchState> = mutable

    private var job: Job? = null
    private var installed: List<InstalledSource> = emptyList()

    init {
        viewModelScope.launch {
            installed = sources.installed.first().filter { it.enabled }
            val kinds = Kind.entries.filter { kind -> installed.any { it.kind == kind } }
            // It starts in every kind, so manga, novels and anime are all found by one search.
            mutable.update { it.copy(loaded = true, kinds = kinds, kind = null) }
            if (mutable.value.query.isNotBlank()) restart(0)
        }
    }

    fun onQuery(text: String) {
        mutable.update { it.copy(query = text) }
        restart(PauseMs)
    }

    // One kind, or null for every kind.
    fun onKind(kind: Kind?) {
        mutable.update { it.copy(kind = kind) }
        restart(0)
    }

    // The id of the title saved from this entry, so a saved one opens as itself and not as a preview.
    suspend fun savedId(source: InstalledSource, entry: SourceEntry): Long? = library.savedId(source.id, entry)

    private fun restart(delayMs: Long) {
        job?.cancel()
        job = viewModelScope.launch {
            delay(delayMs)
            val now = mutable.value
            val query = now.query.trim()
            val wanted = installed
                .filter {
                    now.kind == null || it.kind == now.kind
                }.sortedWith(compareByDescending<InstalledSource> { it.lastUsedAt }.thenBy { it.name.lowercase() })
            if (query.isEmpty() || wanted.isEmpty()) {
                mutable.update { it.copy(results = emptyList()) }
                return@launch
            }
            mutable.update { it.copy(results = wanted.map { source -> SourceResults(source) }) }
            val gate = Semaphore(AtOnce)
            coroutineScope {
                wanted.map { source -> async { gate.withPermit { settle(withTimeoutOrNull(WaitMs) { searchOne(source, query) } ?: SourceResults(source, loading = false, error = "Took longer than ${WaitMs / 1000} seconds")) } } }.awaitAll()
            }
        }
    }

    private suspend fun searchOne(source: InstalledSource, query: String): SourceResults {
        val opened = when (val result = manager.open(source)) {
            is SourceResult.Err -> return SourceResults(source, loading = false, error = result.error.message)
            is SourceResult.Ok -> result.value
        }
        return when (val found = opened.search(query, 1)) {
            is SourceResult.Err -> SourceResults(source, loading = false, error = found.error.message)

            is SourceResult.Ok -> {
                val entries = found.value.take(PerSource)
                val inLibrary = library.savedKeys(source.id).first()
                SourceResults(
                    source,
                    entries,
                    entries.map { it.url }.filter { it in inLibrary }.toSet(),
                    loading = false,
                )
            }
        }
    }

    private fun settle(result: SourceResults) = mutable.update { now ->
        now.copy(results = now.results.map { if (it.source.id == result.source.id) result else it })
    }
}
