package com.sumizuri.app.feature.reader.controls

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.SkipNext
import androidx.compose.material.icons.outlined.SkipPrevious
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.feature.reader.BarState
import com.sumizuri.app.feature.reader.ChromeCalls
import com.sumizuri.app.feature.reader.ReaderState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_next_chapter
import com.sumizuri.app.shared.resources.reader_previous_chapter
import com.sumizuri.app.ui.kit.dock.DockMargin
import com.sumizuri.app.ui.kit.dock.IslandActionWidth
import com.sumizuri.app.ui.kit.dock.IslandCorner
import com.sumizuri.app.ui.kit.dock.IslandHang
import com.sumizuri.app.ui.kit.dock.IslandInside
import com.sumizuri.app.ui.kit.dock.IslandSurface
import com.sumizuri.app.ui.kit.dock.IslandWidth
import com.sumizuri.app.ui.kit.dock.LocalDockLabels
import com.sumizuri.app.ui.kit.dock.WideIslandWidth
import com.sumizuri.app.ui.kit.dock.cascade
import com.sumizuri.app.ui.kit.dock.islandMorph
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource

// How round the resting pill is.
private val PillCorner = 18.dp

// Every control of the reader in one island at the bottom of the screen, or at the top when the person picks that. At rest it is a small pill with the page and a thin line of how far the chapter is read. Opening it, the pill grows into the island with a soft bounce, a ring of ink spreads out from it once, and its rows slide in one after another. On a phone the island holds the chapter, the track and the actions in three rows and a panel opens inside it on the side away from the edge. On a wide window they sit in one row and a panel hangs from its end.
@Composable
internal fun ReaderIsland(
    state: ReaderState,
    calls: ChromeCalls,
    page: Int,
    total: Int,
    bar: BarState,
    previousLabel: String?,
    nextLabel: String?,
    left: String?,
    expanded: Boolean,
    resting: String?,
    wide: Boolean,
    bottom: Boolean,
    // False when the slider runs down the side of the screen instead, so the island leaves out its track.
    slider: Boolean,
    panelMax: Dp,
    shade: Float,
    defaultMode: ReaderMode,
    modifier: Modifier = Modifier,
) {
    val reduce = LocalReduceMotion.current
    val panel = calls.panel
    fun toggle(which: DockPanel) = calls.onPanel(if (panel == which) DockPanel.None else which)

    // The rows slide in starting from the one nearest the edge the island sits on.
    fun order(row: Int) = if (bottom) 2 - row else row
    val body: @Composable (DockPanel) -> Unit = { shown -> IslandPanelBody(shown, bar, calls, defaultMode) }
    val track: @Composable (Modifier) -> Unit = { look ->
        Row(look, verticalAlignment = Alignment.CenterVertically) {
            ChapterEnd(
                Icons.Outlined.SkipPrevious,
                stringResource(Res.string.reader_previous_chapter),
                previousLabel,
                state.previousId,
                calls.onOpenChapter,
            )
            if (total > 1) {
                PageTrack(
                    page,
                    total,
                    vertical = false,
                    calls.preview,
                    calls.onJump,
                    Modifier.weight(1f),
                    tagged = true,
                )
            } else {
                Spacer(Modifier.weight(1f))
            }
            ChapterEnd(
                Icons.Outlined.SkipNext,
                stringResource(Res.string.reader_next_chapter),
                nextLabel,
                state.nextId,
                calls.onOpenChapter,
            )
        }
    }
    val head: @Composable (Modifier) -> Unit = { look ->
        ReaderTopBar(
            state,
            calls.onBack,
            calls.onBookmark,
            calls.onOpenBrowser,
            calls.onPageMenu,
            look,
            onComments = calls.onComments,
            left = left,
            translator = calls.translator,
        )
    }
    val edge = if (bottom) WindowInsetsSides.Bottom else WindowInsetsSides.Top
    Box(
        modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.safeDrawing.only(edge + WindowInsetsSides.Horizontal))
            .padding(DockMargin),
        contentAlignment = if (bottom) Alignment.BottomCenter else Alignment.TopCenter,
    ) {
        Column(
            Modifier.widthIn(max = if (wide) WideIslandWidth else IslandWidth).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (wide &&
                bottom
            ) {
                IslandHang(if (expanded) panel else DockPanel.None, DockPanel.None, true, panelMax, body)
            }
            AnimatedVisibility(
                expanded || resting != null,
                enter = if (reduce) {
                    fadeIn(tween(150))
                } else {
                    fadeIn(tween(160)) + slideInVertically(spring(0.8f, 420f)) { if (bottom) it / 2 else -it / 2 }
                },
                exit = if (reduce) {
                    fadeOut(tween(120))
                } else {
                    fadeOut(tween(120)) + slideOutVertically(tween(140)) { if (bottom) it / 3 else -it / 3 }
                },
            ) {
                val corner by animateDpAsState(if (expanded) IslandCorner else PillCorner, label = "island corner")
                // Solid while a panel is open inside it, so its words never sit over the page.
                val solid = panel != DockPanel.None && !wide && expanded
                IslandSurface(expanded, shade, corner = corner, solid = solid) {
                    AnimatedContent(
                        expanded,
                        transitionSpec = { islandMorph(reduce) },
                        contentAlignment = if (bottom) Alignment.BottomCenter else Alignment.TopCenter,
                        label = "island",
                    ) { open ->
                        when {
                            !open -> IslandPill(page, total, resting.orEmpty(), calls.onShowControls)

                            wide -> CompositionLocalProvider(LocalDockLabels provides false) {
                                Row(
                                    Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 2.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    head(Modifier.weight(1f).cascade(0, reduce, bottom))
                                    if (slider) track(Modifier.weight(1.1f).cascade(1, reduce, bottom))
                                    Row(
                                        Modifier
                                            .width(
                                                IslandActionWidth * (if (bar.canAuto) 5 else 4),
                                            ).cascade(2, reduce, bottom),
                                    ) {
                                        ReaderActions(bar, panel, ::toggle, calls.onAuto)
                                    }
                                }
                            }

                            else -> Column(Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 4.dp)) {
                                if (bottom) IslandInside(panel, DockPanel.None, true, panelMax, body)
                                head(Modifier.cascade(order(0), reduce, bottom))
                                if (slider) track(Modifier.fillMaxWidth().cascade(order(1), reduce, bottom))
                                CompositionLocalProvider(LocalDockLabels provides true) {
                                    Row(
                                        Modifier
                                            .fillMaxWidth()
                                            .padding(
                                                vertical = 2.dp,
                                            ).cascade(order(2), reduce, bottom),
                                    ) {
                                        ReaderActions(bar, panel, ::toggle, calls.onAuto)
                                    }
                                }
                                if (!bottom) IslandInside(panel, DockPanel.None, false, panelMax, body)
                            }
                        }
                    }
                }
            }
            if (wide &&
                !bottom
            ) {
                IslandHang(if (expanded) panel else DockPanel.None, DockPanel.None, false, panelMax, body)
            }
        }
    }
}

// What a panel of the island shows: the light and the modes are drawn here, every other panel by the reader.
@Composable
private fun IslandPanelBody(shown: DockPanel, bar: BarState, calls: ChromeCalls, defaultMode: ReaderMode) {
    when (shown) {
        DockPanel.Light -> LightPanel(bar.dim, bar.warmth, calls.onLight, calls.onLightDone)

        DockPanel.Mode -> ModePanel(
            bar,
            defaultMode,
            calls.onDefaultMode,
            onClose = { calls.onPanel(DockPanel.None) },
        ) {
            calls.onPanel(DockPanel.None)
            calls.onMode(it)
        }

        else -> calls.panelContent(shown)
    }
}

// The resting island: the page and the count with a thin line under them of how far the chapter is read. A tap opens it.
@Composable
private fun IslandPill(page: Int, total: Int, text: String, onOpen: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val share = if (total > 1) (page + 1).toFloat() / total else 1f
    Column(
        Modifier.clickable(onClickLabel = text, onClick = onOpen).padding(horizontal = 16.dp, vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
            color = colors.onSurface,
        )
        Box(
            Modifier
                .padding(top = 4.dp)
                .width(56.dp)
                .height(2.dp)
                .clip(CircleShape)
                .background(colors.outlineVariant),
        ) {
            Box(Modifier.fillMaxHeight().fillMaxWidth(share).background(colors.primary))
        }
    }
}
