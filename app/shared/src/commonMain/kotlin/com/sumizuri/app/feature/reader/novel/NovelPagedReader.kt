package com.sumizuri.app.feature.reader.novel

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.controls.ReaderAction
import com.sumizuri.app.data.model.controls.TapLayout
import com.sumizuri.app.data.model.reader.ReaderDual
import com.sumizuri.app.feature.reader.ReaderState
import com.sumizuri.app.feature.reader.controls.ink
import com.sumizuri.app.feature.reader.lookup.LookupText
import com.sumizuri.app.feature.reader.view.ChapterEnd
import com.sumizuri.app.feature.reader.view.PageImage
import com.sumizuri.app.feature.reader.view.ReaderView
import com.sumizuri.app.feature.reader.view.readerInput
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.image.ImageFit
import com.sumizuri.app.ui.kit.page.PageGutter
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

// The space above and below the lines of a page.
private val Margin = 28.dp

// A window at least this wide shows two pages side by side when dual page is on.
private val DualWidth = 840.dp

// Words set in pages that are turned, each page holding the lines that fit it. The lines are laid out again when the size of the text or of the window changes, and the reader stays at the paragraph they were at.
@Composable
fun NovelPagedReader(state: ReaderState, view: ReaderView, onOpenChapter: (Long) -> Unit) {
    val settings = state.settings
    val ink = settings.background.ink()
    val style = novelStyle(settings, ink)
    val measurer = rememberTextMeasurer()
    val density = LocalDensity.current
    // The paragraph the reader is at, kept so a new layout opens where the old one was.
    var anchor by remember { mutableIntStateOf((view.startFraction * (state.pages.size - 1)).roundToInt()) }

    BoxWithConstraints(Modifier.fillMaxSize()) {
        val columns = if (settings.dual != ReaderDual.Off && maxWidth >= DualWidth) 2 else 1
        val width = with(density) { (maxWidth / columns - PageGutter * 2).roundToPx() }
        val height = with(density) { (maxHeight - Margin * 2).roundToPx() }
        val gap = with(density) { settings.paragraphGap.dp.roundToPx() }
        val pages by produceState<List<NovelPage>?>(null, state.pages, style, width, height, gap) {
            value = paginate(state.pages, measurer, style, width, height, gap)
        }
        val laid = pages
        if (laid == null) {
            Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
                InkCircularProgressIndicator(Modifier.padding(top = 120.dp), strokeWidth = 2.dp)
            }
        } else {
            NovelScreens(laid.chunked(columns), anchor, state, view, style, onOpenChapter) { anchor = it }
        }
    }
}

@Composable
private fun NovelScreens(
    screens: List<List<NovelPage>>,
    anchor: Int,
    state: ReaderState,
    view: ReaderView,
    style: TextStyle,
    onOpenChapter: (Long) -> Unit,
    onAnchor: (Int) -> Unit,
) {
    val settings = state.settings
    val end = screens.size
    val first = screens
        .indexOfFirst { screen ->
            screen.any { page ->
                page.chunks.any {
                    it.paragraph >= anchor
                }
            }
        }.coerceAtLeast(0)
    val pager = rememberPagerState(initialPage = first) { end + 1 }
    val scope = rememberCoroutineScope()

    fun turn(next: Boolean) {
        val target = (pager.currentPage + if (next) 1 else -1).coerceIn(0, end)
        scope.launch { if (settings.animatePages) pager.animateScrollToPage(target) else pager.scrollToPage(target) }
    }

    LaunchedEffect(end) { view.onCount(end) }
    LaunchedEffect(view.jump) {
        view.jump?.let {
            pager.scrollToPage(it.coerceIn(0, end))
            view.onJumped()
        }
    }
    LaunchedEffect(pager, screens) {
        snapshotFlow { pager.currentPage }.collect { index ->
            view.onPage(index.coerceAtMost(end - 1))
            screens
                .getOrNull(index)
                ?.first()
                ?.chunks
                ?.first()
                ?.let { onAnchor(it.paragraph) }
            view.onProgress(index.coerceAtMost(end - 1), index.coerceAtMost(end - 1), end)
        }
    }

    Box(
        Modifier.fillMaxSize().readerInput(TapLayout.Paged) { action, tap ->
            // A tap can be turned around in the options, and a key cannot.
            val leftIsNext = tap && settings.invertTaps
            when (action) {
                ReaderAction.NextPage, ReaderAction.ScrollDown -> turn(next = true)
                ReaderAction.PreviousPage, ReaderAction.ScrollUp -> turn(next = false)
                ReaderAction.PageLeft -> turn(next = leftIsNext)
                ReaderAction.PageRight -> turn(next = !leftIsNext)
                else -> return@readerInput view.onCommon(action)
            }
            true
        },
    ) {
        HorizontalPager(pager, Modifier.fillMaxSize()) { index ->
            if (index == end) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    ChapterEnd(
                        state.chapters,
                        state.kind,
                        state.chapterId,
                        state.previousId,
                        state.nextId,
                        settings.background.ink(),
                        onOpenChapter,
                    )
                }
            } else {
                Row(Modifier.fillMaxSize().padding(vertical = Margin)) {
                    for (page in screens[index]) {
                        Column(Modifier.weight(1f).padding(horizontal = PageGutter)) {
                            page.chunks.forEachIndexed { place, chunk ->
                                val picture = chunk.picture
                                if (picture != null) {
                                    PageImage(
                                        picture,
                                        state.imageHeaders,
                                        chunk.paragraph + 1,
                                        Modifier.fillMaxSize(),
                                        fit = ImageFit.Screen,
                                    )
                                } else {
                                    val above = if (chunk.first && place > 0) settings.paragraphGap.dp else 0.dp
                                    LookupText(chunk.text, style, Modifier.padding(top = above))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
