package com.sumizuri.app.feature.lists

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.lists.Added
import com.sumizuri.app.data.lists.ListItem
import com.sumizuri.app.data.lists.ListRepository
import com.sumizuri.app.data.lists.ListTitle
import com.sumizuri.app.data.lists.ReadingList
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

// A title of the list with the one of the library that has its name and kind, when there is one.
data class ShownItem(val item: ListItem, val saved: Title?)

// What the page of a list shows. Until it has loaded there is no list, and a list that was deleted stays null.
data class ListPage(
    val loaded: Boolean = false,
    val list: ReadingList? = null,
    val items: List<ShownItem> = emptyList(),
)

// One list, its titles matched to the library by name, and the changes to it.
class ListViewModel(private val id: Long, private val repo: ListRepository, library: LibraryRepository) : ViewModel() {
    // The keys of the library titles, kept by name and kind so a big library is folded once and not on every change.
    private val match = LibraryMatch()

    val page: StateFlow<ListPage> = combine(repo.list(id), repo.items(id), library.library) { list, items, titles ->
        val saved = match.byKey(titles)
        ListPage(true, list, items.map { ShownItem(it, saved[it.key]) })
    }.flowOn(Dispatchers.Default).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ListPage())

    fun onDescribe(name: String, about: String) {
        viewModelScope.launch { repo.describe(id, name, about) }
    }

    fun onDelete() {
        viewModelScope.launch { repo.delete(id) }
    }

    fun onMove(ids: List<Long>) {
        viewModelScope.launch { repo.moveItems(id, ids) }
    }

    fun onNote(itemId: Long, note: String) {
        viewModelScope.launch { repo.setNote(id, itemId, note) }
    }

    fun onRemove(itemId: Long) {
        viewModelScope.launch { repo.removeItems(id, listOf(itemId)) }
    }
}
