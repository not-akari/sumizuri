package com.sumizuri.app.feature.title.info

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.library.DetailsEdit
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.playback.fetchBytes
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.edit_author
import com.sumizuri.app.shared.resources.edit_cover_file
import com.sumizuri.app.shared.resources.edit_cover_source
import com.sumizuri.app.shared.resources.edit_cover_sources
import com.sumizuri.app.shared.resources.edit_genres
import com.sumizuri.app.shared.resources.edit_genres_hint
import com.sumizuri.app.shared.resources.edit_kept_note
import com.sumizuri.app.shared.resources.edit_name
import com.sumizuri.app.shared.resources.edit_reset
import com.sumizuri.app.shared.resources.edit_status
import com.sumizuri.app.shared.resources.edit_summary
import com.sumizuri.app.shared.resources.edit_title
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.image.SourceReferers
import com.sumizuri.app.ui.kit.input.rememberImagePicker
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// Changes what a title says about itself: its name, author, status, genres and summary, and its cover, from a file or from another source. What is changed here stays when the source says otherwise, until the source's own is asked for again.
@Composable
internal fun EditTitleDialog(title: Title, onRefresh: () -> Unit, onDismiss: () -> Unit) {
    val container = LocalAppContainer.current
    val edits = container.library.edits
    val scope = rememberCoroutineScope()
    val edited by remember(title.id) { edits.observeEdited(title.id) }.collectAsState(emptySet())
    val customCover by remember(title.id) { edits.observeCustomCover(title.id) }.collectAsState(false)
    var name by rememberSaveable { mutableStateOf(title.name) }
    var author by rememberSaveable { mutableStateOf(title.author) }
    var summary by rememberSaveable { mutableStateOf(title.summary) }
    var genres by rememberSaveable { mutableStateOf(title.genres.joinToString(", ")) }
    var status by remember { mutableStateOf(title.status) }
    var searching by remember { mutableStateOf(false) }
    val pickImage = rememberImagePicker { bytes ->
        scope.launch { edits.setCustomCover(title.id, container.coverFiles.save(title.id, bytes)) }
    }
    if (searching) {
        CoverSearchDialog(
            title,
            onPick = { found ->
                searching = false
                scope.launch {
                    // The picture is kept as a file, so it still shows when the site it came from wants headers this title's source does not send.
                    val site = SourceReferers.of(found.sourceId)
                    val headers =
                        (site?.let { mapOf("Referer" to it) } ?: emptyMap()) + SourceReferers.headersOf(found.sourceId)
                    val bytes = fetchBytes(found.url, headers)
                    edits.setCustomCover(
                        title.id,
                        if (bytes ==
                            null
                        ) {
                            found.url
                        } else {
                            container.coverFiles.save(title.id, bytes)
                        },
                    )
                }
            },
            onDismiss = { searching = false },
        )
    }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.edit_title)) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    CoverArt(title, Modifier.width(72.dp), letterSize = 22)
                    Column {
                        TextButton(pickImage) { Text(stringResource(Res.string.edit_cover_file)) }
                        TextButton({ searching = true }) { Text(stringResource(Res.string.edit_cover_sources)) }
                        if (customCover) {
                            TextButton({
                                scope.launch {
                                    edits.clearCustomCover(title.id)
                                    container.coverFiles.forget(title.id)
                                    onRefresh()
                                }
                            }) { Text(stringResource(Res.string.edit_cover_source)) }
                        }
                    }
                }
                OutlinedTextField(name, {
                    name = it
                }, Modifier.fillMaxWidth(), label = { Text(stringResource(Res.string.edit_name)) }, singleLine = true)
                OutlinedTextField(author, {
                    author = it
                }, Modifier.fillMaxWidth(), label = { Text(stringResource(Res.string.edit_author)) }, singleLine = true)
                Text(stringResource(Res.string.edit_status), style = MaterialTheme.typography.labelLarge)
                ChipRow {
                    for (choice in Status.entries) {
                        ChoiceChip(stringResource(choice.label), status == choice) {
                            status =
                                choice
                        }
                    }
                }
                OutlinedTextField(
                    genres,
                    { genres = it },
                    Modifier.fillMaxWidth(),
                    label = { Text(stringResource(Res.string.edit_genres)) },
                    supportingText = { Text(stringResource(Res.string.edit_genres_hint)) },
                )
                OutlinedTextField(
                    summary,
                    { summary = it },
                    Modifier.fillMaxWidth(),
                    label = { Text(stringResource(Res.string.edit_summary)) },
                    minLines = 3,
                    maxLines = 8,
                )
                Text(
                    stringResource(Res.string.edit_kept_note),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                if (edited.isNotEmpty()) {
                    TextButton({
                        scope.launch {
                            edits.reset(title.id)
                            onRefresh()
                            onDismiss()
                        }
                    }) { Text(stringResource(Res.string.edit_reset)) }
                }
            }
        },
        confirmButton = {
            TextButton({
                // The window closes once the details are saved, so leaving it never cuts the saving short.
                scope.launch {
                    edits.save(title.id, DetailsEdit(name, author, summary, status, genres.split(',', '\n')))
                    onDismiss()
                }
            }, enabled = name.isNotBlank()) { Text(stringResource(Res.string.save)) }
        },
        dismissButton = { TextButton(onDismiss) { Text(stringResource(Res.string.cancel)) } },
    )
}
