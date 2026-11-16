package com.sumizuri.app.feature.share

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.ShareProblem
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.import_damaged
import com.sumizuri.app.shared.resources.import_done_block
import com.sumizuri.app.shared.resources.import_done_repos
import com.sumizuri.app.shared.resources.import_done_repos_all
import com.sumizuri.app.shared.resources.import_done_settings
import com.sumizuri.app.shared.resources.import_done_theme
import com.sumizuri.app.shared.resources.import_finish
import com.sumizuri.app.shared.resources.import_newer
import com.sumizuri.app.shared.resources.import_not_now
import com.sumizuri.app.shared.resources.import_not_ours
import com.sumizuri.app.shared.resources.import_reading
import com.sumizuri.app.shared.resources.import_title
import com.sumizuri.app.shared.resources.import_try_again
import com.sumizuri.app.shared.resources.import_undo
import com.sumizuri.app.shared.resources.settings_import_page_hint
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.art.Notice
import com.sumizuri.app.ui.kit.input.rememberFilePicker
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The one place files come into the app and things go out of it. A file is shown before anything is taken, and a backup goes on to the backup page, which asks how to restore it. The backup page opens on top of this one to make a backup, and in its place to restore one.
@Composable
fun ImportRoute(onBack: () -> Unit, onOpenBackup: () -> Unit, onRestore: () -> Unit) {
    val container = LocalAppContainer.current
    val model = viewModel { ImportViewModel(container.settings, container.themes, container.blocks, container.repos) }
    val state by model.state.collectAsStateWithLifecycle()
    // A page opened again starts clean, unless a file is still being read.
    LaunchedEffect(Unit) {
        if (model.state.value !is ImportState.Reading) model.onAgain()
        container.autoBackups.refresh()
    }
    // The page is cleared before the backup page opens, so coming back here never opens it again.
    LaunchedEffect(state) {
        if (state == ImportState.ToBackup) {
            model.onAgain()
            onRestore()
        }
    }
    val pick = rememberFilePicker(onPicked = model::onSource)
    SettingsPageFrame(Res.string.import_title, onBack, subtitle = Res.string.settings_import_page_hint) {
        when (val now = state) {
            ImportState.Empty -> ImportHome(
                onPick = pick,
                onDrop = model::onSource,
                onOpenBackup = onOpenBackup,
            )

            ImportState.Reading, ImportState.ToBackup -> Row(
                Modifier.padding(vertical = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                InkCircularProgressIndicator(Modifier.size(28.dp))
                Text(stringResource(Res.string.import_reading))
            }

            is ImportState.Ready -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                val theme = remember(now.thing) { model.themeOf(now.thing) }
                ImportPreview(now.thing, theme)
                InkButton(model::onTake, Modifier.fillMaxWidth()) { Text(stringResource(takeLabel(now.thing.kind))) }
                TextButton(model::onAgain, Modifier.fillMaxWidth()) { Text(stringResource(Res.string.import_not_now)) }
            }

            is ImportState.Done -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                ResultNotice(Icons.Outlined.CheckCircle, doneText(now), MaterialTheme.colorScheme.primary)
                InkButton(model::onAgain, Modifier.fillMaxWidth()) { Text(stringResource(Res.string.import_finish)) }
                if (now.undo != null) {
                    TextButton(model::onUndo, Modifier.fillMaxWidth()) { Text(stringResource(Res.string.import_undo)) }
                }
            }

            is ImportState.Failed -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                ResultNotice(
                    Icons.Outlined.ErrorOutline,
                    stringResource(problemText(now.problem)),
                    MaterialTheme.colorScheme.error,
                )
                InkButton(model::onAgain, Modifier.fillMaxWidth()) { Text(stringResource(Res.string.import_try_again)) }
            }
        }
    }
}

// How it went, tinted with the color that says so.
@Composable
private fun ResultNotice(icon: ImageVector, text: String, tint: Color) =
    Notice(text, icon = icon, tint = tint, fill = tint.copy(alpha = 0.12f))

// What was taken, in words that fit each kind.
@Composable
private fun doneText(done: ImportState.Done): String = when (done.kind) {
    ShareKind.Settings -> pluralStringResource(Res.plurals.import_done_settings, done.taken, done.taken)

    ShareKind.Theme -> stringResource(Res.string.import_done_theme)

    ShareKind.Block -> stringResource(Res.string.import_done_block)

    ShareKind.Repos -> if (done.taken == done.of) {
        pluralStringResource(Res.plurals.import_done_repos_all, done.taken, done.taken)
    } else {
        stringResource(Res.string.import_done_repos, done.taken, done.of)
    }

    ShareKind.Backup -> error("a backup goes to the backup page")
}

private fun problemText(problem: ShareProblem) = when (problem) {
    ShareProblem.NotOurs -> Res.string.import_not_ours
    ShareProblem.Newer -> Res.string.import_newer
    ShareProblem.Damaged -> Res.string.import_damaged
}
