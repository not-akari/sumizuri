package com.sumizuri.app.feature.profile

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.profile.LocalProfiles

@Composable
fun ProfileRoute(
    onOpenSettings: () -> Unit,
    onOpenSync: () -> Unit,
    onOpenTrackers: () -> Unit,
    onOpenMissing: () -> Unit,
    onOpenTitle: (Long) -> Unit,
    onArrange: () -> Unit,
    onLayouts: () -> Unit,
) {
    val container = LocalAppContainer.current
    val profiles = LocalProfiles.current
    val viewModel = viewModel { ProfileViewModel(profiles, container.statistics, container.library, container.blocks) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val calls =
        remember(
            viewModel,
            onOpenSettings,
            onOpenSync,
            onOpenTrackers,
            onOpenMissing,
            onOpenTitle,
            onArrange,
            onLayouts,
        ) {
            ProfileCalls(
                onOpenSettings = onOpenSettings,
                onOpenSync = onOpenSync,
                onOpenTrackers = onOpenTrackers,
                onOpenMissing = onOpenMissing,
                onOpenTitle = onOpenTitle,
                onSwitch = viewModel::onSwitch,
                onCreate = viewModel::onCreate,
                onSave = viewModel::onSave,
                onDelete = viewModel::onDelete,
                onLayouts = onLayouts,
                onArrange = onArrange,
            )
        }
    ProfileScreen(state, calls)
}
