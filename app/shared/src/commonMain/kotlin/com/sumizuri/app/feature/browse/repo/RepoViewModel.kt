package com.sumizuri.app.feature.browse.repo

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.source.repo.RepoSource
import com.sumizuri.app.source.repo.installIdFor
import com.sumizuri.app.source.repo.originId
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// One repo, the sources it lists, and installing, updating and removing them.
class RepoViewModel(
    repo: Repo,
    private val sources: SourceRepository,
    private val manager: SourceManager,
    private val library: LibraryRepository,
) : ViewModel() {
    private val mutableState = MutableStateFlow(RepoState(repo))
    val state: StateFlow<RepoState> = mutableState

    // Everything installed, from any repo, so a source gets an id that nothing else holds.
    private var all: List<InstalledSource> = emptyList()

    init {
        viewModelScope.launch {
            sources.installed.collect { list ->
                all = list
                val here = list.filter { source -> source.repoUrl == mutableState.value.repo.url }
                mutableState.update {
                    it.copy(
                        installed = here.associate { source ->
                            source.originId to
                                InstalledRef(source.id, source.version, source.name, source.iconUrl)
                        },
                    )
                }
            }
        }
        onLoad()
    }

    fun onLoad() {
        mutableState.update { it.copy(loading = true, error = null) }
        viewModelScope.launch {
            when (val result = manager.repos.fetchIndex(mutableState.value.repo.url)) {
                is SourceResult.Err -> mutableState.update {
                    it.copy(loading = false, error = result.error.message, available = emptyList())
                }

                is SourceResult.Ok -> mutableState.update { it.copy(loading = false, available = result.value.sources) }
            }
        }
    }

    fun onInstall(source: RepoSource) {
        viewModelScope.launch { install(source) }
    }

    // Updates each source that has a newer version, one after the other.
    fun onUpdateAll() {
        viewModelScope.launch { mutableState.value.updates.forEach { install(it) } }
    }

    fun onQuery(value: String) = mutableState.update { it.copy(query = value) }

    fun onKind(value: Kind) = mutableState.update { it.copy(chosenKind = value) }

    fun onLanguage(value: String?) = mutableState.update { it.copy(chosenLanguage = value) }

    fun onShowNsfw(value: Boolean) = mutableState.update { it.copy(showNsfw = value) }

    private suspend fun install(source: RepoSource) {
        if (source.id in mutableState.value.busy) return
        mutableState.update { it.copy(busy = it.busy + source.id, error = null) }
        when (val result = manager.repos.fetchSource(source, mutableState.value.repo.url)) {
            is SourceResult.Err -> mutableState.update { it.copy(error = result.error.message) }

            is SourceResult.Ok -> sources.save(
                result.value.copy(id = installIdFor(result.value.repoUrl, source.id, all)),
            )
        }
        mutableState.update { it.copy(busy = it.busy - source.id) }
    }

    // A source that saved titles came from is only removed after a yes that says what happens to them.
    fun onRemove(id: String, name: String) {
        if (id in mutableState.value.busy) return
        viewModelScope.launch {
            val titles = library.countOf(id)
            if (titles == 0) remove(id) else mutableState.update { it.copy(removing = RemovePrompt(id, name, titles)) }
        }
    }

    fun onConfirmRemove() {
        val prompt = mutableState.value.removing ?: return
        mutableState.update { it.copy(removing = null) }
        remove(prompt.id)
    }

    fun onCancelRemove() = mutableState.update { it.copy(removing = null) }

    private fun remove(id: String) {
        if (id in mutableState.value.busy) return
        mutableState.update { it.copy(busy = it.busy + id) }
        viewModelScope.launch {
            manager.close(id)
            sources.remove(id)
            mutableState.update { it.copy(busy = it.busy - id) }
        }
    }
}
