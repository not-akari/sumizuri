package com.sumizuri.app.feature.lists

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.lists.ListNameLimit
import com.sumizuri.app.data.lists.MakeResult
import com.sumizuri.app.data.lists.cleanLine
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.list_delete
import com.sumizuri.app.shared.resources.list_delete_message
import com.sumizuri.app.shared.resources.list_edit
import com.sumizuri.app.shared.resources.lists_empty
import com.sumizuri.app.shared.resources.lists_find
import com.sumizuri.app.shared.resources.lists_hint
import com.sumizuri.app.shared.resources.lists_new
import com.sumizuri.app.shared.resources.lists_title
import com.sumizuri.app.shared.resources.shelves_add
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.page.PageGrid
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.page.readableLine
import com.sumizuri.app.ui.kit.scroll.ReorderCell
import com.sumizuri.app.ui.kit.scroll.gridReorder
import com.sumizuri.app.ui.kit.scroll.rememberGridReorder
import com.sumizuri.app.ui.motion.entrance
import org.jetbrains.compose.resources.stringResource

// The windows the page of the lists can open over itself.
private sealed interface ListsWindow {
    data object None : ListsWindow
    data object New : ListsWindow
    data class Hold(val face: ListFace) : ListsWindow
    data class Edit(val face: ListFace) : ListsWindow
    data class Delete(val face: ListFace) : ListsWindow
}

// The widest the grid grows before it is centered, as on the other grids.
internal val GridWidth = 1100.dp

// The page of the lists as a grid of cover stacks, like the library. The search finds a list by name, and the bar makes a new one. A tap opens a list, holding one and dragging moves it, and holding it still offers to edit or delete it.
@Composable
fun ListsRoute(onBack: () -> Unit, onOpen: (Long) -> Unit) {
    val container = LocalAppContainer.current
    val viewModel = viewModel { ListsViewModel(container.lists, container.library) }
    val faces by viewModel.faces.collectAsStateWithLifecycle()
    var query by rememberSaveable { mutableStateOf("") }
    var window by remember { mutableStateOf<ListsWindow>(ListsWindow.None) }
    var newNotice by remember { mutableStateOf<ListNotice?>(null) }
    val all = faces.orEmpty()
    val wanted = cleanLine(query, ListNameLimit)
    val shown = if (wanted.isEmpty()) all else all.filter { it.list.name.contains(wanted, ignoreCase = true) }
    val grid = rememberLazyGridState()
    val look = libraryGrid()
    val reorder = rememberGridReorder(shown, { it.list.id }, grid)
    ReadableColumn(GridWidth) {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(
                stringResource(
                    Res.string.lists_title,
                ),
                subtitle = stringResource(Res.string.lists_hint),
                onBack = onBack,
                actions = {
                    IconButton(
                        { window = ListsWindow.New },
                    ) { Icon(Icons.Outlined.Add, stringResource(Res.string.lists_new)) }
                },
            )
            if (faces != null && all.isEmpty()) {
                Box(
                    Modifier.padding(horizontal = PageGutter, vertical = 8.dp),
                ) { EmptyCard(stringResource(Res.string.lists_empty)) }
            }
            if (all.isNotEmpty()) {
                PageGrid(
                    Modifier.weight(1f).gridReorder(
                        reorder,
                        onTap = { onOpen(it.list.id) },
                        onHold = { window = ListsWindow.Hold(it) },
                        onReorder = { ordered ->
                            viewModel.onReorder(
                                withOrder(all.map { it.list.id }, ordered.map { it.list.id }),
                            )
                        },
                    ),
                    state = grid,
                    maxCell = look.cellWidth.dp,
                    gap = look.gridGap.dp,
                ) {
                    readableLine(
                        "search",
                    ) { AppSearchBar(query, { query = it }, stringResource(Res.string.lists_find)) }
                    items(reorder.order, key = { it.list.id }) { face ->
                        ReorderCell(reorder, face.list.id) { ListStack(face) { onOpen(face.list.id) } }
                    }
                }
            }
        }
    }
    val close = { window = ListsWindow.None }
    when (val open = window) {
        ListsWindow.None -> Unit

        ListsWindow.New -> EditListDialog("", "", { name, about ->
            viewModel.onCreate(name, about) { made ->
                newNotice = made.notice()
                if (made is MakeResult.Made) close()
            }
        }, {
            newNotice = null
            close()
        }, title = Res.string.lists_new, confirm = Res.string.shelves_add, notice = newNotice)

        is ListsWindow.Hold -> AppSheet(close, spacing = 2.dp, title = open.face.list.name) {
            PanelRow(
                Icons.Outlined.Edit,
                stringResource(Res.string.list_edit),
                { window = ListsWindow.Edit(open.face) },
            )
            PanelRow(Icons.Outlined.DeleteOutline, stringResource(Res.string.list_delete), {
                window =
                    ListsWindow.Delete(open.face)
            }, danger = true)
        }

        is ListsWindow.Edit -> EditListDialog(open.face.list.name, open.face.list.about, { name, about ->
            viewModel.onDescribe(open.face.list.id, name, about)
            close()
        }, close)

        is ListsWindow.Delete -> ConfirmDialog(
            stringResource(Res.string.list_delete),
            stringResource(Res.string.list_delete_message),
            stringResource(Res.string.list_delete),
            onConfirm = {
                viewModel.onDelete(open.face.list.id)
                close()
            },
            onDismiss = close,
        )
    }
}

// The order of every list when the ones shown are put in the order given, which takes the places the shown ones had and leaves the others where they are.
private fun withOrder(all: List<Long>, shown: List<Long>): List<Long> {
    val places = shown.toMutableList()
    val here = shown.toSet()
    return all.map { if (it in here) places.removeAt(0) else it }
}

// A soft card with a line, in place of a list that has nothing in it.
@Composable
internal fun EmptyCard(text: String) {
    Row(
        Modifier
            .fillMaxWidth()
            .entrance()
            .softCard()
            .padding(horizontal = 16.dp, vertical = 18.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Icon(Icons.AutoMirrored.Outlined.FormatListBulleted, null, tint = MaterialTheme.colorScheme.primary)
        Text(text, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
