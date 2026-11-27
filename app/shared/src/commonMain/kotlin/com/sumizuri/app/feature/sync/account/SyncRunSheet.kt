package com.sumizuri.app.feature.sync.account

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.automirrored.outlined.Label
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material.icons.outlined.LibraryAdd
import androidx.compose.material.icons.outlined.RemoveCircleOutline
import androidx.compose.material.icons.outlined.RemoveDone
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.account.SyncChanges
import com.sumizuri.app.data.account.SyncLogEntry
import com.sumizuri.app.data.account.SyncWhy
import com.sumizuri.app.data.account.TitleChange
import com.sumizuri.app.data.account.durationText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_change_added
import com.sumizuri.app.shared.resources.sync_change_bookmarks
import com.sumizuri.app.shared.resources.sync_change_favorite
import com.sumizuri.app.shared.resources.sync_change_off
import com.sumizuri.app.shared.resources.sync_change_on
import com.sumizuri.app.shared.resources.sync_change_places
import com.sumizuri.app.shared.resources.sync_change_read
import com.sumizuri.app.shared.resources.sync_change_removed
import com.sumizuri.app.shared.resources.sync_change_unfavorite
import com.sumizuri.app.shared.resources.sync_change_unread
import com.sumizuri.app.shared.resources.sync_fig_fetched
import com.sumizuri.app.shared.resources.sync_fig_in
import com.sumizuri.app.shared.resources.sync_fig_out
import com.sumizuri.app.shared.resources.sync_fig_sent
import com.sumizuri.app.shared.resources.sync_history_kept
import com.sumizuri.app.shared.resources.sync_history_sent
import com.sumizuri.app.shared.resources.sync_run_conflicts_title
import com.sumizuri.app.shared.resources.sync_run_here
import com.sumizuri.app.shared.resources.sync_run_lists
import com.sumizuri.app.shared.resources.sync_run_more
import com.sumizuri.app.shared.resources.sync_run_nothing
import com.sumizuri.app.shared.resources.sync_run_repeated
import com.sumizuri.app.shared.resources.sync_run_settings
import com.sumizuri.app.shared.resources.sync_run_sources
import com.sumizuri.app.shared.resources.sync_run_there
import com.sumizuri.app.shared.resources.sync_why_after_reading
import com.sumizuri.app.shared.resources.sync_why_asked
import com.sumizuri.app.shared.resources.sync_why_background
import com.sumizuri.app.shared.resources.sync_why_from_scratch
import com.sumizuri.app.shared.resources.sync_why_opened
import com.sumizuri.app.shared.resources.sync_why_other_device
import com.sumizuri.app.shared.resources.sync_why_timer
import com.sumizuri.app.shared.resources.sync_why_unknown
import com.sumizuri.app.ui.kit.art.Notice
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.text.Figure
import com.sumizuri.app.ui.kit.text.FigureSize
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.byteSizeText
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// What started a sync, in words.
@Composable
internal fun whyText(why: SyncWhy): String = stringResource(
    when (why) {
        SyncWhy.Asked -> Res.string.sync_why_asked
        SyncWhy.Opened -> Res.string.sync_why_opened
        SyncWhy.Timer -> Res.string.sync_why_timer
        SyncWhy.AfterReading -> Res.string.sync_why_after_reading
        SyncWhy.OtherDevice -> Res.string.sync_why_other_device
        SyncWhy.Background -> Res.string.sync_why_background
        SyncWhy.FromScratch -> Res.string.sync_why_from_scratch
        SyncWhy.Unknown -> Res.string.sync_why_unknown
    },
)

// One sync in full, in the look of a panel: what started it with when and how long, four figures for what came in and went out, then a row for each title it changed on this device and sent to the server with an icon for its main change, the counts of settings, sources and lists, and the conflicts it settled. A failure says why, how often and its code.
@Composable
internal fun SyncRunSheet(entry: SyncLogEntry, onDismiss: () -> Unit) {
    AppSheet(onDismiss, spacing = 4.dp, title = if (entry.ok) runTitle(entry) else whyText(entry.why)) {
        Text(
            runWhen(entry),
            Modifier.padding(start = 6.dp, bottom = 6.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (!entry.ok) {
            Notice(
                entry.message,
                icon = Icons.Outlined.ErrorOutline,
                tint = MaterialTheme.colorScheme.error,
                fill = MaterialTheme.colorScheme.error.copy(alpha = 0.12f),
            )
            if (entry.code.isNotEmpty()) Quiet(entry.code)
            return@AppSheet
        }
        if (entry.why != SyncWhy.Unknown) Figures(entry)
        Changes(stringResource(Res.string.sync_run_here), entry.here)
        Changes(stringResource(Res.string.sync_run_there), entry.there)
        if (entry.conflicts.isNotEmpty()) {
            Heading(stringResource(Res.string.sync_run_conflicts_title))
            for (conflict in entry.conflicts) {
                ChangeRow(
                    Icons.Outlined.WarningAmber,
                    conflict.name,
                    conflictLine(
                        conflict,
                    ).removePrefix(conflict.name + ": ").replaceFirstChar {
                        it.uppercase()
                    },
                )
            }
        }
    }
}

// What came in and went out and the data each way, as four figures in a row.
@Composable
private fun Figures(entry: SyncLogEntry) {
    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalArrangement = Arrangement.SpaceEvenly) {
        Figure(
            (entry.here.titleCount + entry.here.lists).toString(),
            stringResource(Res.string.sync_fig_in),
            size = FigureSize.Small,
        )
        Figure(
            (entry.there.titleCount + entry.there.lists).toString(),
            stringResource(Res.string.sync_fig_out),
            size = FigureSize.Small,
        )
        Figure(byteSizeText(entry.fetchedBytes), stringResource(Res.string.sync_fig_fetched), size = FigureSize.Small)
        Figure(byteSizeText(entry.bytes), stringResource(Res.string.sync_fig_sent), size = FigureSize.Small)
    }
}

// The changes of one side, as a heading with a row for each title and the counts of settings, sources and lists.
@Composable
private fun Changes(title: String, changes: SyncChanges) {
    if (changes.empty) return
    Heading(title)
    for (change in changes.titles) {
        ChangeRow(
            changeIcon(change),
            change.name,
            changeText(change).replaceFirstChar {
                it.uppercase()
            },
        )
    }
    val more = changes.titleCount - changes.titles.size
    if (more > 0) Quiet(stringResource(Res.string.sync_run_more, more))
    if (changes.settings > 0) {
        ChangeRow(
            Icons.Outlined.Tune,
            pluralStringResource(Res.plurals.sync_run_settings, changes.settings, changes.settings),
            null,
        )
    }
    if (changes.sources > 0) {
        ChangeRow(
            Icons.Outlined.Extension,
            pluralStringResource(Res.plurals.sync_run_sources, changes.sources, changes.sources),
            null,
        )
    }
    if (changes.lists > 0) {
        ChangeRow(
            Icons.AutoMirrored.Outlined.FormatListBulleted,
            pluralStringResource(Res.plurals.sync_run_lists, changes.lists, changes.lists),
            null,
        )
    }
}

// The icon of the main change of a title: added, taken out, read, unread, a favorite, shelves, bookmarks or the reading place.
private fun changeIcon(change: TitleChange): ImageVector = when {
    change.added -> Icons.Outlined.LibraryAdd
    change.removed -> Icons.Outlined.RemoveCircleOutline
    change.read > 0 -> Icons.Outlined.DoneAll
    change.unread > 0 -> Icons.Outlined.RemoveDone
    change.favorite == true -> Icons.Outlined.Star
    change.favorite == false -> Icons.Outlined.StarBorder
    change.shelvesIn.isNotEmpty() || change.shelvesOut.isNotEmpty() -> Icons.AutoMirrored.Outlined.Label
    change.bookmarks != 0 -> Icons.Outlined.BookmarkBorder
    else -> Icons.AutoMirrored.Outlined.MenuBook
}

// One changed thing: an icon on a round tile, its name, and what changed under it.
@Composable
private fun ChangeRow(icon: ImageVector, title: String, detail: String?) {
    val colors = MaterialTheme.colorScheme
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(
            Modifier.size(36.dp).background(colors.surfaceContainerHighest, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, null, Modifier.size(18.dp), tint = colors.primary)
        }
        Column(Modifier.weight(1f)) {
            Text(
                title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (!detail.isNullOrEmpty()) {
                Text(
                    detail,
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.onSurfaceVariant,
                )
            }
        }
    }
}

// What changed for one title, in words.
@Composable
private fun changeText(change: TitleChange): String = buildList {
    if (change.added) add(stringResource(Res.string.sync_change_added))
    if (change.removed) add(stringResource(Res.string.sync_change_removed))
    change.favorite?.let {
        add(stringResource(if (it) Res.string.sync_change_favorite else Res.string.sync_change_unfavorite))
    }
    if (change.read > 0) add(pluralStringResource(Res.plurals.sync_change_read, change.read, change.read))
    if (change.unread > 0) add(pluralStringResource(Res.plurals.sync_change_unread, change.unread, change.unread))
    if (change.bookmarks != 0) {
        val count = kotlin.math.abs(change.bookmarks)
        add(pluralStringResource(Res.plurals.sync_change_bookmarks, count, count))
    }
    if (change.places > 0) add(pluralStringResource(Res.plurals.sync_change_places, change.places, change.places))
    if (change.shelvesIn.isNotEmpty()) add(stringResource(Res.string.sync_change_on, change.shelvesIn.joinToString()))
    if (change.shelvesOut.isNotEmpty()) {
        add(
            stringResource(Res.string.sync_change_off, change.shelvesOut.joinToString()),
        )
    }
}.joinToString(", ")

@Composable
private fun Heading(text: String) {
    Text(
        text,
        Modifier.padding(start = 6.dp, top = 14.dp, bottom = 2.dp),
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
    )
}

@Composable
private fun Quiet(text: String) {
    Text(
        text,
        Modifier.padding(horizontal = 6.dp, vertical = 4.dp),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}
