package com.sumizuri.app.feature.library.top

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Label
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material.icons.outlined.Shuffle
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.feature.library.LibraryCalls
import com.sumizuri.app.feature.library.LibraryState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_shelves
import com.sumizuri.app.shared.resources.download_title
import com.sumizuri.app.shared.resources.library_cancel_update
import com.sumizuri.app.shared.resources.library_display
import com.sumizuri.app.shared.resources.library_random
import com.sumizuri.app.shared.resources.library_search
import com.sumizuri.app.shared.resources.library_title
import com.sumizuri.app.shared.resources.library_update
import com.sumizuri.app.shared.resources.library_update_shelf
import com.sumizuri.app.shared.resources.library_updating
import com.sumizuri.app.shared.resources.titles_count
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.text.progressTimeText
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The bar over the library. The name with how many titles are shown under it, or how far the check for new chapters has got with a line along the bottom. On the right the search, the look of the grid, a stop while the check runs, the saved chapters while some are on the way, and a menu to update, to open a title by chance, to change the shelves and to see the saved chapters.
@Composable
internal fun LibraryTopBar(
    state: LibraryState,
    calls: LibraryCalls,
    searchOpen: Boolean,
    onSearch: () -> Unit,
    onDisplay: () -> Unit,
) {
    val progress = state.progress
    val subtitle = when {
        progress != null -> listOfNotNull(
            stringResource(Res.string.library_updating, progress.done, progress.total),
            progressTimeText(progress.done, progress.total),
        ).joinToString(" · ")

        state.loaded -> pluralStringResource(Res.plurals.titles_count, state.titles.size, state.titles.size)

        else -> null
    }
    PageTopBar(
        stringResource(Res.string.library_title),
        subtitle = subtitle,
        progress = progress?.let { if (it.total == 0) 0f else it.done.toFloat() / it.total },
    ) {
        if (progress !=
            null
        ) {
            IconButton(
                calls.onCancelUpdate,
            ) { Icon(Icons.Outlined.Close, stringResource(Res.string.library_cancel_update)) }
        }
        // While chapters are being saved to the device, a button with how many are left leads to them.
        val downloading by LocalAppContainer.current.downloads.active
            .collectAsStateWithLifecycle(0)
        if (downloading > 0) {
            IconButton(calls.onOpenDownloads) {
                BadgedBox(badge = {
                    Badge { Text(downloading.toString()) }
                }) { Icon(Icons.Outlined.Download, stringResource(Res.string.download_title)) }
            }
        }
        if (state.prefs.collapsibleSearch) {
            IconButton(onSearch) {
                Icon(
                    if (searchOpen) Icons.Outlined.SearchOff else Icons.Outlined.Search,
                    stringResource(Res.string.library_search),
                )
            }
        }
        IconButton(onDisplay) { Icon(Icons.Outlined.GridView, stringResource(Res.string.library_display)) }
        MoreMenu(state.prefs.category != null, progress == null, calls)
    }
}

@Composable
private fun MoreMenu(shelfOpen: Boolean, canUpdate: Boolean, calls: LibraryCalls) {
    var open by remember { mutableStateOf(false) }
    // The menu opens under the button, so the two are together in one box.
    Box {
        IconButton({ open = true }) { Icon(Icons.Outlined.MoreVert, null) }
        AppMenu(open, { open = false }) {
            AppMenuItem(
                text = {
                    Text(
                        stringResource(if (shelfOpen) Res.string.library_update_shelf else Res.string.library_update),
                    )
                },
                leadingIcon = { Icon(Icons.Outlined.Refresh, null, Modifier.size(20.dp)) },
                enabled = canUpdate,
                onClick = {
                    open = false
                    calls.onUpdate()
                },
            )
            AppMenuItem(
                text = { Text(stringResource(Res.string.library_random)) },
                leadingIcon = { Icon(Icons.Outlined.Shuffle, null, Modifier.size(20.dp)) },
                onClick = {
                    open = false
                    calls.onRandom()
                },
            )
            AppMenuItem(
                text = { Text(stringResource(Res.string.display_shelves)) },
                leadingIcon = { Icon(Icons.AutoMirrored.Outlined.Label, null, Modifier.size(20.dp)) },
                onClick = {
                    open = false
                    calls.onOpenShelves()
                },
            )
            AppMenuItem(
                text = { Text(stringResource(Res.string.download_title)) },
                leadingIcon = { Icon(Icons.Outlined.Download, null, Modifier.size(20.dp)) },
                onClick = {
                    open = false
                    calls.onOpenDownloads()
                },
            )
        }
    }
}
