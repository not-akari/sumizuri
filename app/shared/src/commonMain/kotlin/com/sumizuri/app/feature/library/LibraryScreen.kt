package com.sumizuri.app.feature.library

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.core.perf.Perf
import com.sumizuri.app.core.perf.StartMark
import com.sumizuri.app.data.model.controls.LibraryCoverAction
import com.sumizuri.app.data.model.library.LibrarySection
import com.sumizuri.app.feature.library.display.LibraryDisplaySheet
import com.sumizuri.app.feature.library.display.LibrarySortSheet
import com.sumizuri.app.feature.library.part.LibraryPartOf
import com.sumizuri.app.feature.library.part.partItems
import com.sumizuri.app.feature.library.tile.CoverDrag
import com.sumizuri.app.feature.library.tile.CoverDragLayer
import com.sumizuri.app.feature.library.tile.LibraryTile
import com.sumizuri.app.feature.library.tile.TileCalls
import com.sumizuri.app.feature.library.tile.TileContext
import com.sumizuri.app.feature.library.tile.coverDrag
import com.sumizuri.app.feature.library.top.ConnectionLostNotice
import com.sumizuri.app.feature.library.top.FailuresNotice
import com.sumizuri.app.feature.library.top.LibraryControls
import com.sumizuri.app.feature.library.top.LibraryPickBottom
import com.sumizuri.app.feature.library.top.LibraryPickTop
import com.sumizuri.app.feature.library.top.LibrarySearchRow
import com.sumizuri.app.feature.library.top.LibraryTopBar
import com.sumizuri.app.feature.library.top.MissingSourcesNotice
import com.sumizuri.app.feature.library.top.NoticeAction
import com.sumizuri.app.feature.library.top.SearchSourcesRow
import com.sumizuri.app.feature.library.top.ShelfTabs
import com.sumizuri.app.feature.library.top.ShelvesDialog
import com.sumizuri.app.feature.library.top.UpdateFailuresSheet
import com.sumizuri.app.feature.library.top.shelfOrder
import com.sumizuri.app.feature.library.top.swipeShelves
import com.sumizuri.app.navigation.LocalTabShown
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.library_empty
import com.sumizuri.app.shared.resources.library_nothing_matches
import com.sumizuri.app.shared.resources.library_part_hidden
import com.sumizuri.app.shared.resources.library_remove
import com.sumizuri.app.shared.resources.library_remove_message
import com.sumizuri.app.shared.resources.library_show_all
import com.sumizuri.app.shared.resources.library_show_them
import com.sumizuri.app.shared.resources.library_title
import com.sumizuri.app.shared.resources.library_unreachable
import com.sumizuri.app.shared.resources.undo
import com.sumizuri.app.ui.controls.LocalAppGestures
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.cover.CoverPick
import com.sumizuri.app.ui.kit.cover.LocalCoverFlight
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.image.PreloadCovers
import com.sumizuri.app.ui.kit.input.SearchFocus
import com.sumizuri.app.ui.kit.page.LocalBottomClearance
import com.sumizuri.app.ui.kit.page.LocalHideBottomBar
import com.sumizuri.app.ui.kit.page.PageGrid
import com.sumizuri.app.ui.kit.page.fullSpan
import com.sumizuri.app.ui.kit.scroll.PullRefresh
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.Rise
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.motion.motionMs
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.getString
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The windows the page can open over itself.
private enum class Window { None, Sort, Display, Failures, Shelves, Remove }

// The library. A bar on top, which becomes the bar of the picked titles. Under it the notes about titles that cannot be reached, the search, the shelves as tabs, a row of chips for the order, the kinds and the filters, the titles read last, and the covers. Pulling the page down checks the library for new chapters, and a swipe sideways changes the shelf.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun LibraryScreen(state: LibraryState, calls: LibraryCalls) {
    val gestures = LocalAppGestures.current
    var window by remember { mutableStateOf(Window.None) }
    val prefs = state.prefs
    // Covers being dragged onto a shelf.
    val drag = remember { CoverDrag() }
    // The grid of covers, whose place the covers past the screen are loaded from.
    val gridState = rememberLazyGridState()
    val flight = LocalCoverFlight.current
    // With the search tucked into the bar, whether its field is showing under it.
    var searchOpen by remember { mutableStateOf(false) }
    val showSearch = !prefs.collapsibleSearch || searchOpen || state.query.isNotEmpty()
    LaunchedEffect(searchOpen) {
        if (searchOpen) {
            delay(80)
            SearchFocus.request()
        }
    }
    // The bar of actions on picked titles takes the place of the tabs at the bottom while titles are picked.
    val hideBottomBar = LocalHideBottomBar.current
    val inSight = LocalTabShown.current
    LaunchedEffect(state.selecting, inSight) { hideBottomBar(state.selecting && inSight) }
    // Back while titles are picked ends the picking instead of leaving the tab.
    NavigationBackHandler(
        rememberNavigationEventState(NavigationEventInfo.None),
        isBackEnabled =
        state.selecting && inSight,
    ) {
        calls.onClearSelection()
    }
    DisposableEffect(Unit) { onDispose { hideBottomBar(false) } }
    // The first time the titles are there is the moment the start counts as done, for the performance page.
    LaunchedEffect(state.loaded) { if (state.loaded) Perf.mark(StartMark.LibraryShown) }
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    // Hiding a part says so, with Undo to bring it back.
    val hidePart: (LibrarySection) -> Unit = { section ->
        val count = prefs.countOf(section)
        calls.onPrefs { it.withCount(section, 0) }
        scope.launch {
            snackbar.currentSnackbarData?.dismiss()
            val text = getString(Res.string.library_part_hidden, getString(section.label))
            if (snackbar.showSnackbar(text, getString(Res.string.undo)) ==
                SnackbarResult.ActionPerformed
            ) {
                calls.onPrefs { it.withCount(section, count) }
            }
        }
    }
    val context =
        remember(prefs, state.sources) {
            TileContext(
                prefs.badges,
                prefs.showProgress,
                prefs.favoritesEnabled,
                state.sources,
                prefs.panoramaAspect,
                prefs.listCover,
                prefs.nameScale,
            )
        }
    // The favorite action adds when some picked title is not one yet, and takes off when all are.
    val favorite = if (prefs.favoritesEnabled) state.titles.any { it.id in state.selected && !it.favorite } else null

    fun act(action: LibraryCoverAction, id: Long) {
        when (action) {
            LibraryCoverAction.Open -> if (state.selecting) calls.onSelect(id) else calls.onOpenTitle(id)
            LibraryCoverAction.Select -> calls.onSelect(id)
            LibraryCoverAction.None -> Unit
        }
    }
    val pick = LibraryPickCalls(
        onClose = calls.onClearSelection,
        onSelectAll = calls.onSelectAll,
        onInvert = calls.onInvert,
        onMarkRead = calls.onMarkRead,
        onFavorite = calls.onFavorite,
        onShelves = { window = Window.Shelves },
        onMove = { state.selected.singleOrNull()?.let(calls.onMove) },
        onMigrate = { calls.onMigrate(state.selected.toList()) },
        onRemove = { window = Window.Remove },
    )

    Column(Modifier.fillMaxSize()) {
        val fast = motionMs(AppMotion.Fast)
        // The bar over the page and the bar of the picked titles change places with a fade.
        AnimatedContent(state.selecting, transitionSpec = {
            fadeIn(tween(fast)) togetherWith fadeOut(tween(fast))
        }, label = "bar") { selecting ->
            if (selecting) {
                LibraryPickTop(state.selected.size, state.titles.size, pick)
            } else {
                LibraryTopBar(state, calls, searchOpen, {
                    searchOpen = !searchOpen
                    if (!searchOpen) calls.onQuery("")
                }, onDisplay = { window = Window.Display })
            }
        }
        // The bar shows how far the check has got, so the pull has no spinner of its own.
        PullRefresh(state.progress != null, { if (!state.selecting) calls.onUpdate() }, Modifier.weight(1f)) {
            Box(
                Modifier.fillMaxSize().swipeShelves(
                    state.shelfOrder(),
                    prefs.category,
                    !state.selecting,
                    calls::onShelf,
                ),
            ) {
                PreloadCovers(gridState, state.titles)
                PageGrid(maxCell = prefs.cellWidth.dp, state = gridState, gap = prefs.gridGap.dp) {
                    val rows = !prefs.style.isGrid
                    fullSpan {
                        LibraryHeader(state, calls, showSearch, onSort = { window = Window.Sort }, onFailures = {
                            window =
                                Window.Failures
                        })
                    }
                    // The heading over the covers is only needed when other parts stand above them.
                    val partsAbove = prefs.sectionOrder.takeWhile { it != LibrarySection.Library }.any {
                        partItems(state, it) !=
                            null
                    }
                    // The covers are a part like the others, so they stand where the person put them.
                    for (section in prefs.sectionOrder) {
                        if (section != LibrarySection.Library) {
                            partItems(
                                state,
                                section,
                            )?.let { items -> fullSpan { LibraryPartOf(state, calls, section, items, hidePart) } }
                            continue
                        }
                        if (partsAbove) fullSpan { AppSectionLabel(stringResource(Res.string.library_title)) }
                        if (state.loaded && state.titles.isEmpty()) {
                            fullSpan {
                                val text = if (state.total ==
                                    0
                                ) {
                                    Res.string.library_empty
                                } else {
                                    Res.string.library_nothing_matches
                                }
                                Text(
                                    stringResource(text),
                                    Modifier.entrance().fillMaxWidth().padding(32.dp),
                                    color = MaterialTheme.colorScheme.outline,
                                )
                            }
                        }
                        items(
                            state.titles,
                            key = { it.id },
                            span = { if (rows) GridItemSpan(maxLineSpan) else GridItemSpan(1) },
                        ) { title ->
                            LibraryTile(
                                title,
                                prefs.style,
                                context,
                                CoverPick(state.selecting, title.id in state.selected),
                                modifier = Modifier.animateItem().coverDrag(drag, title, {
                                    state.titles.filter {
                                        it.id in
                                            state.selected
                                    }
                                }, calls.onDropOnShelf),
                                calls = TileCalls(
                                    onClick = {
                                        if (state.selecting) {
                                            calls.onSelect(
                                                title.id,
                                            )
                                        } else {
                                            flight?.launch(title)
                                            act(gestures.libraryTap, title.id)
                                        }
                                    },
                                    onLongClick = { act(gestures.libraryLongPress, title.id) },
                                    onDoubleClick = gestures.libraryDoubleTap
                                        .takeIf {
                                            it != LibraryCoverAction.None
                                        }?.let { action -> { act(action, title.id) } },
                                    onContinue = if (state.selecting) null else ({ calls.onContinue(title.id) }),
                                ),
                            )
                        }
                    }
                    // Room under the last row for the bar of actions.
                    if (state.selecting) fullSpan { Spacer(Modifier.height(96.dp)) }
                }
                SnackbarHost(
                    snackbar,
                    Modifier.align(Alignment.BottomCenter).padding(bottom = LocalBottomClearance.current),
                )
                // The bar of actions rises from the bottom when titles are picked.
                Rise(
                    state.selecting,
                    Modifier.align(Alignment.BottomCenter).windowInsetsPadding(WindowInsets.navigationBars),
                ) {
                    LibraryPickBottom(state.selected.size, favorite, pick, Modifier)
                }
                // A cover dragged from the grid floats under the pointer over the shelves it can go on.
                CoverDragLayer(drag, state.categories.filter { it.id >= 0 }, Modifier.fillMaxSize())
            }
        }
    }
    val close = { window = Window.None }
    when (window) {
        Window.None -> Unit

        Window.Sort -> LibrarySortSheet(state, calls.onPrefs, calls.onShelfRule, close)

        Window.Display -> LibraryDisplaySheet(prefs, calls.onPrefs, calls.onOpenShelves, close)

        Window.Failures -> UpdateFailuresSheet(state.failures, calls.onOpenTitle, close)

        Window.Shelves -> ShelvesDialog(
            categories = state.pickShelves,
            picked = state.selected.size,
            onShelves = state.selectedShelves,
            onCreate = calls.onCreateShelf,
            onApply = { add, remove ->
                calls.onShelves(add, remove)
                close()
            },
            onDismiss = close,
        )

        Window.Remove -> ConfirmDialog(
            stringResource(Res.string.library_remove),
            pluralStringResource(Res.plurals.library_remove_message, state.selected.size, state.selected.size),
            stringResource(Res.string.library_remove),
            onConfirm = {
                calls.onRemove()
                close()
            },
            onDismiss = close,
        )
    }
}
