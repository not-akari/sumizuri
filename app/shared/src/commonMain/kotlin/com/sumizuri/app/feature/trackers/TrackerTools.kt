package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.db.tracker.LibraryTitle
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.OnTracker
import com.sumizuri.app.data.tracker.TrackStatus
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_search_titles
import com.sumizuri.app.shared.resources.tracker_sort
import com.sumizuri.app.shared.resources.tracker_sort_name
import com.sumizuri.app.shared.resources.tracker_sort_progress
import com.sumizuri.app.shared.resources.tracker_sort_score
import com.sumizuri.app.shared.resources.tracker_sort_updated
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChipSeparator
import com.sumizuri.app.ui.kit.chips.KindChips
import com.sumizuri.app.ui.kit.chips.SortChip
import com.sumizuri.app.ui.kit.chips.ToggleChip
import com.sumizuri.app.ui.kit.chips.hasKindChoice
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import org.jetbrains.compose.resources.stringResource

// The orders the titles of a tracker page can take. Titles with no entry yet only have their names to go by.
internal enum class TitleSort { Name, Updated, Progress, Score }

// What the person narrowed the titles of a tracker page to: words of the name, a kind, a status and the order. It is the same for each list of the page.
internal class TitleTools(
    query: MutableState<String>,
    kind: MutableState<Int?>,
    status: MutableState<String?>,
    sort: MutableState<TitleSort>,
    ascending: MutableState<Boolean>,
) {
    var query by query
    var kindCode by kind
    var statusCode by status
    var sort by sort
    var ascending by ascending

    val kind: Kind? get() = kindCode?.let(Kind::fromCode)
    val status: TrackStatus? get() = statusCode?.let(TrackStatus::of)

    // Everything the lists are narrowed and ordered by, so a list is worked out again only when one of them changes.
    val key: List<Any?> get() = listOf(query, kindCode, statusCode, sort, ascending)

    // A new order starts from A to Z for names and from the most for the rest, and the same order again turns it round.
    fun sortBy(next: TitleSort) {
        if (next == sort) {
            ascending = !ascending
        } else {
            sort = next
            ascending = next == TitleSort.Name
        }
    }

    private fun named(name: String): Boolean = query.isBlank() || name.contains(query.trim(), ignoreCase = true)

    private fun <T> ordered(items: List<T>, name: (T) -> String, value: (T) -> Long): List<T> {
        val byName = compareBy<T, String>(String.CASE_INSENSITIVE_ORDER) { name(it) }
        val order = if (sort == TitleSort.Name) byName else compareBy<T> { value(it) }.then(byName)
        return items.sortedWith(if (ascending) order else order.reversed())
    }

    fun links(items: List<TrackerLinkEntity>): List<TrackerLinkEntity> = ordered(
        items.filter {
            named(it.remoteName) && (kindCode == null || it.kind == kindCode) &&
                (statusCode == null || it.status == statusCode)
        },
        { it.remoteName },
    ) {
        when (sort) {
            TitleSort.Updated -> maxOf(it.changedAt, it.remoteAt)
            TitleSort.Progress -> it.progress.toLong()
            TitleSort.Score -> it.score.toLong()
            TitleSort.Name -> 0
        }
    }

    // Titles with no entry are always by name from A to Z, as they have nothing else to order by.
    fun titles(items: List<LibraryTitle>): List<LibraryTitle> = items
        .filter { named(it.name) && (kindCode == null || it.kind == kindCode) }
        .sortedWith(compareBy(String.CASE_INSENSITIVE_ORDER) { it.name })

    fun entries(items: List<OnTracker>): List<OnTracker> = ordered(
        items.filter {
            named(it.media.name) && (kind == null || it.kind == kind) &&
                (statusCode == null || it.entry.status == statusCode)
        },
        { it.media.name },
    ) {
        when (sort) {
            TitleSort.Updated -> it.entry.updatedAt
            TitleSort.Progress -> it.entry.progress.toLong()
            TitleSort.Score -> it.entry.score.toLong()
            TitleSort.Name -> 0
        }
    }
}

@Composable
internal fun rememberTitleTools(tracker: TrackerId): TitleTools {
    val query = rememberSaveable(tracker) { mutableStateOf("") }
    val kind = rememberSaveable(tracker) { mutableStateOf<Int?>(null) }
    val status = rememberSaveable(tracker) { mutableStateOf<String?>(null) }
    val sort = rememberSaveable(tracker) { mutableStateOf(TitleSort.Name) }
    val ascending = rememberSaveable(tracker) { mutableStateOf(true) }
    return remember(tracker) { TitleTools(query, kind, status, sort, ascending) }
}

// The search field, the order and the kinds over the titles, and a chip with a count for each status when the list has statuses.
@Composable
internal fun TitleToolsBar(
    tools: TitleTools,
    kinds: Set<Kind>,
    statuses: Map<TrackStatus, Int>?,
    sorts: List<TitleSort>,
) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        AppSearchBar(tools.query, { tools.query = it }, stringResource(Res.string.tracker_search_titles))
        val kindChoice = hasKindChoice(kinds, tools.kind)
        if (sorts.size > 1 || kindChoice) {
            ChipRow {
                if (sorts.size > 1) SortMenu(tools, sorts)
                if (sorts.size > 1 && kindChoice) ChipSeparator()
                KindChips(tools.kind, kinds) { tools.kindCode = it?.code }
            }
        }
        // A status is offered while titles have it, and the one picked stays so it can be turned off.
        val offered = statuses?.filter { (status, count) -> count > 0 || status == tools.status }.orEmpty()
        if (offered.size > 1 || tools.status != null) {
            ChipRow {
                for ((status, count) in offered) {
                    val on = tools.status == status
                    ToggleChip("${statusLabel(status, tools.kind ?: kinds.singleOrNull() ?: Kind.Manga)} $count", on, {
                        tools.statusCode = if (on) null else status.code
                    })
                }
            }
        }
    }
}

// The order chip, which opens the orders to pick from. Picking the one in use turns it round.
@Composable
private fun SortMenu(tools: TitleTools, sorts: List<TitleSort>) {
    var open by remember { mutableStateOf(false) }
    Box {
        SortChip(sortLabel(tools.sort), tools.ascending, { open = true }, stringResource(Res.string.tracker_sort))
        AppMenu(open, { open = false }) {
            for (sort in sorts) {
                AppMenuItem({ Text(sortLabel(sort)) }, {
                    open = false
                    tools.sortBy(sort)
                })
            }
        }
    }
}

@Composable
private fun sortLabel(sort: TitleSort): String = stringResource(
    when (sort) {
        TitleSort.Name -> Res.string.tracker_sort_name
        TitleSort.Updated -> Res.string.tracker_sort_updated
        TitleSort.Progress -> Res.string.tracker_sort_progress
        TitleSort.Score -> Res.string.tracker_sort_score
    },
)

// How many of the titles have each status, in the order of the statuses.
internal fun statusCounts(codes: List<String>): Map<TrackStatus, Int> {
    val counts = codes.groupingBy { TrackStatus.of(it) }.eachCount()
    return TrackStatus.entries.associateWith { counts[it] ?: 0 }
}
