package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material.icons.outlined.Timeline
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.TrackStatus
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.data.tracker.TrackerMedia
import com.sumizuri.app.data.tracker.TrackerProblem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_add_again
import com.sumizuri.app.shared.resources.tracker_delete
import com.sumizuri.app.shared.resources.tracker_delete_message
import com.sumizuri.app.shared.resources.tracker_delete_title
import com.sumizuri.app.shared.resources.tracker_gone_hint
import com.sumizuri.app.shared.resources.tracker_leave_out
import com.sumizuri.app.shared.resources.tracker_linking
import com.sumizuri.app.shared.resources.tracker_open
import com.sumizuri.app.shared.resources.tracker_progress
import com.sumizuri.app.shared.resources.tracker_progress_set
import com.sumizuri.app.shared.resources.tracker_score
import com.sumizuri.app.shared.resources.tracker_search
import com.sumizuri.app.shared.resources.tracker_search_none
import com.sumizuri.app.shared.resources.tracker_status
import com.sumizuri.app.shared.resources.tracker_unlink
import com.sumizuri.app.shared.resources.tracker_unlink_message
import com.sumizuri.app.shared.resources.tracker_unlink_remove
import com.sumizuri.app.shared.resources.tracker_unlink_title
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.Notice
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.kit.sync.CoverRow
import com.sumizuri.app.ui.kit.text.WorkingRow
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// A title of the library on one tracker: finding it there and linking it, or once linked, its status, progress and score, which sync both ways.
@Composable
internal fun TrackSheet(tracker: TrackerId, titleId: Long, name: String, kind: Kind, onDismiss: () -> Unit) {
    val sync = LocalAppContainer.current.trackerSync
    val links by remember(titleId) { sync.linksOf(titleId) }.collectAsStateWithLifecycle(null)
    AppSheet(onDismiss, title = tracker.label) {
        val known = links ?: return@AppSheet
        val link = known.firstOrNull { it.tracker == tracker.id }
        if (link == null) LinkSearch(tracker, titleId, name, kind, onDismiss) else LinkEditor(tracker, link, onDismiss)
    }
}

// Finds the title on the tracker by its name, which the person can change, and links the one tapped.
@Composable
private fun LinkSearch(tracker: TrackerId, titleId: Long, name: String, kind: Kind, onDismiss: () -> Unit) {
    val sync = LocalAppContainer.current.trackerSync
    val scope = rememberCoroutineScope()
    var query by remember { mutableStateOf(name) }
    var found by remember { mutableStateOf<List<TrackerMedia>?>(null) }
    var busy by remember { mutableStateOf(false) }
    var problem by remember { mutableStateOf<TrackerProblem?>(null) }

    // Runs one step against the tracker, with the page waiting and saying what went wrong.
    fun work(step: suspend () -> Unit) {
        busy = true
        problem = null
        scope.launch {
            try {
                step()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                problem = TrackerProblem.from(error)
            }
            busy = false
        }
    }
    val search = { if (query.isNotBlank()) work { found = sync.search(tracker, query.trim(), kind) } }
    // A title the tracker does not have, such as a show that is not anime, is left out of it here.
    TextButton({
        scope.launch {
            sync.use.leaveOut(tracker, titleId)
            onDismiss()
        }
    }) { Text(stringResource(Res.string.tracker_leave_out, tracker.label)) }
    LaunchedEffect(Unit) { search() }
    AppTextField(
        query,
        { query = it },
        Modifier.fillMaxWidth(),
        label = { Text(stringResource(Res.string.tracker_search, tracker.label)) },
        singleLine = true,
        trailingIcon = {
            IconButton(search, enabled = !busy) {
                Icon(Icons.Outlined.Search, stringResource(Res.string.tracker_search, tracker.label))
            }
        },
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        keyboardActions = KeyboardActions(onSearch = { search() }),
    )
    if (busy) {
        WorkingRow(stringResource(Res.string.tracker_linking))
    }
    problem?.let {
        ProblemLine(it, tracker)
    }
    val results = found ?: return
    if (results.isEmpty()) {
        Text(
            stringResource(Res.string.tracker_search_none),
            color = MaterialTheme.colorScheme.outline,
            style = MaterialTheme.typography.bodyMedium,
        )
        return
    }
    SettingsSection {
        for (media in results) {
            row {
                val line = listOfNotNull(
                    formatWords(media.format),
                    media.year?.toString(),
                    media.total?.toString(),
                ).joinToString(" · ")
                CoverRow(media.name, kind, media.cover, line, onClick = {
                    if (!busy) work { sync.link(tracker, titleId, kind, media) }
                })
            }
        }
    }
}

// The entry of a linked title, which the person changes here and which syncs a moment later.
@Composable
private fun LinkEditor(tracker: TrackerId, link: TrackerLinkEntity, onDismiss: () -> Unit) {
    val container = LocalAppContainer.current
    val sync = container.trackerSync
    val scope = rememberCoroutineScope()
    val uri = LocalUriHandler.current
    val accounts by remember(container) { container.trackers.signedIn }.collectAsStateWithLifecycle(emptyMap())
    val format = accounts[tracker]?.scoreFormat
    val kind = Kind.fromCode(link.kind)
    var unlinking by remember { mutableStateOf(false) }
    var removing by remember { mutableStateOf(false) }
    var removeProblem by remember { mutableStateOf<TrackerProblem?>(null) }
    var setting by remember { mutableStateOf(false) }
    val change = { status: String, progress: Int, score: Int ->
        scope.launch {
            sync.change(link.titleId, tracker, status, progress, score)
        }
    }
    SettingsSection {
        row { CoverRow(link.remoteName, kind, link.remoteCover, linkLine(link, tracker, format)) }
    }
    if (link.gone) {
        Notice(stringResource(Res.string.tracker_gone_hint, tracker.label))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            InkButton({
                scope.launch { sync.addAgain(link.titleId, tracker) }
            }) { Text(stringResource(Res.string.tracker_add_again)) }
            TextButton({ unlinking = true }) { Text(stringResource(Res.string.tracker_unlink)) }
        }
    } else {
        SettingsSection {
            padded {
                ChoiceSetting(
                    Res.string.tracker_status,
                    TrackStatus.entries,
                    TrackStatus.of(link.status),
                    { statusLabel(it, kind) },
                    icon = Icons.Outlined.Visibility,
                ) { change(it.code, link.progress, link.score) }
            }
            row {
                SettingRow(
                    stringResource(Res.string.tracker_progress),
                    subtitle = progressText(link.progress, link.remoteTotal, kind),
                    leading = { SettingIcon(Icons.Outlined.Timeline) },
                    onClick = { setting = true },
                    trailing = {
                        Row {
                            IconButton(
                                { change(link.status, link.progress - 1, link.score) },
                                enabled =
                                link.progress > 0,
                            ) { Icon(Icons.Outlined.Remove, null) }
                            IconButton(
                                { change(link.status, link.progress + 1, link.score) },
                                enabled =
                                link.remoteTotal == null || link.progress < link.remoteTotal,
                            ) {
                                Icon(Icons.Outlined.Add, null)
                            }
                        }
                    },
                )
            }
            padded {
                ChoiceSetting(
                    Res.string.tracker_score,
                    scoreChoices(format),
                    nearestScore(link.score, format),
                    { scoreText(it, format) },
                    icon = Icons.Outlined.StarOutline,
                ) { change(link.status, link.progress, it) }
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            link.remoteUrl?.let { address ->
                TextButton({
                    runCatching { uri.openUri(address) }
                }) { Text(stringResource(Res.string.tracker_open, tracker.label)) }
            }
            TextButton({ removing = true }) {
                Text(stringResource(Res.string.tracker_delete, tracker.label), color = MaterialTheme.colorScheme.error)
            }
            TextButton({ unlinking = true }) { Text(stringResource(Res.string.tracker_unlink)) }
        }
        removeProblem?.let {
            ProblemLine(it, tracker)
        }
    }
    // Deletes the entry on the tracker, such as one planned and then not wanted, and leaves the title out so linking the library does not add it again.
    if (removing) {
        ConfirmDialog(
            stringResource(Res.string.tracker_delete_title, tracker.label),
            stringResource(Res.string.tracker_delete_message, tracker.label),
            stringResource(Res.string.tracker_delete, tracker.label),
            onConfirm = {
                removing = false
                removeProblem = null
                scope.launch {
                    try {
                        sync.unlink(link.titleId, tracker, removeThere = true)
                        sync.use.leaveOut(tracker, link.titleId)
                        onDismiss()
                    } catch (error: CancellationException) {
                        throw error
                    } catch (error: Exception) {
                        removeProblem = TrackerProblem.from(error)
                    }
                }
            },
            onDismiss = { removing = false },
        )
    }
    if (setting) {
        ProgressDialog(link.progress, link.remoteTotal, onDismiss = { setting = false }) {
            setting = false
            change(link.status, it, link.score)
        }
    }
    if (unlinking) {
        var removeThere by remember { mutableStateOf(false) }
        AppDialog(
            { unlinking = false },
            confirmButton = {
                InkButton({
                    unlinking = false
                    scope.launch {
                        runCatching { sync.unlink(link.titleId, tracker, removeThere) }
                        onDismiss()
                    }
                }) { Text(stringResource(Res.string.tracker_unlink)) }
            },
            dismissButton = { CancelButton({ unlinking = false }) },
            title = { Text(stringResource(Res.string.tracker_unlink_title)) },
            text = {
                Column {
                    Text(stringResource(Res.string.tracker_unlink_message, tracker.label))
                    if (!link.gone && link.entryId != null) {
                        SwitchSetting(stringResource(Res.string.tracker_unlink_remove, tracker.label), removeThere, {
                            removeThere =
                                it
                        })
                    }
                }
            },
        )
    }
}

// Types how far a title is, for a jump too long for the buttons.
@Composable
private fun ProgressDialog(progress: Int, total: Int?, onDismiss: () -> Unit, onSet: (Int) -> Unit) {
    var typed by remember { mutableStateOf(progress.toString()) }
    val value = typed.toIntOrNull()?.takeIf { it >= 0 && (total == null || it <= total) }
    AppDialog(
        onDismiss,
        confirmButton = {
            InkButton(
                { value?.let(onSet) },
                enabled = value != null,
            ) { Text(stringResource(Res.string.tracker_progress_set)) }
        },
        dismissButton = { CancelButton(onDismiss) },
        title = { Text(stringResource(Res.string.tracker_progress)) },
        text = {
            AppTextField(
                typed,
                { typed = it.filter(Char::isDigit).take(6) },
                Modifier.fillMaxWidth(),
                singleLine = true,
                suffix = total?.let { { Text("/ $it") } },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { value?.let(onSet) }),
            )
        },
    )
}
