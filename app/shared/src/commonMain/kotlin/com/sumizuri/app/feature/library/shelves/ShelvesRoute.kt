package com.sumizuri.app.feature.library.shelves

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer

@Composable
fun ShelvesRoute(onBack: () -> Unit, onEdit: (Long) -> Unit) {
    val container = LocalAppContainer.current
    val viewModel = viewModel { ShelvesViewModel(container.categories, container.library, container.sources) }
    val categories by viewModel.categories.collectAsStateWithLifecycle()
    val calls =
        remember(viewModel, onEdit) {
            ShelfCalls(
                viewModel::onAdd,
                viewModel::onReorder,
                onEdit,
            )
        }
    ShelvesScreen(categories, onBack, calls)
}
