package com.sumizuri.app.feature.lists

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.lists.ListNameLimit
import com.sumizuri.app.data.lists.ListTitle
import com.sumizuri.app.data.lists.MakeResult
import com.sumizuri.app.data.lists.cleanLine
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.list_add_to
import com.sumizuri.app.shared.resources.list_make
import com.sumizuri.app.shared.resources.lists_find_or_new
import com.sumizuri.app.shared.resources.lists_new
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.AppSheet
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.stringResource

// Puts titles, given by name and kind, on lists in a panel in the look of the reading mode panel. A list that holds every title is lit with a tick and one that holds some has a dash, and a tap puts them all on or takes them all off at once. The field at the top finds a list by its name, and makes one with that name when none has it. The titles are worked out away from the screen, so thousands of picked titles do not stall it.
@Composable
fun AddToListDialog(picked: List<Pair<String, Kind>>, onDismiss: () -> Unit) {
    val container = LocalAppContainer.current
    val repo = container.lists
    // Each list comes with the cover of its first title, matched to the library away from the screen.
    val faces by remember(repo, container.library) {
        val match = LibraryMatch()
        combine(repo.lists, repo.fronts, container.library.library) { lists, fronts, library ->
            val saved = match.byKey(library)
            lists.map { list -> ListFace(list, fronts[list.id].orEmpty().take(1).map { it.coverTitle(saved[it.key]) }) }
        }.flowOn(Dispatchers.Default)
    }.collectAsStateWithLifecycle(null)
    val titles by produceState<List<ListTitle>?>(null, picked) {
        value = withContext(Dispatchers.Default) { picked.map { ListTitle(it.first, it.second) } }
    }
    val ready = titles
    val holding by remember(repo, ready) {
        if (ready == null) flowOf(emptyMap()) else repo.holding(ready.map { it.key })
    }.collectAsStateWithLifecycle(emptyMap())
    val keys = remember(ready) { ready?.map { it.key }?.distinct()?.size ?: 0 }
    val scope = rememberCoroutineScope()
    var text by rememberSaveable { mutableStateOf("") }
    var notice by remember { mutableStateOf<ListNotice?>(null) }
    AppSheet(onDismiss, spacing = 2.dp, title = stringResource(Res.string.list_add_to)) {
        val all = faces?.map { it.list } ?: return@AppSheet
        if (ready == null) return@AppSheet
        val covers = faces.orEmpty().associate { it.list.id to it.covers.firstOrNull() }
        AppSearchBar(
            text,
            {
                text = it.take(ListNameLimit)
                notice = null
            },
            stringResource(if (all.isEmpty()) Res.string.lists_new else Res.string.lists_find_or_new),
            Modifier.padding(bottom = 6.dp),
        )
        NoticeLine(notice)
        val wanted = cleanLine(text, ListNameLimit)
        val shown = if (wanted.isEmpty()) all else all.filter { it.name.contains(wanted, ignoreCase = true) }
        if (wanted.isNotEmpty() && all.none { it.name.equals(wanted, ignoreCase = true) }) {
            PanelRow(Icons.Outlined.Add, stringResource(Res.string.list_make, wanted), onClick = {
                scope.launch {
                    when (val made = repo.create(wanted)) {
                        is MakeResult.Made -> {
                            notice = repo.add(made.id, ready).notice()
                            text = ""
                        }

                        else -> notice = made.notice()
                    }
                }
            })
        }
        for (list in shown) {
            val count = holding[list.id] ?: 0
            val every = keys > 0 && count >= keys
            PanelRow(
                Icons.AutoMirrored.Outlined.FormatListBulleted,
                list.name,
                onClick = { scope.launch { notice = repo.toggle(list.id, ready, on = !every).notice() } },
                lit = every,
                leading = { RowCover(covers[list.id]) },
                end = {
                    when {
                        every -> Icon(Icons.Outlined.Check, null, tint = MaterialTheme.colorScheme.primary)
                        count > 0 -> Icon(Icons.Outlined.Remove, null, tint = MaterialTheme.colorScheme.primary)
                    }
                },
            )
        }
    }
}
