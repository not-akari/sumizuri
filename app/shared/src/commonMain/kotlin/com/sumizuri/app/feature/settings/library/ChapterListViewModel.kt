package com.sumizuri.app.feature.settings.library

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.settings.SessionRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// The choices about the list of chapters of a title, which are kept for every title. The title pages follow them as they change.
data class ChapterListChoices(
    val oldestFirst: Boolean = false,
    val grid: Boolean = false,
    val hideDuplicates: Boolean = false,
    val sort: ChapterSort = ChapterSort.Source,
    val filter: ChapterFilter = ChapterFilter(),
    val pictures: Boolean = false,
)

class ChapterListViewModel(private val session: SessionRepository) : ViewModel() {
    private val mutableState = MutableStateFlow(ChapterListChoices())
    val state: StateFlow<ChapterListChoices> = mutableState

    init {
        // The switches show a change made on a title page too, as this page is kept while the profile is open.
        viewModelScope.launch {
            session.chapterLook.collect { chosen ->
                mutableState.value =
                    ChapterListChoices(
                        chosen.oldestFirst,
                        chosen.grid,
                        chosen.hideDuplicates,
                        chosen.sort,
                        chosen.filter,
                        chosen.pictures,
                    )
            }
        }
    }

    fun onOldestFirst(on: Boolean) {
        mutableState.update { it.copy(oldestFirst = on) }
        viewModelScope.launch { session.setOldestFirst(on) }
    }

    fun onGrid(on: Boolean) {
        mutableState.update { it.copy(grid = on) }
        viewModelScope.launch { session.setChapterGrid(on) }
    }

    fun onPictures(on: Boolean) {
        mutableState.update { it.copy(pictures = on) }
        viewModelScope.launch { session.setChapterPictures(on) }
    }

    fun onHideDuplicates(on: Boolean) {
        mutableState.update { it.copy(hideDuplicates = on) }
        viewModelScope.launch { session.setHideDuplicates(on) }
    }

    fun onFilter(filter: ChapterFilter) {
        mutableState.update { it.copy(filter = filter) }
        viewModelScope.launch { session.setChapterFilter(filter) }
    }

    fun onSort(sort: ChapterSort) {
        mutableState.update { it.copy(sort = sort) }
        viewModelScope.launch { session.setChapterSort(sort) }
    }
}
