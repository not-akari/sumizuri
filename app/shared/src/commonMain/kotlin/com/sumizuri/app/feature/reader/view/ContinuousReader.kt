package com.sumizuri.app.feature.reader.view

import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.interaction.DragInteraction
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.data.model.controls.ReaderAction
import com.sumizuri.app.data.model.controls.TapLayout
import com.sumizuri.app.feature.reader.ReaderState
import com.sumizuri.app.feature.reader.controls.ink
import com.sumizuri.app.feature.reader.lookup.LookupText
import com.sumizuri.app.feature.reader.novel.novelStyle
import com.sumizuri.app.ui.controls.LocalReaderControls
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.scroll.scrollFrom
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

// How many pages ahead and behind the ones in view are asked for early.
private const val Ahead = 5

// How many pages ahead and behind the ones in view are read and cut in full before they show.
private const val ReadAhead = 2
private const val ReadBehind = 1

// The next chapter is added when the pages in view come within this many pages of the end.
private const val NearEnd = 4
private const val Behind = 2

// A second in nanoseconds, to turn the time of a frame into a distance.
private const val NanosPerSecond = 1_000_000_000f

// The auto scroll stops when this many frames in a row move nothing, which is the end of the chapter.
private const val StuckFrames = 10

// The pages of a chapter one under another in a column, and at the end the way to the chapter before and after.
@Composable
fun ContinuousReader(state: ReaderState, view: ReaderView, onOpenChapter: (Long) -> Unit) {
    val settings = state.settings
    val list = rememberLazyListState(initialFirstVisibleItemIndex = view.startPage)
    val scope = rememberCoroutineScope()
    val last = state.pages.size - 1
    val page by remember(last) { derivedStateOf { list.firstVisibleItemIndex.coerceIn(0, last) } }
    var height by remember { mutableIntStateOf(0) }
    val ink = settings.background.ink()
    val style = novelStyle(settings, ink)
    val context = LocalPlatformContext.current
    // The shape of each page that is known, so a page that is not in view keeps its height and the list does not jump when one arrives.
    val first = state.segments.firstOrNull()?.chapterId
    val shapes = remember(first) { mutableStateMapOf<Int, Float>() }
    val asked = remember(first) { mutableSetOf<Int>() }
    val read = remember(first, settings.quality) { mutableSetOf<Int>() }
    val dividerHeights = remember(first) { mutableStateMapOf<Int, Int>() }
    val chapterStarts = remember(state.segments) { state.segments.drop(1).associateBy { it.start } }

    LaunchedEffect(view.jump) {
        view.jump?.let {
            list.scrollToItem(it.coerceIn(0, last))
            view.onJumped()
        }
    }
    LaunchedEffect(page) { view.onPage(page) }
    // The page in view, which is the place kept, and the furthest page on the screen, which counts toward reading the chapter. The page in view is the top one unless only a sliver of it is left, then the one under it.
    LaunchedEffect(list, last) {
        snapshotFlow {
            val layout = list.layoutInfo
            val top = layout.viewportStartOffset
            val room = layout.viewportEndOffset - top
            val shown = layout.visibleItemsInfo.firstOrNull { it.offset + it.size - top > room / 4 }?.index ?: 0
            shown to (layout.visibleItemsInfo.lastOrNull()?.index ?: 0)
        }.collect { (shown, reached) ->
            view.onProgress(
                shown.coerceAtMost(last),
                reached.coerceAtMost(last),
                state.pages.size,
            )
        }
    }

    // The pages just ahead and just behind are asked for early, which fills the disk cache and gives their height. The nearest ones are read and cut in full, so the heavy work is done before they scroll in and not while they do.
    LaunchedEffect(list, state.pages, settings.quality) {
        // Work for pages the reader has gone well past is called off, so it neither holds up the pages it comes to nor pushes them out of the cache.
        val reading = HashMap<Int, Job>()
        val probing = HashMap<Int, Job>()
        snapshotFlow {
            (
                list.layoutInfo.visibleItemsInfo
                    .firstOrNull()
                    ?.index ?: 0
                ) to (
                list.layoutInfo.visibleItemsInfo
                    .lastOrNull()
                    ?.index ?: 0
                )
        }.collect { (first, lastShown) ->
            val near = (first - Behind - 1)..(lastShown + Ahead + 1)
            reading.dropFar(near, read)
            probing.dropFar(near, asked)
            val ready = (lastShown + 1..lastShown + ReadAhead) + (first - 1 downTo first - ReadBehind)
            for (index in ready) {
                val item = state.pages.getOrNull(index) ?: continue
                val url = item.imageUrl ?: continue
                if (!read.add(index)) continue
                reading[index] = launch {
                    readPage(
                        context,
                        url,
                        state.imageHeaders,
                        settings.quality.maxWidth,
                        item.descramble,
                        ahead = true,
                    )?.let { slices ->
                        shapes[index] = slices.sumOf { it.height }.toFloat() / slices.first().width
                    }
                }
            }
            val wanted = (lastShown + 1..lastShown + Ahead) + (first - 1 downTo first - Behind)
            for (index in wanted) {
                val url = state.pages.getOrNull(index)?.imageUrl ?: continue
                if (index in shapes || index in read || !asked.add(index)) continue
                probing[index] = launch {
                    probeAspect(
                        context,
                        url,
                        state.imageHeaders,
                        ahead = true,
                    )?.let { shapes[index] = it.toFloat() }
                }
            }
        }
    }
    val density = LocalDensity.current.density
    // The scroll moves by the speed times the time of each frame, and ends when the end of the chapter stops it.
    LaunchedEffect(view.auto, view.autoSpeed) {
        if (!view.auto) return@LaunchedEffect
        var before = withFrameNanos { it }
        var stuck = 0
        while (true) {
            val now = withFrameNanos { it }
            val wanted = view.autoSpeed * density * (now - before) / NanosPerSecond
            before = now
            stuck = if (list.scrollBy(wanted) == 0f) stuck + 1 else 0
            if (stuck >= StuckFrames) {
                view.onAutoStopped()
                return@LaunchedEffect
            }
        }
    }
    // A finger on the list takes the scroll back.
    LaunchedEffect(view.auto) {
        if (view.auto) {
            list.interactionSource.interactions.collect {
                if (it is DragInteraction.Start) {
                    view
                        .onAutoStopped()
                }
            }
        }
    }

    // The next chapter is asked for while the last few pages are in view, so it is there before the end.
    LaunchedEffect(list, last) {
        snapshotFlow {
            (
                list.layoutInfo.visibleItemsInfo
                    .lastOrNull()
                    ?.index ?: 0
                ) >= last - NearEnd
        }.collect { near -> if (near) view.onNearEnd() }
    }

    val controls = LocalReaderControls.current

    fun scrollBy(pixels: Float) {
        scope.launch { list.animateScrollBy(pixels) }
    }

    Box(
        Modifier
            .fillMaxSize()
            .onSizeChanged {
                height = it.height
            }.scrollFrom { list }
            .readerInput(TapLayout.Continuous) { action, tap ->
                val steps = controls.scroll
                when (action) {
                    ReaderAction.NextPage -> scrollBy(height * if (tap) steps.tapFraction else steps.pageFraction)
                    ReaderAction.PreviousPage -> scrollBy(-height * if (tap) steps.tapFraction else steps.pageFraction)
                    ReaderAction.ScrollDown -> scrollBy(steps.arrowDp * density)
                    ReaderAction.ScrollUp -> scrollBy(-steps.arrowDp * density)
                    else -> return@readerInput view.onCommon(action)
                }
                true
            },
        contentAlignment = Alignment.TopCenter,
    ) {
        val widest = settings.width.dp?.dp
        LazyColumn(
            (if (widest == null) Modifier else Modifier.widthIn(max = widest)).fillMaxSize(),
            state = list,
            // Words start a little way down, and pictures start at the very top.
            contentPadding = PaddingValues(top = if (state.isText) 24.dp else 0.dp),
            verticalArrangement = Arrangement.spacedBy(settings.gap.dp.dp),
        ) {
            itemsIndexed(
                items = state.pages,
                key = { index, _ -> index },
                contentType = { _, item -> if (item.imageUrl == null) "text" else "image" },
            ) { index, item ->
                val url = item.imageUrl
                Column {
                    // Where another chapter starts, its name stands above its first page.
                    chapterStarts[index]?.let {
                        ChapterDivider(
                            it,
                            state.chapters,
                            state.kind,
                            ink,
                            Modifier.onSizeChanged { size ->
                                dividerHeights[index] =
                                    size.height
                            },
                        )
                    }
                    if (url != null) {
                        PageImage(
                            url,
                            state.imageHeaders,
                            index + 1,
                            shape = { shapes[index] ?: shapes[index - 1] ?: shapes[index + 1] },
                            onShape = { shapes[index] = it },
                            visibleRangePx = {
                                val layout = list.layoutInfo
                                val itemInfo = layout.visibleItemsInfo.firstOrNull { it.index == index }
                                if (itemInfo == null) {
                                    1f..0f
                                } else {
                                    val dividerHeight = dividerHeights[index] ?: 0
                                    val imageTop = itemInfo.offset + dividerHeight
                                    val top = (layout.viewportStartOffset - imageTop).coerceAtLeast(0)
                                    val bottom = (layout.viewportEndOffset - imageTop).coerceAtMost(
                                        itemInfo.size - dividerHeight,
                                    )
                                    if (bottom > top) top.toFloat()..bottom.toFloat() else 1f..0f
                                }
                            },
                            maxWidth = settings.quality.maxWidth,
                            descramble = item.descramble,
                        )
                    } else {
                        LookupText(
                            item.text.orEmpty(),
                            style,
                            Modifier.padding(start = PageGutter, end = PageGutter, bottom = settings.paragraphGap.dp),
                        )
                    }
                }
            }
            item {
                ChapterEnd(
                    state.chapters,
                    state.kind,
                    state.segments.lastOrNull()?.chapterId ?: state.chapterId,
                    state.segments.firstOrNull()?.previousId,
                    state.segments.lastOrNull()?.nextId,
                    ink,
                    onOpenChapter,
                )
            }
        }
    }
}

// Calls off the work for pages outside the range near the screen, so they can be asked for again when the reader comes back, and forgets the work that is done.
private fun MutableMap<Int, Job>.dropFar(near: IntRange, started: MutableSet<Int>) {
    entries.removeAll { (index, job) ->
        val far = index !in near && !job.isCompleted
        if (far) {
            job.cancel()
            started.remove(index)
        }
        far || job.isCompleted
    }
}
