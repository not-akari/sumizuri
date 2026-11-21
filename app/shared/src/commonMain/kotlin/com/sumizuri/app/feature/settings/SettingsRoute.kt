package com.sumizuri.app.feature.settings

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.feature.backup.BackupRoute
import com.sumizuri.app.feature.library.display.LibraryDisplayRoute
import com.sumizuri.app.feature.library.shelves.EditShelfRoute
import com.sumizuri.app.feature.library.shelves.ShelvesRoute
import com.sumizuri.app.feature.logs.LogsRoute
import com.sumizuri.app.feature.migration.MigrationRoute
import com.sumizuri.app.feature.migration.single.MigrateRoute
import com.sumizuri.app.feature.settings.controls.ControlsPage
import com.sumizuri.app.feature.settings.controls.ControlsRoute
import com.sumizuri.app.feature.share.ImportRoute
import com.sumizuri.app.feature.theme.ThemeViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.settings_language_system
import com.sumizuri.app.ui.kit.page.LocalHideBack
import com.sumizuri.app.ui.motion.LocalPageMotion
import com.sumizuri.app.ui.motion.pageTransform
import com.sumizuri.app.ui.motion.rememberMotionShift
import org.jetbrains.compose.resources.stringResource
// From this width the settings show the list and the open page side by side.
private val TwoPaneWidth = 840.dp

// A page open beside the list: a page of the settings, one of the controls, or the moving of one title or of many, which the pages of the settings lead to.
private sealed interface PaneEntry {
    data class Target(val target: SettingsTarget) : PaneEntry
    data class Controls(val page: ControlsPage) : PaneEntry
    data class Migrate(val titleId: Long) : PaneEntry
    data class Migration(val ids: List<Long>) : PaneEntry
    data class EditShelf(val shelfId: Long) : PaneEntry
}

// The pages open beside the list, the last one on top. It is kept outside the page, so a title opened over the settings and closed again finds the same page beside the list.
private class SettingsPane : ViewModel() {
    var entries by mutableStateOf(listOf<PaneEntry>())
}

@Composable
fun SettingsRoute(
    onBack: () -> Unit,
    onOpen: (SettingsTarget) -> Unit,
    onOpenControls: (ControlsPage) -> Unit,
    onOpenTitle: (Long) -> Unit,
    // The editor of a theme opens over the whole window, since it needs the room for its preview.
    onEditTheme: (String) -> Unit,
) {
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val reader = viewModel { GlobalReaderViewModel(container.reading) }
    val themes = viewModel { ThemeViewModel(container.themes) }
    val paneModel = viewModel { SettingsPane() }
    val themeMode by settings.themeMode.collectAsStateWithLifecycle()
    val themeName by themes.active.collectAsStateWithLifecycle()
    val language by settings.language.collectAsStateWithLifecycle()
    val updateHours by settings.updateHours.collectAsStateWithLifecycle()
    val navStyle by settings.navStyle.collectAsStateWithLifecycle()
    val readerSettings by reader.settings.collectAsStateWithLifecycle()
    val library by container.libraryPrefs.prefs.collectAsStateWithLifecycle(LibraryPrefs())
    val unreachable by remember(
        container,
    ) { container.library.unreachableSources }.collectAsStateWithLifecycle(emptyList())
    val shelves by remember(container) { container.categories.categories }.collectAsStateWithLifecycle(emptyList())
    val languageName = language.nativeName ?: stringResource(Res.string.settings_language_system)
    val now =
        SettingsNow(
            themeMode, themeName.name, languageName, library, readerSettings, updateHours,
            unreachable.sumOf {
                it.count
            },
            navStyle, shelves.size,
        )
    BoxWithConstraints(Modifier.fillMaxSize()) {
        if (maxWidth < TwoPaneWidth) {
            SettingsScreen(settingsPages(now, SettingsOpens(onOpen, onOpenControls)), onBack)
            return@BoxWithConstraints
        }
        val pane = paneModel.entries

        // A row of the list starts the pages beside it again, and a page that leads on adds to them, so its arrow goes back.
        fun push(entry: PaneEntry) {
            paneModel.entries = pane + entry
        }
        val back = { paneModel.entries = pane.dropLast(1) }
        // Back closes the pages beside the list one at a time, and the settings only when one is left.
        NavigationBackHandler(
            rememberNavigationEventState(NavigationEventInfo.None),
            isBackEnabled = pane.size > 1,
        ) { back() }
        val top = pane.lastOrNull() ?: PaneEntry.Target(SettingsTarget.Appearance)
        val selected = when (val first = pane.firstOrNull() ?: top) {
            is PaneEntry.Target -> first.target
            else -> null
        }
        val pages =
            settingsPages(
                now,
                SettingsOpens({ paneModel.entries = listOf(PaneEntry.Target(it)) }, { page ->
                    paneModel.entries =
                        listOf(PaneEntry.Target(SettingsTarget.Controls), PaneEntry.Controls(page))
                }),
            )
        SettingsScreen(pages, onBack, selected) {
            // The first page needs no arrow, since the list beside it is the way to another. A page it led to has one, back to it. A page it leads to comes in over it, and going back uncovers it again, in the motion the person chose.
            val style = LocalPageMotion.current
            val ms = style.pageMs()
            val shift = rememberMotionShift()
            AnimatedContent(PaneShown(top, pane.size), transitionSpec = {
                pageTransform(
                    style,
                    ms,
                    targetState.depth >= initialState.depth,
                    shift,
                ) using
                    null
            }, label = "pane") { now ->
                CompositionLocalProvider(LocalHideBack provides (now.depth <= 1)) {
                    when (val shown = now.entry) {
                        is PaneEntry.Target -> when (shown.target) {
                            SettingsTarget.LibraryDisplay -> LibraryDisplayRoute(onBack = back)

                            SettingsTarget.Shelves -> ShelvesRoute(onBack = back) { push(PaneEntry.EditShelf(it)) }

                            SettingsTarget.Backup -> BackupRoute(
                                onBack = back,
                            ) { ids -> push(PaneEntry.Migration(ids)) }

                            SettingsTarget.Logs -> LogsRoute(onBack = back)

                            SettingsTarget.Import -> {
                                val backup = { push(PaneEntry.Target(SettingsTarget.Backup)) }
                                ImportRoute(back, backup, backup)
                            }

                            SettingsTarget.Migration -> MigrationRoute(
                                emptyList(),
                                onBack = back,
                                onOpenTitle = onOpenTitle,
                            )

                            else -> SettingsTargetRoute(
                                shown.target,
                                back,
                                { push(PaneEntry.Target(it)) },
                                { push(PaneEntry.Migrate(it)) },
                                { push(PaneEntry.Migration(it)) },
                                onEditTheme,
                            ) { page -> push(PaneEntry.Controls(page)) }
                        }

                        is PaneEntry.Controls -> ControlsRoute(shown.page, back)

                        // A title moved from beside the list goes back to the page it came from, which shows it gone from the missing ones.
                        is PaneEntry.Migrate -> MigrateRoute(shown.titleId, onBack = back, onMoved = { back() })

                        is PaneEntry.Migration -> MigrationRoute(shown.ids, onBack = back, onOpenTitle = onOpenTitle)

                        is PaneEntry.EditShelf -> EditShelfRoute(shown.shelfId, onBack = back)
                    }
                }
            }
        }
    }
}

// What the pane beside the list shows: the page on top and how many are open, which tells a page coming in from one going back.
private data class PaneShown(val entry: PaneEntry, val depth: Int)
