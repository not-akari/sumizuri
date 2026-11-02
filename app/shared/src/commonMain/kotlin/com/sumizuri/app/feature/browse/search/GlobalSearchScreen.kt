package com.sumizuri.app.feature.browse.search

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.feature.browse.asTitle
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.all
import com.sumizuri.app.shared.resources.global_search_hint
import com.sumizuri.app.shared.resources.global_search_intro
import com.sumizuri.app.shared.resources.global_search_none
import com.sumizuri.app.shared.resources.global_search_title
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.cover.CoverTile
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.kit.cover.shownName
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.input.SearchFocus
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.scroll.mouseDragScroll
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// A cover in the rows of results is this wide.
private val CellWidth = 108.dp

// The search of every source: the field, which takes the keys at once, the kinds when there is more than one, and a row of covers for each source. The sources that found something come first, the ones still asking next, and the ones that found nothing or failed last, each on one quiet line.
@Composable
internal fun GlobalSearchScreen(
    state: GlobalSearchState,
    onBack: () -> Unit,
    onQuery: (String) -> Unit,
    onKind: (Kind?) -> Unit,
    onOpen: (InstalledSource, SourceEntry) -> Unit,
) {
    LaunchedEffect(Unit) {
        delay(80)
        SearchFocus.request()
    }
    val ordered = state.results.sortedBy { result ->
        when {
            result.entries.isNotEmpty() -> 0
            result.loading -> 1
            else -> 2
        }
    }
    // The search keeps to the middle column every page uses, so a tablet does not stretch it across the screen.
    ReadableColumn {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(stringResource(Res.string.global_search_title), onBack = onBack)
            Column(Modifier.padding(horizontal = PageGutter), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                AppSearchBar(state.query, onQuery, stringResource(Res.string.global_search_hint))
                // Every kind at once, or one of them.
                val kind = state.kind
                if (state.kinds.size > 1) {
                    ChipRow {
                        ChoiceChip(stringResource(Res.string.all), kind == null) { onKind(null) }
                        for (each in state.kinds) ChoiceChip(stringResource(each.label), each == kind) { onKind(each) }
                    }
                }
            }
            LazyColumn(
                Modifier.weight(1f),
                contentPadding = PaddingValues(start = PageGutter, end = PageGutter, top = 16.dp, bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                if (state.query.isBlank()) {
                    item(key = "intro") {
                        Text(
                            stringResource(Res.string.global_search_intro),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.outline,
                        )
                    }
                }
                items(ordered, key = { it.source.id }) { result ->
                    SourceSection(
                        result,
                        showKind =
                        state.kind == null && state.kinds.size > 1,
                        onOpen,
                        Modifier.animateItem(),
                    )
                }
            }
        }
    }
}

// The answer of one source: its icon and name, and its kind when every kind is searched, with a spinner while it is asked, then its covers, or a quiet line when it found nothing or could not be searched.
@Composable
private fun SourceSection(
    result: SourceResults,
    showKind: Boolean,
    onOpen: (InstalledSource, SourceEntry) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = MaterialTheme.colorScheme
    val source = result.source
    Column(modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            SourceMark(source.iconUrl, size = 24.dp, sourceId = source.id)
            Text(
                source.shownName(),
                Modifier.weight(1f, fill = false),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (showKind) {
                Text(
                    stringResource(source.kind.label),
                    Modifier
                        .background(
                            colors.primary.copy(alpha = 0.14f),
                            MaterialTheme.shapes.small,
                        ).padding(horizontal = 8.dp, vertical = 2.dp),
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.primary,
                )
            }
            Spacer(Modifier.weight(1f))
            when {
                result.loading -> InkCircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp)

                result.entries.isNotEmpty() -> Text(
                    result.entries.size.toString(),
                    style = MaterialTheme.typography.labelMedium,
                    color = colors.outline,
                )

                else -> Text(
                    result.error ?: stringResource(Res.string.global_search_none),
                    Modifier.weight(1f, fill = false),
                    style = MaterialTheme.typography.bodySmall,
                    color = if (result.error !=
                        null
                    ) {
                        colors.error
                    } else {
                        colors.outline
                    },
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        if (result.entries.isNotEmpty()) {
            val row = rememberLazyListState()
            LazyRow(
                Modifier.mouseDragScroll(row, horizontal = true),
                state = row,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                items(result.entries, key = { it.url }) { entry ->
                    CoverTile(
                        entry.asTitle(source.kind, source.id),
                        onClick = { onOpen(source, entry) },
                        modifier = Modifier.width(CellWidth),
                        saved =
                        entry.url in result.saved,
                    )
                }
            }
        }
    }
}
