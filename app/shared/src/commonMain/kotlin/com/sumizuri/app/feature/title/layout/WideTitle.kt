package com.sumizuri.app.feature.title.layout

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.chapter.ItemGap
import com.sumizuri.app.feature.title.chapter.chapterSection
import com.sumizuri.app.feature.title.chapter.rememberChapterListModel
import com.sumizuri.app.feature.title.chapter.rememberOpenSeason
import com.sumizuri.app.feature.title.info.AboutPanel
import com.sumizuri.app.feature.title.info.SourceNotice
import com.sumizuri.app.ui.kit.page.LoadStatus
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.scroll.mouseDragScroll
import com.sumizuri.app.ui.kit.scroll.scrollFrom
import com.sumizuri.app.ui.text.displayName
import kotlin.math.max

// The widest the page grows before it is centered, the same as in the Flutter app.
private val ContentWidth = 1100.dp

// The width of the details panel.
private val PanelWidth = 340.dp

// A cell of the chapter grid is about this wide.
private val CellWidth = 170.dp

// How far the cover reaches down past the banner, behind the first chapters.
private val BackdropExtra = 200.dp

// How far the page scrolls before the bar gets its backdrop.
private const val BarFade = 80f

// The height of the banner of the title opened last, and a likely height before any was opened.
private var lastBannerPx = 0
private val LikelyBanner = 420.dp

// The wide page. The banner runs across the top over the blurred cover, with the cover, the name, the buttons and the description. The chapters are under it on the left, and the details panel stands on their right, from the bottom of the banner. All of it is one scrolling page: the panel moves up with it until it reaches the bar, where it stays and scrolls on its own if it is longer than the window.
@Composable
internal fun WideTitle(
    state: TitleState,
    title: Title,
    calls: TitleCallbacks,
    onPreview: () -> Unit,
    onBackground: () -> Unit,
) {
    // The whole window scrolls the chapters, so the wheel and a finger work in the empty space around them too.
    val list = rememberLazyListState()
    var openSeason by rememberOpenSeason()
    val model = rememberChapterListModel(state, openSeason)
    val settled = rememberSettled()
    val bar = titleBarRoom()
    val density = LocalDensity.current
    val barPx = with(density) { bar.roundToPx() }
    val gapPx = with(density) { 8.dp.roundToPx() }
    // The height of the banner starts as it was on the last title, or a likely height, so the backdrop has its size on the first frame and is not laid out again when the banner is measured.
    var bannerPx by remember {
        mutableIntStateOf(lastBannerPx.takeIf { it > 0 } ?: with(density) { LikelyBanner.roundToPx() })
    }
    // How far the page has scrolled while the banner is in sight, and a great deal once it is out of it. Item offsets begin under the room of the bar.
    val scrolled by remember {
        derivedStateOf {
            list.layoutInfo.visibleItemsInfo
                .firstOrNull { it.index == 0 }
                ?.let { -it.offset } ?: Int.MAX_VALUE / 4
        }
    }
    // Where the bottom of the banner is on the screen, or the top of the room under the bar once it has gone.
    val panelTop by remember {
        derivedStateOf {
            max(
                barPx + gapPx,
                barPx + (
                    list.layoutInfo.visibleItemsInfo
                        .firstOrNull { it.index == 0 }
                        ?.let { it.offset + it.size } ?: 0
                    ),
            )
        }
    }
    val inset = PanelWidth + PageGutter * 2
    Box(Modifier.fillMaxSize().scrollFrom { list }) {
        TitleBackdrop(title, bar + with(density) { bannerPx.toDp() } + BackdropExtra, state.focus) { scrolled }
        BoxWithConstraints(Modifier.widthIn(max = ContentWidth).fillMaxSize().align(Alignment.TopCenter)) {
            val columns = maxOf(2, ((maxWidth - PageGutter * 2 - inset) / CellWidth).toInt())
            LazyColumn(
                Modifier.fillMaxSize().mouseDragScroll(list),
                state = list,
                contentPadding = titleListPadding(),
            ) {
                item(key = "banner") {
                    Box(
                        Modifier.padding(bottom = ItemGap).onSizeChanged {
                            bannerPx = it.height
                            lastBannerPx = it.height
                        },
                    ) { WideBanner(state, title, calls, onPreview, onBackground) }
                }
                item(key = "notices") {
                    Column(
                        Modifier.padding(end = inset - PageGutter, bottom = ItemGap),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        SourceNotice(state, calls)
                        LoadStatus(
                            false,
                            state.error,
                            calls.onRefresh,
                            onSolve = calls.onSolve.takeIf {
                                state.challengeUrl !=
                                    null
                            },
                        )
                    }
                }
                if (settled) {
                    chapterSection(
                        state,
                        calls,
                        model,
                        columns,
                        endInset = inset - PageGutter,
                        onSeason = { openSeason = it },
                    )
                } else {
                    chaptersWait()
                }
            }
            val panelTopDp = with(density) { panelTop.toDp() }
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .offset { IntOffset(0, panelTop) }
                    .width(PanelWidth + PageGutter)
                    .heightIn(max = (maxHeight - panelTopDp - 24.dp).coerceAtLeast(120.dp))
                    .verticalScroll(rememberScrollState())
                    .padding(end = PageGutter),
            ) {
                if (settled) AboutPanel(state, title, panel = true)
            }
        }
        if (state.selecting) {
            SelectionBar(
                state.selected.size,
                model.shown.size,
                calls.selection,
                Modifier.align(Alignment.TopCenter),
                calls.downloads,
            )
        } else {
            // The name of the title takes the place of the banner in the bar once the banner has scrolled out of sight.
            val named = scrolled > bannerPx - with(density) { 40.dp.roundToPx() }
            TitleBar(
                if (named) title.displayName() else "",
                (scrolled / BarFade).coerceIn(0f, 1f),
                calls.onBack,
                Modifier.align(Alignment.TopCenter),
            )
        }
    }
}
