package com.sumizuri.app.feature.reader

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraintsScope
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.reader.ReaderControls
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.data.model.reader.ReaderProgressBar
import com.sumizuri.app.data.text.numberText
import com.sumizuri.app.feature.reader.controls.DockPanel
import com.sumizuri.app.feature.reader.controls.PagePreview
import com.sumizuri.app.feature.reader.controls.ReaderIsland
import com.sumizuri.app.feature.reader.translate.NovelTranslator
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_latest
import com.sumizuri.app.shared.resources.reader_minutes_left
import com.sumizuri.app.shared.resources.reader_page_of
import com.sumizuri.app.shared.resources.reader_units_left
import com.sumizuri.app.ui.kit.dock.DockMargin
import com.sumizuri.app.ui.kit.dock.IslandWidth
import com.sumizuri.app.ui.kit.dock.WideIslandWidth
import com.sumizuri.app.ui.kit.dock.keepTaps
import com.sumizuri.app.ui.text.unitCount
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// From this width of room the island lays its rows out in one.
private val WideWidth = 840.dp

// How far from the edge the island must end to leave the track down the side clear of it, and how long the island takes to settle before the track measures it.
private val SideTrackClear = 64.dp
private const val SettleMs = 450L

// The least room the track down the side needs between the top and the dock. With less, such as under a tall panel, it steps away.
private val SideTrackLeast = 280.dp

// What the controls over the pages show and what their buttons do.
internal class ChromeCalls(
    val onBack: () -> Unit,
    val onBookmark: () -> Unit,
    val onOpenBrowser: (() -> Unit)?,
    val onPageMenu: (() -> Unit)?,
    val onComments: (() -> Unit)?,
    val onJump: (Int) -> Unit,
    val onOpenChapter: (Long) -> Unit,
    val onMode: (ReaderMode) -> Unit,
    val onLight: (Float, Float) -> Unit,
    val onLightDone: () -> Unit,
    val onAuto: () -> Unit,
    // The panel open in the island, a way to open or close one, and what each panel shows.
    val panel: DockPanel,
    val onPanel: (DockPanel) -> Unit,
    val panelContent: @Composable (DockPanel) -> Unit,
    // Brings the controls out, as a tap on the resting pill does, and puts them away again.
    val onShowControls: () -> Unit,
    val onHideControls: () -> Unit,
    // Makes a mode the default of every title without a mode of its own.
    val onDefaultMode: (ReaderMode) -> Unit,
    val preview: (Int) -> PagePreview?,
    // Translates the words of a novel, or null for a chapter of pictures.
    val translator: NovelTranslator? = null,
)

// The controls over the pages as one floating island at the bottom or the top that touches no edge of the screen, with an optional track down the side. With them hidden only a small page pill is left, when the person keeps it.
@Composable
internal fun BoxWithConstraintsScope.ReaderChrome(
    state: ReaderState,
    controls: Boolean,
    page: Int,
    total: Int,
    minutesLeft: Int?,
    bar: BarState,
    calls: ChromeCalls,
) {
    val settings = state.settings
    // Room as wide as a desktop gets the island in one row, so it covers less of the page.
    val wide = maxWidth >= WideWidth
    val style = settings.controls
    // A panel in the island takes at most a bit over half the height of the window, so the page and the top stay in sight.
    val panelMax = with(LocalDensity.current) { (LocalWindowInfo.current.containerSize.height * 0.58f).toDp() }
    // The number of a chapter of this title, for the buttons that open the one before and after.
    val numberOf: (Long?) -> String? = { id ->
        state.chapters
            .firstOrNull { it.id == id }
            ?.number
            ?.numberText()
    }
    // How many chapters come after this one, said under its name.
    val ahead = state.chapters.firstOrNull { it.id == state.chapterId }?.let { now ->
        state.chapters.count {
            it.number >
                now.number
        }
    }
    val chaptersLeft = when (ahead) {
        null -> null
        0 -> stringResource(Res.string.reader_latest)
        else -> stringResource(Res.string.reader_units_left, unitCount(state.kind, ahead))
    }
    // The minutes left in this chapter and the chapters left in the title, said after its name.
    val minutes = minutesLeft?.takeIf { it > 0 }?.let { stringResource(Res.string.reader_minutes_left, it) }
    val left = listOfNotNull(minutes, chaptersLeft).joinToString("  ·  ").ifEmpty { null }
    val density = LocalDensity.current
    // How much of the height the island takes now, and once it has settled with no panel open.
    var islandRoom by remember { mutableStateOf(0.dp) }
    var restRoom by remember { mutableStateOf(0.dp) }
    val noPanel = calls.panel == DockPanel.None
    LaunchedEffect(controls, noPanel, maxWidth, maxHeight) {
        if (!controls || !noPanel) return@LaunchedEffect
        delay(SettleMs)
        restRoom = islandRoom
    }
    val bottom = style == ReaderControls.Island
    // The island sits in the middle and grows only so wide, so on a wide window the track at the edge is clear of it.
    val islandWidth = minOf(maxWidth - DockMargin * 2, if (wide) WideIslandWidth else IslandWidth)
    val clear = (maxWidth - islandWidth) / 2 >= SideTrackClear
    // The track keeps one place: full height when the island is clear of it, else in the room the settled island leaves. A panel that grows the island over it fades it out instead of pushing it up.
    val room = if (clear) 0.dp else restRoom
    val covered = !clear && islandRoom > restRoom + 1.dp
    val sideMost = maxHeight * 0.62f
    AnimatedVisibility(
        controls &&
            settings.progressBar == ReaderProgressBar.Vertical &&
            (clear || restRoom > 0.dp) &&
            !covered &&
            maxHeight - room >= SideTrackLeast,
        Modifier
            .align(Alignment.TopEnd)
            .padding(top = if (bottom) 0.dp else room, bottom = if (bottom) room else 0.dp)
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Vertical + WindowInsetsSides.End))
            .padding(end = 8.dp),
        enter = fadeIn(),
        exit = fadeOut(),
    ) {
        Box(Modifier.fillMaxHeight(), contentAlignment = Alignment.Center) {
            SideTrack(
                page,
                total,
                SideChapter(state.previousId, numberOf(state.previousId)),
                SideChapter(state.nextId, numberOf(state.nextId)),
                calls,
                Modifier
                    .heightIn(max = sideMost)
                    .fillMaxHeight()
                    .padding(vertical = 8.dp)
                    .keepTaps(),
            )
        }
    }
    // The island is always there and changes its own shape: the full island with the controls, a small pill with the page while they rest.
    val resting = if (settings.pageNumber && total > 1 &&
        !bar.auto
    ) {
        stringResource(Res.string.reader_page_of, page + 1, total)
    } else {
        null
    }
    ReaderIsland(
        state = state,
        calls = calls,
        page = page,
        total = total,
        bar = bar,
        previousLabel = numberOf(state.previousId),
        nextLabel = numberOf(state.nextId),
        left = left,
        expanded = controls,
        resting = resting,
        wide = wide,
        bottom = bottom,
        slider = settings.progressBar == ReaderProgressBar.Horizontal,
        panelMax = panelMax,
        shade = settings.controlShade,
        defaultMode = settings.mode,
        modifier = Modifier
            .align(if (bottom) Alignment.BottomCenter else Alignment.TopCenter)
            .onSizeChanged { islandRoom = with(density) { it.height.toDp() } },
    )
}
