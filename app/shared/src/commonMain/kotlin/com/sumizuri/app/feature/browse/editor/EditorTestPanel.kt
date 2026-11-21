package com.sumizuri.app.feature.browse.editor

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.sumizuri.app.core.log.LogEntry
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.ext_edit_failed
import com.sumizuri.app.shared.resources.ext_edit_run_done
import com.sumizuri.app.shared.resources.ext_edit_running
import com.sumizuri.app.shared.resources.ext_edit_search_hint
import com.sumizuri.app.shared.resources.ext_edit_stop
import com.sumizuri.app.shared.resources.ext_edit_test_hint
import com.sumizuri.app.shared.resources.ext_edit_worked
import com.sumizuri.app.source.model.CommentSort
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.art.InkTonalButton
import com.sumizuri.app.ui.kit.chips.SoftActionChip
import com.sumizuri.app.ui.kit.input.AppTextField
import org.jetbrains.compose.resources.stringResource

// The tests of the draft against the real site. Run all goes through everything the code offers and writes a report. Each part can also be tried alone: the lists, a search, the catalogs, the filters, the settings and what the code says about itself, and from a list a title with its chapters and comments, and from those a chapter with its pages. What came back is shown with notes on what would look wrong, and the console under it shows what the code said.
@Composable
internal fun EditorTestPanel(
    state: ExtensionEditorState,
    console: List<LogEntry>,
    actions: ExtensionEditorActions,
    padding: PaddingValues,
    modifier: Modifier,
) {
    val test = state.test
    var query by rememberSaveable { mutableStateOf("") }
    var consoleOpen by rememberSaveable { mutableStateOf(true) }
    val idle = test.running == null
    Column(modifier.padding(padding), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        AppTextField(
            query,
            { query = it },
            Modifier.fillMaxWidth(),
            placeholder = { Text(stringResource(Res.string.ext_edit_search_hint)) },
            singleLine = true,
            trailingIcon = {
                IconButton({
                    actions.onSearch(query)
                }, enabled = idle && query.isNotBlank()) {
                    Icon(
                        Icons.Outlined.Search,
                        stringResource(TestStep.Search.label),
                    )
                }
            },
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
            keyboardActions = KeyboardActions(onSearch = { actions.onSearch(query) }),
        )
        // Every part that can be tried shows at once, on a second line when the panel is narrow.
        FlowRow(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            InkTonalButton(actions.onRunAll, enabled = idle) {
                Icon(Icons.Outlined.PlayArrow, null, Modifier.size(18.dp))
                Text(stringResource(TestStep.RunAll.label), Modifier.padding(start = 6.dp))
            }
            StepChip(TestStep.Popular, idle, actions.onPopular)
            StepChip(TestStep.Latest, idle, actions.onLatest)
            StepChip(TestStep.Catalogs, idle, actions.onCatalogs)
            StepChip(TestStep.Filters, idle, actions.onFilters)
            StepChip(TestStep.Settings, idle, actions.onSettings)
            StepChip(TestStep.Info, idle, actions.onInfo)
        }
        StepLine(test, actions.onStopTest)
        if (test.view != TestView.Report) Notes(test.notes)
        LazyColumn(Modifier.weight(1f).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            val back = if (test.trail.size > 1) actions.onTestBack else null
            when (test.view) {
                TestView.Hint -> item { Hint(stringResource(Res.string.ext_edit_test_hint)) }

                TestView.List -> listPart(test, idle, back, actions)

                TestView.Title -> test.entry?.let { titlePart(it, test, idle, back, actions) }

                TestView.Chapter -> chapterPart(test, idle, back, actions)

                TestView.Comments -> commentsPart(
                    test.entry?.title.orEmpty(),
                    test.comments,
                    test.commentSort,
                    idle,
                    back,
                ) {
                    actions.onComments(it)
                }

                TestView.ChapterComments -> commentsPart(
                    test.chapter?.title.orEmpty(),
                    test.chapterComments,
                    test.commentSort,
                    idle,
                    back,
                ) {
                    actions.onChapterComments(it)
                }

                TestView.Info -> test.info?.let { infoPart(it, back) }

                TestView.Filters -> filtersPart(test.filters, back)

                TestView.Catalogs -> catalogsPart(test.catalogs, idle, back, actions.onOpenCatalog)

                TestView.Settings -> settingsPart(test.settings, test.settingValues, back)

                TestView.Report -> reportPart(test, actions.onShowView)
            }
        }
        EditorConsole(console, actions.onClearConsole, consoleOpen, {
            consoleOpen = !consoleOpen
        }, if (consoleOpen) Modifier.fillMaxWidth().height(180.dp) else Modifier.fillMaxWidth())
    }
}

@Composable
private fun StepChip(step: TestStep, enabled: Boolean, onClick: () -> Unit) {
    SoftActionChip(onClick, { Text(stringResource(step.label)) }, enabled = enabled)
}

// What runs now with a way to stop it, how long the last step took, or what went wrong in it, which can be selected and copied.
@Composable
private fun StepLine(test: ExtensionTest, onStop: () -> Unit) {
    val running = test.running
    val failed = test.failed
    val done = test.done
    when {
        running != null -> Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            InkCircularProgressIndicator(Modifier.size(14.dp), strokeWidth = 2.dp)
            val name = stringResource(running.label)
            Text(
                stringResource(
                    Res.string.ext_edit_running,
                    if (test.runningAll) "${stringResource(TestStep.RunAll.label)} · $name" else name,
                ),
                Modifier.weight(1f),
                style = MaterialTheme.typography.bodySmall,
            )
            TextButton(onStop) { Text(stringResource(Res.string.ext_edit_stop)) }
        }

        failed != null && failed != TestStep.Start -> SelectionContainer {
            Column {
                Text(
                    stringResource(Res.string.ext_edit_failed, stringResource(failed.label), test.tookMs ?: 0L),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.error,
                )
                test.error?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.bodySmall,
                        fontFamily = FontFamily.Monospace,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            }
        }

        // Run all is over even when some of its steps failed, which its report says, so it only says it finished.
        done == TestStep.RunAll -> Text(
            stringResource(Res.string.ext_edit_run_done, test.tookMs ?: 0L),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        done != null -> Text(
            stringResource(Res.string.ext_edit_worked, stringResource(done.label), test.tookMs ?: 0L),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

// What looks wrong in the last answer, such as titles with no cover.
@Composable
internal fun Notes(notes: List<TestNote>) {
    if (notes.isEmpty()) return
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        for (note in notes) {
            Text(
                "⚠ " + noteText(note),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.tertiary,
            )
        }
    }
}

@Composable
internal fun noteText(note: TestNote): String = stringResource(note.text, *note.args.toTypedArray())

// The comments of a title or a chapter come in the order picked here.
internal val CommentOrders = listOf(CommentSort.Newest, CommentSort.Oldest, CommentSort.Top)
