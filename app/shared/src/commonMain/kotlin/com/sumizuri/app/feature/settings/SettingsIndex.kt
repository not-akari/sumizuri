package com.sumizuri.app.feature.settings

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.automirrored.outlined.Label
import androidx.compose.material.icons.outlined.AutoStories
import androidx.compose.material.icons.outlined.BugReport
import androidx.compose.material.icons.outlined.Dashboard
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.LinkOff
import androidx.compose.material.icons.outlined.Lan
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.PieChart
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.material.icons.outlined.SettingsBackupRestore
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material.icons.outlined.SystemUpdate
import androidx.compose.material.icons.outlined.TouchApp
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.Update
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.data.net.networkSupported
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.appupdate.UpdateState
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.controls.ControlsPage
import com.sumizuri.app.feature.settings.library.updateIntervalLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.about_licenses
import com.sumizuri.app.shared.resources.advanced_reset_library
import com.sumizuri.app.shared.resources.advanced_reset_look
import com.sumizuri.app.shared.resources.advanced_reset_reader
import com.sumizuri.app.shared.resources.appupdate_auto_check
import com.sumizuri.app.shared.resources.appupdate_changes
import com.sumizuri.app.shared.resources.appupdate_check_now
import com.sumizuri.app.shared.resources.appupdate_new_version
import com.sumizuri.app.shared.resources.appupdate_prerelease
import com.sumizuri.app.shared.resources.appupdate_source
import com.sumizuri.app.shared.resources.appupdate_title
import com.sumizuri.app.shared.resources.chapter_filter_bookmarked
import com.sumizuri.app.shared.resources.chapter_filter_downloaded
import com.sumizuri.app.shared.resources.chapter_filter_title
import com.sumizuri.app.shared.resources.chapter_filter_unread
import com.sumizuri.app.shared.resources.chapter_list_duplicates
import com.sumizuri.app.shared.resources.chapter_list_grid
import com.sumizuri.app.shared.resources.chapter_list_pictures
import com.sumizuri.app.shared.resources.chapter_list_oldest
import com.sumizuri.app.shared.resources.chapter_settings_hint
import com.sumizuri.app.shared.resources.chapter_settings_title
import com.sumizuri.app.shared.resources.chapter_sort_title
import com.sumizuri.app.shared.resources.controls_hint
import com.sumizuri.app.shared.resources.controls_title
import com.sumizuri.app.shared.resources.diagnostics_copy
import com.sumizuri.app.shared.resources.display_collapsible_search
import com.sumizuri.app.shared.resources.display_cover_size
import com.sumizuri.app.shared.resources.display_favorites
import com.sumizuri.app.shared.resources.display_gap
import com.sumizuri.app.shared.resources.display_group_corners
import com.sumizuri.app.shared.resources.display_hide_all_tab
import com.sumizuri.app.shared.resources.display_hide_no_shelf_tab
import com.sumizuri.app.shared.resources.display_home_cover
import com.sumizuri.app.shared.resources.display_name_size
import com.sumizuri.app.shared.resources.display_progress
import com.sumizuri.app.shared.resources.display_style
import com.sumizuri.app.shared.resources.display_title
import com.sumizuri.app.shared.resources.download_ahead
import com.sumizuri.app.shared.resources.download_delete_after
import com.sumizuri.app.shared.resources.download_delete_on_mark
import com.sumizuri.app.shared.resources.download_keep_bookmarked
import com.sumizuri.app.shared.resources.download_new
import com.sumizuri.app.shared.resources.download_new_limit
import com.sumizuri.app.shared.resources.download_pages_at_once
import com.sumizuri.app.shared.resources.download_pause
import com.sumizuri.app.shared.resources.download_queue_open
import com.sumizuri.app.shared.resources.download_retry_all
import com.sumizuri.app.shared.resources.download_settings_hint
import com.sumizuri.app.shared.resources.download_skip_shelves
import com.sumizuri.app.shared.resources.download_title
import com.sumizuri.app.shared.resources.download_wifi_only
import com.sumizuri.app.shared.resources.incognito_mode
import com.sumizuri.app.shared.resources.legal_title
import com.sumizuri.app.shared.resources.lock_after
import com.sumizuri.app.shared.resources.lock_now
import com.sumizuri.app.shared.resources.lock_on
import com.sumizuri.app.shared.resources.mig_rule_chapters
import com.sumizuri.app.shared.resources.mig_rule_compare_all
import com.sumizuri.app.shared.resources.mig_rule_keep_old
import com.sumizuri.app.shared.resources.mig_rule_strictness
import com.sumizuri.app.shared.resources.mig_rule_try_address
import com.sumizuri.app.shared.resources.mig_subtitle
import com.sumizuri.app.shared.resources.mig_title
import com.sumizuri.app.shared.resources.page_motion
import com.sumizuri.app.shared.resources.page_stagger
import com.sumizuri.app.shared.resources.player_set_auto_next
import com.sumizuri.app.shared.resources.player_set_double_tap
import com.sumizuri.app.shared.resources.player_set_hold_speed
import com.sumizuri.app.shared.resources.player_set_language
import com.sumizuri.app.shared.resources.player_set_quality
import com.sumizuri.app.shared.resources.player_set_resume
import com.sumizuri.app.shared.resources.player_set_seek
import com.sumizuri.app.shared.resources.player_set_show_subtitles
import com.sumizuri.app.shared.resources.player_set_skip
import com.sumizuri.app.shared.resources.player_set_speed
import com.sumizuri.app.shared.resources.player_set_watched
import com.sumizuri.app.shared.resources.privacy_title
import com.sumizuri.app.shared.resources.reader_auto_speed
import com.sumizuri.app.shared.resources.reader_background
import com.sumizuri.app.shared.resources.reader_brightness
import com.sumizuri.app.shared.resources.reader_default_mode
import com.sumizuri.app.shared.resources.reader_dual
import com.sumizuri.app.shared.resources.reader_font
import com.sumizuri.app.shared.resources.reader_gap
import com.sumizuri.app.shared.resources.reader_hide_bars
import com.sumizuri.app.shared.resources.reader_inline_next
import com.sumizuri.app.shared.resources.reader_invert_taps
import com.sumizuri.app.shared.resources.reader_keep_on
import com.sumizuri.app.shared.resources.reader_line_height
import com.sumizuri.app.shared.resources.reader_paragraph_gap
import com.sumizuri.app.shared.resources.reader_quality
import com.sumizuri.app.shared.resources.reader_scale
import com.sumizuri.app.shared.resources.reader_skip_filtered
import com.sumizuri.app.shared.resources.reader_skip_read
import com.sumizuri.app.shared.resources.reader_text_align
import com.sumizuri.app.shared.resources.reader_text_size
import com.sumizuri.app.shared.resources.reader_warmth
import com.sumizuri.app.shared.resources.reader_width
import com.sumizuri.app.shared.resources.reader_wpm
import com.sumizuri.app.shared.resources.secure_screen
import com.sumizuri.app.shared.resources.settings_about
import com.sumizuri.app.shared.resources.settings_advanced
import com.sumizuri.app.shared.resources.settings_advanced_hint
import com.sumizuri.app.shared.resources.settings_appearance
import com.sumizuri.app.shared.resources.settings_backup
import com.sumizuri.app.shared.resources.settings_backup_hint
import com.sumizuri.app.shared.resources.settings_compact_lists
import com.sumizuri.app.shared.resources.settings_diagnostics
import com.sumizuri.app.shared.resources.settings_diagnostics_hint
import com.sumizuri.app.shared.resources.settings_home_parts
import com.sumizuri.app.shared.resources.settings_language
import com.sumizuri.app.shared.resources.settings_layout
import com.sumizuri.app.shared.resources.settings_library_updates
import com.sumizuri.app.shared.resources.settings_logs
import com.sumizuri.app.shared.resources.settings_missing_sources
import com.sumizuri.app.shared.resources.settings_mode
import com.sumizuri.app.shared.resources.settings_nav_style
import com.sumizuri.app.shared.resources.settings_oled
import com.sumizuri.app.shared.resources.settings_oled_glow
import com.sumizuri.app.shared.resources.settings_player
import com.sumizuri.app.shared.resources.settings_player_hint
import com.sumizuri.app.shared.resources.settings_reading
import com.sumizuri.app.shared.resources.settings_reduce_motion
import com.sumizuri.app.shared.resources.network_connections
import com.sumizuri.app.shared.resources.network_routes_title
import com.sumizuri.app.shared.resources.network_type_wireguard
import com.sumizuri.app.shared.resources.settings_network
import com.sumizuri.app.shared.resources.settings_network_hint
import com.sumizuri.app.shared.resources.settings_security
import com.sumizuri.app.shared.resources.settings_security_hint
import com.sumizuri.app.shared.resources.settings_storage
import com.sumizuri.app.shared.resources.settings_storage_hint
import com.sumizuri.app.shared.resources.settings_theme
import com.sumizuri.app.shared.resources.settings_version
import com.sumizuri.app.shared.resources.shelves_count
import com.sumizuri.app.shared.resources.shelves_hint
import com.sumizuri.app.shared.resources.shelves_title
import com.sumizuri.app.shared.resources.storage_image_cache
import com.sumizuri.app.shared.resources.storage_page_cache
import com.sumizuri.app.shared.resources.storage_path_database
import com.sumizuri.app.shared.resources.storage_path_images
import com.sumizuri.app.shared.resources.theme_import
import com.sumizuri.app.shared.resources.theme_new
import com.sumizuri.app.shared.resources.titles_count
import com.sumizuri.app.shared.resources.update_background
import com.sumizuri.app.shared.resources.update_charging
import com.sumizuri.app.shared.resources.update_interval
import com.sumizuri.app.shared.resources.update_notify
import com.sumizuri.app.shared.resources.update_skip_completed
import com.sumizuri.app.shared.resources.update_skip_not_started
import com.sumizuri.app.shared.resources.update_skip_unread
import com.sumizuri.app.shared.resources.update_wifi_only
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The pages of the settings with what each is set to now. This list is the one place that says which pages there are, so the home and the search both come from it. The words a search can find inside a page are the names of the settings in it.
@Composable
internal fun settingsPages(now: SettingsNow, opens: SettingsOpens): List<SettingsPage> {
    val theme = stringResource(now.themeMode.label)
    val style = stringResource(now.library.style.label)
    val readerMode = stringResource(now.reader.mode.label)
    val font = stringResource(now.reader.font.label)
    val updateEvery = updateIntervalLabel(now.updateHours)
    val update by LocalAppContainer.current.updater.state
        .collectAsStateWithLifecycle()
    val updateLine = (update as? UpdateState.Available)?.let { stringResource(Res.string.appupdate_new_version, it.latest.version) } ?: stringResource(Res.string.settings_version, BuildInfo.Version)
    val unreachable = if (now.unreachable > 0) pluralStringResource(Res.plurals.titles_count, now.unreachable, now.unreachable) else ""
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    // The new pages the person has opened. While it is being read every page counts as opened, so no mark shows for a moment and goes.
    val opened by remember(container) { container.settings.text(SettingKey.SettingsSeen).map { it.orEmpty().split(',').toSet() } }.collectAsStateWithLifecycle(null)
    fun page(group: SettingsGroup, icon: ImageVector, title: String, summary: String, items: List<StringResource>, target: SettingsTarget): SettingsPage {
        val seen = opened
        val fresh = seen != null && target in NewPages && target.name !in seen
        return SettingsPage(group, icon, title, summary, items, target, fresh) {
            if (fresh) scope.launch { container.settings.setText(SettingKey.SettingsSeen, (seen + target.name).filter { it.isNotEmpty() }.joinToString(",")) }
            opens.target(target)
        }
    }
    val navigation = stringResource(now.navStyle.label)
    // The pages of controls are found by their names and notes, and the search opens the page that leads to them.
    val controlsItems = ControlsPage.entries.flatMap { listOf(it.title, it.hint) }
    return buildList {
        // Look: what the app looks like and how it is laid out, with what each is set to.
        add(page(SettingsGroup.Look, Icons.Outlined.Palette, stringResource(Res.string.settings_appearance), "${now.themeName} · $theme", listOf(Res.string.settings_theme, Res.string.settings_mode, Res.string.settings_oled, Res.string.settings_oled_glow, Res.string.theme_new, Res.string.theme_import), SettingsTarget.Appearance))
        add(page(SettingsGroup.Look, Icons.Outlined.Dashboard, stringResource(Res.string.settings_layout), "${now.language} · $navigation", listOf(Res.string.settings_language, Res.string.settings_compact_lists, Res.string.settings_reduce_motion, Res.string.page_motion, Res.string.page_stagger, Res.string.settings_nav_style, Res.string.settings_home_parts), SettingsTarget.Layout))

        // Library: how it is shown, its shelves and its checks for new chapters.
        val displayItems = listOf(
            Res.string.display_style, Res.string.display_cover_size, Res.string.display_gap, Res.string.display_name_size, Res.string.display_progress,
            Res.string.display_favorites, Res.string.display_group_corners, Res.string.display_home_cover, Res.string.display_hide_all_tab,
            Res.string.display_hide_no_shelf_tab, Res.string.display_collapsible_search,
        )
        add(page(SettingsGroup.Library, Icons.Outlined.GridView, stringResource(Res.string.display_title), if (now.library.style.isGrid) "$style · ${now.library.cellWidth} dp" else style, displayItems, SettingsTarget.LibraryDisplay))
        add(page(SettingsGroup.Library, Icons.AutoMirrored.Outlined.Label, stringResource(Res.string.shelves_title), if (now.shelves > 0) pluralStringResource(Res.plurals.shelves_count, now.shelves, now.shelves) else stringResource(Res.string.shelves_hint), emptyList(), SettingsTarget.Shelves))
        add(page(SettingsGroup.Library, Icons.Outlined.Update, stringResource(Res.string.settings_library_updates), updateEvery, listOf(Res.string.update_interval, Res.string.update_background, Res.string.update_wifi_only, Res.string.update_charging, Res.string.update_notify, Res.string.update_skip_completed, Res.string.update_skip_not_started, Res.string.update_skip_unread), SettingsTarget.LibraryUpdates))
        add(page(SettingsGroup.Library, Icons.AutoMirrored.Outlined.FormatListBulleted, stringResource(Res.string.chapter_settings_title), stringResource(Res.string.chapter_settings_hint), listOf(Res.string.chapter_sort_title, Res.string.chapter_list_oldest, Res.string.chapter_list_grid, Res.string.chapter_list_pictures, Res.string.chapter_list_duplicates, Res.string.chapter_filter_title, Res.string.chapter_filter_unread, Res.string.chapter_filter_downloaded, Res.string.chapter_filter_bookmarked, Res.string.reader_skip_read, Res.string.reader_skip_filtered), SettingsTarget.ChapterList))

        // Reading: the reader, the player and every key, tap and gesture in one place.
        add(page(SettingsGroup.Reading, Icons.Outlined.AutoStories, stringResource(Res.string.settings_reading), "$readerMode · $font · ${now.reader.fontSize}", listOf(Res.string.reader_default_mode, Res.string.reader_scale, Res.string.reader_quality, Res.string.reader_background, Res.string.reader_gap, Res.string.reader_width, Res.string.reader_dual, Res.string.reader_invert_taps, Res.string.reader_font, Res.string.reader_text_align, Res.string.reader_text_size, Res.string.reader_line_height, Res.string.reader_paragraph_gap, Res.string.reader_keep_on, Res.string.reader_hide_bars, Res.string.reader_inline_next, Res.string.reader_brightness, Res.string.reader_warmth, Res.string.reader_auto_speed, Res.string.reader_wpm), SettingsTarget.Reading))
        add(page(SettingsGroup.Reading, Icons.Outlined.PlayCircle, stringResource(Res.string.settings_player), stringResource(Res.string.settings_player_hint), listOf(Res.string.player_set_speed, Res.string.player_set_quality, Res.string.player_set_resume, Res.string.player_set_auto_next, Res.string.player_set_watched, Res.string.player_set_seek, Res.string.player_set_skip, Res.string.player_set_double_tap, Res.string.player_set_hold_speed, Res.string.player_set_show_subtitles, Res.string.player_set_language), SettingsTarget.Player))
        add(page(SettingsGroup.Reading, Icons.Outlined.TouchApp, stringResource(Res.string.controls_title), stringResource(Res.string.controls_hint), controlsItems, SettingsTarget.Controls))

        // Data: what is kept and moved, the backups, and the tools that mend the library.
        add(page(SettingsGroup.Data, Icons.Outlined.Download, stringResource(Res.string.download_title), stringResource(Res.string.download_settings_hint), listOf(Res.string.download_queue_open, Res.string.download_pause, Res.string.download_retry_all, Res.string.download_wifi_only, Res.string.download_pages_at_once, Res.string.download_new, Res.string.download_new_limit, Res.string.download_skip_shelves, Res.string.download_ahead, Res.string.download_delete_after, Res.string.download_delete_on_mark, Res.string.download_keep_bookmarked), SettingsTarget.DownloadOptions))
        add(page(SettingsGroup.Data, Icons.Outlined.SettingsBackupRestore, stringResource(Res.string.settings_backup), stringResource(Res.string.settings_backup_hint), emptyList(), SettingsTarget.Backup))
        add(page(SettingsGroup.Data, Icons.Outlined.PieChart, stringResource(Res.string.settings_storage), stringResource(Res.string.settings_storage_hint), listOf(Res.string.storage_image_cache, Res.string.storage_page_cache, Res.string.storage_path_database, Res.string.storage_path_images), SettingsTarget.Storage))
        add(page(SettingsGroup.Data, Icons.Outlined.SwapHoriz, stringResource(Res.string.mig_title), stringResource(Res.string.mig_subtitle), listOf(Res.string.mig_rule_strictness, Res.string.mig_rule_chapters, Res.string.mig_rule_compare_all, Res.string.mig_rule_try_address, Res.string.mig_rule_keep_old), SettingsTarget.Migration))
        if (now.unreachable > 0) add(page(SettingsGroup.Data, Icons.Outlined.LinkOff, stringResource(Res.string.settings_missing_sources), unreachable, emptyList(), SettingsTarget.MissingSources))

        // System
        add(page(SettingsGroup.System, Icons.Outlined.Lock, stringResource(Res.string.settings_security), stringResource(Res.string.settings_security_hint), listOf(Res.string.lock_on, Res.string.lock_after, Res.string.lock_now, Res.string.secure_screen, Res.string.incognito_mode), SettingsTarget.Security))
        if (networkSupported) add(page(SettingsGroup.System, Icons.Outlined.Lan, stringResource(Res.string.settings_network), stringResource(Res.string.settings_network_hint), listOf(Res.string.network_routes_title, Res.string.network_connections, Res.string.network_type_wireguard), SettingsTarget.Network))
        add(page(SettingsGroup.System, Icons.Outlined.Tune, stringResource(Res.string.settings_advanced), stringResource(Res.string.settings_advanced_hint), listOf(Res.string.advanced_reset_look, Res.string.advanced_reset_library, Res.string.advanced_reset_reader), SettingsTarget.Advanced))
        add(page(SettingsGroup.System, Icons.Outlined.BugReport, stringResource(Res.string.settings_diagnostics), stringResource(Res.string.settings_diagnostics_hint), listOf(Res.string.settings_logs, Res.string.diagnostics_copy), SettingsTarget.Diagnostics))
        add(page(SettingsGroup.System, Icons.Outlined.Info, stringResource(Res.string.settings_about), stringResource(Res.string.settings_version, BuildInfo.Version), listOf(Res.string.about_licenses, Res.string.legal_title, Res.string.privacy_title), SettingsTarget.About))
        add(page(SettingsGroup.System, Icons.Outlined.SystemUpdate, stringResource(Res.string.appupdate_title), updateLine, listOf(Res.string.appupdate_check_now, Res.string.appupdate_auto_check, Res.string.appupdate_prerelease, Res.string.appupdate_source, Res.string.appupdate_changes), SettingsTarget.AppUpdate))
    }
}
