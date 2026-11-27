package com.sumizuri.app.feature.lists

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.EditNote
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
import com.sumizuri.app.data.lists.listData
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.feature.share.ShareDialog
import com.sumizuri.app.navigation.LocalSearchSources
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_menu_more
import com.sumizuri.app.shared.resources.list_add_title
import com.sumizuri.app.shared.resources.list_delete
import com.sumizuri.app.shared.resources.list_delete_message
import com.sumizuri.app.shared.resources.list_edit
import com.sumizuri.app.shared.resources.list_empty
import com.sumizuri.app.shared.resources.list_note_edit
import com.sumizuri.app.shared.resources.list_remove_item
import com.sumizuri.app.shared.resources.list_share
import com.sumizuri.app.shared.resources.share_title
import com.sumizuri.app.shared.resources.titles_count
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.page.PageGrid
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.page.readableLine
import com.sumizuri.app.ui.kit.scroll.ReorderCell
import com.sumizuri.app.ui.kit.scroll.gridReorder
import com.sumizuri.app.ui.kit.scroll.rememberGridReorder
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The windows the page of a list can open over itself.
private sealed interface Window {
    data object None : Window
    data object Add : Window
    data object Edit : Window
    data object Delete : Window
    data object Share : Window
    data class Hold(val shown: ShownItem) : Window
    data class Note(val shown: ShownItem) : Window
}

// The page of one list: its titles as a grid of covers. A tap opens a title in the library, or looks it up by name in the sources of its kind. Holding a cover and dragging moves it, and holding it still shows its note and removal. The bar adds a title, and its menu edits or deletes the list.
@Composable
fun ListRoute(listId: Long, onBack: () -> Unit, onOpenSaved: (Long) -> Unit) {
    val container = LocalAppContainer.current
    val viewModel = viewModel(key = "list-$listId") { ListViewModel(listId, container.lists, container.library) }
    val page by viewModel.page.collectAsStateWithLifecycle()
    val search = LocalSearchSources.current
    // A list deleted while it was open closes its page.
    LaunchedEffect(page.loaded, page.list) { if (page.loaded && page.list == null) onBack() }
    val list = page.list ?: return
    var window by remember { mutableStateOf<Window>(Window.None) }
    var menu by remember { mutableStateOf(false) }
    val grid = rememberLazyGridState()
    val look = libraryGrid()
    val reorder = rememberGridReorder(page.items, { it.item.id }, grid)
    ReadableColumn(GridWidth) {
        Column(Modifier.fillMaxSize()) {
            val count = pluralStringResource(Res.plurals.titles_count, list.size, list.size)
            PageTopBar(list.name, subtitle = count, onBack = onBack, actions = {
                if (page.items.isNotEmpty()) {
                    IconButton(
                        { window = Window.Share },
                    ) { Icon(Icons.Outlined.Share, stringResource(Res.string.list_share)) }
                }
                IconButton(
                    { window = Window.Add },
                ) { Icon(Icons.Outlined.Add, stringResource(Res.string.list_add_title)) }
                Box {
                    IconButton(
                        { menu = true },
                    ) { Icon(Icons.Outlined.MoreVert, stringResource(Res.string.chapter_menu_more)) }
                    AppMenu(menu, { menu = false }) {
                        AppMenuItem(stringResource(Res.string.list_edit), Icons.Outlined.Edit, {
                            menu = false
                            window = Window.Edit
                        })
                        AppMenuItem(stringResource(Res.string.list_delete), Icons.Outlined.DeleteOutline, {
                            menu = false
                            window = Window.Delete
                        }, danger = true)
                    }
                }
            })
            if (page.items.isEmpty()) {
                Box(
                    Modifier.padding(horizontal = PageGutter, vertical = 8.dp),
                ) { EmptyCard(stringResource(Res.string.list_empty)) }
            } else {
                val open = { shown: ShownItem ->
                    shown.saved?.let { onOpenSaved(it.id) }
                        ?: search(shown.item.title, shown.item.kind)
                }
                PageGrid(
                    Modifier.weight(1f).gridReorder(
                        reorder,
                        onTap = open,
                        onHold = { window = Window.Hold(it) },
                        onReorder = { ordered -> viewModel.onMove(ordered.map { it.item.id }) },
                    ),
                    state = grid,
                    maxCell = look.cellWidth.dp,
                    gap = look.gridGap.dp,
                ) {
                    // The line about the list sits over the covers, in the width a line is read in.
                    if (list.about.isNotBlank()) {
                        readableLine("about") {
                            Text(
                                list.about,
                                Modifier.padding(bottom = 6.dp),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                    items(
                        reorder.order,
                        key = { it.item.id },
                    ) { shown -> ReorderCell(reorder, shown.item.id) { ListCell(shown) { open(shown) } } }
                }
            }
        }
    }
    val close = { window = Window.None }
    when (val open = window) {
        Window.None -> Unit

        Window.Add -> AddTitlesSheet(
            listId,
            remember(page.items) { page.items.mapTo(HashSet()) { it.item.key } },
            close,
        )

        Window.Edit -> EditListDialog(list.name, list.about, { name, about ->
            viewModel.onDescribe(name, about)
            close()
        }, close)

        // A list goes out as a file of the app with its titles, kinds and notes, and never a source.
        Window.Share -> {
            val data = remember(list, page.items) { listData(list, page.items.map { it.item }) }
            ShareDialog(stringResource(Res.string.share_title, list.name), list.name, ShareKind.List, data, close)
        }

        Window.Delete -> ConfirmDialog(
            stringResource(Res.string.list_delete),
            stringResource(Res.string.list_delete_message),
            stringResource(Res.string.list_delete),
            onConfirm = {
                close()
                viewModel.onDelete()
            },
            onDismiss = close,
        )

        is Window.Hold -> AppSheet(close, spacing = 2.dp, title = open.shown.item.title) {
            PanelRow(Icons.Outlined.EditNote, stringResource(Res.string.list_note_edit), {
                window =
                    Window.Note(open.shown)
            })
            PanelRow(Icons.Outlined.DeleteOutline, stringResource(Res.string.list_remove_item), {
                viewModel.onRemove(open.shown.item.id)
                close()
            }, danger = true)
        }

        is Window.Note -> NoteDialog(open.shown.item.title, open.shown.item.note, { note ->
            viewModel.onNote(open.shown.item.id, note)
            close()
        }, close)
    }
}
