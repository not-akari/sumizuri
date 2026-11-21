package com.sumizuri.app.feature.profile.layouts

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.blocks.ProfileBlocksRepository
import com.sumizuri.app.data.blocks.ProfilePreset
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.library.StatisticsRepository
import com.sumizuri.app.data.model.FeedItem
import com.sumizuri.app.data.model.stats.ReadingStats
import com.sumizuri.app.feature.profile.ShownBlock
import com.sumizuri.app.feature.profile.showBlocks
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

// Each layout drawn with the reading of the person as it is now, so it can be seen before it is chosen.
class LayoutsState(
    val previews: Map<ProfilePreset, List<ShownBlock>> = emptyMap(),
    val stats: ReadingStats = ReadingStats(),
    val recent: List<FeedItem> = emptyList(),
)

class LayoutsViewModel(
    private val blocks: ProfileBlocksRepository,
    statistics: StatisticsRepository,
    library: LibraryRepository,
) : ViewModel() {
    val state: StateFlow<LayoutsState> = combine(statistics.reading, library.history) { reading, history ->
        LayoutsState(
            ProfilePreset.entries.associateWith { showBlocks(it.layout(), reading) },
            reading.stats,
            history.distinctBy { it.title.id }.take(RecentCount),
        )
    }.flowOn(Dispatchers.Default).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), LayoutsState())

    // Puts the layout in place of the blocks, then closes the page. Classic forgets the saved blocks, so the page is the one it came with.
    fun onUse(preset: ProfilePreset, done: () -> Unit) {
        viewModelScope.launch {
            if (preset == ProfilePreset.Classic) blocks.reset() else blocks.save(preset.layout())
            done()
        }
    }

    private companion object {
        const val RecentCount = 8
    }
}

@Composable
fun LayoutsRoute(onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val viewModel = viewModel { LayoutsViewModel(container.blocks, container.statistics, container.library) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    LayoutsScreen(state, onUse = { viewModel.onUse(it, onBack) }, onBack = onBack)
}
