package com.sumizuri.app.feature.player.overlay

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.outlined.HighQuality
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.Subtitles
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector
import com.sumizuri.app.feature.player.SessionState
import com.sumizuri.app.feature.player.VideoChoice
import com.sumizuri.app.feature.player.picker.Picker
import com.sumizuri.app.feature.player.picker.hasAnyAudio
import com.sumizuri.app.feature.player.picker.hasSubtitleChoices
import com.sumizuri.app.playback.PlayerState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_audio
import com.sumizuri.app.shared.resources.player_episodes
import com.sumizuri.app.shared.resources.player_quality
import com.sumizuri.app.shared.resources.player_settings_title
import com.sumizuri.app.shared.resources.player_speed
import com.sumizuri.app.shared.resources.player_subtitles
import org.jetbrains.compose.resources.stringResource

// One action of the island: its picture, its name, whether its choice is open, and what it does.
internal class PlayerAction(val icon: ImageVector, val label: String, val active: Boolean, val onClick: () -> Unit)

// The actions of the island: the episodes, the subtitles, the sound, the quality, the speed, and the settings, which hold what has no button of its own. An action with nothing to choose is left out.
@Composable
internal fun playerActions(
    session: SessionState,
    engine: PlayerState,
    picker: Picker?,
    calls: OverlayCalls,
): List<PlayerAction> {
    val video = session.current
    fun choice(icon: ImageVector, label: String, which: Picker) =
        PlayerAction(icon, label, picker == which) { calls.onOpen(which) }
    return listOfNotNull(
        choice(
            Icons.AutoMirrored.Outlined.FormatListBulleted,
            stringResource(Res.string.player_episodes),
            Picker.Episodes,
        ).takeIf { session.episodes.size > 1 },
        choice(Icons.Outlined.Subtitles, stringResource(Res.string.player_subtitles), Picker.Subtitles)
            .takeIf { hasSubtitleChoices(engine, video) },
        choice(Icons.AutoMirrored.Outlined.VolumeUp, stringResource(Res.string.player_audio), Picker.Audio)
            .takeIf { hasAnyAudio(engine, video) || VideoChoice.versions(session.videos, video) != null },
        choice(Icons.Outlined.HighQuality, stringResource(Res.string.player_quality), Picker.Quality)
            .takeIf { session.videos.size > 1 },
        choice(Icons.Outlined.Speed, stringResource(Res.string.player_speed), Picker.Speed),
        choice(Icons.Outlined.Tune, stringResource(Res.string.player_settings_title), Picker.Settings),
    )
}
