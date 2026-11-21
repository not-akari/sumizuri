package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.db.tracker.LibraryTitle
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_left_out_hint
import com.sumizuri.app.shared.resources.tracker_not_found_hint
import com.sumizuri.app.shared.resources.tracker_not_found_line
import com.sumizuri.app.shared.resources.tracker_take_back
import com.sumizuri.app.shared.resources.tracker_titles_empty
import com.sumizuri.app.shared.resources.tracker_tools_none
import com.sumizuri.app.shared.resources.tracker_track_hint
import com.sumizuri.app.shared.resources.tracker_unlinked_empty
import com.sumizuri.app.shared.resources.trackers_title
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.badge.PickBadge
import com.sumizuri.app.ui.kit.sync.ListStep
import com.sumizuri.app.ui.kit.sync.MoreRows
import com.sumizuri.app.ui.kit.text.NoteText
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// How wide a cover of the grid is at least, so a phone shows three in a row and a wide window more, at a size that still reads.
private val CellWidth = 120.dp

// A title the sheet is open for.
private class Opened(val titleId: Long, val name: String, val kind: Kind)

// One title of a grid: its cover, its name, a short line under it, what a tap and a long press do, whether it is picked, and a button under it when it has one.
internal class GridItem(
    val key: Any,
    val name: String,
    val kind: Kind,
    val cover: String?,
    val line: String,
    val alert: Boolean = false,
    val onClick: (() -> Unit)? = null,
    val action: Pair<String, () -> Unit>? = null,
    val onLongClick: (() -> Unit)? = null,
    val picked: Boolean? = null,
)

// Titles as a grid of covers that fills the width, a set at a time so a big library stays quick to draw. Only the shown titles are made into cells.
@Composable
internal fun <T> TitleGrid(items: List<T>, key: Any, cell: @Composable (T) -> GridItem) {
    var shown by rememberSaveable(key) { mutableIntStateOf(ListStep) }
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val columns = (maxWidth / CellWidth).toInt().coerceAtLeast(2)
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            for (row in items.take(shown).chunked(columns)) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    for (item in row) GridCell(cell(item), Modifier.weight(1f))
                    repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
            if (items.size > shown) MoreRows(items.size - shown) { shown += ListStep }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun GridCell(item: GridItem, modifier: Modifier) {
    // Made once for its name and cover, so the grid does not make it again at each change.
    val shownTitle = remember(item.key, item.cover) {
        Title(
            id = (item.key as? Long) ?: item.key.hashCode().toLong(),
            name = item.name,
            kind = item.kind,
            coverUrl = item.cover,
            unread = 0,
            status = Status.Unknown,
            summary = "",
            inLibrary = false,
        )
    }
    val colors = MaterialTheme.colorScheme
    val tap = if (item.onClick != null || item.onLongClick != null) {
        Modifier.combinedClickable(onLongClick = item.onLongClick, onClick = item.onClick ?: {})
    } else {
        Modifier
    }
    Column(
        modifier.clip(MaterialTheme.shapes.medium).then(tap),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        // While titles are picked each cover has the ring of the library, filled for the picked ones, which are dimmed.
        Box {
            CoverArt(shownTitle, Modifier.fillMaxWidth().alpha(if (item.picked == true) 0.55f else 1f), letterSize = 26)
            item.picked?.let { PickBadge(it, Modifier.align(Alignment.TopStart).padding(6.dp)) }
        }
        Text(
            item.name,
            Modifier.padding(horizontal = 2.dp),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            item.line,
            Modifier.padding(horizontal = 2.dp),
            style = MaterialTheme.typography.labelSmall,
            color = if (item.alert) colors.error else colors.outline,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        item.action?.let { (label, act) ->
            TextButton(act, enabled = item.picked == null) { Text(label, style = MaterialTheme.typography.labelMedium) }
        }
    }
}

// What a cell does in a list that picks: a long press picks it, and while some are picked a tap does too.
private class Pickable(val tap: () -> Unit, val press: () -> Unit, val picked: Boolean?)

private fun pickable(id: Long, picking: Picking, onOpen: () -> Unit) = Pickable(
    { if (picking.on) picking.toggle(id) else onOpen() },
    { picking.toggle(id) },
    if (picking.on) id in picking.ids else null,
)

// Linked titles with how each stands on the tracker, a tap opening the sheet that changes it. Titles removed on the tracker use the same grid.
@Composable
internal fun LinkedTitles(
    tracker: TrackerId,
    account: TrackerAccount,
    links: List<TrackerLinkEntity>,
    key: Any,
    picking: Picking,
    narrowed: Boolean,
) {
    var open by remember { mutableStateOf<Opened?>(null) }
    if (links.isEmpty()) {
        NoteText(
            if (narrowed) {
                stringResource(Res.string.tracker_tools_none)
            } else {
                stringResource(Res.string.tracker_titles_empty, stringResource(Res.string.trackers_title))
            },
        )
    }
    TitleGrid(links, key) { link ->
        val kind = Kind.fromCode(link.kind)
        val pick = pickable(link.titleId, picking) { open = Opened(link.titleId, link.remoteName, kind) }
        GridItem(
            link.titleId,
            link.remoteName,
            kind,
            link.remoteCover,
            linkLine(link, tracker, account.scoreFormat),
            alert = link.gone,
            onClick = pick.tap,
            onLongClick = pick.press,
            picked = pick.picked,
        )
    }
    open?.let { TrackSheet(tracker, it.titleId, it.name, it.kind) { open = null } }
}

// Titles of the library with no link yet, a tap opening the search for one. Those a search found nothing for say so in red.
@Composable
internal fun UnlinkedTitles(tracker: TrackerId, titles: List<LibraryTitle>, notFound: Boolean, picking: Picking) {
    var open by remember { mutableStateOf<Opened?>(null) }
    if (notFound) {
        NoteText(stringResource(Res.string.tracker_not_found_hint, tracker.label))
    } else if (titles.isEmpty()) {
        NoteText(stringResource(Res.string.tracker_unlinked_empty, tracker.label))
    }
    val hint =
        stringResource(
            if (notFound) Res.string.tracker_not_found_line else Res.string.tracker_track_hint,
            tracker.label,
        )
    TitleGrid(titles, if (notFound) "not found" else "unlinked") { title ->
        val kind = Kind.fromCode(title.kind)
        val pick = pickable(title.id, picking) { open = Opened(title.id, title.name, kind) }
        GridItem(
            title.id,
            title.name,
            kind,
            title.coverUrl,
            hint,
            alert = notFound,
            onClick = pick.tap,
            onLongClick = pick.press,
            picked = pick.picked,
        )
    }
    open?.let { TrackSheet(tracker, it.titleId, it.name, it.kind) { open = null } }
}

// Titles left out of the tracker by hand, each of which can be tracked again.
@Composable
internal fun LeftOutTitles(tracker: TrackerId, titles: List<LibraryTitle>, picking: Picking) {
    val use = LocalAppContainer.current.trackerSync.use
    val scope = rememberCoroutineScope()
    NoteText(stringResource(Res.string.tracker_left_out_hint, tracker.label))
    val again = stringResource(Res.string.tracker_take_back)
    TitleGrid(titles, "left out") { title ->
        val kind = Kind.fromCode(title.kind)
        val pick = pickable(title.id, picking) {}
        GridItem(
            title.id,
            title.name,
            kind,
            title.coverUrl,
            stringResource(kind.label),
            onClick = pick.tap,
            action = again to { scope.launch { use.takeBack(tracker, title.id) } },
            onLongClick = pick.press,
            picked = pick.picked,
        )
    }
}
