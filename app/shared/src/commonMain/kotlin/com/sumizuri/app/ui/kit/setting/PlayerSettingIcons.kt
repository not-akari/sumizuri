package com.sumizuri.app.ui.kit.setting

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AspectRatio
import androidx.compose.material.icons.outlined.Audiotrack
import androidx.compose.material.icons.outlined.FastForward
import androidx.compose.material.icons.outlined.FormatBold
import androidx.compose.material.icons.outlined.FormatColorFill
import androidx.compose.material.icons.outlined.FormatSize
import androidx.compose.material.icons.outlined.Forward10
import androidx.compose.material.icons.outlined.HighQuality
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.SkipNext
import androidx.compose.material.icons.outlined.SlowMotionVideo
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.Subtitles
import androidx.compose.material.icons.outlined.Swipe
import androidx.compose.material.icons.outlined.TaskAlt
import androidx.compose.material.icons.outlined.Terminal
import androidx.compose.material.icons.outlined.TouchApp
import androidx.compose.material.icons.outlined.VerticalAlignBottom
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.ui.graphics.vector.ImageVector
import com.sumizuri.app.shared.resources.Res
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
import org.jetbrains.compose.resources.StringResource

// The icons of the player settings, which join the others in settingIconOf.
internal fun playerSettingIconOf(title: StringResource): ImageVector? = when (title) {
    // Player
    Res.string.player_set_speed -> Icons.Outlined.Speed

    Res.string.player_set_quality -> Icons.Outlined.HighQuality

    Res.string.player_set_audio_pref -> Icons.Outlined.Audiotrack

    Res.string.player_set_resume -> Icons.Outlined.History

    Res.string.player_set_auto_next -> Icons.Outlined.SkipNext

    Res.string.player_set_watched -> Icons.Outlined.TaskAlt

    Res.string.player_set_seek -> Icons.Outlined.Forward10

    Res.string.player_set_skip -> Icons.Outlined.FastForward

    Res.string.player_set_double_tap -> Icons.Outlined.TouchApp

    Res.string.player_set_hide -> Icons.Outlined.VisibilityOff

    Res.string.player_set_swipe -> Icons.Outlined.Swipe

    Res.string.player_set_hold_speed -> Icons.Outlined.SlowMotionVideo

    Res.string.player_set_show_log -> Icons.Outlined.Terminal

    Res.string.player_aspect -> Icons.Outlined.AspectRatio

    Res.string.player_set_sub_size -> Icons.Outlined.FormatSize

    Res.string.player_set_sub_color -> Icons.Outlined.Palette

    Res.string.player_set_sub_background -> Icons.Outlined.FormatColorFill

    Res.string.player_set_sub_bold -> Icons.Outlined.FormatBold

    Res.string.player_set_sub_position -> Icons.Outlined.VerticalAlignBottom

    Res.string.player_set_show_subtitles -> Icons.Outlined.Subtitles

    Res.string.player_set_language -> Icons.Outlined.Language

    else -> moreSettingIconOf(title)
}
