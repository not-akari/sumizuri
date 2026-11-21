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
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.chapter.GroupGap
import com.sumizuri.app.feature.title.chapter.chapterSection
import com.sumizuri.app.feature.title.chapter.rememberChapterListModel
import com.sumizuri.app.feature.title.chapter.rememberOpenSeason
import com.sumizuri.app.feature.title.chapter.spotText
import com.sumizuri.app.feature.title.info.ContinueBlock
import com.sumizuri.app.feature.title.info.SourceNotice
import com.sumizuri.app.feature.title.info.TitleHeading
import com.sumizuri.app.feature.title.info.TitleSummary
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.title_continue_next
import com.sumizuri.app.ui.kit.page.LoadStatus
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.scroll.mouseDragScroll
import com.sumizuri.app.ui.motion.Rise
import com.sumizuri.app.ui.text.displayName
import org.jetbrains.compose.resources.stringResource

// How far down the screen the cover reaches, and how much of it shows before the page starts over it. The cover is the backdrop of the page, so a good part of it shows above the name and the buttons.
private const val Reach = 0.68f
private const val StartAt = 0.50f

// A cell of the chapter grid is about this wide.
private val CellWidth = 150.dp

// The phone page, laid out like the page on a computer. The cover fills the top behind everything, and the name, the facts, the buttons and the chapters scroll up over it.
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
    // Once the name and the buttons have scrolled away, a small continue button waits at the bottom.
    val past by remember { derivedStateOf { list.firstVisibleItemIndex > 1 } }
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
                // The top falls into groups with room between them: the name, the story, then the continue card with the actions close under it.
                Column(Modifier.padding(bottom = GroupGap), verticalArrangement = Arrangement.spacedBy(GroupGap)) {
                    // The name sits over the cover, so a tap on it opens the cover in full.
                    TitleHeading(state, title, wide = false, onClick = onPreview)
                    // The story, two lines until More shows all of it.
                    if (title.summary.isNotBlank()) TitleSummary(title.summary, lines = 2, overCover = true)
                    ContinueBlock(state, title, calls)
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
                chapterSection(state, calls, model, columns, onSeason = { openSeason = it })
            } else {
                chaptersWait()
            }
        }
        // Once the continue button has scrolled away with the banner, a smaller one waits at the bottom, so going on never needs a scroll back up.
        val target = state.target
        Rise(
            past && state.readable && target != null && !state.selecting,
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
            ) { shade -> TitleBarActions(state, title, calls, onBackground, shade) }
        }
    }
}
