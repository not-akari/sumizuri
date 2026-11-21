package com.sumizuri.app.feature.title.layout

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.RowScope
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CenterFocusStrong
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.DownloadForOffline
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.FilterList
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.RemoveDone
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonColors
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.vector.ImageVector
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.chapter.ChapterOptionsSheet
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_menu_mark_all_read
import com.sumizuri.app.shared.resources.chapter_menu_mark_all_unread
import com.sumizuri.app.shared.resources.chapter_menu_more
import com.sumizuri.app.shared.resources.chapter_menu_select_all
import com.sumizuri.app.shared.resources.chapter_options
import com.sumizuri.app.shared.resources.download_all
import com.sumizuri.app.shared.resources.download_delete_all
import com.sumizuri.app.shared.resources.download_title
import com.sumizuri.app.shared.resources.download_unread
import com.sumizuri.app.shared.resources.refresh
import com.sumizuri.app.shared.resources.title_action_background
import com.sumizuri.app.shared.resources.title_action_edit
import com.sumizuri.app.shared.resources.title_action_move
import com.sumizuri.app.shared.resources.title_action_web
import com.sumizuri.app.shared.resources.title_menu_group
import com.sumizuri.app.shared.resources.title_view_chapters
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuDivider
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.kit.menu.AppMenuLabel
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import org.jetbrains.compose.resources.stringResource

// The buttons at the right of the bar of a title page, the same on a phone and a computer: ask the source again, the options of the chapter list, and one menu with the things to do with all the chapters and then with the title itself. Each sits on the same round shade as the back arrow, so it reads over the cover.
@Composable
internal fun RowScope.TitleBarActions(
    state: TitleState,
    title: Title,
    calls: TitleCallbacks,
    onBackground: () -> Unit,
    shade: IconButtonColors,
) {
    var options by remember { mutableStateOf(false) }
    var open by remember { mutableStateOf(false) }
    val openSite = LocalOpenSite.current
    if (state.readable) {
        IconButton(calls.onRefresh, enabled = !state.loading, colors = shade) {
            Icon(Icons.Outlined.Refresh, stringResource(Res.string.refresh))
        }
    }
    // The options of the list, tinted while a filter hides some chapters.
    IconButton({ options = true }, colors = shade) {
        Icon(
            Icons.Outlined.FilterList,
            stringResource(Res.string.chapter_options),
            tint = if (state.filtering) MaterialTheme.colorScheme.primary else LocalContentColor.current,
        )
    }
    // A preview whose source gives no website has nothing for the menu, so it has no button.
    val web = title.webUrl?.takeIf { it.isNotBlank() }
    if (state.preview && web == null) {
        if (options) ChapterOptionsSheet(state, calls) { options = false }
        return
    }
    // The menu opens under its button, so the two are in one box.
    Box {
        IconButton({
            open = true
        }, colors = shade) { Icon(Icons.Outlined.MoreVert, stringResource(Res.string.chapter_menu_more)) }
        AppMenu(open, { open = false }) {
            @Composable
            fun item(text: String, icon: ImageVector, danger: Boolean = false, action: () -> Unit) =
                AppMenuItem(text, icon, {
                    open = false
                    action()
                }, danger = danger)
            // A preview has nothing to mark, pick or save.
            if (!state.preview) {
                AppMenuLabel(stringResource(Res.string.title_view_chapters))
                item(
                    stringResource(Res.string.chapter_menu_select_all),
                    Icons.Outlined.Checklist,
                    action = calls.selection.onSelectAll,
                )
                item(
                    stringResource(Res.string.chapter_menu_mark_all_read),
                    Icons.Outlined.DoneAll,
                ) { calls.onMarkAll(true) }
                item(
                    stringResource(Res.string.chapter_menu_mark_all_unread),
                    Icons.Outlined.RemoveDone,
                ) { calls.onMarkAll(false) }
                calls.downloads?.let { downloads ->
                    val start = downloads.onDownloadAll
                    if (start != null || state.downloads.isNotEmpty()) {
                        AppMenuDivider()
                        AppMenuLabel(stringResource(Res.string.download_title))
                    }
                    start?.let {
                        item(stringResource(Res.string.download_unread), Icons.Outlined.Download) { it(true) }
                        item(stringResource(Res.string.download_all), Icons.Outlined.DownloadForOffline) { it(false) }
                    }
                    if (state.downloads.isNotEmpty()) {
                        item(
                            stringResource(Res.string.download_delete_all),
                            Icons.Outlined.DeleteOutline,
                            danger = true,
                            action = downloads.onRemoveAll,
                        )
                    }
                }
                AppMenuDivider()
                AppMenuLabel(stringResource(Res.string.title_menu_group))
                item(stringResource(Res.string.title_action_edit), Icons.Outlined.Edit, action = calls.onEdit)
            }
            web?.let { address ->
                if (state.preview) AppMenuLabel(stringResource(Res.string.title_menu_group))
                item(stringResource(Res.string.title_action_web), Icons.Outlined.Public) { openSite(address) }
            }
            // A title that cannot be reached has a button for moving it of its own.
            if (!state.preview &&
                state.readable
            ) {
                item(stringResource(Res.string.title_action_move), Icons.Outlined.SwapHoriz, action = calls.onMigrate)
            }
            if (!state.preview && !title.coverUrl.isNullOrBlank()) {
                item(
                    stringResource(Res.string.title_action_background),
                    Icons.Outlined.CenterFocusStrong,
                    action = onBackground,
                )
            }
        }
    }
    if (options) ChapterOptionsSheet(state, calls) { options = false }
}
