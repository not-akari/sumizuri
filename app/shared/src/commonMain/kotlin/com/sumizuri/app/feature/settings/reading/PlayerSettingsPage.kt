package com.sumizuri.app.feature.settings.reading

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.player.AudioPreference
import com.sumizuri.app.data.model.player.PlayerPrefs
import com.sumizuri.app.data.model.player.QualityMode
import com.sumizuri.app.feature.player.overlay.speedText
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.playback.AspectMode
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_percent
import com.sumizuri.app.shared.resources.player_aspect
import com.sumizuri.app.shared.resources.player_audio_any
import com.sumizuri.app.shared.resources.player_audio_dub
import com.sumizuri.app.shared.resources.player_audio_sub
import com.sumizuri.app.shared.resources.player_group_controls
import com.sumizuri.app.shared.resources.player_group_picture
import com.sumizuri.app.shared.resources.player_group_playback
import com.sumizuri.app.shared.resources.player_hide_never
import com.sumizuri.app.shared.resources.player_quality_highest
import com.sumizuri.app.shared.resources.player_quality_lowest
import com.sumizuri.app.shared.resources.player_quality_remember
import com.sumizuri.app.shared.resources.player_set_ambient
import com.sumizuri.app.shared.resources.player_set_ambient_hint
import com.sumizuri.app.shared.resources.player_set_audio_pref
import com.sumizuri.app.shared.resources.player_set_auto_next
import com.sumizuri.app.shared.resources.player_set_auto_next_hint
import com.sumizuri.app.shared.resources.player_set_auto_server
import com.sumizuri.app.shared.resources.player_set_auto_server_hint
import com.sumizuri.app.shared.resources.player_set_double_tap
import com.sumizuri.app.shared.resources.player_set_double_tap_hint
import com.sumizuri.app.shared.resources.player_set_hide
import com.sumizuri.app.shared.resources.player_set_hold_speed
import com.sumizuri.app.shared.resources.player_set_language_none
import com.sumizuri.app.shared.resources.player_set_quality
import com.sumizuri.app.shared.resources.player_set_resume
import com.sumizuri.app.shared.resources.player_set_seek
import com.sumizuri.app.shared.resources.player_set_show_log
import com.sumizuri.app.shared.resources.player_set_show_log_hint
import com.sumizuri.app.shared.resources.player_set_skip
import com.sumizuri.app.shared.resources.player_set_speed
import com.sumizuri.app.shared.resources.player_set_swipe
import com.sumizuri.app.shared.resources.player_set_swipe_hint
import com.sumizuri.app.shared.resources.player_set_watched
import com.sumizuri.app.shared.resources.player_speed_value
import com.sumizuri.app.shared.resources.player_unit_seconds
import com.sumizuri.app.shared.resources.settings_player
import com.sumizuri.app.shared.resources.settings_player_hint
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The page for the player: how an episode starts and ends, what the keys, taps and the hold do, and the picture and the subtitles.
@Composable
fun PlayerSettingsRoute(onBack: () -> Unit) {
    val repository = LocalAppContainer.current.playerPrefs
    val settings = LocalAppContainer.current.settings
    val prefs by repository.prefs.collectAsStateWithLifecycle(PlayerPrefs())
    val scope = rememberCoroutineScope()
    fun change(edit: (PlayerPrefs) -> PlayerPrefs) {
        scope.launch { repository.update(edit) }
    }
    SettingsPageFrame(Res.string.settings_player, onBack, subtitle = Res.string.settings_player_hint, onReset = {
        settings.reset("player.")
    }) {
        SettingsSection(Res.string.player_group_playback) {
            padded {
                ChoiceSetting(Res.string.player_set_speed, PlayerPrefs.Speeds, prefs.speed, {
                    stringResource(Res.string.player_speed_value, speedText(it))
                }) { speed -> change { it.copy(speed = speed) } }
            }
            padded {
                ChoiceSetting(Res.string.player_set_quality, QualityMode.entries, prefs.qualityMode, {
                    stringResource(
                        when (it) {
                            QualityMode.Remember -> Res.string.player_quality_remember
                            QualityMode.Best -> Res.string.player_quality_highest
                            QualityMode.Lowest -> Res.string.player_quality_lowest
                        },
                    )
                }) { mode -> change { it.copy(qualityMode = mode) } }
            }
            padded {
                ChoiceSetting(Res.string.player_set_audio_pref, AudioPreference.entries, prefs.audioPreference, {
                    stringResource(
                        when (it) {
                            AudioPreference.Any -> Res.string.player_audio_any
                            AudioPreference.Sub -> Res.string.player_audio_sub
                            AudioPreference.Dub -> Res.string.player_audio_dub
                        },
                    )
                }) { value -> change { it.copy(audioPreference = value) } }
            }
            padded {
                SwitchSetting(
                    Res.string.player_set_resume,
                    prefs.resume,
                    { on -> change { it.copy(resume = on) } },
                )
            }
            padded {
                SwitchSetting(Res.string.player_set_ambient, prefs.ambient, { on ->
                    change { it.copy(ambient = on) }
                }, Res.string.player_set_ambient_hint)
            }
            padded {
                SwitchSetting(Res.string.player_set_auto_next, prefs.autoNext, { on ->
                    change {
                        it.copy(autoNext = on)
                    }
                }, Res.string.player_set_auto_next_hint)
            }
            padded {
                SwitchSetting(Res.string.player_set_auto_server, prefs.autoNextServer, { on ->
                    change {
                        it.copy(autoNextServer = on)
                    }
                }, Res.string.player_set_auto_server_hint)
            }
            padded {
                ChoiceSetting(Res.string.player_set_watched, PlayerPrefs.WatchedAt, prefs.watchedAt, {
                    stringResource(Res.string.display_percent, it)
                }) { percent -> change { it.copy(watchedAt = percent) } }
            }
        }
        SettingsSection(Res.string.player_group_controls) {
            padded {
                ChoiceSetting(Res.string.player_set_seek, PlayerPrefs.DoubleTapSteps, prefs.doubleTapSeconds, {
                    stringResource(Res.string.player_unit_seconds, it)
                }) { seconds -> change { it.copy(doubleTapSeconds = seconds) } }
            }
            padded {
                ChoiceSetting(Res.string.player_set_skip, PlayerPrefs.SkipSteps, prefs.skipSeconds, {
                    stringResource(Res.string.player_unit_seconds, it)
                }) { seconds -> change { it.copy(skipSeconds = seconds) } }
            }
            padded {
                SwitchSetting(Res.string.player_set_double_tap, prefs.doubleTapSeek, { on ->
                    change {
                        it.copy(doubleTapSeek = on)
                    }
                }, Res.string.player_set_double_tap_hint)
            }
            padded {
                ChoiceSetting(Res.string.player_set_hide, PlayerPrefs.HideSteps, prefs.hideControlsSeconds, {
                    if (it ==
                        0
                    ) {
                        stringResource(Res.string.player_hide_never)
                    } else {
                        stringResource(Res.string.player_unit_seconds, it)
                    }
                }) { seconds -> change { it.copy(hideControlsSeconds = seconds) } }
            }
            padded {
                SwitchSetting(Res.string.player_set_swipe, prefs.swipeGestures, { on ->
                    change {
                        it.copy(swipeGestures = on)
                    }
                }, Res.string.player_set_swipe_hint)
            }
            padded {
                ChoiceSetting(Res.string.player_set_hold_speed, PlayerPrefs.HoldSpeeds, prefs.holdSpeed, {
                    if (it <=
                        1f
                    ) {
                        stringResource(Res.string.player_set_language_none)
                    } else {
                        stringResource(Res.string.player_speed_value, speedText(it))
                    }
                }) { speed -> change { it.copy(holdSpeed = speed) } }
            }
        }
        SettingsSection(Res.string.player_group_picture) {
            padded {
                SwitchSetting(Res.string.player_set_show_log, prefs.showLog, { on ->
                    change {
                        it.copy(showLog = on)
                    }
                }, Res.string.player_set_show_log_hint)
            }
            padded {
                ChoiceSetting(Res.string.player_aspect, AspectMode.entries, prefs.aspect, {
                    stringResource(it.label)
                }) { aspect -> change { it.copy(aspect = aspect) } }
            }
        }
        PlayerSubtitleSettings(prefs, ::change)
    }
}
