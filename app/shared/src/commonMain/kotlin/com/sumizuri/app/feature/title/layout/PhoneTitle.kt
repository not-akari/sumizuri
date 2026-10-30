package com.sumizuri.app.feature.title.layout

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.chapter.ItemGap
import com.sumizuri.app.feature.title.chapter.chapterSection
import com.sumizuri.app.feature.title.chapter.rememberChapterListModel
import com.sumizuri.app.feature.title.chapter.rememberOpenSeason
import com.sumizuri.app.feature.title.chapter.spotText
import com.sumizuri.app.feature.title.info.AboutPanel
import com.sumizuri.app.feature.title.info.ContinueButton
import com.sumizuri.app.feature.title.info.PosterActions
import com.sumizuri.app.feature.title.info.SourceNotice
import com.sumizuri.app.feature.title.info.TitleHeading
import com.sumizuri.app.feature.title.info.TitleSummary
import com.sumizuri.app.feature.title.info.UnreachableActions
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.title_continue_next
import com.sumizuri.app.ui.kit.page.LoadStatus
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.scroll.mouseDragScroll
import com.sumizuri.app.ui.motion.LocalPageMotion
import com.sumizuri.app.ui.motion.Rise
import com.sumizuri.app.ui.text.displayName
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// How far down the screen the cover reaches, and how much of it shows before the page starts over it. The cover is the backdrop of the page, so a good part of it shows above the name and the buttons.
private const val Reach = 0.68f
private const val StartAt = 0.50f

// Where the tabs are in the list, after the room for the cover and the banner.
private const val TabsAt = 2

// A cell of the chapter grid is about this wide.
private val CellWidth = 150.dp

// The phone page. The cover fills the top behind everything, and the name, the buttons, the tabs and the chapters scroll up over it. The tabs stay under the top bar.
@Composable
internal fun PhoneTitle(
    state: TitleState,
    title: Title,
    calls: TitleCallbacks,
    height: Dp,
    onPreview: () -> Unit,
    onBackground: () -> Unit,
) {
    val list = rememberLazyListState()
    var tab by rememberSaveable { mutableStateOf(TitleTab.Chapters) }
    val settled = rememberSettled()
    var openSeason by rememberOpenSeason()
    val model = rememberChapterListModel(state, openSeason)
    val reach = height * Reach
    val bar = titleBarRoom()
    val scroll by remember {
        derivedStateOf {
            if (list.firstVisibleItemIndex ==
                0
            ) {
                list.firstVisibleItemScrollOffset
            } else {
                Int.MAX_VALUE / 4
            }
        }
    }
    // The tabs are pinned once the page has scrolled them up to the bar.
    val stuck by remember {
        derivedStateOf {
            val tabs = list.layoutInfo.visibleItemsInfo.firstOrNull { it.key == "tabs" }
            if (tabs != null) tabs.offset <= 0 else list.firstVisibleItemIndex > TabsAt
        }
    }
    // A tab picked from the pinned copy starts at its top, where it used to open as far down as the list was.
    val scope = rememberCoroutineScope()
    val pick: (TitleTab) -> Unit = { picked ->
        if (stuck) scope.launch { list.scrollToItem(TabsAt) }
        tab = picked
    }
    val barAt = with(LocalDensity.current) { (reach * 0.6f).toPx() }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val columns = maxOf(2, ((maxWidth - PageGutter * 2) / CellWidth).toInt())
        TitleCoverBehind(title, reach, state.focus) { scroll }
        LazyColumn(
            Modifier.fillMaxSize().mouseDragScroll(list),
            state = list,
            contentPadding = titleListPadding(),
        ) {
            // The cover is the background of the page, so a tap on the room where it shows opens it in full.
            item(key = "cover-room") {
                Spacer(
                    Modifier
                        .fillMaxWidth()
                        .height(
                            (reach * StartAt - bar).coerceAtLeast(0.dp),
                        ).clickable(
                            interactionSource = remember {
                                MutableInteractionSource()
                            },
                            indication = null,
                            onClick = onPreview,
                        ),
                )
            }
            item(key = "banner") {
                Column(Modifier.padding(bottom = ItemGap), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    // The name sits over the cover, so a tap on it opens the cover in full.
                    TitleHeading(state, title, wide = false, onClick = onPreview)
                    if (state.readable) {
                        ContinueButton(
                            state.target,
                            title.kind,
                            calls.onContinue,
                        )
                    } else {
                        UnreachableActions(state, title, calls)
                    }
                    PosterActions(state, title, calls, onBackground)
                    if (title.summary.isNotBlank()) TitleSummary(title.summary, onMore = { tab = TitleTab.About })
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
            item(key = "tabs") {
                PhoneTabs(tab, pick, title.kind, state.counted.size, stuck = false, Modifier.padding(bottom = ItemGap))
            }
            when (tab) {
                TitleTab.Chapters -> if (settled) {
                    chapterSection(state, calls, model, columns, onSeason = {
                        openSeason =
                            it
                    })
                } else {
                    chaptersWait()
                }

                TitleTab.About -> item(key = "about") { AboutPanel(state, title, panel = false) }
            }
        }
        // A copy of the tabs under the bar, over the list, once the real ones have scrolled away.
        if (stuck) {
            PhoneTabs(
                tab,
                pick,
                title.kind,
                state.counted.size,
                stuck = true,
                Modifier.align(Alignment.TopCenter).padding(top = bar),
            )
        }
        // Once the continue button has scrolled away with the banner, a smaller one waits at the bottom, so going on never needs a scroll back up.
        val target = state.target
        Rise(
            stuck && state.readable && target != null && !state.selecting,
            Modifier.align(Alignment.BottomEnd).windowInsetsPadding(WindowInsets.navigationBars).padding(16.dp),
        ) {
            if (target != null) {
                ExtendedFloatingActionButton(
                    onClick = { calls.onContinue(target.id) },
                    icon = { Icon(Icons.Outlined.PlayArrow, null) },
                    text = {
                        Text(
                            stringResource(
                                Res.string.title_continue_next,
                                spotText(title.kind, target.number, target.season),
                            ),
                        )
                    },
                )
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
            TitleBar(
                title.displayName(),
                (scroll / barAt).coerceIn(0f, 1f),
                calls.onBack,
                Modifier.align(Alignment.TopCenter),
            )
        }
    }
}
