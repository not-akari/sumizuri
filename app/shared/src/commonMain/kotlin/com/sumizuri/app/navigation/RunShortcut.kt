package com.sumizuri.app.navigation

import com.sumizuri.app.data.model.controls.AppShortcut
import com.sumizuri.app.ui.kit.input.SearchFocus

// What the app does for the shortcuts that are not a move between tabs.
internal class ShortcutActions(
    val refreshLibrary: () -> Unit,
    val scrollToTop: () -> Unit,
    val showShortcuts: () -> Unit,
    // Back through the same chain as the back of the system, false when nothing listens.
    val goBack: () -> Boolean,
)

// Does a shortcut key of the app, and says whether it did. Going back or forward leaves it to the page when there is nowhere to go.
internal fun runShortcut(
    shortcut: AppShortcut,
    place: NavigationState,
    navigation: NavigationViewModel,
    tabs: List<Destination>,
    actions: ShortcutActions,
): Boolean {
    val at = tabs.indexOf(place.tab).coerceAtLeast(0)
    return when (shortcut) {
        AppShortcut.NextTab -> navigation.select(tabs[(at + 1) % tabs.size]).let { true }
        AppShortcut.PreviousTab -> navigation.select(tabs[(at + tabs.size - 1) % tabs.size]).let { true }
        AppShortcut.GoToLibrary -> goTo(Destination.Library, tabs, navigation)
        AppShortcut.GoToUpdates -> goTo(Destination.Updates, tabs, navigation)
        AppShortcut.GoToHistory -> goTo(Destination.History, tabs, navigation)
        AppShortcut.GoToBrowse -> goTo(Destination.Browse, tabs, navigation)
        AppShortcut.GoToProfile -> goTo(Destination.Profile, tabs, navigation)
        AppShortcut.OpenSettings -> navigation.push(Page.Settings).let { true }
        AppShortcut.Search -> SearchFocus.request()
        AppShortcut.ScrollToTop -> actions.scrollToTop().let { true }
        AppShortcut.RefreshLibrary -> actions.refreshLibrary().let { true }
        AppShortcut.ShowShortcuts -> actions.showShortcuts().let { true }
        AppShortcut.GoBack -> actions.goBack()
        AppShortcut.GoForward -> navigation.forward()
    }
}

// Opens a tab, which also closes the pages over the tabs, or the page of it when the person folded it into the library.
private fun goTo(target: Destination, tabs: List<Destination>, navigation: NavigationViewModel): Boolean {
    if (target in tabs) {
        navigation.select(target)
        return true
    }
    navigation.push(if (target == Destination.Updates) Page.Updates else Page.History)
    return true
}
