package com.sumizuri.app.feature.reader.controls

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.SkipNext
import androidx.compose.material.icons.outlined.SkipPrevious
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.feature.reader.BarState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.manga_group_mode
import com.sumizuri.app.shared.resources.reader_mode_default
import com.sumizuri.app.shared.resources.reader_mode_make_default
import com.sumizuri.app.shared.resources.reader_mode_this_title
import com.sumizuri.app.shared.resources.reader_next_chapter
import com.sumizuri.app.shared.resources.reader_previous_chapter
import com.sumizuri.app.ui.kit.dock.DockMargin
import com.sumizuri.app.ui.kit.dock.DockRule
import com.sumizuri.app.ui.kit.dock.DockShape
import com.sumizuri.app.ui.kit.dock.LocalDockLabels
import com.sumizuri.app.ui.kit.dock.PanelHead
import com.sumizuri.app.ui.kit.dock.dockEnter
import com.sumizuri.app.ui.kit.dock.dockExit
import com.sumizuri.app.ui.kit.dock.dockMorph
import com.sumizuri.app.ui.kit.dock.keepTaps
import com.sumizuri.app.ui.kit.dock.panelChange
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource

// How wide the dock grows while the actions of a page are open, and how wide the window must be before they sit beside the picture with the track.
private val PageMenuWidth = 960.dp
private val PageBesideWidth = 840.dp

// How wide the window must be before the buttons of the dock show their names.
private val NamedWidth = 400.dp

// The room one action takes in the one row dock of a wide window, and the widest a panel opens in it.
private val ActionWidth = 76.dp
private val RowPanelWidth = 640.dp

// How wide the button to the chapter before or after is at an end of the row.
private val ChapterEndWidth = 48.dp

// The track of the dock, given to the panel of a page that draws it beside its picture on a wide dock, or null when the dock draws it itself.
internal val LocalDockTrack = compositionLocalOf<(@Composable () -> Unit)?> { null }

// The bottom of the reader as one floating dock that touches no edge of the screen, so the page shows all around it. A thin track runs across its top with the page and the count riding on the thumb, and under it one row holds the actions between the chapter before and the chapter after. A wide window puts all of it in one row. The light, the settings, the chapters, the actions of a page and the meaning of a word open inside the dock above the track, which grows to hold them, so the reader needs no sheets.
@Composable
fun ReaderBottomBar(
    page: Int,
    total: Int,
    slider: Boolean,
    bar: BarState,
    previousId: Long?,
    nextId: Long?,
    // The numbers of the chapter before and after, shown beside their arrows.
    previousLabel: String?,
    nextLabel: String?,
    // Whether the row of small page pictures shows over the track.
    strip: Boolean,
    // How solid the dock is, from see through to fully solid.
    shade: Float,
    // The widest the dock grows on a big window.
    maxWidth: Dp,
    // On a wide window the track and the actions sit side by side in one row, so the dock covers less of the page.
    oneRow: Boolean = false,
    // False when the open panel shows docked at the side of a wide window instead of in the dock.
    panelInDock: Boolean = true,
    preview: (Int) -> PagePreview?,
    onJump: (Int) -> Unit,
    onOpenChapter: (Long) -> Unit,
    onMode: (ReaderMode) -> Unit,
    onLight: (dim: Float, warmth: Float) -> Unit,
    onLightDone: () -> Unit,
    onAuto: () -> Unit,
    // The panel the dock holds open over its track, the most room it may take, and what the settings, the chapters, a page or a word show in it.
    panel: DockPanel,
    onPanel: (DockPanel) -> Unit,
    panelMax: Dp,
    panelContent: @Composable (DockPanel) -> Unit,
    // Whether the whole dock is out, and what it shrinks to while the controls are hidden: a small pill with the page, or nothing when that is null.
    expanded: Boolean,
    collapsed: String?,
    onExpand: () -> Unit,
    // The mode of titles without a mode of their own, and a way to change it from the panel of modes.
    defaultMode: ReaderMode,
    onDefaultMode: (ReaderMode) -> Unit,
    modifier: Modifier = Modifier,
) {
    fun toggle(which: DockPanel) = onPanel(if (panel == which) DockPanel.None else which)
    val reduce = LocalReduceMotion.current
    val colors = MaterialTheme.colorScheme
    // With the track down the side, the chapter buttons and the page go with it, and only the actions stay in the dock.
    val side = !slider && total > 1
    val windowWidth = with(LocalDensity.current) { LocalWindowInfo.current.containerSize.width.toDp() }
    Box(
        modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom + WindowInsetsSides.Horizontal))
            .padding(DockMargin),
        contentAlignment = Alignment.BottomCenter,
    ) {
        // The dock is one surface that changes its shape: the full dock while the controls are out, a small pill with the page while they rest, and gone when no pill is kept.
        AnimatedVisibility(expanded || collapsed != null, enter = dockEnter(fromTop = false, reduce), exit = dockExit(fromTop = false, reduce)) {
        // The dock grows wider while the actions of a page are open, so they fit in one row beside the picture on a big screen.
        val widest by animateDpAsState(if (panel == DockPanel.Page) maxOf(maxWidth, PageMenuWidth) else maxWidth, label = "dock width")
        Surface(
            Modifier.widthIn(max = widest).keepTaps(),
            shape = DockShape,
            // Solid while a panel is open, so its words never sit over the page.
            color = colors.surfaceContainerHigh.copy(alpha = if (panel == DockPanel.None || !panelInDock) shade else 1f),
            border = BorderStroke(1.dp, colors.outlineVariant.copy(alpha = 0.5f)),
        ) {
          AnimatedContent(expanded, transitionSpec = { dockMorph(reduce) }, label = "dock shape") { open ->
            if (!open) {
                Text(
                    collapsed.orEmpty(),
                    Modifier.clickable(onClickLabel = collapsed, onClick = onExpand).padding(horizontal = 14.dp, vertical = 5.dp),
                    style = MaterialTheme.typography.labelMedium,
                    color = colors.onSurface,
                )
                return@AnimatedContent
            }
            Box {
            // On a wide window the actions of a page take the track into their own panel, beside the picture of the page. The window is measured, as the dock itself changes its size while it opens.
            val pageBeside = panel == DockPanel.Page && windowWidth >= PageBesideWidth
            // The track alone across the dock, its thumb a tag with the page and the count.
            val track: @Composable () -> Unit = {
                if (total > 1) PageTrack(page, total, vertical = false, preview, onJump, Modifier.fillMaxWidth(), tagged = true)
            }
            // The chapter before and after, at the two ends of the row of actions.
            val before: @Composable () -> Unit = {
                ChapterEnd(Icons.Outlined.SkipPrevious, stringResource(Res.string.reader_previous_chapter), previousLabel, previousId, onOpenChapter)
            }
            val after: @Composable () -> Unit = {
                ChapterEnd(Icons.Outlined.SkipNext, stringResource(Res.string.reader_next_chapter), nextLabel, nextId, onOpenChapter)
            }
            Column(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 6.dp)) {
                // The open panel grows out of the dock above the track, and a new one fades in where the last one was.
                AnimatedContent(
                    if (panelInDock) panel else DockPanel.None,
                    transitionSpec = { panelChange(reduce, DockPanel.None) },
                    label = "dock panel",
                ) { shown ->
                    if (shown != DockPanel.None) {
                        Column {
                            Box(
                                Modifier
                                    .heightIn(max = panelMax)
                                    .then(if (oneRow && shown != DockPanel.Page) Modifier.widthIn(max = RowPanelWidth).align(Alignment.CenterHorizontally) else Modifier),
                            ) {
                                when (shown) {
                                    DockPanel.Light -> LightPanel(bar.dim, bar.warmth, onLight, onLightDone)

                                    DockPanel.Mode -> ModePanel(bar, defaultMode, onDefaultMode, onClose = { onPanel(DockPanel.None) }) {
                                        onPanel(DockPanel.None)
                                        onMode(it)
                                    }

                                    else -> CompositionLocalProvider(LocalDockTrack provides if (pageBeside && !side) track else null) { panelContent(shown) }
                                }
                            }
                            DockRule()
                        }
                    }
                }
                if (strip && !side && total > 1 && preview(page) != null) {
                    PageStrip(page, total, preview, onJump, Modifier.padding(horizontal = 4.dp, vertical = 6.dp))
                }
                if (oneRow) {
                    CompositionLocalProvider(LocalDockLabels provides true) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (!side) before()
                            if (!side && !pageBeside) Box(Modifier.weight(1f).padding(horizontal = 8.dp)) { track() } else Spacer(Modifier.weight(1f))
                            Row(Modifier.width(ActionWidth * (if (bar.canAuto) 5 else 4))) { ReaderActions(bar, panel, ::toggle, onAuto) }
                            if (!side) after()
                        }
                    }
                } else {
                if (!side && !pageBeside) track()
                // The buttons show their names under their icons where the screen has the room, so none of them needs a guess. A small phone keeps the icons alone, as the names would break.
                CompositionLocalProvider(LocalDockLabels provides (windowWidth >= NamedWidth)) {
                Row(Modifier.fillMaxWidth().padding(vertical = 2.dp), verticalAlignment = Alignment.CenterVertically) {
                    if (!side) before()
                    ReaderActions(bar, panel, ::toggle, onAuto)
                    if (!side) after()
                }
                }
                }
            }
            }
          }
        }
        }
    }
}

// The chapter before or after at an end of the row of actions, in the look of an action: the arrow, and the number of the chapter under it where the actions show their names. Faded when there is none.
@Composable
private fun ChapterEnd(icon: ImageVector, label: String, number: String?, target: Long?, onOpenChapter: (Long) -> Unit) {
    val enabled = target != null
    val named = LocalDockLabels.current
    val tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = if (enabled) 1f else 0.3f)
    Column(
        Modifier
            .width(ChapterEndWidth)
            .clip(MaterialTheme.shapes.medium)
            .clickable(enabled = enabled, role = Role.Button, onClickLabel = label) { target?.let(onOpenChapter) }
            .padding(vertical = if (named) 4.dp else 0.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(Modifier.height(if (named) 32.dp else 38.dp), contentAlignment = Alignment.Center) {
            Icon(icon, label, Modifier.size(22.dp), tint = tint)
        }
        if (named) Text(number.orEmpty(), Modifier.padding(top = 2.dp), style = MaterialTheme.typography.labelSmall, color = tint, maxLines = 1)
    }
}

// The ways to read as a panel of the dock. A mode picked here is kept for this title, which the line under the head says. The mode every other title opens in carries a small tag, and a button makes the mode of this title that default too, so the mode has one place and not two.
@Composable
internal fun ModePanel(bar: BarState, defaultMode: ReaderMode, onDefaultMode: (ReaderMode) -> Unit, onClose: () -> Unit, onMode: (ReaderMode) -> Unit) {
    val colors = MaterialTheme.colorScheme
    // Words read in pages under every mode but the scroll, so a mode stands for the row it falls under.
    fun row(mode: ReaderMode) = if (bar.textual && mode != ReaderMode.Continuous) ReaderMode.LeftToRight else mode
    Column {
        PanelHead(stringResource(Res.string.manga_group_mode), onClose)
        Text(
            stringResource(Res.string.reader_mode_this_title),
            Modifier.padding(start = 10.dp, bottom = 4.dp),
            style = MaterialTheme.typography.bodySmall,
            color = colors.onSurfaceVariant,
        )
        val modes = if (bar.textual) listOf(ReaderMode.LeftToRight, ReaderMode.Continuous) else ReaderMode.entries
        for (mode in modes) {
            val chosen = mode == row(bar.mode)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(if (chosen) colors.secondaryContainer else Color.Transparent)
                    .clickable(role = Role.RadioButton) { onMode(mode) }
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Icon(mode.icon(), null, tint = if (chosen) colors.onSecondaryContainer else colors.onSurfaceVariant)
                Text(
                    stringResource(mode.labelFor(bar.textual)),
                    Modifier.weight(1f),
                    color = if (chosen) colors.onSecondaryContainer else colors.onSurface,
                    fontWeight = if (chosen) FontWeight.SemiBold else FontWeight.Normal,
                )
                if (mode == row(defaultMode)) {
                    Text(
                        stringResource(Res.string.reader_mode_default),
                        Modifier.background(colors.surfaceContainerHighest, CircleShape).padding(horizontal = 8.dp, vertical = 2.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.onSurfaceVariant,
                    )
                }
                if (chosen) Icon(Icons.Outlined.Check, null, tint = colors.primary)
            }
        }
        if (row(bar.mode) != row(defaultMode)) {
            TextButton({ onDefaultMode(bar.mode) }, Modifier.align(Alignment.End)) {
                Text(stringResource(Res.string.reader_mode_make_default))
            }
        }
    }
}
