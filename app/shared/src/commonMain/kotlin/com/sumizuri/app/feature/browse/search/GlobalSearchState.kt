package com.sumizuri.app.feature.browse.search

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource

// The search of every installed source at once: the words, the kinds that have sources and the one searched, and what each source answered.
data class GlobalSearchState(
    val loaded: Boolean = false,
    val query: String = "",
    val kinds: List<Kind> = emptyList(),
    val kind: Kind? = null,
    val results: List<SourceResults> = emptyList(),
) {
    // No source that is on can search the kind picked, or any kind, so the page says so instead of staying blank.
    val noSources: Boolean get() = loaded && (kinds.isEmpty() || (kind != null && kind !in kinds))
}

// What one source answered: its first results, the addresses of those already in the library, or the message of the source when it could not be searched. Loading until it answers.
data class SourceResults(
    val source: InstalledSource,
    val entries: List<SourceEntry> = emptyList(),
    val saved: Set<String> = emptySet(),
    val loading: Boolean = true,
    val error: String? = null,
)
