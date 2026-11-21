package com.sumizuri.app.ui.kit.setting

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.AltRoute
import androidx.compose.material.icons.automirrored.outlined.CompareArrows
import androidx.compose.material.icons.automirrored.outlined.MergeType
import androidx.compose.material.icons.automirrored.outlined.ViewSidebar
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.Animation
import androidx.compose.material.icons.outlined.ArrowUpward
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.AutoStories
import androidx.compose.material.icons.outlined.Bedtime
import androidx.compose.material.icons.outlined.Bookmarks
import androidx.compose.material.icons.outlined.Brightness4
import androidx.compose.material.icons.outlined.CallToAction
import androidx.compose.material.icons.outlined.Category
import androidx.compose.material.icons.outlined.Compress
import androidx.compose.material.icons.outlined.Contrast
import androidx.compose.material.icons.outlined.Crop
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.FilterBAndW
import androidx.compose.material.icons.outlined.FilterList
import androidx.compose.material.icons.outlined.FilterVintage
import androidx.compose.material.icons.outlined.FormatListNumbered
import androidx.compose.material.icons.outlined.Gradient
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.InvertColors
import androidx.compose.material.icons.outlined.Lightbulb
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.Menu
import androidx.compose.material.icons.outlined.Panorama
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PhonelinkErase
import androidx.compose.material.icons.outlined.Replay
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Science
import androidx.compose.material.icons.outlined.ScreenRotation
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Speaker
import androidx.compose.material.icons.outlined.SwapVert
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material.icons.outlined.SyncAlt
import androidx.compose.material.icons.outlined.Tag
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.TimerOff
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.VerticalSplit
import androidx.compose.material.icons.outlined.Wifi
import androidx.compose.material.icons.outlined.ZoomIn
import androidx.compose.material.icons.outlined.ZoomOutMap
import androidx.compose.ui.graphics.vector.ImageVector
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.experimental_profile_banner
import com.sumizuri.app.shared.resources.experimental_show
import com.sumizuri.app.shared.resources.long_tap_menu
import com.sumizuri.app.shared.resources.mig_rule_allow_merge
import com.sumizuri.app.shared.resources.mig_rule_auto_accept
import com.sumizuri.app.shared.resources.mig_rule_chapters
import com.sumizuri.app.shared.resources.mig_rule_compare_all
import com.sumizuri.app.shared.resources.mig_rule_delay
import com.sumizuri.app.shared.resources.mig_rule_give_up
import com.sumizuri.app.shared.resources.mig_rule_keep_favorite
import com.sumizuri.app.shared.resources.mig_rule_keep_old
import com.sumizuri.app.shared.resources.mig_rule_keep_shelves
import com.sumizuri.app.shared.resources.mig_rule_looks_at
import com.sumizuri.app.shared.resources.mig_rule_min_chapters
import com.sumizuri.app.shared.resources.mig_rule_parallel
import com.sumizuri.app.shared.resources.mig_rule_prefer_more
import com.sumizuri.app.shared.resources.mig_rule_read_chapters
import com.sumizuri.app.shared.resources.mig_rule_require_author
import com.sumizuri.app.shared.resources.mig_rule_shorter
import com.sumizuri.app.shared.resources.mig_rule_strictness
import com.sumizuri.app.shared.resources.mig_rule_try_address
import com.sumizuri.app.shared.resources.network_source_route
import com.sumizuri.app.shared.resources.network_source_source
import com.sumizuri.app.shared.resources.player_set_ambient
import com.sumizuri.app.shared.resources.reader_bedtime
import com.sumizuri.app.shared.resources.reader_bedtime_dim
import com.sumizuri.app.shared.resources.reader_contrast
import com.sumizuri.app.shared.resources.reader_control_shade
import com.sumizuri.app.shared.resources.reader_controls
import com.sumizuri.app.shared.resources.reader_crop_borders
import com.sumizuri.app.shared.resources.reader_grayscale
import com.sumizuri.app.shared.resources.reader_invert_colors
import com.sumizuri.app.shared.resources.reader_orientation
import com.sumizuri.app.shared.resources.reader_page_number
import com.sumizuri.app.shared.resources.reader_page_turn
import com.sumizuri.app.shared.resources.reader_panel_zoom
import com.sumizuri.app.shared.resources.reader_sepia
import com.sumizuri.app.shared.resources.reader_zoom_start
import com.sumizuri.app.shared.resources.search_history
import com.sumizuri.app.shared.resources.settings_title_split
import com.sumizuri.app.shared.resources.shelves_kind
import com.sumizuri.app.shared.resources.sync_every
import com.sumizuri.app.shared.resources.sync_password_sign_out_others
import com.sumizuri.app.shared.resources.tracker_rule_add_new
import com.sumizuri.app.shared.resources.tracker_rule_background
import com.sumizuri.app.shared.resources.tracker_rule_both_other
import com.sumizuri.app.shared.resources.tracker_rule_both_progress
import com.sumizuri.app.shared.resources.tracker_rule_match
import com.sumizuri.app.shared.resources.tracker_rule_reading_moves
import com.sumizuri.app.shared.resources.tracker_rule_reread
import com.sumizuri.app.shared.resources.tracker_rule_wifi
import com.sumizuri.app.shared.resources.update_smart
import com.sumizuri.app.shared.resources.updates_side
import com.sumizuri.app.shared.resources.volume_keys
import com.sumizuri.app.shared.resources.volume_keys_invert
import org.jetbrains.compose.resources.StringResource

// The icons of the rows that had none of their own, so every row of the settings has one. The list of icons by kind of setting is asked after these.
internal fun rowSettingIconOf(title: StringResource): ImageVector? = when (title) {
    Res.string.long_tap_menu -> Icons.Outlined.Menu
    Res.string.volume_keys -> Icons.Outlined.Speaker
    Res.string.volume_keys_invert -> Icons.Outlined.SwapVert
    Res.string.mig_rule_strictness -> Icons.Outlined.Tune
    Res.string.mig_rule_require_author -> Icons.Outlined.Person
    Res.string.mig_rule_auto_accept -> Icons.Outlined.DoneAll
    Res.string.mig_rule_read_chapters -> Icons.Outlined.AutoStories
    Res.string.mig_rule_looks_at -> Icons.Outlined.Search
    Res.string.mig_rule_chapters -> Icons.Outlined.FormatListNumbered
    Res.string.mig_rule_min_chapters -> Icons.Outlined.FilterList
    Res.string.mig_rule_prefer_more -> Icons.Outlined.AddCircleOutline
    Res.string.mig_rule_shorter -> Icons.Outlined.Compress
    Res.string.mig_rule_try_address -> Icons.Outlined.Link
    Res.string.mig_rule_compare_all -> Icons.AutoMirrored.Outlined.CompareArrows
    Res.string.mig_rule_parallel -> Icons.AutoMirrored.Outlined.AltRoute
    Res.string.mig_rule_delay -> Icons.Outlined.Timer
    Res.string.mig_rule_give_up -> Icons.Outlined.TimerOff
    Res.string.mig_rule_keep_old -> Icons.Outlined.History
    Res.string.mig_rule_keep_shelves -> Icons.Outlined.Bookmarks
    Res.string.mig_rule_keep_favorite -> Icons.Outlined.FavoriteBorder
    Res.string.mig_rule_allow_merge -> Icons.AutoMirrored.Outlined.MergeType
    Res.string.network_source_route -> Icons.Outlined.Route
    Res.string.network_source_source -> Icons.Outlined.Extension
    Res.string.player_set_ambient -> Icons.Outlined.Lightbulb
    Res.string.reader_bedtime -> Icons.Outlined.Bedtime
    Res.string.reader_bedtime_dim -> Icons.Outlined.Brightness4
    Res.string.reader_contrast -> Icons.Outlined.Contrast
    Res.string.reader_control_shade -> Icons.Outlined.Gradient
    Res.string.reader_crop_borders -> Icons.Outlined.Crop
    Res.string.reader_invert_colors -> Icons.Outlined.InvertColors
    Res.string.reader_orientation -> Icons.Outlined.ScreenRotation
    Res.string.reader_panel_zoom -> Icons.Outlined.ZoomIn
    Res.string.reader_sepia -> Icons.Outlined.FilterVintage
    Res.string.reader_zoom_start -> Icons.Outlined.ZoomOutMap
    Res.string.reader_page_turn -> Icons.Outlined.Animation
    Res.string.reader_grayscale -> Icons.Outlined.FilterBAndW
    Res.string.reader_controls -> Icons.Outlined.CallToAction
    Res.string.reader_page_number -> Icons.Outlined.Tag
    Res.string.search_history -> Icons.Outlined.History
    Res.string.settings_title_split -> Icons.Outlined.VerticalSplit
    Res.string.shelves_kind -> Icons.Outlined.Category
    Res.string.sync_every -> Icons.Outlined.Schedule
    Res.string.sync_password_sign_out_others -> Icons.Outlined.PhonelinkErase
    Res.string.tracker_rule_add_new -> Icons.Outlined.AddCircleOutline
    Res.string.tracker_rule_background -> Icons.Outlined.Sync
    Res.string.tracker_rule_both_other -> Icons.AutoMirrored.Outlined.CompareArrows
    Res.string.tracker_rule_both_progress -> Icons.Outlined.SyncAlt
    Res.string.tracker_rule_match -> Icons.Outlined.Link
    Res.string.tracker_rule_reading_moves -> Icons.Outlined.ArrowUpward
    Res.string.tracker_rule_reread -> Icons.Outlined.Replay
    Res.string.tracker_rule_wifi -> Icons.Outlined.Wifi
    Res.string.update_smart -> Icons.Outlined.AutoAwesome
    Res.string.updates_side -> Icons.AutoMirrored.Outlined.ViewSidebar
    Res.string.experimental_profile_banner -> Icons.Outlined.Panorama
    Res.string.experimental_show -> Icons.Outlined.Science
    else -> null
}
