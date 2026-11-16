package com.sumizuri.app.data.model.controls

import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.shortcut_back
import com.sumizuri.app.shared.resources.shortcut_forward
import com.sumizuri.app.shared.resources.shortcut_go_browse
import com.sumizuri.app.shared.resources.shortcut_go_history
import com.sumizuri.app.shared.resources.shortcut_go_library
import com.sumizuri.app.shared.resources.shortcut_go_profile
import com.sumizuri.app.shared.resources.shortcut_go_updates
import com.sumizuri.app.shared.resources.shortcut_help
import com.sumizuri.app.shared.resources.shortcut_next_tab
import com.sumizuri.app.shared.resources.shortcut_previous_tab
import com.sumizuri.app.shared.resources.shortcut_refresh
import com.sumizuri.app.shared.resources.shortcut_scroll_top
import com.sumizuri.app.shared.resources.shortcut_search
import com.sumizuri.app.shared.resources.shortcut_settings
import org.jetbrains.compose.resources.StringResource

// What a key can do anywhere in the app, outside the reader.
enum class AppShortcut(val label: StringResource) {
    NextTab(Res.string.shortcut_next_tab),
    PreviousTab(Res.string.shortcut_previous_tab),
    GoToLibrary(Res.string.shortcut_go_library),
    GoToUpdates(Res.string.shortcut_go_updates),
    GoToHistory(Res.string.shortcut_go_history),
    GoToBrowse(Res.string.shortcut_go_browse),
    GoToProfile(Res.string.shortcut_go_profile),
    Search(Res.string.shortcut_search),
    ScrollToTop(Res.string.shortcut_scroll_top),
    RefreshLibrary(Res.string.shortcut_refresh),
    OpenSettings(Res.string.shortcut_settings),
    GoBack(Res.string.shortcut_back),
    GoForward(Res.string.shortcut_forward),
    ShowShortcuts(Res.string.shortcut_help),
}
