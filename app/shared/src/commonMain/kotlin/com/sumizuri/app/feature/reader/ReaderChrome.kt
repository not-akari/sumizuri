package com.sumizuri.app.feature.reader

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraintsScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.KeyboardDoubleArrowDown
import androidx.compose.material.icons.outlined.KeyboardDoubleArrowUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.data.model.reader.ReaderProgressBar
import com.sumizuri.app.data.text.numberText
import com.sumizuri.app.feature.reader.controls.DockPanel
import com.sumizuri.app.feature.reader.controls.PagePreview
import com.sumizuri.app.feature.reader.controls.PageTrack
import com.sumizuri.app.feature.reader.controls.ReaderBottomBar
import com.sumizuri.app.feature.reader.controls.ReaderTopBar
import com.sumizuri.app.feature.reader.translate.NovelTranslator
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_latest
import com.sumizuri.app.shared.resources.reader_minutes_left
import com.sumizuri.app.shared.resources.reader_next_chapter
import com.sumizuri.app.shared.resources.reader_page_of
import com.sumizuri.app.shared.resources.reader_previous_chapter
import com.sumizuri.app.shared.resources.reader_units_left
import com.sumizuri.app.ui.kit.dock.DockMargin
import com.sumizuri.app.ui.kit.dock.DockShape
import com.sumizuri.app.ui.kit.dock.LocalAsideDock
import com.sumizuri.app.ui.kit.dock.dockEnter
import com.sumizuri.app.ui.kit.dock.dockExit
import com.sumizuri.app.ui.kit.dock.tellsAsideCard
import com.sumizuri.app.ui.text.unitCount
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource

// The widest the controls at the top and the bottom grow on a big window.
private val BarWidth = 640.dp

// From this width of room the dock lays the track and the actions in one row, and how wide it and the top grow then.
private val WideWidth = 840.dp
private val WideBarWidth = 1100.dp

// The least room the track down the side needs between the top and the dock. With less, such as under a tall panel, it steps away.
private val SideTrackLeast = 280.dp

// How far from the right edge a card above the dock must end to leave the track down the side clear.
private val SideTrackClear = 64.dp

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
    // The panel open in the dock, a way to open or close one, and what each panel shows.
    val panel: DockPanel,
    val onPanel: (DockPanel) -> Unit,
    val panelContent: @Composable (DockPanel) -> Unit,
    // Brings the controls out, as a tap on the resting pill does.
    val onShowControls: () -> Unit,
    // Makes a mode the default of every title without a mode of its own.
    val onDefaultMode: (ReaderMode) -> Unit,
    val preview: (Int) -> PagePreview?,
    // Translates the words of a novel, or null for a chapter of pictures.
    val translator: NovelTranslator? = null,
    // Whether the open panel shows docked at the side of a wide window, so the dock leaves it out.
    val panelAside: Boolean = false,
)

// The controls over the pages as two floating pieces in the colors of the theme that touch no edge of the screen: a capsule at the top with the chapter, and a dock at the bottom with the track and the actions. With them hidden only a small page number is left at the bottom, when the person keeps it.
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
    val reduce = LocalReduceMotion.current
    // Room as wide as a desktop gets the same pieces laid out wider and lower, so they cover less of the page.
    val wide = maxWidth >= WideWidth
    // How wide the dock is, which an open card at the bottom right is told so it sits beside the dock or above it.
    val dockWidth = minOf(
        if (wide &&
            settings.progressBar == ReaderProgressBar.Horizontal
        ) {
            WideBarWidth
        } else {
            BarWidth
        },
        maxWidth - DockMargin * 2,
    )
    // A panel in the dock takes at most a bit over half the height of the window, so the page and the top stay in sight.
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
    // The bars and pills in the container color of the theme, as solid as the person chose, with clear edges and no fade.
    val fill = MaterialTheme.colorScheme.surfaceContainer.copy(alpha = settings.controlShade)
    // How much of the height the capsule at the top and the dock at the bottom take, so the track down the side fits between them as the dock grows.
    val density = LocalDensity.current
    var topRoom by remember { mutableStateOf(0.dp) }
    var dockRoom by remember { mutableStateOf(0.dp) }
    AnimatedVisibility(
        controls,
        Modifier.align(Alignment.TopCenter).fillMaxWidth(),
        enter = dockEnter(fromTop = true, reduce),
        exit = dockExit(fromTop = true, reduce),
    ) {
        // A capsule that floats clear of the edges of the screen, the same as the dock at the bottom.
        Box(
            Modifier
                .fillMaxWidth()
                .onSizeChanged { topRoom = with(density) { it.height.toDp() } }
                .windowInsetsPadding(
                    WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal),
                ).padding(DockMargin),
            contentAlignment = Alignment.TopCenter,
        ) {
            Surface(
                Modifier.widthIn(max = if (wide) WideBarWidth else BarWidth).fillMaxWidth().keepTaps(),
                shape = DockShape,
                color = MaterialTheme.colorScheme.surfaceContainerHigh.copy(alpha = settings.controlShade),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
            ) {
                ReaderTopBar(
                    state,
                    calls.onBack,
                    calls.onBookmark,
                    calls.onOpenBrowser,
                    calls.onPageMenu,
                    Modifier.padding(horizontal = 4.dp),
                    onComments = calls.onComments,
                    left = left,
                    translator = calls.translator,
                )
            }
        }
    }
    // The track down the side sits in the room between the capsule and the dock, shrinking as a panel grows the dock. It steps away when that room gets too small, or when a card at the side of a wide window reaches its edge. A card above a narrow dock ends short of it and leaves it be.
    val sideRoom = maxHeight - topRoom - dockRoom
    val sideMost = maxHeight * 0.62f
    val asideDock = LocalAsideDock.current
    val cardAside = calls.panelAside &&
        calls.panel != DockPanel.None &&
        (asideDock == null || !asideDock.inTheWay || asideDock.end < SideTrackClear)
    AnimatedVisibility(
        controls && settings.progressBar == ReaderProgressBar.Vertical && !cardAside && sideRoom >= SideTrackLeast,
        Modifier
            .align(Alignment.TopEnd)
            .padding(top = topRoom, bottom = dockRoom)
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.End))
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
    // The dock is always there and changes its own shape: the full dock with the controls, a small pill with the page while they rest.
    val resting = if (settings.pageNumber && total > 1 &&
        !bar.auto
    ) {
        stringResource(Res.string.reader_page_of, page + 1, total)
    } else {
        null
    }
    ReaderBottomBar(
        page = page,
        total = total,
        slider = settings.progressBar == ReaderProgressBar.Horizontal,
        bar = bar,
        previousId = state.previousId,
        nextId = state.nextId,
        previousLabel = numberOf(state.previousId),
        nextLabel = numberOf(state.nextId),
        strip = settings.pageStrip,
        shade = settings.controlShade,
        maxWidth = if (wide && settings.progressBar == ReaderProgressBar.Horizontal) WideBarWidth else BarWidth,
        oneRow = wide,
        panelInDock = !calls.panelAside,
        preview = calls.preview,
        onJump = calls.onJump,
        onOpenChapter = calls.onOpenChapter,
        onMode = calls.onMode,
        onLight = calls.onLight,
        onLightDone = calls.onLightDone,
        onAuto = calls.onAuto,
        panel = calls.panel,
        onPanel = calls.onPanel,
        panelMax = panelMax,
        panelContent = calls.panelContent,
        expanded = controls,
        collapsed = resting,
        onExpand = calls.onShowControls,
        defaultMode = settings.mode,
        onDefaultMode = calls.onDefaultMode,
        modifier = Modifier
            .align(Alignment.BottomCenter)
            .tellsAsideCard(dockWidth, maxWidth)
            .onSizeChanged { dockRoom = with(density) { it.height.toDp() } },
    )
}

// Taps on the controls stay on them, so a tap between two buttons does not turn the page or hide the controls.
private fun Modifier.keepTaps(): Modifier = pointerInput(Unit) { detectTapGestures { } }

// The chapter before or after, by its id and the number shown under its arrow.
private class SideChapter(val id: Long?, val number: String?)

// The page track down the side of the screen, in a slim pill in the surface color of the theme: the chapter before at the top, then the page and the count, the track, and the chapter after at the bottom, so all the moving through the title sits in one place.
@Composable
private fun SideTrack(
    page: Int,
    total: Int,
    previous: SideChapter,
    next: SideChapter,
    calls: ChromeCalls,
    modifier: Modifier,
) {
    if (total < 2) return
    Column(
        modifier
            .width(
                44.dp,
            ).background(MaterialTheme.colorScheme.surfaceContainer.copy(alpha = 0.95f), RoundedCornerShape(22.dp))
            .padding(vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        SideChapterButton(
            Icons.Outlined.KeyboardDoubleArrowUp,
            stringResource(Res.string.reader_previous_chapter),
            previous,
            numberBelow = true,
            calls.onOpenChapter,
        )
        SideRule()
        Text(
            (page + 1).toString(),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Text(
            total.toString(),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        PageTrack(page, total, vertical = true, calls.preview, calls.onJump, Modifier.weight(1f).padding(top = 6.dp))
        SideRule()
        SideChapterButton(
            Icons.Outlined.KeyboardDoubleArrowDown,
            stringResource(Res.string.reader_next_chapter),
            next,
            numberBelow = false,
            calls.onOpenChapter,
        )
    }
}

// A short line that keeps the chapter buttons apart from the page and the track, so their numbers are not read as one.
@Composable
private fun SideRule() {
    Box(
        Modifier
            .padding(vertical = 6.dp)
            .width(18.dp)
            .height(1.dp)
            .background(MaterialTheme.colorScheme.outlineVariant),
    )
}

// An arrow to the chapter before or after with its number beside it, faded when there is none.
@Composable
private fun SideChapterButton(
    icon: ImageVector,
    label: String,
    chapter: SideChapter,
    numberBelow: Boolean,
    onOpenChapter: (Long) -> Unit,
) {
    val enabled = chapter.id != null
    val tint = if (enabled) {
        MaterialTheme.colorScheme.onSurface
    } else {
        MaterialTheme.colorScheme.onSurface.copy(
            alpha = 0.3f,
        )
    }
    Column(
        Modifier
            .clip(RoundedCornerShape(16.dp))
            .clickable(enabled = enabled, role = Role.Button, onClickLabel = label) { chapter.id?.let(onOpenChapter) }
            .padding(horizontal = 6.dp, vertical = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (!numberBelow) chapter.number?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = tint) }
        Icon(icon, label, Modifier.size(22.dp), tint = tint)
        if (numberBelow) chapter.number?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = tint) }
    }
}
