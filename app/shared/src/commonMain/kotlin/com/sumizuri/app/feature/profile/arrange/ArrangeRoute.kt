package com.sumizuri.app.feature.profile.arrange

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.blocks.BlockLayout
import com.sumizuri.app.data.blocks.BlockTemplate
import com.sumizuri.app.data.blocks.ProfileBlocksRepository
import com.sumizuri.app.data.blocks.ProfilePreset
import com.sumizuri.app.data.blocks.decodeBlock
import com.sumizuri.app.data.blocks.newBlockId
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.library.StatisticsRepository
import com.sumizuri.app.data.model.FeedItem
import com.sumizuri.app.data.model.stats.ReadingStats
import com.sumizuri.app.feature.profile.BlockCalls
import com.sumizuri.app.feature.profile.ShownBlock
import com.sumizuri.app.feature.profile.blocks.GridColumns
import com.sumizuri.app.feature.profile.blocks.MostRows
import com.sumizuri.app.feature.profile.showBlocks
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonElement

// What the page of the blocks shows: the blocks with what they show, and what a preview of the page needs.
class ArrangeState(
    val blocks: List<ShownBlock> = emptyList(),
    val stats: ReadingStats = ReadingStats(),
    val recent: List<FeedItem> = emptyList(),
    val loaded: Boolean = false,
    val context: com.sumizuri.app.data.blocks.BlockContext? = null,
)

// How many titles the preview of the continue section shows, as the profile does.
private const val RecentCount = 8

// The blocks of the profile, to put in order, size, add, copy and remove. Each change is saved at once.
class ArrangeViewModel(
    private val blocks: ProfileBlocksRepository,
    statistics: StatisticsRepository,
    library: LibraryRepository,
) : ViewModel() {
    val state: StateFlow<ArrangeState> = combine(
        blocks.layout,
        statistics.reading,
        library.history,
    ) { layout, reading, history ->
        ArrangeState(
            showBlocks(layout, reading),
            reading.stats,
            history
                .distinctBy {
                    it.title.id
                }.take(RecentCount),
            loaded = true,
            context = reading,
        )
    }.flowOn(Dispatchers.Default).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ArrangeState())

    private fun change(edit: (BlockLayout) -> BlockLayout) = viewModelScope.launch { blocks.update(edit) }

    // Puts a block at another place in the order.
    fun onMove(id: String, to: Int) = change { layout ->
        val moving = layout.blocks.firstOrNull { it.id == id } ?: return@change layout
        val rest = layout.blocks - moving
        layout.copy(blocks = rest.toMutableList().apply { add(to.coerceIn(0, rest.size), moving) })
    }

    fun onResize(id: String, w: Int, h: Int) = viewModelScope.launch {
        blocks.updateBlock(id) { it.copy(w = w.coerceIn(1, GridColumns), h = h.coerceIn(0, MostRows)) }
    }

    fun onRemove(id: String) = change { layout -> layout.copy(blocks = layout.blocks.filter { it.id != id }) }

    // A copy of a block, right after it.
    fun onDuplicate(id: String) = change { layout ->
        val index = layout.blocks.indexOfFirst { it.id == id }
        if (index <
            0
        ) {
            layout
        } else {
            layout.copy(
                blocks = layout.blocks.toMutableList().apply {
                    add(index + 1, layout.blocks[index].copy(id = newBlockId()))
                },
            )
        }
    }

    fun onAdd(template: BlockTemplate) = viewModelScope.launch {
        val block = template.block()
        blocks.update { it.copy(blocks = it.blocks + block) }
    }

    // Adds the block of a file someone shared, and gives false when it holds no block.
    suspend fun onImport(data: JsonElement): Boolean {
        val block = decodeBlock(data) ?: return false
        blocks.update { it.copy(blocks = it.blocks + block.copy(id = newBlockId())) }
        return true
    }

    // Replaces the blocks with a preset. Classic forgets the saved blocks, so the page is the one it came with.
    fun onPreset(preset: ProfilePreset) = viewModelScope.launch {
        if (preset ==
            ProfilePreset.Classic
        ) {
            blocks.reset()
        } else {
            blocks.save(preset.layout())
        }
    }
}

@Composable
fun ArrangeRoute(onBack: () -> Unit, onEditScript: (String) -> Unit) {
    val container = LocalAppContainer.current
    val viewModel = viewModel { ArrangeViewModel(container.blocks, container.statistics, container.library) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val calls = remember(viewModel, onEditScript) {
        BlockCalls(
            onMove = { id, to -> viewModel.onMove(id, to) },
            onResize = { id, w, h -> viewModel.onResize(id, w, h) },
            onRemove = { viewModel.onRemove(it) },
            onDuplicate = { viewModel.onDuplicate(it) },
            onAdd = { viewModel.onAdd(it) },
            onImport = viewModel::onImport,
            onEdit = onEditScript,
            onPreset = { viewModel.onPreset(it) },
        )
    }
    ArrangeScreen(state, calls, onBack)
}
