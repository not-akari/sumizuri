package com.sumizuri.app.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import com.sumizuri.app.feature.backup.BackupRoute
import com.sumizuri.app.feature.blockscript.BlockScriptRoute
import com.sumizuri.app.feature.browse.editor.ExtensionEditorRoute
import com.sumizuri.app.feature.browse.repo.RepoRoute
import com.sumizuri.app.feature.browse.search.GlobalSearchRoute
import com.sumizuri.app.feature.browse.source.SourceBrowseRoute
import com.sumizuri.app.feature.comments.CommentsRoute
import com.sumizuri.app.feature.history.HistoryRoute
import com.sumizuri.app.feature.library.display.LibraryDisplayRoute
import com.sumizuri.app.feature.library.shelves.ShelvesRoute
import com.sumizuri.app.feature.logs.LogsRoute
import com.sumizuri.app.feature.migration.MigrationRoute
import com.sumizuri.app.feature.migration.single.MigrateRoute
import com.sumizuri.app.feature.player.ChapterRoute
import com.sumizuri.app.feature.profile.arrange.ArrangeRoute
import com.sumizuri.app.feature.settings.SettingsRoute
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.SettingsTargetRoute
import com.sumizuri.app.feature.settings.controls.ControlsRoute
import com.sumizuri.app.feature.theme.ThemeEditorRoute
import com.sumizuri.app.feature.title.PreviewRoute
import com.sumizuri.app.feature.title.TitleRoute
import com.sumizuri.app.feature.updates.UpdatesRoute
import com.sumizuri.app.feature.web.WebPage
import com.sumizuri.app.ui.kit.page.LocalPageBack

// Draws the page that is on top, and turns what its screen asks for into navigation.
@Composable
fun PageHost(page: Page, navigation: NavigationViewModel) {
    when (page) {
        is Page.Source -> SourceBrowseRoute(
            source = page.source,
            onBack = navigation::pop,
            onOpenSaved = { navigation.push(Page.Saved(it)) },
            onOpenPreview = { source, entry -> navigation.push(Page.Preview(source, entry)) },
            onEditCode = { navigation.push(Page.ExtensionEditor(page.source.id)) },
        )

        is Page.ExtensionEditor -> ExtensionEditorRoute(page.sourceId, onBack = navigation::pop)

        is Page.Comments -> CommentsRoute(page.target, onBack = navigation::pop)

        is Page.BlockScript -> BlockScriptRoute(page.blockId, onBack = navigation::pop)

        Page.ArrangeBlocks -> ArrangeRoute(
            onBack = navigation::pop,
            onEditScript = { navigation.push(Page.BlockScript(it)) },
        )

        is Page.RepoSources -> RepoRoute(page.repo, onBack = navigation::pop)

        Page.Logs -> LogsRoute(onBack = navigation::pop)

        Page.Shelves -> ShelvesRoute(onBack = navigation::pop)

        Page.LibraryDisplay -> LibraryDisplayRoute(onBack = navigation::pop)

        Page.Backup -> BackupRoute(onBack = navigation::pop, onMigrate = { navigation.push(Page.Migration(it)) })

        is Page.SettingsPage -> SettingsTargetRoute(page.target, navigation::pop, {
            navigation.push(pageOf(it))
        }, {
            navigation.push(Page.Migrate(it))
        }, {
            navigation.push(Page.Migration(it))
        }, { navigation.push(Page.ThemeEditor(it)) }) { navigation.push(Page.Controls(it)) }

        is Page.ThemeEditor -> ThemeEditorRoute(page.themeId, onBack = navigation::pop)

        Page.Updates -> BackedPage(navigation::pop) {
            UpdatesRoute({
                navigation.push(Page.Saved(it))
            }, { navigation.push(Page.SettingsPage(SettingsTarget.MissingSources)) })
        }

        Page.History -> BackedPage(navigation::pop) { HistoryRoute { navigation.push(Page.Saved(it)) } }

        Page.Settings -> SettingsRoute(
            onBack = navigation::pop,
            onOpen = { navigation.push(pageOf(it)) },
            onOpenControls = { navigation.push(Page.Controls(it)) },
            onOpenTitle = { navigation.push(Page.Saved(it)) },
            onEditTheme = { navigation.push(Page.ThemeEditor(it)) },
        )

        is Page.Controls -> ControlsRoute(page.page, onBack = navigation::pop)

        is Page.Saved -> TitleRoute(
            titleId = page.titleId,
            onBack = navigation::pop,
            onOpenChapter = { navigation.push(Page.Reader(it)) },
            onMigrate = { navigation.push(Page.Migrate(it)) },
            onOpenComments = { navigation.push(Page.Comments(it)) },
        )

        is Page.Migration -> MigrationRoute(page.ids, onBack = navigation::pop, onOpenTitle = {
            navigation.push(Page.Saved(it))
        })

        is Page.Migrate -> MigrateRoute(
            titleId = page.titleId,
            onBack = navigation::pop,
            // The moved title takes the place of the one that was open, and a list the move was started from is left as it was.
            onMoved = { id -> navigation.moved(page.titleId, id) },
        )

        is Page.Web -> WebPage(page.url, onBack = navigation::pop)

        is Page.Reader -> ChapterRoute(
            chapterId = page.chapterId,
            onBack = navigation::pop,
            // The next chapter takes the place of this one, so back still leads to the title.
            onOpenChapter = { navigation.replaceTop(Page.Reader(it, fromReader = true)) },
            onOpenComments = { navigation.push(Page.Comments(it)) },
            quiet = page.fromReader,
        )

        is Page.GlobalSearch -> GlobalSearchRoute(
            initial = page.query,
            onBack = navigation::pop,
            onOpenSaved = { navigation.push(Page.Saved(it)) },
            onOpenPreview = { source, entry -> navigation.push(Page.Preview(source, entry)) },
        )

        is Page.Preview -> PreviewRoute(
            source = page.source,
            entry = page.entry,
            onBack = navigation::pop,
            // The preview becomes the saved title in the same place, so back still leads to the grid.
            onSaved = { id -> navigation.replaceTop(Page.Saved(id)) },
            // Reading a chapter saves the title out of the library, so the reader opens over the saved page and back leads to it.
            onRead = { id, chapter ->
                navigation.replaceTop(Page.Saved(id))
                navigation.push(Page.Reader(chapter))
            },
            onOpenComments = { navigation.push(Page.Comments(it)) },
        )
    }
}

// A page that is also a tab, opened from the library. Its own bar shows the back arrow.
@Composable
private fun BackedPage(onBack: () -> Unit, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalPageBack provides onBack) {
        Box(Modifier.fillMaxSize()) { content() }
    }
}

// The page that opens for a target of the settings.
private fun pageOf(target: SettingsTarget): Page = when (target) {
    SettingsTarget.LibraryDisplay -> Page.LibraryDisplay
    SettingsTarget.Shelves -> Page.Shelves
    SettingsTarget.Backup -> Page.Backup
    SettingsTarget.Logs -> Page.Logs
    SettingsTarget.Migration -> Page.Migration(emptyList())
    else -> Page.SettingsPage(target)
}
