package com.sumizuri.app.feature.browse.repo

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.ui.kit.input.rememberCopyText

@Composable
fun RepoRoute(repo: Repo, onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val viewModel =
        viewModel(
            key = "repo_${repo.url}",
        ) { RepoViewModel(repo, container.sources, container.manager, container.library) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val copy = rememberCopyText()
    val actions = RepoActions(
        onLoad = viewModel::onLoad,
        onInstall = viewModel::onInstall,
        onRemove = viewModel::onRemove,
        onQuery = viewModel::onQuery,
        onKind = viewModel::onKind,
        onLanguage = viewModel::onLanguage,
        onShowNsfw = viewModel::onShowNsfw,
        onUpdateAll = viewModel::onUpdateAll,
        onCopyAddress = { copy(repo.url) },
        onBack = onBack,
    )
    RepoScreen(state, actions)
    state.removing?.let { RemoveSourceDialog(it, viewModel::onConfirmRemove, viewModel::onCancelRemove) }
}
