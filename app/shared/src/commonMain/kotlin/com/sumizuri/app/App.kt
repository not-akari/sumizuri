package com.sumizuri.app

import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.LocalViewModelStoreOwner
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import coil3.SingletonImageLoader
import coil3.annotation.DelicateCoilApi
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.core.perf.PerfOverlay
import com.sumizuri.app.core.perf.PerfWatch
import com.sumizuri.app.data.AppContainer
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.controls.AppShortcut
import com.sumizuri.app.data.model.controls.NavDoubleTapAction
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.profile.ProfileHost
import com.sumizuri.app.data.profile.ProfileStoreOwner
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.library.continueChapterOf
import com.sumizuri.app.feature.sync.HandoffNotice
import com.sumizuri.app.feature.appupdate.AppUpdateNotices
import com.sumizuri.app.feature.onboarding.OnboardingScreen
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.feature.settings.controls.ControlsViewModel
import com.sumizuri.app.feature.settings.system.perfDetails
import com.sumizuri.app.feature.theme.ThemeViewModel
import com.sumizuri.app.feature.theme.ThemeLinkDialog
import com.sumizuri.app.navigation.AppLinks
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.navigation.KeptTabs
import com.sumizuri.app.navigation.MainScaffold
import com.sumizuri.app.navigation.NavigationViewModel
import com.sumizuri.app.navigation.Page
import com.sumizuri.app.navigation.PageBack
import com.sumizuri.app.navigation.PageStack
import com.sumizuri.app.navigation.ShortcutActions
import com.sumizuri.app.navigation.ShortcutsDialog
import com.sumizuri.app.navigation.bar.NavAvatar
import com.sumizuri.app.navigation.runShortcut
import com.sumizuri.app.ui.UiRefreshRate
import com.sumizuri.app.ui.controls.LocalAppGestures
import com.sumizuri.app.ui.controls.LocalReaderControls
import com.sumizuri.app.ui.controls.appShortcuts
import com.sumizuri.app.ui.kit.image.PageCache
import com.sumizuri.app.ui.kit.image.PageImages
import com.sumizuri.app.ui.kit.image.coverImageLoader
import com.sumizuri.app.ui.kit.image.pageImageLoader
import com.sumizuri.app.ui.kit.input.SearchFocus
import com.sumizuri.app.ui.kit.scroll.ScrollTops
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import com.sumizuri.app.ui.language.applyAppLanguage
import com.sumizuri.app.ui.motion.LocalPageMotion
import com.sumizuri.app.ui.motion.LocalStagger
import com.sumizuri.app.ui.motion.rememberMotionShift
import com.sumizuri.app.ui.security.AppGuard
import com.sumizuri.app.ui.kit.cover.CoverFlight
import com.sumizuri.app.ui.kit.cover.CoverFlightLayer
import com.sumizuri.app.ui.kit.cover.LocalCoverFlight
import com.sumizuri.app.ui.theme.background.LocalBackdropCovers
import com.sumizuri.app.ui.theme.spec.BackgroundStyle
import com.sumizuri.app.ui.theme.LocalCompactLists
import com.sumizuri.app.ui.theme.LocalReduceMotion
import com.sumizuri.app.ui.theme.SumizuriTheme
import com.sumizuri.app.core.perf.reportActivity
import com.sumizuri.app.ui.theme.background.BackdropSlot
import com.sumizuri.app.ui.theme.background.LocalBackdropSlot
import com.sumizuri.app.ui.theme.background.ambientBackground
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

// Two taps on a tab this close together are a double tap.
private const val DoubleTapMs = 400L

// The window bar is drawn over the whole app on a desktop window that has no bar of its own.
@Composable
fun App(profiles: ProfileHost, requestedTab: Destination? = null, onTabOpened: () -> Unit = {}, windowBar: (@Composable () -> Unit)? = null) {
    val container by profiles.container.collectAsStateWithLifecycle()
    // Each profile has its own screens, so a switch starts them again from nothing, with a place of their own to keep their view models in.
    val owner = remember(container) { ProfileStoreOwner() }
    DisposableEffect(owner) { onDispose { owner.viewModelStore.clear() } }
    key(container) {
        CompositionLocalProvider(LocalViewModelStoreOwner provides owner, LocalProfiles provides profiles) {
            UiRefreshRate()
            AppContent(container, windowBar, requestedTab, onTabOpened)
        }
    }
}

@OptIn(ExperimentalComposeUiApi::class, DelicateCoilApi::class)
@Composable
private fun AppContent(container: AppContainer, windowBar: (@Composable () -> Unit)?, requestedTab: Destination?, onTabOpened: () -> Unit) {
    val context = LocalPlatformContext.current
    // The covers of a site that guards them are loaded through the sources of the open profile, so the loader is made again for each profile.
    val settings = viewModel { SettingsViewModel(container.settings) }
    val imageDiskMb by settings.imageDiskMb.collectAsStateWithLifecycle()
    val imageMemoryPercent by settings.imageMemoryPercent.collectAsStateWithLifecycle()
    val pageMemoryMb by settings.pageMemoryMb.collectAsStateWithLifecycle()
    val pageKeepMinutes by settings.pageKeepMinutes.collectAsStateWithLifecycle()
    // The loader is made again when a size of the cache changes, and the one it replaces is shut down so it lets go of its files and memory.
    val loader = remember(container, imageDiskMb, imageMemoryPercent) { coverImageLoader(context, container.manager.images, imageDiskMb, imageMemoryPercent).also { SingletonImageLoader.setUnsafe(it) } }
    DisposableEffect(loader) { onDispose { loader.shutdown() } }
    val pageLoader = remember(container, imageDiskMb) { pageImageLoader(context, container.manager.images, imageDiskMb).also { PageImages.set(it) } }
    DisposableEffect(pageLoader) {
        onDispose {
            PageImages.release(pageLoader)
            pageLoader.shutdown()
        }
    }
    LaunchedEffect(pageMemoryMb, pageKeepMinutes) { PageCache.configure(pageMemoryMb * 1024L * 1024L, pageKeepMinutes * 60_000L) }

    AppBackgroundWork(container, loader)
    val perfOverlay by remember(container) { container.settings.flag(SettingKey.PerfOverlay, false) }.collectAsStateWithLifecycle(false)
    val perfAdvanced by remember(container) { container.settings.text(SettingKey.PerfOverlayLevel) }.collectAsStateWithLifecycle(null)
    val perfAt by remember(container) { container.settings.text(SettingKey.PerfOverlayAt) }.collectAsStateWithLifecycle(null)
    val perfLines = remember(container, context, perfAdvanced) { if (perfAdvanced == "advanced") perfDetails(container, context) else null }
    val webInApp by remember(container) { container.settings.flag(SettingKey.WebInApp, true) }.collectAsStateWithLifecycle(true)
    // Whether the first steps after installing were gone through, null until it is read, so neither they nor the library flash before the other.
    val onboardingDone by remember(container) { container.settings.flag(SettingKey.OnboardingDone, false).map<Boolean, Boolean?> { it } }.collectAsStateWithLifecycle(null)

    val themeMode by settings.themeMode.collectAsStateWithLifecycle()
    val themes = viewModel { ThemeViewModel(container.themes) }
    val theme by themes.active.collectAsStateWithLifecycle()
    val compactLists by settings.compactLists.collectAsStateWithLifecycle()
    val reduceMotion by settings.reduceMotion.collectAsStateWithLifecycle()
    val oled by settings.oled.collectAsStateWithLifecycle()
    val oledGlow by settings.oledGlow.collectAsStateWithLifecycle()
    val navStyle by settings.navStyle.collectAsStateWithLifecycle()
    val navLabels by settings.navLabels.collectAsStateWithLifecycle()
    val navSwipe by settings.navSwipe.collectAsStateWithLifecycle()
    val pageMotion by settings.pageMotion.collectAsStateWithLifecycle()
    val stagger by settings.stagger.collectAsStateWithLifecycle()
    val profileState by LocalProfiles.current.state.collectAsStateWithLifecycle()
    val navAvatar = profileState.active.let { NavAvatar(it.name, it.avatar) }
    // The count of new chapters that are not read, on the tab of the updates.
    val unreadCount by remember(container) { container.library.unreadUpdateCount }.collectAsStateWithLifecycle(0)
    val badges = mapOf(Destination.Updates to unreadCount)
    val language by settings.language.collectAsStateWithLifecycle()
    // The words are read again from the language the person chose, so the screens below are built again when it changes.
    remember(language) {
        applyAppLanguage(language.code)
        language
    }
    val controls = viewModel { ControlsViewModel(container.controls) }
    val readerControls by controls.reader.collectAsStateWithLifecycle()
    val gestures by controls.app.collectAsStateWithLifecycle()
    // The covers of the library for the background that shows them, read only while that background is in use, in a steady mix.
    val coverBackground = theme.options.background.style == BackgroundStyle.Covers
    val backdropCovers by remember(container, coverBackground) {
        if (!coverBackground) {
            flowOf(emptyList())
        } else {
            container.library.library.map { titles -> titles.mapNotNull { it.coverUrl?.takeIf(String::isNotBlank) }.sortedBy { it.hashCode() }.take(30) }
        }
    }.collectAsStateWithLifecycle(emptyList())

    key(language) {
        CompositionLocalProvider(
            LocalAppContainer provides container,
            LocalCompactLists provides compactLists,
            LocalReduceMotion provides reduceMotion,
            LocalReaderControls provides readerControls,
            LocalAppGestures provides gestures,
            LocalBackdropCovers provides backdropCovers,
        ) {
            val navigation = viewModel { NavigationViewModel(container.session, container.sources, container.library) }
            val place by navigation.state.collectAsStateWithLifecycle()
            // The screen a performance warning names.
            LaunchedEffect(place.top, place.tab) { PerfWatch.screen = place.top?.let { it::class.simpleName } ?: place.tab.name }
            LaunchedEffect(navigation) { navigation.restore(container.settings.flag(SettingKey.ReopenPlace, false).first()) }
            // A shortcut of the launcher opens its tab once the saved place has been read, so the saved place does not take it back.
            LaunchedEffect(requestedTab, place.restored) {
                if (requestedTab != null && place.restored) {
                    navigation.select(requestedTab)
                    onTabOpened()
                }
            }
            // A link that asks to add a repo opens Browse, where the window of adding one shows it and waits for a yes.
            val linkedRepo by AppLinks.addRepo.collectAsStateWithLifecycle()
            LaunchedEffect(linkedRepo, place.restored) {
                if (linkedRepo != null && place.restored) navigation.select(Destination.Browse)
            }

            // A notice of new chapters opens its title, or reads on in it from where it was left.
            val linkedTitle by AppLinks.openTitle.collectAsStateWithLifecycle()
            LaunchedEffect(linkedTitle, place.restored) {
                val link = linkedTitle ?: return@LaunchedEffect
                if (!place.restored) return@LaunchedEffect
                AppLinks.titleTaken()
                val chapter = if (link.read) continueChapterOf(container.library, link.id) else null
                navigation.push(chapter?.let { Page.Reader(it) } ?: Page.Saved(link.id))
            }
            val linkedUpdates by AppLinks.openUpdates.collectAsStateWithLifecycle()
            LaunchedEffect(linkedUpdates, place.restored) {
                if (linkedUpdates && place.restored) {
                    AppLinks.updatesTaken()
                    navigation.select(Destination.Updates)
                }
            }

            // A link with a theme in it asks whether to add that theme.
            val sharedTheme by AppLinks.sharedTheme.collectAsStateWithLifecycle()

            // Back closes the top page, and on a tab other than the library it goes to the library first. A back gesture of the system moves the top page with the finger, and one given up lets the page slide back.
            val backState = rememberNavigationEventState(NavigationEventInfo.None)
            val pageBack = remember { PageBack() }
            NavigationBackHandler(backState, isBackEnabled = place.top != null || place.tab != Destination.Library, onBackCancelled = pageBack::cancel) {
                if (place.top != null) navigation.pop() else navigation.select(Destination.Library)
            }

            val scope = rememberCoroutineScope()
            val libraryPrefs by container.libraryPrefs.prefs.collectAsStateWithLifecycle(LibraryPrefs())
            // The updates and the history are tabs unless the person folded them into the library.
            val tabs = Destination.entries.filter { (it != Destination.Updates || libraryPrefs.showUpdatesTab) && (it != Destination.History || libraryPrefs.showHistoryTab) }
            LaunchedEffect(tabs, place.tab, place.restored) {
                if (place.restored && place.tab !in tabs) navigation.select(Destination.Library)
            }
            var shortcutsOpen by remember { mutableStateOf(false) }
            val actions = ShortcutActions(
                refreshLibrary = { scope.launch { container.sync.refreshLibrary() } },
                scrollToTop = { scope.launch { ScrollTops.toTop() } },
                showShortcuts = { shortcutsOpen = true },
            )
            val onShortcut: (AppShortcut) -> Boolean = { shortcut -> runShortcut(shortcut, place, navigation, tabs, actions) }
            // A second tap on the tab that is open does what the person chose for it.
            var lastTap by remember { mutableStateOf<Pair<Destination, Long>?>(null) }
            val onSelectTab: (Destination) -> Unit = { tab ->
                val now = nowMillis()
                val before = lastTap
                if (tab == place.tab && before != null && before.first == tab && now - before.second <= DoubleTapMs) {
                    when (gestures.navDoubleTap) {
                        NavDoubleTapAction.ScrollToTop -> scope.launch { ScrollTops.toTop() }
                        NavDoubleTapAction.Search -> SearchFocus.request()
                        NavDoubleTapAction.GlobalSearch -> navigation.push(Page.GlobalSearch())
                        NavDoubleTapAction.None -> Unit
                    }
                }
                lastTap = tab to now
                navigation.select(tab)
            }

            // Every button that opens a site opens it the way the person chose, in a page of the app or in their own browser.
            val uriHandler = LocalUriHandler.current
            val openSite: (String) -> Unit = { address -> if (webInApp) navigation.push(Page.Web(address)) else runCatching { uriHandler.openUri(address) } }
            // A cover tapped in the library flies to its place on the page of the title.
            val flight = remember { CoverFlight() }
            CompositionLocalProvider(LocalOpenSite provides openSite, LocalPageMotion provides pageMotion, LocalStagger provides stagger, LocalCoverFlight provides flight) {
                SumizuriTheme(themeMode, theme, oled, oledGlow) {
                    val tabMs = pageMotion.pageMs()
                    val shift = rememberMotionShift()
                    val locked by container.lock.locked.collectAsStateWithLifecycle()
                    // The background under the tabs, which a page hides once it covers the whole window.
                    val rootSlot = remember { BackdropSlot() }
                    CompositionLocalProvider(LocalBackdropSlot provides rootSlot) {
                    Column(Modifier.fillMaxSize().ambientBackground(rootSlot).reportActivity().appShortcuts { shortcut -> locked != false || onShortcut(shortcut) }) {
                        windowBar?.invoke()
                        if (locked == false) {
                            Surface(Modifier.weight(1f).fillMaxWidth(), color = Color.Transparent, contentColor = MaterialTheme.colorScheme.onBackground) {
                                // The tabs stay composed under the pages so a grid keeps its place, and nothing draws until the saved place is read.
                                if (place.restored && onboardingDone != null) {
                                    Box(Modifier.fillMaxSize()) {
                                        // The tabs are the page under the first one, so they give way to it and come back in the same motion.
                                        PageStack(place, navigation, backState, pageBack) {
                                            MainScaffold(tabs, navStyle, navLabels, navSwipe, place.tab, navAvatar, badges, onSelect = onSelectTab) {
                                                // The next tab moves in from the side it sits on, quicker than a page, in the style the person chose, and each tab is kept once made.
                                                KeptTabs(place.tab, tabs, pageMotion, tabMs, shift) { tab ->
                                                    AppTab(tab, tabs, navigation)
                                                }
                                            }
                                        }
                                        CoverFlightLayer(flight)
                                        // An offer to go on with a title that was read further on another device.
                                        val handoff by remember(container) { container.librarySync.handoff }.collectAsStateWithLifecycle()
                                        HandoffNotice(
                                            handoff,
                                            onContinue = { id ->
                                                container.librarySync.handoff.value = null
                                                scope.launch { navigation.push(continueChapterOf(container.library, id)?.let { Page.Reader(it) } ?: Page.Saved(id)) }
                                            },
                                            onDismiss = { container.librarySync.handoff.value = null },
                                            Modifier.align(Alignment.TopCenter).windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal)).padding(12.dp),
                                        )
                                        // A new version of the app at the top for five seconds, and the notes of this one once after an update.
                                        AppUpdateNotices({ navigation.push(Page.SettingsPage(SettingsTarget.AppUpdate)) }, Modifier.align(Alignment.TopCenter).windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal)).padding(12.dp))
                                        // The first steps after installing, over everything until they are gone through or skipped, then fading away to the library.
                                        androidx.compose.animation.AnimatedVisibility(onboardingDone == false, enter = fadeIn(tween(300)), exit = fadeOut(tween(450)) + scaleOut(tween(450), targetScale = 1.03f)) {
                                            OnboardingScreen(onMigrate = { navigation.push(Page.Migration(it)) })
                                        }
                                        if (perfOverlay) {
                                            // The box stays where it was dragged to, and starts in a corner that suits the screen.
                                            val place = perfAt
                                                ?.split(",")
                                                ?.mapNotNull { it.toFloatOrNull() }
                                                ?.takeIf { it.size == 2 }
                                                ?.let { Offset(it[0], it[1]) }
                                            PerfOverlay(perfLines, place, { at -> scope.launch { container.settings.setText(SettingKey.PerfOverlayAt, "${at.x},${at.y}") } }, Modifier.windowInsetsPadding(WindowInsets.safeDrawing).padding(8.dp))
                                        }
                                    }
                                }
                            }
                        }
                        // While locked the lock takes the place of the app, dialogs and all, under the bar of the window so the window can still be moved and closed.
                        AppGuard(container.lock, container.reading)
                    }
                    }
                    if (locked == false && shortcutsOpen) ShortcutsDialog(gestures) { shortcutsOpen = false }
                    if (locked == false) sharedTheme?.let { ThemeLinkDialog(it, AppLinks::themeTaken) }
                }
            }
        }
    }
}
