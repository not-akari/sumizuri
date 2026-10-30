package com.sumizuri.app.ui.kit.setting
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.LabelOff
import androidx.compose.material.icons.automirrored.outlined.ManageSearch
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.automirrored.outlined.Sort
import androidx.compose.material.icons.automirrored.outlined.ViewList
import androidx.compose.material.icons.automirrored.outlined.ViewQuilt
import androidx.compose.material.icons.automirrored.outlined.WrapText
import androidx.compose.material.icons.outlined.AdsClick
import androidx.compose.material.icons.outlined.Animation
import androidx.compose.material.icons.outlined.AutoAwesomeMotion
import androidx.compose.material.icons.outlined.AutoStories
import androidx.compose.material.icons.outlined.AvTimer
import androidx.compose.material.icons.outlined.BatteryChargingFull
import androidx.compose.material.icons.outlined.BlurOn
import androidx.compose.material.icons.outlined.Bookmark
import androidx.compose.material.icons.outlined.Bookmarks
import androidx.compose.material.icons.outlined.Brightness6
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Contrast
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.DensitySmall
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.DonutLarge
import androidx.compose.material.icons.outlined.DownloadDone
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material.icons.outlined.FastForward
import androidx.compose.material.icons.outlined.FiberNew
import androidx.compose.material.icons.outlined.FilterAlt
import androidx.compose.material.icons.outlined.FilterList
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.FontDownload
import androidx.compose.material.icons.outlined.FormatAlignJustify
import androidx.compose.material.icons.outlined.FormatLineSpacing
import androidx.compose.material.icons.outlined.FormatListNumbered
import androidx.compose.material.icons.outlined.Fullscreen
import androidx.compose.material.icons.outlined.Height
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.HorizontalSplit
import androidx.compose.material.icons.outlined.HourglassEmpty
import androidx.compose.material.icons.outlined.ImportContacts
import androidx.compose.material.icons.outlined.ImportExport
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Layers
import androidx.compose.material.icons.outlined.LightMode
import androidx.compose.material.icons.outlined.LinearScale
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.LowPriority
import androidx.compose.material.icons.outlined.Memory
import androidx.compose.material.icons.outlined.MotionPhotosOff
import androidx.compose.material.icons.outlined.NewReleases
import androidx.compose.material.icons.outlined.NoPhotography
import androidx.compose.material.icons.outlined.NotStarted
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.outlined.Numbers
import androidx.compose.material.icons.outlined.OpenInBrowser
import androidx.compose.material.icons.outlined.PanTool
import androidx.compose.material.icons.outlined.Panorama
import androidx.compose.material.icons.outlined.PauseCircle
import androidx.compose.material.icons.outlined.Photo
import androidx.compose.material.icons.outlined.PhotoSizeSelectLarge
import androidx.compose.material.icons.outlined.PrivacyTip
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.QueryStats
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Science
import androidx.compose.material.icons.outlined.SdStorage
import androidx.compose.material.icons.outlined.SpaceBar
import androidx.compose.material.icons.outlined.SpaceDashboard
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material.icons.outlined.SwapVert
import androidx.compose.material.icons.outlined.Swipe
import androidx.compose.material.icons.outlined.SwipeLeft
import androidx.compose.material.icons.outlined.SwipeRight
import androidx.compose.material.icons.outlined.Tab
import androidx.compose.material.icons.outlined.TaskAlt
import androidx.compose.material.icons.outlined.TextFields
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.TouchApp
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.UnfoldLess
import androidx.compose.material.icons.outlined.Update
import androidx.compose.material.icons.outlined.VerticalSplit
import androidx.compose.material.icons.outlined.ViewAgenda
import androidx.compose.material.icons.outlined.ViewModule
import androidx.compose.material.icons.outlined.Wallpaper
import androidx.compose.material.icons.outlined.WbTwilight
import androidx.compose.material.icons.outlined.WidthNormal
import androidx.compose.material.icons.outlined.Wifi
import androidx.compose.material.icons.outlined.ZoomOutMap
import androidx.compose.ui.graphics.vector.ImageVector
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.appupdate_auto_check
import com.sumizuri.app.shared.resources.appupdate_prerelease
import com.sumizuri.app.shared.resources.appupdate_skip
import com.sumizuri.app.shared.resources.badge_favorite
import com.sumizuri.app.shared.resources.badge_language
import com.sumizuri.app.shared.resources.badge_source
import com.sumizuri.app.shared.resources.badge_status
import com.sumizuri.app.shared.resources.badge_unread
import com.sumizuri.app.shared.resources.chapter_filter_bookmarked
import com.sumizuri.app.shared.resources.chapter_filter_downloaded
import com.sumizuri.app.shared.resources.chapter_filter_unread
import com.sumizuri.app.shared.resources.chapter_list_duplicates
import com.sumizuri.app.shared.resources.chapter_list_grid
import com.sumizuri.app.shared.resources.chapter_list_oldest
import com.sumizuri.app.shared.resources.chapter_sort_title
import com.sumizuri.app.shared.resources.display_collapsible_search
import com.sumizuri.app.shared.resources.display_cover_size
import com.sumizuri.app.shared.resources.display_favorites
import com.sumizuri.app.shared.resources.display_gap
import com.sumizuri.app.shared.resources.display_hide_all_tab
import com.sumizuri.app.shared.resources.display_hide_no_shelf_tab
import com.sumizuri.app.shared.resources.display_home_cover
import com.sumizuri.app.shared.resources.display_list_cover
import com.sumizuri.app.shared.resources.display_name_size
import com.sumizuri.app.shared.resources.display_panorama
import com.sumizuri.app.shared.resources.display_part_count
import com.sumizuri.app.shared.resources.display_progress
import com.sumizuri.app.shared.resources.display_row_style
import com.sumizuri.app.shared.resources.display_style
import com.sumizuri.app.shared.resources.download_ahead
import com.sumizuri.app.shared.resources.download_ahead_saved
import com.sumizuri.app.shared.resources.download_delete_after
import com.sumizuri.app.shared.resources.download_delete_on_mark
import com.sumizuri.app.shared.resources.download_keep_bookmarked
import com.sumizuri.app.shared.resources.download_new
import com.sumizuri.app.shared.resources.download_new_limit
import com.sumizuri.app.shared.resources.download_new_started
import com.sumizuri.app.shared.resources.download_pages_at_once
import com.sumizuri.app.shared.resources.download_pause
import com.sumizuri.app.shared.resources.download_wifi_only
import com.sumizuri.app.shared.resources.gesture_library_double_tap
import com.sumizuri.app.shared.resources.gesture_library_long_press
import com.sumizuri.app.shared.resources.gesture_library_tap
import com.sumizuri.app.shared.resources.gesture_long_press
import com.sumizuri.app.shared.resources.gesture_nav_double
import com.sumizuri.app.shared.resources.gesture_swipe_left
import com.sumizuri.app.shared.resources.gesture_swipe_right
import com.sumizuri.app.shared.resources.incognito_mode
import com.sumizuri.app.shared.resources.lock_after
import com.sumizuri.app.shared.resources.lock_on
import com.sumizuri.app.shared.resources.page_motion
import com.sumizuri.app.shared.resources.page_stagger
import com.sumizuri.app.shared.resources.perf_overlay
import com.sumizuri.app.shared.resources.reader_auto_speed
import com.sumizuri.app.shared.resources.reader_background
import com.sumizuri.app.shared.resources.reader_brightness
import com.sumizuri.app.shared.resources.reader_default_mode
import com.sumizuri.app.shared.resources.reader_dual
import com.sumizuri.app.shared.resources.reader_font
import com.sumizuri.app.shared.resources.reader_gap
import com.sumizuri.app.shared.resources.reader_hide_bars
import com.sumizuri.app.shared.resources.reader_incognito_switch
import com.sumizuri.app.shared.resources.reader_inline_next
import com.sumizuri.app.shared.resources.reader_invert_taps
import com.sumizuri.app.shared.resources.reader_keep_on
import com.sumizuri.app.shared.resources.reader_line_height
import com.sumizuri.app.shared.resources.reader_lookup
import com.sumizuri.app.shared.resources.reader_paragraph_gap
import com.sumizuri.app.shared.resources.reader_progress_bar
import com.sumizuri.app.shared.resources.reader_quality
import com.sumizuri.app.shared.resources.reader_scale
import com.sumizuri.app.shared.resources.reader_skip_filtered
import com.sumizuri.app.shared.resources.reader_skip_read
import com.sumizuri.app.shared.resources.reader_text_align
import com.sumizuri.app.shared.resources.reader_text_size
import com.sumizuri.app.shared.resources.reader_warmth
import com.sumizuri.app.shared.resources.reader_width
import com.sumizuri.app.shared.resources.reader_wpm
import com.sumizuri.app.shared.resources.rule_own_order
import com.sumizuri.app.shared.resources.rule_status
import com.sumizuri.app.shared.resources.scroll_arrow
import com.sumizuri.app.shared.resources.scroll_page
import com.sumizuri.app.shared.resources.scroll_tap
import com.sumizuri.app.shared.resources.secure_screen
import com.sumizuri.app.shared.resources.settings_compact_lists
import com.sumizuri.app.shared.resources.settings_language
import com.sumizuri.app.shared.resources.settings_mode
import com.sumizuri.app.shared.resources.settings_nav_labels
import com.sumizuri.app.shared.resources.settings_nav_style
import com.sumizuri.app.shared.resources.settings_nav_swipe
import com.sumizuri.app.shared.resources.settings_oled
import com.sumizuri.app.shared.resources.settings_oled_glow
import com.sumizuri.app.shared.resources.settings_reduce_motion
import com.sumizuri.app.shared.resources.settings_reopen_place
import com.sumizuri.app.shared.resources.sort_by
import com.sumizuri.app.shared.resources.sort_direction
import com.sumizuri.app.shared.resources.sort_pin_favorites
import com.sumizuri.app.shared.resources.sort_pin_unread
import com.sumizuri.app.shared.resources.sort_then
import com.sumizuri.app.shared.resources.sort_then_direction
import com.sumizuri.app.shared.resources.storage_image_disk_limit
import com.sumizuri.app.shared.resources.storage_image_memory_limit
import com.sumizuri.app.shared.resources.storage_page_keep
import com.sumizuri.app.shared.resources.storage_page_memory_limit
import com.sumizuri.app.shared.resources.tap_bands_side
import com.sumizuri.app.shared.resources.tap_bands_top
import com.sumizuri.app.shared.resources.update_background
import com.sumizuri.app.shared.resources.update_charging
import com.sumizuri.app.shared.resources.update_interval
import com.sumizuri.app.shared.resources.update_notify
import com.sumizuri.app.shared.resources.update_skip_completed
import com.sumizuri.app.shared.resources.update_skip_not_started
import com.sumizuri.app.shared.resources.update_skip_unread
import com.sumizuri.app.shared.resources.update_wifi_only
import com.sumizuri.app.shared.resources.updates_swipe_marks_read
import com.sumizuri.app.shared.resources.web_in_app
import org.jetbrains.compose.resources.StringResource

// The icon beside each setting, found by the name of the setting, so every page shows the same icon for the same choice without passing it along. Only the icon asked for is made, as making all of them at once held up the first opening of the settings.
fun settingIconOf(title: StringResource): ImageVector? = when (title) {
    // Interface
    Res.string.settings_language -> Icons.Outlined.Translate

    Res.string.settings_compact_lists -> Icons.Outlined.DensitySmall

    Res.string.settings_nav_style -> Icons.Outlined.SpaceDashboard

    Res.string.settings_nav_labels -> Icons.Outlined.TextFields

    Res.string.settings_nav_swipe -> Icons.Outlined.Swipe

    Res.string.settings_reopen_place -> Icons.Outlined.History

    Res.string.web_in_app -> Icons.Outlined.OpenInBrowser

    Res.string.page_motion -> Icons.Outlined.Animation

    Res.string.page_stagger -> Icons.Outlined.AutoAwesomeMotion

    Res.string.settings_reduce_motion -> Icons.Outlined.MotionPhotosOff

    // Appearance
    Res.string.settings_mode -> Icons.Outlined.Contrast

    Res.string.settings_oled -> Icons.Outlined.DarkMode

    Res.string.settings_oled_glow -> Icons.Outlined.BlurOn

    // Downloads
    Res.string.download_pause -> Icons.Outlined.PauseCircle

    Res.string.download_wifi_only -> Icons.Outlined.Wifi

    Res.string.download_pages_at_once -> Icons.Outlined.Layers

    Res.string.download_new -> Icons.Outlined.NewReleases

    Res.string.download_new_started -> Icons.AutoMirrored.Outlined.MenuBook

    Res.string.download_new_limit -> Icons.Outlined.FormatListNumbered

    Res.string.download_ahead -> Icons.Outlined.FastForward

    Res.string.download_ahead_saved -> Icons.Outlined.Bookmarks

    Res.string.download_delete_after -> Icons.Outlined.DeleteSweep

    Res.string.download_delete_on_mark -> Icons.Outlined.DoneAll

    Res.string.download_keep_bookmarked -> Icons.Outlined.Bookmark

    // Storage
    Res.string.storage_image_disk_limit -> Icons.Outlined.SdStorage

    Res.string.storage_image_memory_limit -> Icons.Outlined.Memory

    Res.string.storage_page_memory_limit -> Icons.Outlined.Memory

    Res.string.storage_page_keep -> Icons.Outlined.Timer

    // Library updates
    Res.string.update_interval -> Icons.Outlined.Schedule

    Res.string.update_background -> Icons.Outlined.Update

    Res.string.update_wifi_only -> Icons.Outlined.Wifi

    Res.string.update_charging -> Icons.Outlined.BatteryChargingFull

    Res.string.update_notify -> Icons.Outlined.Notifications

    Res.string.update_skip_completed -> Icons.Outlined.TaskAlt

    Res.string.update_skip_not_started -> Icons.Outlined.NotStarted

    Res.string.update_skip_unread -> Icons.Outlined.HourglassEmpty

    // Chapter list
    Res.string.chapter_sort_title -> Icons.AutoMirrored.Outlined.Sort

    Res.string.chapter_list_oldest -> Icons.Outlined.SwapVert

    Res.string.chapter_list_grid -> Icons.Outlined.ViewModule

    Res.string.chapter_list_duplicates -> Icons.Outlined.ContentCopy

    Res.string.chapter_filter_unread -> Icons.Outlined.FiberNew

    Res.string.chapter_filter_downloaded -> Icons.Outlined.DownloadDone

    Res.string.chapter_filter_bookmarked -> Icons.Outlined.Bookmark

    Res.string.reader_skip_read -> Icons.Outlined.DoneAll

    Res.string.reader_skip_filtered -> Icons.Outlined.FilterAlt

    // Controls
    Res.string.tap_bands_side -> Icons.Outlined.VerticalSplit

    Res.string.tap_bands_top -> Icons.Outlined.HorizontalSplit

    Res.string.scroll_arrow -> Icons.Outlined.Keyboard

    Res.string.scroll_page -> Icons.Outlined.ImportExport

    Res.string.scroll_tap -> Icons.Outlined.TouchApp

    // Security
    Res.string.lock_on -> Icons.Outlined.Lock

    Res.string.lock_after -> Icons.Outlined.Timer

    Res.string.secure_screen -> Icons.Outlined.NoPhotography

    Res.string.incognito_mode -> Icons.Outlined.PrivacyTip

    else -> playerSettingIconOf(title)
}
