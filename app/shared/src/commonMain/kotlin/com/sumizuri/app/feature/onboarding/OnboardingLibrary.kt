package com.sumizuri.app.feature.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.sources.RepoMigration
import com.sumizuri.app.feature.backup.BackupCalls
import com.sumizuri.app.feature.backup.BackupDialogs
import com.sumizuri.app.feature.backup.BackupState
import com.sumizuri.app.feature.backup.BackupViewModel
import com.sumizuri.app.feature.backup.RestoreRow
import com.sumizuri.app.feature.browse.extensions.AddRepoDialog
import com.sumizuri.app.feature.browse.extensions.ExtensionsViewModel
import com.sumizuri.app.feature.browse.extensions.SourceFileImporter
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.backup_done_added
import com.sumizuri.app.shared.resources.backup_done_matched
import com.sumizuri.app.shared.resources.backup_matching
import com.sumizuri.app.shared.resources.backup_migrate_now
import com.sumizuri.app.shared.resources.backup_progress
import com.sumizuri.app.shared.resources.backup_reading
import com.sumizuri.app.shared.resources.extensions_add_repo
import com.sumizuri.app.shared.resources.onboarding_library_another
import com.sumizuri.app.shared.resources.onboarding_library_done
import com.sumizuri.app.shared.resources.onboarding_library_text
import com.sumizuri.app.shared.resources.onboarding_library_title
import com.sumizuri.app.shared.resources.onboarding_library_waiting
import com.sumizuri.app.shared.resources.onboarding_repo_hint
import com.sumizuri.app.shared.resources.onboarding_repos_added
import com.sumizuri.app.ui.kit.art.DrawnCheck
import com.sumizuri.app.ui.kit.art.ProgressRing
import com.sumizuri.app.ui.kit.art.QuietButton
import com.sumizuri.app.ui.kit.art.rise
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// A backup of this app or of another, brought in here. The way is the row of the backup page. While it works, a ring fills with the count of titles, and at the end a tick draws itself over what came in. Asking for a password or a yes uses the windows of the backup page.
@Composable
internal fun LibraryStep(onMigrate: (List<Long>) -> Unit) {
    val container = LocalAppContainer.current
    val model = viewModel { BackupViewModel(container.restorer, container.matcher, container.backupWriter, container.settings) }
    val state by model.state.collectAsStateWithLifecycle()
    val calls = remember(model) {
        BackupCalls(
            onBack = {}, onPicked = model::onPicked, onPassword = model::onPassword, onConfirm = model::onConfirm, onCancel = model::onCancel,
            onDismiss = model::onDismiss, onMigrate = onMigrate, onMake = { _, _ -> }, onSaved = {}, onMakeDismiss = {},
        )
    }
    // The repos come first, as a new app has no sources and finds no titles without one.
    val extensions = viewModel {
        ExtensionsViewModel(
            container.repos,
            container.updates,
            SourceFileImporter(container.manager, container.sources),
            RepoMigration(container.manager.repos, container.sources, container.database),
        )
    }
    val sources by extensions.state.collectAsStateWithLifecycle()
    StepHeader(stringResource(Res.string.onboarding_library_title), stringResource(Res.string.onboarding_library_text))
    AnimatedContent(state.phase(), Modifier.fillMaxWidth().rise(2), transitionSpec = { (fadeIn(tween(300)) + scaleIn(initialScale = 0.96f)) togetherWith fadeOut(tween(180)) }, label = "library") { phase ->
        when (phase) {
            LibraryPhase.Choose -> SettingsSection {
                row { RepoRow(sources.repos.size, extensions::onAddOpen) }
                row { RestoreRow(model::onPicked) }
            }

            LibraryPhase.Working -> Working(state)

            LibraryPhase.Done -> Finished(state as? BackupState.Done, onAnother = model::onDismiss, onMigrate = onMigrate)
        }
    }
    // A password, a yes before the titles go in, and a file that could not be read are asked in the windows of the backup page.
    if (state is BackupState.Password || state is BackupState.Confirm || state is BackupState.Failed) BackupDialogs(state, calls)
    sources.adding?.let { AddRepoDialog(it, extensions::onAddress, extensions::onAddConfirm, extensions::onAddDismiss) }
}

// Adding a repo, which says how many are in once there are some.
@Composable
private fun RepoRow(count: Int, onAdd: () -> Unit) {
    val line = if (count > 0) pluralStringResource(Res.plurals.onboarding_repos_added, count, count) else stringResource(Res.string.onboarding_repo_hint)
    SettingRow(stringResource(Res.string.extensions_add_repo), subtitle = line, subtitleLines = 3, leading = {
        SettingIcon(Icons.Outlined.Extension)
    }, trailing = { ListChevron() }, onClick = onAdd)
}

// What the step shows for where the backup is: the ways to choose from, the work going on, or what came in.
private enum class LibraryPhase { Choose, Working, Done }

private fun BackupState.phase(): LibraryPhase = when (this) {
    BackupState.Reading, is BackupState.Running -> LibraryPhase.Working
    is BackupState.Done -> LibraryPhase.Done
    else -> LibraryPhase.Choose
}

@Composable
private fun Working(state: BackupState) {
    val running = state as? BackupState.Running
    val progress = running?.let { if (it.total > 0) it.done.toFloat() / it.total else 0f } ?: 0f
    Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(24.dp)) {
        ProgressRing(progress, Modifier.size(110.dp))
        val line = when {
            running == null -> stringResource(Res.string.backup_reading)
            running.matching -> stringResource(Res.string.backup_matching, running.done, running.total)
            else -> stringResource(Res.string.backup_progress, running.done, running.total)
        }
        Text(line, style = MaterialTheme.typography.titleMedium)
    }
}

@Composable
private fun Finished(state: BackupState.Done?, onAnother: () -> Unit, onMigrate: (List<Long>) -> Unit) {
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.size(120.dp), contentAlignment = Alignment.Center) { DrawnCheck(Modifier.fillMaxSize()) }
        Text(stringResource(Res.string.onboarding_library_done), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
        if (state != null) {
            Text(stringResource(Res.string.backup_done_added, state.result.added, state.result.skipped), color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
            state.matched?.let { Text(stringResource(Res.string.backup_done_matched, it), color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center) }
            if (state.waiting.isNotEmpty()) Text(stringResource(Res.string.onboarding_library_waiting, state.waiting.size), color = MaterialTheme.colorScheme.outline, textAlign = TextAlign.Center, style = MaterialTheme.typography.bodySmall)
        }
        Row(Modifier.padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            QuietButton(stringResource(Res.string.onboarding_library_another), onAnother, Icons.Rounded.Add)
            if (state != null && state.waiting.isNotEmpty()) QuietButton(stringResource(Res.string.backup_migrate_now), { onMigrate(state.waiting) })
        }
    }
}
