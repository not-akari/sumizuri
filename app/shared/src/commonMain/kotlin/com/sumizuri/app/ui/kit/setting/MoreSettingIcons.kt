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
import androidx.compose.material.icons.outlined.AspectRatio
import androidx.compose.material.icons.outlined.Audiotrack
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
import androidx.compose.material.icons.outlined.FormatBold
import androidx.compose.material.icons.outlined.FormatColorFill
import androidx.compose.material.icons.outlined.FormatLineSpacing
import androidx.compose.material.icons.outlined.FormatListNumbered
import androidx.compose.material.icons.outlined.FormatSize
import androidx.compose.material.icons.outlined.Forward10
import androidx.compose.material.icons.outlined.Fullscreen
import androidx.compose.material.icons.outlined.Height
import androidx.compose.material.icons.outlined.HighQuality
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.HorizontalSplit
import androidx.compose.material.icons.outlined.HourglassEmpty
import androidx.compose.material.icons.outlined.ImportContacts
import androidx.compose.material.icons.outlined.ImportExport
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Language
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
import androidx.compose.material.icons.outlined.Palette
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
import androidx.compose.material.icons.outlined.SkipNext
import androidx.compose.material.icons.outlined.SlowMotionVideo
import androidx.compose.material.icons.outlined.SpaceBar
import androidx.compose.material.icons.outlined.SpaceDashboard
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material.icons.outlined.Subtitles
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material.icons.outlined.SwapVert
import androidx.compose.material.icons.outlined.Swipe
import androidx.compose.material.icons.outlined.SwipeLeft
import androidx.compose.material.icons.outlined.SwipeRight
import androidx.compose.material.icons.outlined.Tab
import androidx.compose.material.icons.outlined.TaskAlt
import androidx.compose.material.icons.outlined.Terminal
import androidx.compose.material.icons.outlined.TextFields
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.TouchApp
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.UnfoldLess
import androidx.compose.material.icons.outlined.Update
import androidx.compose.material.icons.outlined.VerticalAlignBottom
import androidx.compose.material.icons.outlined.VerticalSplit
import androidx.compose.material.icons.outlined.ViewAgenda
import androidx.compose.material.icons.outlined.ViewModule
import androidx.compose.material.icons.outlined.VisibilityOff
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
import com.sumizuri.app.shared.resources.player_aspect
import com.sumizuri.app.shared.resources.player_set_audio_pref
import com.sumizuri.app.shared.resources.player_set_auto_next
import com.sumizuri.app.shared.resources.player_set_double_tap
import com.sumizuri.app.shared.resources.player_set_hide
import com.sumizuri.app.shared.resources.player_set_hold_speed
import com.sumizuri.app.shared.resources.player_set_language
import com.sumizuri.app.shared.resources.player_set_quality
import com.sumizuri.app.shared.resources.player_set_resume
import com.sumizuri.app.shared.resources.player_set_seek
import com.sumizuri.app.shared.resources.player_set_show_log
import com.sumizuri.app.shared.resources.player_set_show_subtitles
import com.sumizuri.app.shared.resources.player_set_skip
import com.sumizuri.app.shared.resources.player_set_speed
import com.sumizuri.app.shared.resources.player_set_sub_background
import com.sumizuri.app.shared.resources.player_set_sub_bold
import com.sumizuri.app.shared.resources.player_set_sub_color
import com.sumizuri.app.shared.resources.player_set_sub_position
import com.sumizuri.app.shared.resources.player_set_sub_size
import com.sumizuri.app.shared.resources.player_set_swipe
import com.sumizuri.app.shared.resources.player_set_watched
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

// The icons of the reader, the display of the library, the updates and the gestures, which join the others in settingIconOf.
internal fun moreSettingIconOf(title: StringResource): ImageVector? = when (title) {
    // Reader
    Res.string.reader_default_mode -> Icons.Outlined.AutoStories

    Res.string.reader_scale -> Icons.Outlined.ZoomOutMap

    Res.string.reader_dual -> Icons.Outlined.ImportContacts

    Res.string.reader_gap -> Icons.Outlined.Height

    Res.string.reader_width -> Icons.Outlined.WidthNormal

    Res.string.reader_background -> Icons.Outlined.Wallpaper

    Res.string.reader_quality -> Icons.Outlined.HighQuality

    Res.string.reader_font -> Icons.Outlined.FontDownload

    Res.string.reader_text_align -> Icons.Outlined.FormatAlignJustify

    Res.string.reader_text_size -> Icons.Outlined.FormatSize

    Res.string.reader_lookup -> Icons.AutoMirrored.Outlined.ManageSearch

    Res.string.reader_line_height -> Icons.Outlined.FormatLineSpacing

    Res.string.reader_paragraph_gap -> Icons.AutoMirrored.Outlined.WrapText

    Res.string.reader_keep_on -> Icons.Outlined.LightMode

    Res.string.reader_hide_bars -> Icons.Outlined.Fullscreen

    Res.string.reader_brightness -> Icons.Outlined.Brightness6

    Res.string.reader_warmth -> Icons.Outlined.WbTwilight

    Res.string.reader_progress_bar -> Icons.Outlined.LinearScale

    Res.string.reader_inline_next -> Icons.Outlined.LowPriority

    Res.string.reader_invert_taps -> Icons.Outlined.SwapHoriz

    Res.string.reader_auto_speed -> Icons.Outlined.Speed

    Res.string.reader_wpm -> Icons.Outlined.AvTimer

    // Advanced and updates of the app
    Res.string.perf_overlay -> Icons.Outlined.QueryStats

    Res.string.appupdate_auto_check -> Icons.Outlined.Update

    Res.string.appupdate_prerelease -> Icons.Outlined.Science

    Res.string.appupdate_skip -> Icons.Outlined.NotificationsOff

    // Library display and order
    Res.string.display_style -> Icons.AutoMirrored.Outlined.ViewQuilt

    Res.string.display_cover_size -> Icons.Outlined.PhotoSizeSelectLarge

    Res.string.display_gap -> Icons.Outlined.SpaceBar

    Res.string.display_panorama -> Icons.Outlined.Panorama

    Res.string.display_list_cover -> Icons.AutoMirrored.Outlined.ViewList

    Res.string.display_name_size -> Icons.Outlined.TextFields

    Res.string.display_progress -> Icons.Outlined.DonutLarge

    Res.string.display_favorites -> Icons.Outlined.StarOutline

    Res.string.badge_unread -> Icons.Outlined.FiberNew

    Res.string.badge_status -> Icons.Outlined.Flag

    Res.string.badge_source -> Icons.Outlined.Extension

    Res.string.badge_language -> Icons.Outlined.Translate

    Res.string.badge_favorite -> Icons.Outlined.StarOutline

    Res.string.display_home_cover -> Icons.Outlined.Photo

    Res.string.display_hide_all_tab -> Icons.Outlined.Tab

    Res.string.display_hide_no_shelf_tab -> Icons.AutoMirrored.Outlined.LabelOff

    Res.string.display_collapsible_search -> Icons.Outlined.UnfoldLess

    Res.string.display_part_count -> Icons.Outlined.Numbers

    Res.string.rule_own_order -> Icons.Outlined.Tune

    Res.string.sort_by -> Icons.AutoMirrored.Outlined.Sort

    Res.string.sort_direction -> Icons.Outlined.SwapVert

    Res.string.sort_then -> Icons.Outlined.FilterList

    Res.string.sort_then_direction -> Icons.Outlined.SwapVert

    Res.string.rule_status -> Icons.Outlined.Flag

    Res.string.sort_pin_favorites -> Icons.Outlined.PushPin

    Res.string.sort_pin_unread -> Icons.Outlined.FiberNew

    // Updates and the reader sheet
    Res.string.display_row_style -> Icons.Outlined.ViewAgenda

    Res.string.updates_swipe_marks_read -> Icons.Outlined.Swipe

    Res.string.reader_incognito_switch -> Icons.Outlined.PrivacyTip

    // Gestures
    Res.string.gesture_library_tap -> Icons.Outlined.TouchApp

    Res.string.gesture_library_long_press -> Icons.Outlined.PanTool

    Res.string.gesture_library_double_tap -> Icons.Outlined.AdsClick

    Res.string.gesture_swipe_right -> Icons.Outlined.SwipeRight

    Res.string.gesture_swipe_left -> Icons.Outlined.SwipeLeft

    Res.string.gesture_long_press -> Icons.Outlined.PanTool

    Res.string.gesture_nav_double -> Icons.Outlined.Tab

    else -> null
}
