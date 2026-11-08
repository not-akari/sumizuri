package com.sumizuri.app.feature.reader.view

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.data.model.controls.ReaderAction
import com.sumizuri.app.data.model.controls.TapLayout
import com.sumizuri.app.data.model.reader.ReaderDual
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.data.model.reader.ReaderScale
import com.sumizuri.app.data.model.reader.ReaderZoomStart
import com.sumizuri.app.feature.reader.ReaderState
import com.sumizuri.app.feature.reader.controls.ink
import com.sumizuri.app.ui.kit.image.ImageFit
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

// Pages the next screens are made ready for, so a turn shows the picture at once.
private const val Ahead = 1

// Screens past those that are read early.
private const val ReadAhead = 2

// The pages of a chapter turned one screen at a time, sideways or downwards, with the way to the next chapter after the last page.
@Composable
fun PagedReader(state: ReaderState, view: ReaderView, onOpenChapter: (Long) -> Unit) {
    val settings = state.settings
    val rtl = state.mode == ReaderMode.RightToLeft
    val vertical = state.mode == ReaderMode.Vertical
    val spreads = remember(state.pages.size, settings.dual) { spreadsOf(state.pages.size, settings.dual) }
    val end = spreads.size
    val pager = rememberPagerState(initialPage = spreadOf(spreads, view.startPage)) { end + 1 }
    val scope = rememberCoroutineScope()
    val lastPage = state.pages.lastIndex
    // The panel zoomed to on the page on show, or -1 for the whole page. Each page starts whole.
    var panel by remember { mutableIntStateOf(-1) }
    LaunchedEffect(settings.panelZoom) { PagePanels.wanted = settings.panelZoom }
    LaunchedEffect(pager) { snapshotFlow { pager.currentPage }.collect { panel = -1 } }

    // The panels of the page on show in reading order, when panel by panel reading is on and the page has them.
    fun panelsHere(): List<Rect>? {
        if (!settings.panelZoom || settings.dual != ReaderDual.Off || settings.scale != ReaderScale.Screen) return null
        val page = spreads.getOrNull(pager.currentPage)?.singleOrNull() ?: return null
        val url = state.pages.getOrNull(page)?.imageUrl ?: return null
        return PagePanels.get(panelKey(url, settings.cropBorders))?.inOrder(rtl)?.takeIf { it.size >= 2 }
    }

    fun turn(next: Boolean) {
        // With panels, a turn steps to the next or the last panel first, and the page turns after the last one.
        panelsHere()?.let { panels ->
            if (next && panel < panels.lastIndex) {
                panel++
                return
            }
            if (!next && panel >= 0) {
                panel--
                return
            }
        }
        panel = -1
        val target = (pager.currentPage + if (next) 1 else -1).coerceIn(0, end)
        scope.launch { if (settings.animatePages) pager.animateScrollToPage(target) else pager.scrollToPage(target) }
    }

    LaunchedEffect(view.jump) {
        view.jump?.let {
            pager.scrollToPage(spreadOf(spreads, it))
            view.onJumped()
        }
    }
    LaunchedEffect(pager, spreads) {
        snapshotFlow { pager.currentPage }.collect { index ->
            val spread = spreads.getOrNull(index)
            view.onPage(spread?.first() ?: lastPage)
            view.onProgress(spread?.first() ?: lastPage, spread?.last() ?: lastPage, state.pages.size)
        }
    }
    // The pages a few screens past the ones the pager makes ready are read and cut early too, so quick turns do not wait for them.
    val context = LocalPlatformContext.current
    LaunchedEffect(pager, spreads, settings.quality, settings.cropBorders) {
        val read = mutableSetOf<Int>()
        snapshotFlow { pager.currentPage }.collect { index ->
            for (screen in index + Ahead + 1..index + Ahead + ReadAhead) {
                for (page in spreads.getOrNull(screen).orEmpty()) {
                    val item = state.pages.getOrNull(page) ?: continue
                    val url = item.imageUrl ?: continue
                    if (read.add(page)) {
                        launch {
                            readPage(
                                context,
                                url,
                                state.imageHeaders,
                                settings.quality.maxWidth,
                                item.descramble,
                                settings.cropBorders,
                                ahead = true,
                            )
                        }
                    }
                }
            }
        }
    }

    Box(
        Modifier.fillMaxSize().readerInput(TapLayout.Paged) { action, tap ->
            // The page on the left is the next one in a book that reads right to left. A tap can also be turned around in the options.
            val leftIsNext = if (tap) rtl != settings.invertTaps else rtl
            when (action) {
                ReaderAction.NextPage -> turn(next = true)
                ReaderAction.PreviousPage -> turn(next = false)
                ReaderAction.PageLeft -> turn(next = leftIsNext)
                ReaderAction.PageRight -> turn(next = !leftIsNext)
                ReaderAction.ScrollDown -> if (vertical) turn(next = true) else return@readerInput false
                ReaderAction.ScrollUp -> if (vertical) turn(next = false) else return@readerInput false
                else -> return@readerInput view.onCommon(action)
            }
            true
        },
    ) {
        val screen: @Composable (Int) -> Unit = { index ->
            Box(
                Modifier.fillMaxSize().pageTurn(pager, index, settings.pageTurn, vertical, rtl),
                contentAlignment = Alignment.Center,
            ) {
                if (index ==
                    end
                ) {
                    ChapterEnd(
                        state.chapters,
                        state.kind,
                        state.chapterId,
                        state.previousId,
                        state.nextId,
                        settings.background.ink(),
                        onOpenChapter,
                    )
                } else {
                    val focus = if (index == pager.currentPage && panel >= 0) panelsHere()?.getOrNull(panel) else null
                    Spread(spreads[index], state, rtl, focus)
                }
            }
        }
        if (vertical) {
            VerticalPager(pager, Modifier.fillMaxSize(), beyondViewportPageCount = Ahead) { screen(it) }
        } else {
            HorizontalPager(
                pager,
                Modifier.fillMaxSize(),
                beyondViewportPageCount = Ahead,
                reverseLayout = rtl,
            ) { screen(it) }
        }
    }
}

// One screen of pictures, a single page or two side by side. A right to left book puts the first of the two on the right.
@Composable
private fun Spread(pages: List<Int>, state: ReaderState, rtl: Boolean, focus: Rect? = null) {
    val fit = when (state.settings.scale) {
        ReaderScale.Screen -> ImageFit.Screen
        ReaderScale.Width -> ImageFit.Width
        ReaderScale.Height -> ImageFit.Height
        ReaderScale.Original -> ImageFit.Original
    }
    val shown = if (rtl) pages.reversed() else pages
    Row(Modifier.fillMaxSize()) {
        shown.forEachIndexed { place, index ->
            val page = state.pages[index]
            val url = page.imageUrl ?: return@forEachIndexed
            // Two pages lean on each other, so the one on the left sits at its right edge and the other at its left.
            val bias = if (shown.size == 1) {
                0.5f
            } else if (place == 0) {
                1f
            } else {
                0f
            }
            var shape by remember(url) { mutableStateOf<Float?>(null) }
            Box(
                Modifier
                    .weight(
                        1f,
                    ).fillMaxHeight()
                    .scrolling(fit, startAcross(state.settings.zoomStart, rtl))
                    .panelFocus(focus, shape),
                contentAlignment = Alignment.Center,
            ) {
                PageImage(
                    url,
                    state.imageHeaders,
                    index + 1,
                    fit = fit,
                    bias = bias,
                    onShape = { shape = it },
                    maxWidth = state.settings.quality.maxWidth,
                    descramble = page.descramble,
                    crop = state.settings.cropBorders,
                )
            }
        }
    }
}

// How far across a page wider than the screen it starts, from 0 at the left edge to 1 at the right edge.
private fun startAcross(start: ReaderZoomStart, rtl: Boolean): Float = when (start) {
    ReaderZoomStart.Auto -> if (rtl) 1f else 0f
    ReaderZoomStart.Left -> 0f
    ReaderZoomStart.Center -> 0.5f
    ReaderZoomStart.Right -> 1f
}

// A page larger than the screen is moved around by hand. Sideways it starts where the choice of the reader says.
@Composable
private fun Modifier.scrolling(fit: ImageFit, across: Float): Modifier = when (fit) {
    ImageFit.Screen -> this
    ImageFit.Width -> verticalScroll(rememberScrollState())
    ImageFit.Height -> horizontalScroll(sidewaysState(across))
    ImageFit.Original -> verticalScroll(rememberScrollState()).horizontalScroll(sidewaysState(across))
}

// A sideways scroll that moves to its starting place once the page has made it long enough to scroll.
@Composable
private fun sidewaysState(across: Float): ScrollState {
    val state = rememberScrollState()
    var placed by remember { mutableStateOf(false) }
    LaunchedEffect(state.maxValue, across) {
        if (!placed && state.maxValue > 0) {
            state.scrollTo((state.maxValue * across).roundToInt())
            placed = true
        }
    }
    return state
}

// The pages that share each screen, by their numbers from zero.
private fun spreadsOf(count: Int, dual: ReaderDual): List<List<Int>> {
    val all = (0 until count).toList()
    return when (dual) {
        ReaderDual.Off -> all.map { listOf(it) }
        ReaderDual.On -> all.chunked(2)
        ReaderDual.Cover -> if (all.isEmpty()) emptyList() else listOf(listOf(0)) + all.drop(1).chunked(2)
    }
}

// The screen a page is on.
private fun spreadOf(spreads: List<List<Int>>, page: Int): Int = spreads.indexOfFirst { page in it }.coerceAtLeast(0)
