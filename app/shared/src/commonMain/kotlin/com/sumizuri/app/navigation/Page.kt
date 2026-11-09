package com.sumizuri.app.navigation

import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.controls.ControlsPage
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource

// A page that opens over the main tabs and goes away with the back action.
sealed interface Page {
    // A source open for browsing.
    data class Source(val source: InstalledSource) : Page

    // A chapter of a saved title, open in the reader. From the reader itself (the next or the previous chapter) it opens without the opening card.
    data class Reader(val chapterId: Long, val fromReader: Boolean = false) : Page

    // The lines the app has logged.
    data object Logs : Page

    // The sources one repo lists, to install from.
    data class RepoSources(val repo: Repo) : Page

    // A title that is saved in the database.
    data class Saved(val titleId: Long) : Page

    // One of the pages where keys, taps and gestures are set.
    data class Controls(val page: ControlsPage) : Page

    // The shelves of the library, where they are made, named and put in order.
    data object Shelves : Page
    data object LibraryDisplay : Page

    // Where a library is brought back from a backup file.
    data object Backup : Page

    // The updates and the history as pages, for when the person took their tabs away.
    data object Updates : Page
    data object History : Page

    // The settings, which are opened from the profile.
    data object Settings : Page

    // The editor of a theme, opened on the theme with this id. A built in theme is copied when it is saved.
    data class ThemeEditor(val themeId: String) : Page

    // A page of the settings that has no page of its own above.
    data class SettingsPage(val target: SettingsTarget) : Page

    // The search that moves a saved title to another source.
    data class Migrate(val titleId: Long) : Page

    // The work of moving many titles to other sources. The ids are the titles to take, and none means the whole library.
    data class Migration(val ids: List<Long>) : Page

    // A site shown inside the app, in the browser the sources use.
    data class Web(val url: String) : Page

    // An entry of a source that is not saved yet.
    data class Preview(val source: InstalledSource, val entry: SourceEntry) : Page

    // The search of every installed source at once, started with these words.
    data class GlobalSearch(val query: String = "") : Page

    // The editor of an extension: the code of an installed source, or a new one started from the template of this engine when there is no id.
    data class ExtensionEditor(val sourceId: String?) : Page

    // The comments of a title or of one of its chapters, as its source has them.
    data class Comments(val target: CommentsTarget) : Page

    // The page where the blocks of the profile are put in order, sized, added and removed.
    data object ArrangeBlocks : Page

    // The editor of the script of one block of the profile.
    data class BlockScript(val blockId: String) : Page
}

// A page that draws to the edges of the screen, under the bars of the system, and keeps its own controls clear of them: the reader and the player fill the screen, and a title page has its cover behind the status bar. Every other page is kept clear of the bars as a whole.
val Page.edgeToEdge: Boolean get() = this is Page.Reader || this is Page.Saved || this is Page.Preview
