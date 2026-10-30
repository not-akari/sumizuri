package com.sumizuri.app.feature.title.chapter

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapters_empty
import com.sumizuri.app.ui.kit.card.CardPlace
import org.jetbrains.compose.resources.stringResource

// The room under each part of the title page. The rows of the chapters touch, as they make one card.
internal val ItemGap = 6.dp

// The width a chapter cell is counted at, and the widths a poster card and a wide card of a season are given, in dp.
private const val ChapterCell = 170
private const val SeasonCell = 220
private const val WideSeasonCell = 320

// One item of the chapters, with room kept free at its end when the page has a panel beside the chapters.
private fun LazyListScope.room(key: Any, endInset: Dp, content: @Composable () -> Unit) {
    item(key = key) { Box(Modifier.padding(end = endInset, bottom = ItemGap)) { content() } }
}

// The chapters of the page as items of a lazy list: the header, the notes about repeats and breaks, and then the rows or the cells of a grid. The end inset leaves room on the right for a panel that stands beside them.
internal fun LazyListScope.chapterSection(
    state: TitleState,
    calls: TitleCallbacks,
    model: ChapterListModel,
    columns: Int,
    endInset: Dp = 0.dp,
    onSeason: (String?) -> Unit = {},
    wideRows: Boolean = false,
) {
    val title = state.title ?: return
    room("chapters-header", endInset) { ChapterHeader(state, calls) }
    // A title with seasons shows them as cards first, and an open season shows the way back over its episodes.
    if (model.pickingSeason) {
        val wide = seasonsAreWide(model.seasons, title, state.seasonCovers)
        // A season card is bigger than a chapter cell, so a row holds fewer and the pictures can be seen.
        val perRow = maxOf(2, columns * ChapterCell / if (wide) WideSeasonCell else SeasonCell)
        itemsIndexed(model.seasons.chunked(perRow), key = { _, row -> "season-" + row.first().id }) { _, row ->
            SeasonRow(row, perRow, title, state.seasonCovers, wide, {
                onSeason(it.id)
            }, Modifier.padding(end = endInset, bottom = 8.dp))
        }
        return
    }
    model.openSeason?.let { group -> room("season-heading", endInset) { SeasonHeading(group) { onSeason(null) } } }
    // Only while repeats show, as a way to hide them. Once hidden they are not mentioned, and the menu brings them back.
    if (model.duplicates > 0 && !state.hideDuplicates) {
        room("chapters-duplicates", endInset) {
            DuplicatesBanner(model.duplicates, state.hideDuplicates, calls.onToggleDuplicates)
        }
    }
    if (state.grid && model.missing.isNotEmpty()) room("chapters-missing", endInset) { MissingSummary(model.missing) }
    if (state.chapters.isEmpty()) {
        room("chapters-empty", endInset) {
            when {
                state.loading -> ChapterSkeleton()

                state.error == null -> Text(
                    stringResource(Res.string.chapters_empty),
                    Modifier.fillMaxWidth().padding(24.dp),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
        }
        return
    }
    if (model.shown.isEmpty() && state.filtering) {
        room("chapters-filtered", endInset) {
            FilteredEmpty {
                calls.onFilter(ChapterFilter())
                calls.onHideFacets(emptySet())
            }
        }
        return
    }
    if (state.grid) {
        val rows = model.shown.chunked(columns)
        itemsIndexed(rows, key = { _, row -> row.first().key }) { _, row ->
            Row(
                Modifier.animateItem().fillMaxWidth().padding(end = endInset, bottom = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                for (chapter in row) {
                    ChapterGridCell(
                        chapter,
                        title.kind,
                        state.preview,
                        state.selecting,
                        chapter.id in state.selected,
                        calls.chapters,
                        Modifier.weight(1f),
                        calls.downloads?.let { RowDownload(state.downloads[chapter.id], it) },
                    )
                }
                repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    } else {
        itemsIndexed(model.shown, key = { _, chapter -> chapter.key }) { index, chapter ->
            Column(Modifier.animateItem().padding(end = endInset)) {
                if (index == 0 && model.gaps.before.isNotEmpty()) GapMarker(model.gaps.before)
                // A season made of parts says where each part begins.
                if (model.openSeason?.merged == true && model.shown.getOrNull(index - 1)?.season != chapter.season) {
                    PartLabel(chapter.seasonName ?: chapter.season.orEmpty(), first = index == 0)
                }
                val picked = chapter.id in state.selected
                val place = CardPlace(index, model.shown.size)
                if (state.selecting || (state.preview && !wideRows)) {
                    ChapterListRow(chapter, title.kind, state.preview, state.selecting, picked, calls.chapters, place)
                } else if (wideRows) {
                    ChapterWideRow(
                        chapter,
                        title.kind,
                        state.preview,
                        chapter.id == state.target?.id,
                        calls.chapters,
                        place,
                        calls.downloads?.let { RowDownload(state.downloads[chapter.id], it) },
                    )
                } else {
                    SwipeableChapterRow(
                        chapter,
                        title.kind,
                        picked,
                        calls.chapters,
                        place,
                        calls.downloads?.let {
                            RowDownload(state.downloads[chapter.id], it)
                        },
                    )
                }
                model.gaps.after
                    .getOrNull(index)
                    ?.takeIf { it.isNotEmpty() }
                    ?.let { GapMarker(it) }
            }
        }
    }
}

// The name of a part over its first episode, in a season shown as its parts together.
@Composable
private fun PartLabel(name: String, first: Boolean) {
    Text(
        name,
        Modifier.padding(start = 4.dp, top = if (first) 0.dp else 14.dp, bottom = 8.dp),
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.primary,
    )
}
