package com.sumizuri.app.feature.browse.repo

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.source.repo.RepoSource

// A source installed from this repo, with the id it is installed under, its version, and what it is called and looks like.
data class InstalledRef(val id: String, val version: Int, val name: String = "", val iconUrl: String = "")

// A source that is about to be removed while saved titles still came from it.
data class RemovePrompt(val id: String, val name: String, val titles: Int)

// The sources of one repo under the same heading, a language.
class RepoGroup(val language: String, val sources: List<RepoSource>)

data class RepoState(
    val repo: Repo,
    val available: List<RepoSource> = emptyList(),
    // What is installed from this repo, by the id the repo gives the source. A source of the same name installed from another repo is not in it.
    val installed: Map<String, InstalledRef> = emptyMap(),
    val loading: Boolean = true,
    val error: String? = null,
    // The sources that are being installed or removed right now.
    val busy: Set<String> = emptySet(),
    val removing: RemovePrompt? = null,
    val query: String = "",
    val chosenKind: Kind? = null,
    val showNsfw: Boolean = false,
    // The one language on show, or null for all of them.
    val chosenLanguage: String? = null,
) {
    // The kinds the repo has a source of, and the one on show. A kind the repo lacks falls back to the first it has.
    val kinds: List<Kind> get() = Kind.entries.filter { kind -> available.any { it.kind == kind } }
    val kind: Kind? get() = chosenKind?.takeIf { it in kinds } ?: kinds.firstOrNull()
    val hasNsfw: Boolean get() = available.any { it.nsfw }

    // The languages of the sources the kind and the adult choice leave, the biggest first, and the one on show. A language no longer there falls back to all.
    val languages: List<String>
        get() = available
            .filter { (kind == null || it.kind == kind) && (showNsfw || !it.nsfw) }
            .groupingBy { it.lang }
            .eachCount()
            .entries
            .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key })
            .map { it.key }
    val language: String? get() = chosenLanguage?.takeIf { it in languages }

    // What shows under the filters: the kind, the typed words, and the sources the repo marks for adults only when those are asked for.
    val visible: List<RepoSource>
        get() {
            val words = query.trim().lowercase()
            return available.filter {
                (kind == null || it.kind == kind) && (showNsfw || !it.nsfw) &&
                    (language == null || it.lang == language) &&
                    (words.isEmpty() || it.name.lowercase().contains(words))
            }
        }

    // One heading for each language with the biggest first, each with its sources by name.
    val groups: List<RepoGroup>
        get() = visible
            .groupBy { it.lang }
            .map { (language, list) -> RepoGroup(language, list.sortedBy { it.name.lowercase() }) }
            .sortedWith(compareByDescending<RepoGroup> { it.sources.size }.thenBy { it.language })

    // The installed sources the repo has a newer version of.
    val updates: List<RepoSource> get() = available.filter { source ->
        installed[source.id]?.let {
            it.version <
                source.version
        } ==
            true
    }

    // Installed from here but no longer listed, so they will get no updates. Nothing is said while the list is not read.
    val obsolete: List<InstalledRef>
        get() = if (loading ||
            error != null
        ) {
            emptyList()
        } else {
            installed.filterKeys { origin -> available.none { it.id == origin } }.values.toList()
        }
}

// What the callbacks of the repo page do.
class RepoActions(
    val onLoad: () -> Unit,
    val onInstall: (RepoSource) -> Unit,
    val onRemove: (String, String) -> Unit,
    val onQuery: (String) -> Unit,
    val onKind: (Kind) -> Unit,
    val onLanguage: (String?) -> Unit,
    val onShowNsfw: (Boolean) -> Unit,
    val onUpdateAll: () -> Unit,
    val onCopyAddress: () -> Unit,
    val onBack: () -> Unit,
)
