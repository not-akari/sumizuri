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
import com.sumizuri.app.feature.library.shelves.EditShelfRoute
import com.sumizuri.app.feature.library.shelves.ShelvesRoute
import com.sumizuri.app.feature.logs.LogsRoute
import com.sumizuri.app.feature.migration.MigrationRoute
import com.sumizuri.app.feature.migration.single.MigrateRoute
import com.sumizuri.app.feature.player.ChapterRoute
import com.sumizuri.app.feature.profile.arrange.ArrangeRoute
import com.sumizuri.app.feature.profile.layouts.LayoutsRoute
import com.sumizuri.app.feature.settings.SettingsRoute
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.SettingsTargetRoute
import com.sumizuri.app.feature.settings.controls.ControlsRoute
import com.sumizuri.app.feature.share.ImportRoute
import com.sumizuri.app.feature.theme.ThemeEditorRoute
import com.sumizuri.app.feature.title.PreviewRoute
import com.sumizuri.app.feature.title.TitleRoute
import com.sumizuri.app.feature.title.edit.EditTitleRoute
import com.sumizuri.app.feature.tv.browse.TvRepoRoute
import com.sumizuri.app.feature.tv.browse.TvSourceRoute
import com.sumizuri.app.feature.tv.settings.TvSettingsRoute
import com.sumizuri.app.feature.tv.settings.system.tvSettingsPage
import com.sumizuri.app.feature.tv.title.TvPreviewRoute
import com.sumizuri.app.feature.tv.title.TvTitleRoute
import com.sumizuri.app.feature.updates.UpdatesRoute
import com.sumizuri.app.feature.web.WebPage
import com.sumizuri.app.ui.kit.page.LocalPageBack
import com.sumizuri.app.ui.tv.LocalTv

// Draws the page that is on top, and turns what its screen asks for into navigation.
@Composable
fun PageHost(page: Page, navigation: NavigationViewModel) {
    when (page) {
        // A TV has its own pages for a source and for the sources of a repo.
        is Page.Source -> if (LocalTv.current) {
            TvSourceRoute(page.source) { source, entry -> navigation.push(Page.Preview(source, entry)) }
        } else {
            SourceBrowseRoute(
                source = page.source,
                onBack = navigation::pop,
                onOpenSaved = { navigation.push(Page.Saved(it)) },
                onOpenPreview = { source, entry -> navigation.push(Page.Preview(source, entry)) },
                onEditCode = { navigation.push(Page.ExtensionEditor(page.source.id)) },
            )
        }

        is Page.ExtensionEditor -> ExtensionEditorRoute(page.sourceId, onBack = navigation::pop)

        is Page.Comments -> CommentsRoute(page.target, onBack = navigation::pop)

        is Page.BlockScript -> BlockScriptRoute(page.blockId, onBack = navigation::pop)

        Page.ProfileLayouts -> LayoutsRoute(onBack = navigation::pop)

        Page.ArrangeBlocks -> ArrangeRoute(
            onBack = navigation::pop,
            onLayouts = { navigation.push(Page.ProfileLayouts) },
            onEditScript = { navigation.push(Page.BlockScript(it)) },
        )

        is Page.RepoSources -> if (LocalTv.current) {
            TvRepoRoute(
                page.repo,
            )
        } else {
            RepoRoute(page.repo, onBack = navigation::pop)
        }

        Page.Logs -> LogsRoute(onBack = navigation::pop)

        Page.Shelves -> ShelvesRoute(onBack = navigation::pop, onEdit = { navigation.push(Page.EditShelf(it)) })

        is Page.EditShelf -> EditShelfRoute(page.shelfId, onBack = navigation::pop)

        Page.LibraryDisplay -> LibraryDisplayRoute(onBack = navigation::pop)

        Page.Backup -> BackupRoute(onBack = navigation::pop, onMigrate = { navigation.push(Page.Migration(it)) })

        Page.Import -> ImportRoute(
            navigation::pop,
            { navigation.push(Page.Backup) },
        ) { navigation.replaceTop(Page.Backup) }

        // A TV has pages of its own, made for the remote, for the settings it has.
        is Page.SettingsPage -> {
            val tv = if (LocalTv.current) tvSettingsPage(page.target) { navigation.push(pageOf(it)) } else null
            if (tv != null) {
                BackedPage(navigation::pop) { tv() }
            } else {
                SettingsTargetRoute(page.target, navigation::pop, {
                    navigation.push(pageOf(it))
                }, {
                    navigation.push(Page.Migrate(it))
                }, {
                    navigation.push(Page.Migration(it))
                }, { navigation.push(Page.ThemeEditor(it)) }) { navigation.push(Page.Controls(it)) }
            }
        }

        is Page.ThemeEditor -> ThemeEditorRoute(page.themeId, onBack = navigation::pop)

        Page.Updates -> BackedPage(navigation::pop) {
            UpdatesRoute({
                navigation.push(Page.Saved(it))
            }, { navigation.push(Page.SettingsPage(SettingsTarget.MissingSources)) })
        }

        Page.History -> BackedPage(navigation::pop) { HistoryRoute { navigation.push(Page.Saved(it)) } }

        // A TV has settings of its own, in two panes made for the remote.
        Page.Settings -> if (LocalTv.current) {
            BackedPage(navigation::pop) { TvSettingsRoute(onOpen = { navigation.push(pageOf(it)) }) }
        } else {
            SettingsRoute(
                onBack = navigation::pop,
                onOpen = { navigation.push(pageOf(it)) },
                onOpenControls = { navigation.push(Page.Controls(it)) },
                onOpenTitle = { navigation.push(Page.Saved(it)) },
                onEditTheme = { navigation.push(Page.ThemeEditor(it)) },
            )
        }

        is Page.Controls -> ControlsRoute(page.page, onBack = navigation::pop)

        // A TV has a title page of its own, with the art, the buttons and the episodes made for the remote.
        is Page.Saved -> if (LocalTv.current) {
            BackedPage(navigation::pop) { TvTitleRoute(page.titleId) { navigation.push(Page.Reader(it)) } }
        } else {
            TitleRoute(
                titleId = page.titleId,
                onBack = navigation::pop,
                onOpenChapter = { navigation.push(Page.Reader(it)) },
                onMigrate = { navigation.push(Page.Migrate(it)) },
                onOpenComments = { navigation.push(Page.Comments(it)) },
                onEdit = { navigation.push(Page.EditTitle(it)) },
            )
        }

        is Page.EditTitle -> EditTitleRoute(page.titleId, onBack = navigation::pop)

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
            kind = page.kind,
            onBack = navigation::pop,
            onOpenSaved = { navigation.push(Page.Saved(it)) },
            onOpenPreview = { source, entry -> navigation.push(Page.Preview(source, entry)) },
        )

        is Page.Preview -> if (LocalTv.current) {
            BackedPage(navigation::pop) {
                TvPreviewRoute(
                    page.source,
                    page.entry,
                    onSaved = { navigation.replaceTop(Page.Saved(it)) },
                ) { id, chapter ->
                    navigation.replaceTop(Page.Saved(id))
                    navigation.push(Page.Reader(chapter))
                }
            }
        } else {
            PreviewRoute(
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
    SettingsTarget.Import -> Page.Import
    SettingsTarget.Logs -> Page.Logs
    SettingsTarget.Migration -> Page.Migration(emptyList())
    else -> Page.SettingsPage(target)
}
