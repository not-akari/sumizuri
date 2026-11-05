package com.sumizuri.app.feature.reader

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.model.controls.ReaderAction
import com.sumizuri.app.data.model.reader.ReaderLookup
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.feature.reader.controls.ChaptersPanel
import com.sumizuri.app.feature.reader.controls.DockPanel
import com.sumizuri.app.feature.reader.controls.PageMenuPanel
import com.sumizuri.app.feature.reader.controls.PagePreview
import com.sumizuri.app.feature.reader.controls.ReaderAside
import com.sumizuri.app.feature.reader.controls.ReaderLight
import com.sumizuri.app.feature.reader.controls.ReaderSettingsPanel
import com.sumizuri.app.feature.reader.controls.fill
import com.sumizuri.app.feature.reader.controls.goesAside
import com.sumizuri.app.feature.reader.controls.rememberBedtime
import com.sumizuri.app.feature.reader.lookup.DictionaryClient
import com.sumizuri.app.feature.reader.lookup.LocalWordLookup
import com.sumizuri.app.feature.reader.lookup.LookupResult
import com.sumizuri.app.feature.reader.lookup.WordLookupPanel
import com.sumizuri.app.feature.reader.lookup.webSearchFor
import com.sumizuri.app.feature.reader.novel.NovelPagedReader
import com.sumizuri.app.feature.reader.translate.NovelTranslator
import com.sumizuri.app.feature.reader.translate.translatedWith
import com.sumizuri.app.feature.reader.view.ContinuousReader
import com.sumizuri.app.feature.reader.view.LocalPageShown
import com.sumizuri.app.feature.reader.view.PagedReader
import com.sumizuri.app.feature.reader.view.ProbeAspect
import com.sumizuri.app.feature.reader.view.ReaderView
import com.sumizuri.app.feature.reader.view.sampleUrls
import com.sumizuri.app.ui.kit.dock.AsideCard
import com.sumizuri.app.ui.kit.dock.isWideWindow
import com.sumizuri.app.ui.kit.image.LocalPageFilter
import com.sumizuri.app.ui.kit.image.PageSnapshots
import com.sumizuri.app.ui.kit.image.pageFilterOf
import com.sumizuri.app.ui.kit.input.pinchZoom
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import kotlinx.coroutines.delay

// A chapter in the mode that was chosen. A tap in the middle shows the bars, the page slider, the chapter list and the options.
@Composable
fun ReaderScreen(state: ReaderState, actions: ReaderActions, opening: ChapterPlace? = null) {
    // Words can be shown in the language of the app in place of those of the source. Once turned on, the chapters after open translated too.
    val translator = remember { NovelTranslator() }
    DisposableEffect(translator) { onDispose { translator.close() } }
    val language = androidx.compose.ui.text.intl.Locale.current.language
    LaunchedEffect(translator.active, state.pages, language) {
        if (translator.active && state.isText && state.pages.isNotEmpty()) translator.translate(state.pages, language)
    }
    val ready = !(state.loading || state.message != null || state.pages.isEmpty() || !state.modeKnown)
    // The reader is made under the opening card and stays clear until its first page has drawn, so the black of pages still loading never shows. A chapter of words has nothing to wait for, and a slow first page is given up on after a while.
    // It follows the chapter the reader was opened on, so a scroll on into the next chapter, which joins it to the same run, never brings the opening back.
    val opened = state.segments.firstOrNull()?.chapterId ?: state.chapterId
    var drawn by remember(opened) { mutableStateOf(false) }
    LaunchedEffect(ready, opened) {
        if (!ready) return@LaunchedEffect
        if (state.isText) drawn = true
        delay(FirstPageWaitMs)
        drawn = true
    }
    OpeningLayer(
        done = ready && drawn,
        opening = { ReaderStatus(state, actions.onRetry, actions.onSolve, actions.onBack, opening) },
    ) {
        if (ready) CompositionLocalProvider(LocalPageShown provides { drawn = true }) {
            val shown = if (translator.active) state.translatedWith(translator.translations) else state
            Reader(shown, actions, translator.takeIf { state.isText })
        }
    }
    if (!state.loading && !state.modeKnown) ProbeAspect(sampleUrls(state.pages), state.imageHeaders, actions.onAspects)
}

// The longest the opening card waits for the first page before the reader shows anyway.
private const val FirstPageWaitMs = 4000L

// How much a key changes the speed of the auto scroll, and the slowest and the fastest it goes.
private const val AutoStep = 20
private const val AutoMin = 20
private const val AutoMax = 600

@Composable
private fun Reader(state: ReaderState, actions: ReaderActions, translator: NovelTranslator?) {
    val settings = state.settings
    val rootChapterId = state.segments.firstOrNull()?.chapterId ?: state.chapterId
    // The number of pages the viewer made, which for words in pages is not the number the source gave.
    var counted by remember(state.pages, state.mode) { mutableIntStateOf(state.pages.size) }
    var page by rememberSaveable(rootChapterId) { mutableIntStateOf(state.startIndex) }
    var jump by remember(rootChapterId) { mutableStateOf<Int?>(null) }
    var controls by rememberSaveable { mutableStateOf(false) }
    // What the dock holds open. Opening one shows the controls, and hiding the controls closes it.
    var panel by remember { mutableStateOf(DockPanel.None) }
    fun show(which: DockPanel) {
        controls = true
        panel = which
    }
    LaunchedEffect(controls) { if (!controls) panel = DockPanel.None }
    var auto by remember { mutableStateOf(false) }
    // The light follows the sliders at once and is saved when they are let go.
    var dim by remember(settings.dim) { mutableFloatStateOf(settings.dim) }
    var warmth by remember(settings.warmth) { mutableFloatStateOf(settings.warmth) }
    val openSite = LocalOpenSite.current
    // The word that was held down, and what the dictionary said to it.
    var looked by remember { mutableStateOf<String?>(null) }
    val dictionary = remember { DictionaryClient() }
    DisposableEffect(dictionary) { onDispose { dictionary.close() } }
    val meaning by produceState<LookupResult?>(null, looked, settings.lookup) {
        value = null
        looked?.let { value = dictionary.look(it, settings.lookup) }
    }
    val lookup: ((String) -> Unit)? = if (state.isText &&
        settings.lookup != ReaderLookup.Off
    ) {
        { word ->
            looked = word
            show(DockPanel.Lookup)
        }
    } else {
        null
    }
    val view = ReaderView(
        startPage = page,
        jump = jump,
        onJumped = { jump = null },
        onPage = { page = it },
        onProgress = actions.onProgress,
        onNearEnd = actions.onNearEnd,
        startFraction = state.startFraction,
        onCount = { counted = it },
        onToggleControls = { controls = !controls },
        onCommon = { action ->
            when (action) {
                ReaderAction.ToggleControls -> controls = !controls

                ReaderAction.NextChapter -> state.nextId?.let(actions.onOpenChapter) ?: return@ReaderView false

                ReaderAction.PreviousChapter -> state.previousId?.let(actions.onOpenChapter) ?: return@ReaderView false

                ReaderAction.OpenSettings -> show(DockPanel.Settings)

                ReaderAction.OpenChapters -> show(DockPanel.Chapters)

                ReaderAction.OpenInBrowser -> openSite(state.webUrl ?: return@ReaderView false)

                ReaderAction.ToggleBookmark -> actions.onBookmark()

                // Words have no picture to save, and a long press on them is for looking a word up.
                ReaderAction.PageMenu -> if (state.isText) return@ReaderView false else show(DockPanel.Page)

                ReaderAction.ToggleAutoScroll -> {
                    auto = !auto
                    if (auto) controls = false
                }

                ReaderAction.AutoScrollFaster -> actions.onSettings(
                    settings.copy(
                        autoSpeed = (
                            settings.autoSpeed +
                                AutoStep
                            ).coerceAtMost(AutoMax),
                    ),
                )

                ReaderAction.AutoScrollSlower -> actions.onSettings(
                    settings.copy(
                        autoSpeed = (
                            settings.autoSpeed -
                                AutoStep
                            ).coerceAtLeast(AutoMin),
                    ),
                )

                ReaderAction.Close -> actions.onBack()

                else -> return@ReaderView false
            }
            true
        },
        auto = auto && state.mode == ReaderMode.Continuous,
        autoSpeed = settings.autoSpeed,
        onAutoStopped = { auto = false },
    )
    // The bars count the pages of the chapter in view. In a scroll over several chapters that is the stretch the page is in, and the jumps go to a place in that stretch.
    val segment = if (state.mode == ReaderMode.Continuous) state.segments.at(page) else null
    val shownPage = if (segment == null) page else page - segment.start
    val total = segment?.count ?: counted
    val minutesLeft = rememberMinutesLeft(state, shownPage, total)
    // A small picture of the page the person rests on is kept for the cards that ask them to go on, unless they read without leaving a trace.
    val imageContext = LocalPlatformContext.current
    val restingOn = state.pages.getOrNull(page)?.imageUrl
    LaunchedEffect(restingOn, state.titleId) {
        val url = restingOn ?: return@LaunchedEffect
        if (state.titleId == 0L || settings.incognito) return@LaunchedEffect
        delay(SnapshotAfterMs)
        PageSnapshots.save(imageContext, state.titleId, url, state.imageHeaders)
    }
    val jumpTo: (Int) -> Unit = { target ->
        val at = (segment?.start ?: 0) + target
        page = at
        jump = at
    }
    LaunchedEffect(page) { actions.onActive(page) }

    ReaderSystemUi(settings.hideSystemBars, settings.keepScreenOn, settings.orientation)
    val pageFilter =
        remember(settings.grayscale, settings.invertColors, settings.sepia, settings.contrast) {
            pageFilterOf(settings.grayscale, settings.invertColors, settings.sepia, settings.contrast)
        }
    CompositionLocalProvider(LocalWordLookup provides lookup, LocalPageFilter provides pageFilter) {
        // What each panel of the dock shows. Closing one, or picking a chapter in it, folds the dock back.
        val close = { panel = DockPanel.None }
        val panelView: @Composable (DockPanel) -> Unit = { shown ->
            when (shown) {
                DockPanel.Settings -> ReaderSettingsPanel(
                    settings,
                    state.isText,
                    actions.onSettings,
                    onDismiss = close,
                )

                DockPanel.Chapters -> ChaptersPanel(
                    state.chapters,
                    state.kind,
                    state.chapterId,
                    actions.onOpenChapter,
                    onDismiss = close,
                )

                DockPanel.Lookup -> looked?.let { word ->
                    WordLookupPanel(word, meaning, onSearchWeb = { openSite(webSearchFor(word)) }, onDismiss = {
                        looked = null
                        close()
                    })
                }

                DockPanel.Page -> {
                    val held = state.pages.getOrNull(page)
                    val address = held?.imageUrl
                    if (address != null) {
                        // A shuffled page is only put right when it is drawn, so as a cover it would stay shuffled.
                        PageMenuPanel(
                            page + 1,
                            address,
                            onSetCover = if (held.descramble == null) ({ actions.onSetCover(address) }) else null,
                            onOpenBrowser = state.webUrl?.let { url -> { openSite(url) } },
                            onDismiss = close,
                        )
                    }
                }

                else -> Unit
            }
        }
        val bar = BarState(state.mode, auto, state.mode == ReaderMode.Continuous, dim, warmth, state.isText)
        // On a wide window a panel opens as a card at the bottom right, over the pages, which stay where they are.
        val aside = isWideWindow() && controls && panel.goesAside()
        AsideCard(
            aside,
            Modifier.fillMaxSize().background(settings.background.fill()),
            panel = {
                ReaderAside(panel, bar, settings.mode, actions.onDefaultMode, actions.onMode, { newDim, newWarmth ->
                    dim = newDim
                    warmth = newWarmth
                }, { actions.onSettings(settings.copy(dim = dim, warmth = warmth)) }, close, panelView)
            },
        ) {
            BoxWithConstraints(Modifier.fillMaxSize()) {
                // A new chapter, mode, or page pairing starts the viewer at the right place and takes the zoom off.
                key(rootChapterId, state.mode, settings.dual) {
                    Box(Modifier.fillMaxSize().pinchZoom()) {
                        when {
                            state.mode == ReaderMode.Continuous -> ContinuousReader(
                                state,
                                view,
                                actions.onOpenChapter,
                            )

                            state.isText -> NovelPagedReader(state, view, actions.onOpenChapter)

                            else -> PagedReader(state, view, actions.onOpenChapter)
                        }
                    }
                }
                // In the bedtime hours the screen is at least as warm and as dim as bedtime asks, over what was set by hand.
                val bedtime by rememberBedtime(settings.bedtime, settings.bedtimeFrom, settings.bedtimeTo)
                val shownDim = if (bedtime) maxOf(dim, settings.bedtimeDim) else dim
                val shownWarmth = if (bedtime) maxOf(warmth, settings.bedtimeWarmth) else warmth
                ReaderLight(shownDim, shownWarmth)
                val first = segment?.start ?: 0
                ReaderChrome(
                    state,
                    controls,
                    shownPage,
                    total,
                    minutesLeft,
                    bar,
                    ChromeCalls(
                        onBack = actions.onBack,
                        onBookmark = actions.onBookmark,
                        onOpenBrowser = state.webUrl?.let { address -> { openSite(address) } },
                        onPageMenu = if (state.isText) null else ({ show(DockPanel.Page) }),
                        onComments = state.comments?.let { target -> { actions.onComments(target) } },
                        onJump = jumpTo,
                        onOpenChapter = actions.onOpenChapter,
                        onMode = actions.onMode,
                        onLight = { newDim, newWarmth ->
                            dim = newDim
                            warmth = newWarmth
                        },
                        onLightDone = { actions.onSettings(settings.copy(dim = dim, warmth = warmth)) },
                        onAuto = {
                            auto = !auto
                            // Out of the way, so the page can be read while it moves.
                            if (auto) controls = false
                        },
                        panel = panel,
                        onPanel = { panel = it },
                        panelContent = panelView,
                        onShowControls = { controls = true },
                        onDefaultMode = actions.onDefaultMode,
                        translator = translator,
                        preview = { at ->
                            state.pages
                                .getOrNull(first + at)
                                ?.takeIf { it.descramble == null }
                                ?.imageUrl
                                ?.let { PagePreview(it, state.imageHeaders) }
                        },
                        panelAside = aside,
                    ),
                )
            }
        }
    }
}

// How long a page must stay on the screen before its picture is kept as the place to go on from.
private const val SnapshotAfterMs = 1500L
