package com.sumizuri.app.feature.lists

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Check
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.lists.ListTitle
import com.sumizuri.app.data.lists.TitleNameLimit
import com.sumizuri.app.data.lists.cleanLine
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.list_add_hint
import com.sumizuri.app.shared.resources.list_add_name
import com.sumizuri.app.shared.resources.list_add_search
import com.sumizuri.app.shared.resources.list_add_titles
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.AppSheet
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// How many titles of the library the search shows at once.
private const val Matches = 30

// Puts titles on a list in a panel, in the look of the panel that puts titles on lists. The search finds titles in the library by name, each with its cover, and a tap puts one on the list or takes it off at once. A name that is not in the library can be put on by itself, as the kind picked under the search.
@Composable
internal fun AddTitlesSheet(listId: Long, onList: Set<String>, onDismiss: () -> Unit) {
    val container = LocalAppContainer.current
    val repo = container.lists
    val library by remember(container) { container.library.library }.collectAsStateWithLifecycle(emptyList())
    val scope = rememberCoroutineScope()
    var query by rememberSaveable { mutableStateOf("") }
    var kind by rememberSaveable { mutableStateOf(Kind.Manga) }
    var notice by remember { mutableStateOf<ListNotice?>(null) }
    val wanted = cleanLine(query, TitleNameLimit)
    val found = remember(library, wanted) {
        if (wanted.isEmpty()) {
            emptyList()
        } else {
            library
                .filter {
                    it.name.contains(
                        wanted,
                        ignoreCase = true,
                    )
                }.take(Matches)
        }
    }

    fun toggle(title: ListTitle, on: Boolean) {
        scope.launch { notice = repo.toggle(listId, listOf(title), on).notice() }
    }
    AppSheet(onDismiss, spacing = 2.dp, title = stringResource(Res.string.list_add_titles)) {
        AppSearchBar(
            query,
            {
                query = it
                notice = null
            },
            stringResource(Res.string.list_add_search),
            Modifier.padding(bottom = 6.dp),
        )
        NoticeLine(notice)
        if (wanted.isEmpty()) {
            Text(
                stringResource(Res.string.list_add_hint),
                Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            return@AppSheet
        }
        for (title in found) {
            val listed = remember(title.name, title.kind) { ListTitle(title.name, title.kind) }
            val on = listed.key in onList
            PanelRow(
                Icons.Outlined.Add,
                title.name,
                onClick = { toggle(listed, !on) },
                lit = on,
                leading = { RowCover(title) },
                end = { if (on) Icon(Icons.Outlined.Check, null, tint = MaterialTheme.colorScheme.primary) },
            )
        }
        // Any name can go on, for a title that is not in the library, unless the library already showed it.
        val typed = ListTitle(wanted, kind)
        if (found.none { it.kind == kind && ListTitle(it.name, it.kind).key == typed.key }) {
            Column(Modifier.padding(top = 8.dp)) {
                ChipRow(Modifier.padding(horizontal = 6.dp, vertical = 4.dp)) {
                    for (each in Kind.entries) ChoiceChip(stringResource(each.label), kind == each) { kind = each }
                }
                val on = typed.key in onList
                PanelRow(
                    Icons.Outlined.Add,
                    stringResource(Res.string.list_add_name, typed.name, stringResource(kind.label)),
                    onClick = { toggle(typed, !on) },
                    lit = on,
                    end = { if (on) Icon(Icons.Outlined.Check, null, tint = MaterialTheme.colorScheme.primary) },
                )
            }
        }
    }
}

// The small cover in front of a row of a panel, or the icon of a list while it has no titles.
@Composable
internal fun RowCover(title: Title?) {
    Box(Modifier.width(28.dp), contentAlignment = Alignment.Center) {
        if (title != null) {
            CoverArt(title, Modifier.width(28.dp), letterSize = 12)
        } else {
            Icon(
                Icons.AutoMirrored.Outlined.FormatListBulleted,
                null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
