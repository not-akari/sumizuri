package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.db.tracker.LibraryTitle
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.OnTracker
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.data.tracker.TrackerProblem
import com.sumizuri.app.navigation.LocalSearchSources
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_delete
import com.sumizuri.app.shared.resources.tracker_delete_title
import com.sumizuri.app.shared.resources.tracker_on_find_hint
import com.sumizuri.app.shared.resources.tracker_on_find_none
import com.sumizuri.app.shared.resources.tracker_on_find_title
import com.sumizuri.app.shared.resources.tracker_on_link_hint
import com.sumizuri.app.shared.resources.tracker_on_link_title
import com.sumizuri.app.shared.resources.tracker_on_open_hint
import com.sumizuri.app.shared.resources.tracker_on_pick_none
import com.sumizuri.app.shared.resources.tracker_on_pick_search
import com.sumizuri.app.shared.resources.tracker_on_remove_hint
import com.sumizuri.app.shared.resources.tracker_on_remove_message
import com.sumizuri.app.shared.resources.tracker_open
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.sync.CoverRow
import com.sumizuri.app.ui.kit.text.NoteText
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The most titles of the library the picker shows at once, the best matches first.
private const val PickShown = 40

// What can be done with an entry on the list of the tracker that no title here is linked to: find it in the sources, link it to a title of the library, open it on the site, or remove it there. onDone is called when the entry is linked or removed, so the list can let it go.
@Composable
internal fun OnTrackerSheet(tracker: TrackerId, item: OnTracker, onDone: () -> Unit, onDismiss: () -> Unit) {
    val sync = LocalAppContainer.current.trackerSync
    val search = LocalSearchSources.current
    val openSite = LocalOpenSite.current
    val scope = rememberCoroutineScope()
    var picking by remember { mutableStateOf(false) }
    var removing by remember { mutableStateOf(false) }
    var problem by remember { mutableStateOf<TrackerProblem?>(null) }
    val sources = LocalAppContainer.current.sources
    // The kinds some source that is on can search, or null while they are read.
    val searchable by remember(sources) {
        sources.installed.map { list -> list.filter { it.enabled }.map { it.kind }.toSet() }
    }.collectAsStateWithLifecycle(null)
    val canSearch = searchable?.contains(item.kind) != false

    // Runs one step against the tracker, and keeps the sheet open with the reason when it fails.
    fun work(step: suspend () -> Unit) {
        problem = null
        scope.launch {
            try {
                step()
                onDone()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                problem = TrackerProblem.from(error)
            }
        }
    }
    AppSheet(onDismiss, title = tracker.label) {
        SettingsSection { row { CoverRow(item.media.name, item.kind, item.media.cover, entryLine(item)) } }
        if (picking) {
            LibraryPicker(
                tracker,
                item,
            ) { title -> work { sync.linkEntry(tracker, title.id, Kind.fromCode(title.kind), item) } }
        } else {
            SettingsSection {
                row {
                    SettingRow(
                        stringResource(Res.string.tracker_on_find_title),
                        subtitle = if (canSearch) {
                            stringResource(Res.string.tracker_on_find_hint)
                        } else {
                            stringResource(Res.string.tracker_on_find_none, stringResource(item.kind.label))
                        },
                        leading = { SettingIcon(Icons.Outlined.Search) },
                        onClick = if (canSearch) {
                            {
                                onDismiss()
                                search(item.media.name, item.kind)
                            }
                        } else {
                            null
                        },
                    )
                }
                row {
                    SettingRow(
                        stringResource(Res.string.tracker_on_link_title),
                        subtitle = stringResource(Res.string.tracker_on_link_hint, tracker.label),
                        leading = { SettingIcon(Icons.Outlined.Link) },
                        onClick = { picking = true },
                    )
                }
                item.media.url?.let { address ->
                    row {
                        SettingRow(
                            stringResource(Res.string.tracker_open, tracker.label),
                            subtitle = stringResource(Res.string.tracker_on_open_hint),
                            leading = { SettingIcon(Icons.AutoMirrored.Outlined.OpenInNew) },
                            onClick = { openSite(address) },
                        )
                    }
                }
                row {
                    SettingRow(
                        stringResource(Res.string.tracker_delete, tracker.label),
                        subtitle = stringResource(Res.string.tracker_on_remove_hint),
                        leading = { SettingIcon(Icons.Outlined.DeleteOutline) },
                        onClick = { removing = true },
                    )
                }
            }
        }
        problem?.let {
            ProblemLine(it, tracker)
        }
    }
    if (removing) {
        ConfirmDialog(
            stringResource(Res.string.tracker_delete_title, tracker.label),
            stringResource(Res.string.tracker_on_remove_message, tracker.label),
            stringResource(Res.string.tracker_delete, tracker.label),
            onConfirm = {
                removing = false
                work { sync.removeOn(tracker, item.entry) }
            },
            onDismiss = { removing = false },
        )
    }
}

// The titles of the library with no link to the tracker, of the same kind as the entry, the ones whose names come closest first, with a box to narrow them.
@Composable
private fun LibraryPicker(tracker: TrackerId, item: OnTracker, onPick: (LibraryTitle) -> Unit) {
    val linker = LocalAppContainer.current.trackerSync.linker
    val titles by remember(linker, tracker) { linker.unlinked(tracker) }.collectAsStateWithLifecycle(emptyList())
    var query by remember { mutableStateOf("") }
    // Worked out again only when the titles or the search change, not at each redraw.
    val fits = remember(titles, query, item) {
        val video = item.kind == Kind.Anime
        val names = (listOf(item.media.name) + item.media.names + item.media.synonyms).map { it.lowercase() }
        titles
            .filter { (Kind.fromCode(it.kind) == Kind.Anime) == video }
            .filter { query.isBlank() || it.name.contains(query.trim(), ignoreCase = true) }
            .sortedByDescending { title -> closeness(title.name.lowercase(), names) }
            .take(PickShown)
    }
    AppTextField(
        query,
        { query = it },
        Modifier.fillMaxWidth(),
        label = { Text(stringResource(Res.string.tracker_on_pick_search)) },
        singleLine = true,
    )
    if (fits.isEmpty()) {
        NoteText(stringResource(Res.string.tracker_on_pick_none))
        return
    }
    SettingsSection {
        for (title in fits) {
            row {
                val kind = Kind.fromCode(title.kind)
                CoverRow(title.name, kind, title.coverUrl, stringResource(kind.label), onClick = { onPick(title) })
            }
        }
    }
}

// How close a name of the library is to the names of the entry: the same name first, then one holding the other, then by the words they share.
private fun closeness(name: String, names: List<String>): Int = names.maxOf { other ->
    when {
        name == other -> 1000

        name.contains(other) || other.contains(name) -> 500

        else -> {
            val words = other.split(' ').filter { it.length > 2 }.toSet()
            name.split(' ').count { it in words } * 10
        }
    }
}
