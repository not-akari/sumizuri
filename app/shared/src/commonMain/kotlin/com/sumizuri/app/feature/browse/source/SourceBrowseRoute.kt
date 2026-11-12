package com.sumizuri.app.feature.browse.source

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.text.enumNamed
import com.sumizuri.app.feature.title.rememberDuplicateGuard
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

@Composable
fun SourceBrowseRoute(
    source: InstalledSource,
    onBack: () -> Unit,
    onOpenSaved: (Long) -> Unit,
    onOpenPreview: (InstalledSource, SourceEntry) -> Unit,
    onEditCode: () -> Unit,
) {
    val container = LocalAppContainer.current
    val viewModel = viewModel(key = "browse_${source.id}") {
        SourceBrowseViewModel(
            source,
            container.library,
            container.sources,
            container.catalogs,
            container.manager,
            container.session,
            container.solver,
        )
    }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val style by remember {
        container.settings.text(SettingKey.BrowseStyle).map {
            enumNamed<BrowseStyle>(it)
                ?: BrowseStyle.Grid
        }
    }.collectAsStateWithLifecycle(BrowseStyle.Grid)
    val scope = rememberCoroutineScope()
    // A title of the same name in the library is asked about before the cover adds another.
    val guard = rememberDuplicateGuard(onOpen = onOpenSaved)
    val actions = remember(viewModel, onBack, onOpenSaved, onOpenPreview, onEditCode, guard) {
        SourceBrowseActions(
            onBack = onBack,
            onQuery = viewModel::onQuery,
            onTab = viewModel::onTab,
            onLoadMore = viewModel::onLoadMore,
            onRetry = viewModel::onRetry,
            onSolve = viewModel::onSolve,
            onOpenEntry = { entry ->
                // An entry that is saved already opens as the saved title.
                scope.launch {
                    val saved = container.library.savedId(source.id, entry)
                    if (saved != null) onOpenSaved(saved) else onOpenPreview(source, entry)
                }
            },
            onOpenFilters = viewModel::onOpenFilters,
            onFilters = viewModel::onFilters,
            onSaveTab = viewModel::onSaveTab,
            onRenameTab = viewModel::onRenameTab,
            onDeleteTab = viewModel::onDeleteTab,
            onOpenPreferences = viewModel::onOpenPreferences,
            onPreference = viewModel::onPreference,
            onClosePreferences = viewModel::onClosePreferences,
            onEditCode = onEditCode,
            onQuickAdd = { entry -> guard(entry.title, source.kind, -1L) { viewModel.onQuickAdd(entry) } },
            onImport = viewModel::onImport,
            onStyle = { scope.launch { container.settings.setText(SettingKey.BrowseStyle, it.name) } },
            onRemove = viewModel::onRemove,
            onConfirmRemove = viewModel::onConfirmRemove,
            onCancelRemove = viewModel::onCancelRemove,
        )
    }
    SourceBrowseScreen(state, style, actions)
}
