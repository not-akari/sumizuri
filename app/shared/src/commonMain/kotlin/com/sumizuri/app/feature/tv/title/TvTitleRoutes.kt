package com.sumizuri.app.feature.tv.title

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.feature.title.PreviewViewModel
import com.sumizuri.app.feature.title.TitleViewModel
import com.sumizuri.app.feature.title.rememberDuplicateGuard
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource

// A saved title on a TV, from the same model as the title page. OK on an episode plays it, and a title out of the library is checked for one of the same name before it goes in.
@Composable
internal fun TvTitleRoute(titleId: Long, onPlay: (Long) -> Unit) {
    val container = LocalAppContainer.current
    val model = viewModel(key = "title_$titleId") {
        TitleViewModel(
            titleId,
            container.library,
            container.sync,
            container.sources,
            container.session,
            container.focus,
            container.manager,
            container.solver,
            container.libraryPrefs,
            container.downloads,
            container.autoDownloads,
            container.seasonCovers,
            container.settings,
        )
    }
    val state by model.state.collectAsStateWithLifecycle()
    val guard = rememberDuplicateGuard()
    val calls = remember(model, onPlay, guard) {
        TvTitleCalls(
            onPlay = { onPlay(it.id) },
            onToggleLibrary = {
                val title = model.state.value.title
                if (title != null &&
                    !title.inLibrary
                ) {
                    guard(title.name, title.kind, title.id, model::onToggleLibrary)
                } else {
                    model.onToggleLibrary()
                }
            },
            onRefresh = model::onRefresh,
            onToggleWatched = { model.chapters.onToggleRead(it.id, !it.read) },
        )
    }
    TvTitleScreen(state, calls)
}

// A title a source offers, on a TV. Adding it saves it and opens it as a saved title, and playing an episode saves it out of the library first, as the title page does.
@Composable
internal fun TvPreviewRoute(
    source: InstalledSource,
    entry: SourceEntry,
    onSaved: (Long) -> Unit,
    onRead: (Long, Long) -> Unit,
) {
    val container = LocalAppContainer.current
    val model = viewModel(key = "preview_${source.id}_${entry.url}") {
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
    val state by model.state.collectAsStateWithLifecycle()
    val guard = rememberDuplicateGuard(onOpen = onSaved)
    val calls = remember(model, onSaved, onRead, guard) {
        TvTitleCalls(
            onPlay = { model.onRead(it.id, onRead) },
            onToggleLibrary = { guard(entry.title, source.kind, -1L) { model.onAdd(onSaved) } },
            onRefresh = model::onRefresh,
            onToggleWatched = null,
        )
    }
    TvTitleScreen(state, calls)
}
