package com.sumizuri.app.feature.reader

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.feature.comments.CommentsTarget

@Composable
fun ReaderRoute(
    chapterId: Long,
    onBack: () -> Unit,
    onOpenChapter: (Long) -> Unit,
    onOpenComments: (CommentsTarget) -> Unit,
    // What the opener already knows of the chapter, shown while the reader reads the rest.
    opening: ChapterPlace? = null,
) {
    val container = LocalAppContainer.current
    val viewModel = viewModel(key = "reader_$chapterId") {
        ReaderViewModel(
            chapterId,
            container.library,
            container.reading,
            container.sources,
            container.manager,
            container.solver,
            container.downloads,
            container.autoDownloads,
        )
    }
    val state by viewModel.state.collectAsStateWithLifecycle()
    LaunchedEffect(viewModel) { viewModel.open() }
    DisposableEffect(viewModel) { onDispose { viewModel.onLeave() } }
    val actions = remember(viewModel, onBack, onOpenChapter, onOpenComments) {
        ReaderActions(
            onProgress = viewModel::onProgress,
            onRetry = viewModel::onRetry,
            onSolve = viewModel::onSolve,
            onOpenChapter = onOpenChapter,
            onBack = onBack,
            onAspects = viewModel::onAspects,
            onMode = viewModel::onMode,
            onDefaultMode = viewModel::onDefaultMode,
            onSettings = viewModel::onSettings,
            onBookmark = viewModel::onBookmark,
            onSetCover = viewModel::onSetCover,
            onActive = viewModel::onActive,
            onNearEnd = viewModel::onNearEnd,
            onComments = onOpenComments,
        )
    }
    ReaderScreen(state, actions, opening)
}
