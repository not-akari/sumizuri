package com.sumizuri.app.feature.title.edit

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Restore
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.library.DetailsEdit
import com.sumizuri.app.data.library.EditedPart
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.info.CoverSearchDialog
import com.sumizuri.app.playback.fetchBytes
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.edit_author
import com.sumizuri.app.shared.resources.edit_genres
import com.sumizuri.app.shared.resources.edit_kept_note
import com.sumizuri.app.shared.resources.edit_leave
import com.sumizuri.app.shared.resources.edit_leave_message
import com.sumizuri.app.shared.resources.edit_leave_title
import com.sumizuri.app.shared.resources.edit_name
import com.sumizuri.app.shared.resources.edit_reset
import com.sumizuri.app.shared.resources.edit_status
import com.sumizuri.app.shared.resources.edit_summary
import com.sumizuri.app.shared.resources.edit_title
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.ui.kit.art.InkTonalButton
import com.sumizuri.app.ui.kit.card.CardButton
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.image.SourceReferers
import com.sumizuri.app.ui.kit.input.SoftField
import com.sumizuri.app.ui.kit.input.rememberImagePicker
import com.sumizuri.app.ui.kit.page.LocalBottomClearance
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.page.pageScroll
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The page that changes what a title says about itself, opened from its menu.
@Composable
fun EditTitleRoute(titleId: Long, onBack: () -> Unit) {
    val library = LocalAppContainer.current.library
    val title by remember(titleId) { library.title(titleId) }.collectAsStateWithLifecycle(null)
    title?.let { EditTitleScreen(it, onBack) }
}

// The cover beside the parts on a wide window and above them on a phone: name, author, status, genres and summary. A part that differs from the source says so and can be given back to the source on its own. Leaving with changes not saved asks first.
@Composable
private fun EditTitleScreen(title: Title, onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val edits = container.library.edits
    val scope = rememberCoroutineScope()
    val edited by remember(title.id) { edits.observeEdited(title.id) }.collectAsStateWithLifecycle(emptySet())
    val customCover by remember(title.id) { edits.observeCustomCover(title.id) }.collectAsStateWithLifecycle(false)
    var name by rememberSaveable(title.id) { mutableStateOf(title.name) }
    var author by rememberSaveable(title.id) { mutableStateOf(title.author) }
    var summary by rememberSaveable(title.id) { mutableStateOf(title.summary) }
    var genres by rememberSaveable(title.id) { mutableStateOf(title.genres) }
    var status by rememberSaveable(title.id) { mutableStateOf(title.status) }
    var searching by remember { mutableStateOf(false) }
    var leaving by remember { mutableStateOf(false) }
    val dirty =
        name != title.name || author != title.author || summary != title.summary || genres != title.genres ||
            status != title.status
    val pickImage = rememberImagePicker { bytes ->
        scope.launch { edits.setCustomCover(title.id, container.coverFiles.save(title.id, bytes)) }
    }

    // Gives the source its say over the parts, asks it again, and shows what it said in those parts.
    fun useSource(parts: Set<EditedPart>) {
        scope.launch {
            if (parts.size ==
                EditedPart.entries.size
            ) {
                edits.reset(title.id)
            } else {
                parts.forEach { edits.resetPart(title.id, it) }
            }
            container.sync.refresh(title.id)
            val fresh = container.library.title(title.id).first() ?: return@launch
            if (EditedPart.Name in parts) name = fresh.name
            if (EditedPart.Author in parts) author = fresh.author
            if (EditedPart.Summary in parts) summary = fresh.summary
            if (EditedPart.Genres in parts) genres = fresh.genres
            if (EditedPart.Status in parts) status = fresh.status
        }
    }
    val tryBack = { if (dirty) leaving = true else onBack() }
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = dirty) {
        leaving =
            true
    }

    // The bar sits in the middle with the parts, like on every page that is a list.
    ReadableColumn {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(stringResource(Res.string.edit_title), subtitle = title.name, onBack = tryBack) {
                InkTonalButton(
                    {
                        // The page closes once the details are saved, so leaving never cuts the saving short.
                        scope.launch {
                            edits.save(title.id, DetailsEdit(name, author, summary, status, genres))
                            onBack()
                        }
                    },
                    Modifier.padding(
                        end = 8.dp,
                    ),
                    enabled = dirty && name.isNotBlank(),
                ) { Text(stringResource(Res.string.save)) }
            }
            run {
                BoxWithConstraints(Modifier.weight(1f).fillMaxSize()) {
                    val wide = maxWidth >= 600.dp
                    Column(
                        Modifier
                            .fillMaxSize()
                            .pageScroll()
                            .padding(
                                start = PageGutter,
                                end = PageGutter,
                                top = 8.dp,
                                bottom =
                                24.dp + LocalBottomClearance.current,
                            ),
                    ) {
                        val cover: @Composable (Modifier) -> Unit = { place ->
                            CoverPanel(title, customCover, wide, pickImage, { searching = true }, {
                                scope.launch {
                                    edits.clearCustomCover(title.id)
                                    container.coverFiles.forget(title.id)
                                    container.sync.refresh(title.id)
                                }
                            }, place)
                        }
                        val fields: @Composable (Modifier) -> Unit = { place ->
                            Column(place, verticalArrangement = Arrangement.spacedBy(18.dp)) {
                                FieldBlock(
                                    stringResource(Res.string.edit_name),
                                    EditedPart.Name in edited,
                                    { useSource(setOf(EditedPart.Name)) },
                                ) {
                                    SoftField(name, { name = it })
                                }
                                FieldBlock(stringResource(Res.string.edit_author), EditedPart.Author in edited, {
                                    useSource(setOf(EditedPart.Author))
                                }) {
                                    SoftField(author, { author = it })
                                }
                                FieldBlock(stringResource(Res.string.edit_status), EditedPart.Status in edited, {
                                    useSource(setOf(EditedPart.Status))
                                }) {
                                    ChipRow(wrap = true) {
                                        for (choice in Status.entries) {
                                            ChoiceChip(
                                                stringResource(choice.label),
                                                status == choice,
                                            ) { status = choice }
                                        }
                                    }
                                }
                                FieldBlock(stringResource(Res.string.edit_genres), EditedPart.Genres in edited, {
                                    useSource(setOf(EditedPart.Genres))
                                }) {
                                    GenreEditor(genres) { genres = it }
                                }
                                FieldBlock(stringResource(Res.string.edit_summary), EditedPart.Summary in edited, {
                                    useSource(setOf(EditedPart.Summary))
                                }) {
                                    SoftField(summary, { summary = it }, singleLine = false, minLines = 4)
                                }
                                Text(
                                    stringResource(Res.string.edit_kept_note),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                                if (edited.isNotEmpty()) {
                                    CardButton({ useSource(EditedPart.entries.toSet()) }) {
                                        Icon(
                                            Icons.Outlined.Restore,
                                            null,
                                            Modifier.padding(start = 12.dp),
                                            tint = MaterialTheme.colorScheme.error,
                                        )
                                        Text(
                                            stringResource(Res.string.edit_reset),
                                            Modifier.padding(horizontal = 12.dp, vertical = 11.dp),
                                            color = MaterialTheme.colorScheme.error,
                                        )
                                    }
                                }
                            }
                        }
                        if (wide) {
                            Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                                cover(Modifier.width(200.dp))
                                fields(Modifier.weight(1f))
                            }
                        } else {
                            Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
                                cover(Modifier.fillMaxWidth())
                                fields(Modifier.fillMaxWidth())
                            }
                        }
                    }
                }
            }
        }
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
    if (leaving) {
        ConfirmDialog(
            stringResource(Res.string.edit_leave_title),
            stringResource(Res.string.edit_leave_message),
            stringResource(Res.string.edit_leave),
            onConfirm = {
                leaving = false
                onBack()
            },
            onDismiss = { leaving = false },
        )
    }
}
