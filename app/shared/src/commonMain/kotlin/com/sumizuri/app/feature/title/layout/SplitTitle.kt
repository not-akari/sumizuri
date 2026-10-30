package com.sumizuri.app.feature.title.layout

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.chapter.ItemGap
import com.sumizuri.app.feature.title.chapter.chapterSection
import com.sumizuri.app.feature.title.chapter.rememberChapterListModel
import com.sumizuri.app.feature.title.chapter.rememberOpenSeason
import com.sumizuri.app.feature.title.info.ContinueButton
import com.sumizuri.app.feature.title.info.FactStrip
import com.sumizuri.app.feature.title.info.PosterActions
import com.sumizuri.app.feature.title.info.SourceNotice
import com.sumizuri.app.feature.title.info.TitleHeading
import com.sumizuri.app.feature.title.info.TitleSummary
import com.sumizuri.app.feature.title.info.UnreachableActions
import com.sumizuri.app.ui.kit.page.LoadStatus
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.scroll.mouseDragScroll
import com.sumizuri.app.ui.kit.scroll.scrollFrom
import com.sumizuri.app.ui.text.displayName

// The shape of a cover before its own is known, and the least and most of the window the cover takes.
private const val LikelyAspect = 2f / 3f
private val ArtMin = 280.dp
private const val ArtMostShare = 0.6f

// The shapes of the covers seen this run, so a cover opened again takes its place at once and does not grow into it.
private val KnownAspects = HashMap<String, Float>()

// The least and most width of the column of text beside the cover, and how much of the cover it may lie over where the cover melts into the page.
private val TextMin = 480.dp
private val TextMax = 900.dp
private const val OverCover = 0.05f
private val ButtonsWidth = 520.dp

// The room kept on the left of the column, past the usual gutter.
private val TextStart = 16.dp

// A cell of the chapter grid is about this wide.
private val CellWidth = 170.dp

// How far the page scrolls before the bar gets its backdrop, and before the name shows in it.
private const val BarFade = 80f
private val NamedAfter = 160.dp

// The wide page in the way of a streaming app. The art lies behind the window and stays put: the sharp cover stands on the left in its own shape and melts into the page. The name, the buttons, the facts and the chapters scroll in a column beside it, over a wash of the page color.
@Composable
internal fun SplitTitle(
    state: TitleState,
    title: Title,
    calls: TitleCallbacks,
    onPreview: () -> Unit,
    onBackground: () -> Unit,
) {
    val list = rememberLazyListState()
    var openSeason by rememberOpenSeason()
    val model = rememberChapterListModel(state, openSeason)
    val settled = rememberSettled()
    val density = LocalDensity.current
    var aspect by remember(title.coverUrl) {
        mutableFloatStateOf(title.coverUrl?.let { KnownAspects[it] } ?: LikelyAspect)
    }
    // How far the head has scrolled while it is in sight, and a great deal once it is out of it.
    val scrolled by remember {
        derivedStateOf {
            list.layoutInfo.visibleItemsInfo
                .firstOrNull { it.index == 0 }
                ?.let { -it.offset } ?: Int.MAX_VALUE / 4
        }
    }
    val fade = rememberPageFade()
    BoxWithConstraints(Modifier.fillMaxSize().scrollFrom { list }) {
        // The flying cover follows its place, so a change of size while it flies is taken in smoothly.
        val art = (maxHeight * aspect).coerceIn(ArtMin, maxOf(ArtMin, maxWidth * ArtMostShare))
        // The words begin where the cover melts, or further left on a narrow window, so the column keeps its least width.
        val textStart = minOf(art * (1f - OverCover), (maxWidth - TextMin).coerceAtLeast(0.dp))
        SplitArt(
            title,
            state.focus,
            art,
            textStart,
            onPreview,
            {
                aspect = it
                title.coverUrl?.let { url -> KnownAspects[url] = it }
            },
            Modifier.fillMaxSize().graphicsLayer {
                // The art settles from a little bigger as the page comes, which fades in by the motion of pages.
                scaleX = 1f + ArtZoom * (1f - fade.value)
                scaleY = scaleX
            },
        )
        Box(
            Modifier
                .padding(start = textStart)
                .widthIn(max = TextMax)
                .fillMaxHeight(),
        ) {
            BoxWithConstraints(Modifier.fillMaxSize().padding(start = TextStart)) {
                val columns = maxOf(2, ((maxWidth - PageGutter * 2) / CellWidth).toInt())
                LazyColumn(
                    Modifier.fillMaxSize().mouseDragScroll(list),
                    state = list,
                    contentPadding = titleListPadding(),
                ) {
                    item(key = "head") {
                        SplitHead(state, title, calls, onBackground, Modifier.padding(bottom = 20.dp))
                    }
                    item(key = "notices") {
                        Column(Modifier.padding(bottom = ItemGap), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            SourceNotice(state, calls)
                            LoadStatus(
                                false,
                                state.error,
                                calls.onRefresh,
                                onSolve = calls.onSolve.takeIf { state.challengeUrl != null },
                            )
                        }
                    }
                    if (settled) {
                        chapterSection(state, calls, model, columns, onSeason = { openSeason = it }, wideRows = true)
                    } else {
                        chaptersWait()
                    }
                }
            }
            if (state.selecting) {
                SelectionBar(state.selected.size, model.shown.size, calls.selection, Modifier, calls.downloads)
            } else {
                val named = scrolled > with(density) { NamedAfter.roundToPx() }
                TitleBar(
                    if (named) title.displayName() else "",
                    (scrolled / BarFade).coerceIn(0f, 1f),
                    calls.onBack,
                    soft = true,
                )
            }
        }
    }
}

// The top of the column: the name and its facts, the description, the facts the heading does not give, and the continue button with the tiles.
@Composable
private fun SplitHead(
    state: TitleState,
    title: Title,
    calls: TitleCallbacks,
    onBackground: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier.padding(top = 12.dp).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        TitleHeading(state, title, wide = true)
        if (title.summary.isNotBlank()) TitleSummary(title.summary, lines = 4)
        FactStrip(state, title)
        if (!state.readable) UnreachableActions(state, title, calls, Modifier.widthIn(max = ButtonsWidth))
        Column(Modifier.widthIn(max = ButtonsWidth), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            if (state.readable) {
                ContinueButton(state.target, title.kind, calls.onContinue, Modifier.fillMaxWidth(), side = true)
            }
            PosterActions(state, title, calls, onBackground, Modifier.fillMaxWidth(), fixedHeight = true)
        }
    }
}
