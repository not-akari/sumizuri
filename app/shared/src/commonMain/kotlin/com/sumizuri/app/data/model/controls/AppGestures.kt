package com.sumizuri.app.data.model.controls

import com.sumizuri.app.ui.controls.KeyChord

// The gestures and the shortcut keys that work across the app, and not only in the reader.
data class AppGestures(
    val libraryTap: LibraryCoverAction = LibraryCoverAction.Open,
    val libraryLongPress: LibraryCoverAction = LibraryCoverAction.Select,
    val libraryDoubleTap: LibraryCoverAction = LibraryCoverAction.None,
    val chapterSwipeRight: ChapterRowAction = ChapterRowAction.ToggleRead,
    val chapterSwipeLeft: ChapterRowAction = ChapterRowAction.ToggleBookmark,
    val chapterLongPress: ChapterRowAction = ChapterRowAction.Select,
    // A second tap on the open tab searches every source, the quickest way to a title the library does not have yet.
    val navDoubleTap: NavDoubleTapAction = NavDoubleTapAction.GlobalSearch,
    val shortcuts: Map<AppShortcut, List<KeyChord>> = DefaultShortcuts,
) {
    fun shortcutFor(pressed: KeyChord): AppShortcut? = shortcuts.entries.firstOrNull { pressed in it.value }?.key

    // The chord goes to the shortcut, and is taken from any other shortcut that had it.
    fun withShortcut(shortcut: AppShortcut, chord: KeyChord): AppGestures = copy(
        shortcuts = shortcuts.mapValues { (own, chords) ->
            if (own ==
                shortcut
            ) {
                chords.filter { it != chord } + chord
            } else {
                chords.filter { it != chord }
            }
        },
    )

    fun withoutShortcut(shortcut: AppShortcut, chord: KeyChord): AppGestures = copy(
        shortcuts = shortcuts.mapValues { (own, chords) ->
            if (own ==
                shortcut
            ) {
                chords.filter { it != chord }
            } else {
                chords
            }
        },
    )

    fun withShortcutReset(shortcut: AppShortcut): AppGestures {
        val taken = shortcuts
            .filterKeys { it != shortcut }
            .values
            .flatten()
            .toSet()
        return copy(shortcuts = shortcuts + (shortcut to DefaultShortcuts.getValue(shortcut).filter { it !in taken }))
    }

    val isDefault: Boolean get() = this == AppGestures()

    companion object {
        val DefaultShortcuts: Map<AppShortcut, List<KeyChord>> = mapOf(
            AppShortcut.NextTab to listOf(KeyChord("PageDown", ctrl = true)),
            AppShortcut.PreviousTab to listOf(KeyChord("PageUp", ctrl = true)),
            AppShortcut.GoToLibrary to listOf(KeyChord("Digit1", ctrl = true)),
            AppShortcut.GoToUpdates to listOf(KeyChord("Digit2", ctrl = true)),
            AppShortcut.GoToHistory to listOf(KeyChord("Digit3", ctrl = true)),
            AppShortcut.GoToBrowse to listOf(KeyChord("Digit4", ctrl = true)),
            AppShortcut.GoToProfile to listOf(KeyChord("Digit5", ctrl = true)),
            AppShortcut.Search to listOf(KeyChord("F", ctrl = true)),
            AppShortcut.ScrollToTop to listOf(KeyChord("Home", ctrl = true)),
            AppShortcut.RefreshLibrary to listOf(KeyChord("F5"), KeyChord("R", ctrl = true)),
            AppShortcut.OpenSettings to listOf(KeyChord("Comma", ctrl = true)),
            AppShortcut.GoBack to listOf(KeyChord("Left", alt = true), KeyChord("Mouse4")),
            AppShortcut.GoForward to listOf(KeyChord("Right", alt = true), KeyChord("Mouse5")),
            AppShortcut.ShowShortcuts to listOf(KeyChord("F1"), KeyChord("Slash", ctrl = true)),
        )
    }
}
