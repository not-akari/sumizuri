package com.sumizuri.app.feature.share

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.share.ImportSource
import com.sumizuri.app.data.share.Incoming
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.ShareProblem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.import_again
import com.sumizuri.app.shared.resources.import_choose
import com.sumizuri.app.shared.resources.import_damaged
import com.sumizuri.app.shared.resources.import_done_block
import com.sumizuri.app.shared.resources.import_done_repos
import com.sumizuri.app.shared.resources.import_done_repos_all
import com.sumizuri.app.shared.resources.import_done_settings
import com.sumizuri.app.shared.resources.import_done_theme
import com.sumizuri.app.shared.resources.import_hint
import com.sumizuri.app.shared.resources.import_newer
import com.sumizuri.app.shared.resources.import_not_ours
import com.sumizuri.app.shared.resources.import_paste
import com.sumizuri.app.shared.resources.import_read
import com.sumizuri.app.shared.resources.import_reading
import com.sumizuri.app.shared.resources.import_title
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.input.rememberFilePicker
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The one place things come into the app: a .sumizuri file, a link, or pasted text. It shows what is inside before anything is taken. A backup goes on to the backup page, which asks how to restore it.
@Composable
fun ImportRoute(onBack: () -> Unit, onOpenBackup: () -> Unit) {
    val container = LocalAppContainer.current
    val model = viewModel { ImportViewModel(container.settings, container.themes, container.blocks, container.repos) }
    val state by model.state.collectAsStateWithLifecycle()
    val incoming by Incoming.source.collectAsStateWithLifecycle()
    // A page opened again starts clean, unless something new waits for it.
    LaunchedEffect(Unit) {
        if (Incoming.source.value == null && model.state.value !is ImportState.Reading) model.onAgain()
    }
    LaunchedEffect(incoming) {
        incoming?.let {
            Incoming.taken()
            model.onSource(it)
        }
    }
    // The page is cleared before the backup page opens, so coming back here never opens it again.
    LaunchedEffect(state) {
        if (state == ImportState.ToBackup) {
            model.onAgain()
            onOpenBackup()
        }
    }
    val pick = rememberFilePicker { model.onSource(ImportSource.File(it)) }
    ReadableColumn {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(stringResource(Res.string.import_title), onBack = onBack)
            Column(
                Modifier
                    .fillMaxWidth()
                    .verticalScroll(
                        rememberScrollState(),
                    ).padding(horizontal = PageGutter, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                when (val now = state) {
                    ImportState.Empty -> ImportStart(pick, onText = { model.onSource(ImportSource.Text(it)) })

                    ImportState.Reading, ImportState.ToBackup -> Row(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        CircularProgressIndicator(Modifier.padding(2.dp))
                        Text(stringResource(Res.string.import_reading), Modifier.padding(top = 8.dp))
                    }

                    is ImportState.Ready -> {
                        ImportPreview(now.thing, model)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            InkButton(model::onTake) { Text(stringResource(takeLabel(now.thing.kind))) }
                            TextButton(model::onAgain) { Text(stringResource(Res.string.cancel)) }
                        }
                    }

                    is ImportState.Done -> {
                        AppCard { Text(doneText(now), Modifier.padding(16.dp)) }
                        TextButton(model::onAgain) { Text(stringResource(Res.string.import_again)) }
                    }

                    is ImportState.Failed -> {
                        Text(stringResource(problemText(now.problem)), color = MaterialTheme.colorScheme.error)
                        TextButton(model::onAgain) { Text(stringResource(Res.string.import_again)) }
                    }
                }
            }
        }
    }
}

// The two ways in when nothing waits: a file from the device, or a link or text pasted in.
@Composable
private fun ImportStart(pick: () -> Unit, onText: (String) -> Unit) {
    var text by remember { mutableStateOf("") }
    Text(stringResource(Res.string.import_hint), color = MaterialTheme.colorScheme.onSurfaceVariant)
    InkButton(pick) { Text(stringResource(Res.string.import_choose)) }
    OutlinedTextField(text, {
        text = it
    }, Modifier.fillMaxWidth(), label = { Text(stringResource(Res.string.import_paste)) }, minLines = 2, maxLines = 6)
    TextButton({ onText(text) }, enabled = text.isNotBlank()) { Text(stringResource(Res.string.import_read)) }
}

// What was taken, in words that fit each kind.
@Composable
private fun doneText(done: ImportState.Done): String = when (done.kind) {
    ShareKind.Settings -> pluralStringResource(Res.plurals.import_done_settings, done.taken, done.taken)

    ShareKind.Theme -> stringResource(Res.string.import_done_theme)

    ShareKind.Block -> stringResource(Res.string.import_done_block)

    ShareKind.Repos -> if (done.taken ==
        done.of
    ) {
        pluralStringResource(Res.plurals.import_done_repos_all, done.taken, done.taken)
    } else {
        stringResource(Res.string.import_done_repos, done.taken, done.of)
    }

    ShareKind.Backup -> ""
}

private fun problemText(problem: ShareProblem) = when (problem) {
    ShareProblem.NotOurs -> Res.string.import_not_ours
    ShareProblem.Newer -> Res.string.import_newer
    ShareProblem.Damaged -> Res.string.import_damaged
}
