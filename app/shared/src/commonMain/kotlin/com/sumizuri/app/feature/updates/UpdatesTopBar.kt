package com.sumizuri.app.feature.updates

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.Event
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.library_cancel_update
import com.sumizuri.app.shared.resources.library_display
import com.sumizuri.app.shared.resources.library_update
import com.sumizuri.app.shared.resources.library_updating
import com.sumizuri.app.shared.resources.selection_mark_read
import com.sumizuri.app.shared.resources.updates_new_count
import com.sumizuri.app.shared.resources.updates_title
import com.sumizuri.app.shared.resources.updates_upcoming
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.text.progressTimeText
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The bar over the updates: the name with how many new chapters wait, or how far the check has got with a line along the bottom. On the right the buttons to mark all read, to check the library or stop the check, and to set how the page looks.
@Composable
internal fun UpdatesTopBar(
    state: UpdatesState,
    // Left out when what comes next is already shown beside the list.
    onUpcoming: (() -> Unit)?,
    onMarkAll: () -> Unit,
    onUpdate: () -> Unit,
    onCancelUpdate: () -> Unit,
    onDisplay: () -> Unit,
) {
    val progress = state.progress
    // The chapters are counted, not the rows, since a row holds all the chapters of a title that came the same day. With nothing narrowed it is the full count, as the badge on the tab has it, since the page lists only the newest.
    val listed = state.items.sumOf { it.count }
    val chapters = if (state.kind == null && state.shelf == null) maxOf(listed, state.total) else listed
    val subtitle = when {
        progress != null -> listOfNotNull(
            stringResource(Res.string.library_updating, progress.done, progress.total),
            progressTimeText(progress.done, progress.total),
        ).joinToString(" · ")

        state.loaded -> pluralStringResource(Res.plurals.updates_new_count, chapters, chapters)

        else -> null
    }
    PageTopBar(
        stringResource(Res.string.updates_title),
        subtitle = subtitle,
        progress = progress?.let { if (it.total == 0) 0f else it.done.toFloat() / it.total },
    ) {
        if (onUpcoming !=
            null
        ) {
            IconButton(onUpcoming) { Icon(Icons.Outlined.Event, stringResource(Res.string.updates_upcoming)) }
        }
        IconButton(onMarkAll, enabled = state.items.isNotEmpty()) {
            Icon(Icons.Outlined.DoneAll, stringResource(Res.string.selection_mark_read))
        }
        if (progress != null) {
            IconButton(onCancelUpdate) { Icon(Icons.Outlined.Close, stringResource(Res.string.library_cancel_update)) }
        } else {
            IconButton(onUpdate) { Icon(Icons.Outlined.Refresh, stringResource(Res.string.library_update)) }
        }
        IconButton(onDisplay) { Icon(Icons.Outlined.GridView, stringResource(Res.string.library_display)) }
    }
}
