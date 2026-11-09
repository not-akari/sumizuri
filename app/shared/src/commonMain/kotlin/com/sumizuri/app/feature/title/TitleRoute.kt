package com.sumizuri.app.feature.title

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.feature.comments.CommentsTarget

@Composable
fun TitleRoute(titleId: Long, onBack: () -> Unit, onOpenChapter: (Long) -> Unit, onMigrate: (Long) -> Unit, onOpenComments: (CommentsTarget) -> Unit) {
    val container = LocalAppContainer.current
    val viewModel = viewModel(key = "title_$titleId") {
        TitleViewModel(titleId, container.library, container.sync, container.sources, container.session, container.focus, container.manager, container.solver, container.libraryPrefs, container.downloads, container.autoDownloads, container.seasonCovers, container.settings)
    }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val calls = remember(viewModel, onBack, onOpenChapter, onMigrate, onOpenComments) {
        TitleCallbacks(
            onBack = onBack,
            onRefresh = viewModel::onRefresh,
            onSolve = viewModel::onSolve,
            onMigrate = { onMigrate(titleId) },
            onEnableSource = viewModel::onEnableSource,
            onToggleSort = viewModel::onToggleSort,
            onToggleGrid = viewModel::onToggleGrid,
            onToggleGridPictures = viewModel::onToggleGridPictures,
            onToggleDuplicates = viewModel::onToggleDuplicates,
            onSort = viewModel::onSort,
            onFilter = viewModel::onFilter,
            onHideFacets = viewModel::onHideFacets,
            onSwitchVolumes = viewModel::onSwitchVolumes,
            onToggleLibrary = viewModel::onToggleLibrary,
            onToggleFavorite = viewModel::onToggleFavorite,
            onMarkAll = viewModel.chapters::onMarkAll,
            onComments = onOpenComments,
            onContinue = onOpenChapter,
            onSetFocus = viewModel::onSetFocus,
            onClearFocus = viewModel::onClearFocus,
            chapters = ChapterCallbacks(onOpenChapter, viewModel.chapters::onToggleRead, viewModel.chapters::onToggleBookmark, viewModel.chapters::onSelect),
            selection = SelectionCallbacks(
                onClose = viewModel.chapters::onClearSelection,
                onSelectAll = viewModel.chapters::onSelectAll,
                onInvert = viewModel.chapters::onInvertSelection,
                onMarkRead = viewModel.chapters::onMarkSelected,
                onBookmark = viewModel.chapters::onBookmarkSelected,
                onMarkBelowRead = viewModel.chapters::onMarkBelowRead,
            ),
            downloads = DownloadCalls(
                onDownload = viewModel.chapters::onDownload,
                onRemove = viewModel.chapters::onRemoveDownload,
                onDownloadSelected = viewModel.chapters::onDownloadSelected,
                onRemoveSelected = viewModel.chapters::onRemoveSelectedDownloads,
                onDownloadAll = viewModel.chapters::onDownloadAll,
                onRemoveAll = viewModel.chapters::onRemoveAllDownloads,
            ),
        )
    }
    TitleScreen(state, calls)
}
