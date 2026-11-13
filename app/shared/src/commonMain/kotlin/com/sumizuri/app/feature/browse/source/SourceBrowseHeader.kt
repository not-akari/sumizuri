package com.sumizuri.app.feature.browse.source

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BookmarkAdd
import androidx.compose.material.icons.outlined.Code
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.FileOpen
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_filtered
import com.sumizuri.app.shared.resources.browse_filters
import com.sumizuri.app.shared.resources.browse_preferences
import com.sumizuri.app.shared.resources.browse_save_tab
import com.sumizuri.app.shared.resources.browse_search
import com.sumizuri.app.shared.resources.ext_edit_open_code
import com.sumizuri.app.shared.resources.listing_latest
import com.sumizuri.app.shared.resources.listing_popular
import com.sumizuri.app.shared.resources.local_add_files
import com.sumizuri.app.shared.resources.local_hint_folder_manga
import com.sumizuri.app.shared.resources.local_hint_folder_novels
import com.sumizuri.app.shared.resources.local_hint_manga
import com.sumizuri.app.shared.resources.local_hint_novels
import com.sumizuri.app.shared.resources.more
import com.sumizuri.app.shared.resources.source_remove_menu
import com.sumizuri.app.shared.resources.storage_open_folder
import com.sumizuri.app.shared.resources.title_action_web
import com.sumizuri.app.ui.kit.canOpenFolders
import com.sumizuri.app.ui.kit.chips.FilterTabs
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.kit.cover.shownName
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.input.PickedFile
import com.sumizuri.app.ui.kit.input.rememberFilesImporter
import com.sumizuri.app.ui.kit.openFolder
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableWidth
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.stringResource

// The bar of a source page: the back arrow, the icon, the name and language, the buttons for keeping a search and the filters, and a menu with the settings of the source, its code and a way to remove it.
@Composable
fun SourceBrowseTopBar(
    state: SourceBrowseState,
    style: BrowseStyle,
    onStyle: (BrowseStyle) -> Unit,
    onBack: () -> Unit,
    onSaveTab: () -> Unit,
    onFilters: () -> Unit,
    onPreferences: () -> Unit,
    onEditCode: () -> Unit,
    onImport: (List<PickedFile>) -> Unit,
    onRemove: () -> Unit,
) {
    val source = state.source
    val searching = state.tab == TabSearch && (!state.activeQuery.isNullOrBlank() || state.filtersActive)
    val openSite = LocalOpenSite.current
    PageTopBar(source.shownName(), subtitle = languageName(source.lang), onBack = onBack, leading = {
        SourceMark(source.iconUrl, size = 36.dp, sourceId = source.id)
    }) {
        // The site of the source, where a person can sign in or pass a check, which the source then uses too.
        if (source.baseUrl.isNotBlank()) {
            IconButton({
                openSite(source.baseUrl)
            }) { Icon(Icons.Outlined.Public, stringResource(Res.string.title_action_web)) }
        }
        if (searching) {
            IconButton(
                onSaveTab,
            ) { Icon(Icons.Outlined.BookmarkAdd, stringResource(Res.string.browse_save_tab)) }
        }
        if (state.hasFilters) {
            IconButton(onFilters) {
                BadgedBox(badge = {
                    if (state.filtersActive) Badge()
                }) { Icon(Icons.Outlined.Tune, stringResource(Res.string.browse_filters)) }
            }
        }
        BrowseStyleButton(style, onStyle)
        SourceMenu(state.localFolder, state.hasPreferences, onPreferences, onEditCode, onImport, onRemove)
    }
}

// The menu under the three dots, which opens under its button. A source of files on the device has a way to add files and, on a computer, to open its folder in place of its code.
@Composable
private fun SourceMenu(
    folder: String?,
    hasPreferences: Boolean,
    onPreferences: () -> Unit,
    onEditCode: () -> Unit,
    onImport: (List<PickedFile>) -> Unit,
    onRemove: () -> Unit,
) {
    var open by remember { mutableStateOf(false) }
    // A source always is or is not one of files on the device, so the picker is kept only by those that are.
    val pick = if (folder != null) rememberFilesImporter(onImport) else null
    Box {
        IconButton({ open = true }) { Icon(Icons.Outlined.MoreVert, stringResource(Res.string.more)) }
        DropdownMenu(open, { open = false }) {
            if (hasPreferences) {
                DropdownMenuItem(
                    text = { Text(stringResource(Res.string.browse_preferences)) },
                    leadingIcon = { Icon(Icons.Outlined.Settings, null, Modifier.size(20.dp)) },
                    onClick = {
                        open = false
                        onPreferences()
                    },
                )
            }
            if (folder != null && pick != null) {
                DropdownMenuItem(
                    text = { Text(stringResource(Res.string.local_add_files)) },
                    leadingIcon = { Icon(Icons.Outlined.FileOpen, null, Modifier.size(20.dp)) },
                    onClick = {
                        open = false
                        pick()
                    },
                )
                if (canOpenFolders()) {
                    DropdownMenuItem(
                        text = { Text(stringResource(Res.string.storage_open_folder)) },
                        leadingIcon = { Icon(Icons.Outlined.FolderOpen, null, Modifier.size(20.dp)) },
                        onClick = {
                            open = false
                            openFolder(folder)
                        },
                    )
                }
            } else {
                DropdownMenuItem(
                    text = { Text(stringResource(Res.string.ext_edit_open_code)) },
                    leadingIcon = { Icon(Icons.Outlined.Code, null, Modifier.size(20.dp)) },
                    onClick = {
                        open = false
                        onEditCode()
                    },
                )
                // Any source but the built in ones for files can be removed here, also one whose repo was removed.
                DropdownMenuItem(
                    text = { Text(stringResource(Res.string.source_remove_menu)) },
                    leadingIcon = { Icon(Icons.Outlined.Delete, null, Modifier.size(20.dp)) },
                    onClick = {
                        open = false
                        onRemove()
                    },
                )
            }
        }
    }
}

// The top of the covers of a source page: the search bar, then the tabs.
@Composable
fun SourceBrowseHeader(state: SourceBrowseState, actions: SourceBrowseActions, onEditTab: (String) -> Unit) {
    val source = state.source
    val tabs = buildList {
        add(TabPopular to stringResource(Res.string.listing_popular))
        add(TabLatest to stringResource(Res.string.listing_latest))
        state.catalogs.forEach { add(CatalogMark + it.id to it.name) }
        state.savedTabs.forEach { add(SavedMark + it.name to it.name) }
        // A search that is on shows as the last tab, named by what was searched for.
        if (state.tab == TabSearch || state.activeQuery != null) {
            add(TabSearch to (state.activeQuery?.let { "\"$it\"" } ?: stringResource(Res.string.browse_filtered)))
        }
    }
    Column(Modifier.widthIn(max = ReadableWidth).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        AppSearchBar(
            state.query,
            actions.onQuery,
            stringResource(Res.string.browse_search, source.shownName()),
            historyPlace = "source.${source.id}",
        )
        // A source of files on the device says which files it reads, and on a computer the folder they can also be put in. A phone keeps that folder private, so there the files are added from the menu.
        state.localFolder?.let { folder ->
            val novels = source.kind == Kind.Novel
            val how = stringResource(if (novels) Res.string.local_hint_novels else Res.string.local_hint_manga)
            Text(
                if (canOpenFolders()) {
                    how + " " +
                        stringResource(
                            if (novels) Res.string.local_hint_folder_novels else Res.string.local_hint_folder_manga,
                            folder,
                        )
                } else {
                    how
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline,
            )
        }
        FilterTabs(
            items = tabs,
            selected = state.tab,
            onSelect = actions.onTab,
            onLongPress = { tab -> if (tab.startsWith(SavedMark)) onEditTab(tab.removePrefix(SavedMark)) },
        )
    }
}
