package com.sumizuri.app.feature.lists

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.lists.ListRepository
import com.sumizuri.app.data.lists.MakeResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

// The lists of the person, each with the covers of its first titles, and the changes to them. Every change is saved at once.
class ListsViewModel(private val repo: ListRepository, library: LibraryRepository) : ViewModel() {
    private val match = LibraryMatch()

    val faces: StateFlow<List<ListFace>?> = combine(repo.lists, repo.fronts, library.library) { lists, fronts, titles ->
        val saved = match.byKey(titles)
        lists.map { list -> ListFace(list, fronts[list.id].orEmpty().map { it.coverTitle(saved[it.key]) }) }
    }.flowOn(Dispatchers.Default).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    fun onCreate(name: String, about: String, done: (MakeResult) -> Unit) {
        viewModelScope.launch { done(repo.create(name, about)) }
    }

    fun onDescribe(id: Long, name: String, about: String) {
        viewModelScope.launch { repo.describe(id, name, about) }
    }

    fun onDelete(id: Long) {
        viewModelScope.launch { repo.delete(id) }
    }

    fun onReorder(ids: List<Long>) {
        viewModelScope.launch { repo.reorder(ids) }
    }
}
