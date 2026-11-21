package com.sumizuri.app.feature.library.shelves

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.library.CategoryRepository
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.LibraryEntry
import com.sumizuri.app.data.model.library.LibrarySortField
import com.sumizuri.app.data.model.library.shelf.ShelfCondition
import com.sumizuri.app.data.model.library.shelf.ShelfContext
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

// The shelves of the library and the changes to them. Every change is saved at once. The size of a shelf is the titles put on it and the ones that meet its conditions.
class ShelvesViewModel(private val shelves: CategoryRepository, library: LibraryRepository, sources: SourceRepository) :
    ViewModel() {
    // The titles and the source names as they were last seen, for counting what some conditions match.
    private var titles = emptyList<Title>()
    private var seen = emptyList<LibraryEntry>()
    private var names = emptyMap<String, String>()

    val categories: StateFlow<List<Category>?> = combine(
        shelves.categories,
        // The shelves page reads when each title was read and updated, so conditions on those count right.
        library.entries(setOf(LibrarySortField.LastRead, LibrarySortField.LatestChapter)),
        sources.installed,
    ) { all, entries, installed ->
        names = installed.associate { it.id to it.name }
        titles = entries.map { it.title }
        seen = entries
        val context = ShelfContext.of(names, nowMillis(), entries)
        all.map { shelf -> shelf.copy(titles = entries.count { shelf.holds(it, context) }) }
    }.flowOn(Dispatchers.Default).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    fun onAdd(name: String, kind: Kind?) {
        viewModelScope.launch { shelves.add(name, kind) }
    }

    fun onDelete(id: Long) {
        viewModelScope.launch { shelves.delete(id) }
    }

    fun onReorder(ids: List<Long>) {
        viewModelScope.launch { shelves.reorder(ids) }
    }

    // Keeps what the page of the shelf changed, and nothing else.
    internal fun onSave(shelf: Category, edit: ShelfEdit) {
        viewModelScope.launch {
            if (edit.rule != shelf.rule ||
                edit.status != shelf.status
            ) {
                shelves.setRule(shelf.id, edit.rule, edit.status)
            }
            if (edit.kind != shelf.kind) shelves.setKind(shelf.id, edit.kind)
            if (edit.name.trim() != shelf.name) shelves.rename(shelf.id, edit.name)
            if (edit.exclude != shelf.excludeFromUpdate) shelves.setExcluded(shelf.id, edit.exclude)
            if (edit.conditions != shelf.conditions ||
                edit.matchAll != shelf.matchAll
            ) {
                shelves.setConditions(shelf.id, edit.conditions, edit.matchAll)
            }
        }
    }

    fun countMatches(conditions: List<ShelfCondition>, matchAll: Boolean): Int {
        val probe = Category(0, "", false, 0, conditions = conditions, matchAll = matchAll)
        if (!probe.isSmart) return 0
        val context = ShelfContext.of(names, nowMillis(), seen)
        return titles.count { probe.matches(it, context) }
    }
}
