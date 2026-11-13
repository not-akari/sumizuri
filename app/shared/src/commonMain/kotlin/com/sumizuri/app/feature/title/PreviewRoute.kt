package com.sumizuri.app.feature.title

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource

@Composable
fun PreviewRoute(
    source: InstalledSource,
    entry: SourceEntry,
    onBack: () -> Unit,
    onSaved: (Long) -> Unit,
    onRead: (Long, Long) -> Unit,
    onOpenComments: (CommentsTarget) -> Unit,
) {
    val container = LocalAppContainer.current
    val viewModel = viewModel(key = "preview_${source.id}_${entry.url}") {
        PreviewViewModel(
            source,
            entry,
            container.manager,
            container.library,
            container.session,
            container.solver,
            container.seasonCovers,
            container.settings,
        )
    }
    val state by viewModel.state.collectAsStateWithLifecycle()
    // A title of the same name in the library can be opened in place of the preview, as a saved one opens.
    val guard = rememberDuplicateGuard(onOpen = onSaved)
    val calls = remember(viewModel, onBack, onSaved, onRead, onOpenComments, guard) {
        TitleCallbacks(
            onBack = onBack,
            onRefresh = viewModel::onRefresh,
            onSolve = viewModel::onSolve,
            onMigrate = {},
            onEnableSource = {},
            onToggleSort = viewModel::onToggleSort,
            onToggleGrid = viewModel::onToggleGrid,
            onToggleGridPictures = viewModel::onToggleGridPictures,
            onToggleDuplicates = viewModel::onToggleDuplicates,
            onSort = viewModel::onSort,
            onSwitchVolumes = viewModel::onSwitchVolumes,
            onToggleLibrary = { guard(entry.title, source.kind, -1L) { viewModel.onAdd(onSaved) } },
            onToggleFavorite = {},
            onMarkAll = {},
            onComments = onOpenComments,
            onContinue = {},
            onSetFocus = { _, _ -> },
            onClearFocus = {},
            // A chapter opens once the title is saved out of the library. Nothing can be marked or picked before that.
            chapters = ChapterCallbacks({ viewModel.onRead(it, onRead) }, { _, _ -> }, { _, _ -> }, {}),
            selection = SelectionCallbacks({}, {}, {}, {}, {}, {}),
        )
    }
    TitleScreen(state, calls)
}
