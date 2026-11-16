package com.sumizuri.app.feature.backup

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.share.Incoming

@Composable
fun BackupRoute(onBack: () -> Unit, onMigrate: (List<Long>) -> Unit) {
    val container = LocalAppContainer.current
    val viewModel =
        viewModel { BackupViewModel(container.restorer, container.matcher, container.backupWriter, container.settings) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val make by viewModel.make.collectAsStateWithLifecycle()
    val choices by viewModel.choices.collectAsStateWithLifecycle()
    // A backup the import page found is read here, as one picked on this page would be.
    val incoming by Incoming.backup.collectAsStateWithLifecycle()
    LaunchedEffect(incoming) {
        incoming?.let {
            Incoming.backupTaken()
            viewModel.onPicked(it)
        }
    }
    val calls = remember(viewModel, onBack, onMigrate) {
        BackupCalls(
            onBack = onBack,
            onPicked = viewModel::onPicked,
            onPassword = viewModel::onPassword,
            onConfirm = viewModel::onConfirm,
            onCancel = viewModel::onCancel,
            onDismiss = viewModel::onDismiss,
            onMigrate = onMigrate,
            onMake = viewModel::onMake,
            onSaved = viewModel::onSaved,
            onMakeDismiss = viewModel::onMakeDismiss,
            onStopMaking = viewModel::onStopMaking,
        )
    }
    BackupScreen(state, make, choices, calls)
}
