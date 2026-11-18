package com.sumizuri.app.feature.trackers

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.PlaylistAdd
import androidx.compose.material.icons.outlined.AutoStories
import androidx.compose.material.icons.outlined.Bedtime
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.JoinInner
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.LinkOff
import androidx.compose.material.icons.outlined.Replay
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Timeline
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.Wifi
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.tracker.Keep
import com.sumizuri.app.data.tracker.OnRemove
import com.sumizuri.app.data.tracker.TrackerPlatform
import com.sumizuri.app.data.tracker.TrackerRules
import com.sumizuri.app.data.tracker.WhenGone
import com.sumizuri.app.feature.sync.account.intervalText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_every
import com.sumizuri.app.shared.resources.tracker_every_hint
import com.sumizuri.app.shared.resources.tracker_gone_add_back
import com.sumizuri.app.shared.resources.tracker_gone_ask
import com.sumizuri.app.shared.resources.tracker_gone_unlink
import com.sumizuri.app.shared.resources.tracker_keep_here
import com.sumizuri.app.shared.resources.tracker_keep_higher
import com.sumizuri.app.shared.resources.tracker_keep_newer
import com.sumizuri.app.shared.resources.tracker_keep_tracker
import com.sumizuri.app.shared.resources.tracker_removing_delete
import com.sumizuri.app.shared.resources.tracker_removing_keep
import com.sumizuri.app.shared.resources.tracker_rule_add_new
import com.sumizuri.app.shared.resources.tracker_rule_add_new_hint
import com.sumizuri.app.shared.resources.tracker_rule_after_reading
import com.sumizuri.app.shared.resources.tracker_rule_after_reading_hint
import com.sumizuri.app.shared.resources.tracker_rule_background
import com.sumizuri.app.shared.resources.tracker_rule_background_hint
import com.sumizuri.app.shared.resources.tracker_rule_both_other
import com.sumizuri.app.shared.resources.tracker_rule_both_progress
import com.sumizuri.app.shared.resources.tracker_rule_gone
import com.sumizuri.app.shared.resources.tracker_rule_match
import com.sumizuri.app.shared.resources.tracker_rule_match_hint
import com.sumizuri.app.shared.resources.tracker_rule_on_link
import com.sumizuri.app.shared.resources.tracker_rule_on_remove
import com.sumizuri.app.shared.resources.tracker_rule_reading_moves
import com.sumizuri.app.shared.resources.tracker_rule_reading_moves_hint
import com.sumizuri.app.shared.resources.tracker_rule_reread
import com.sumizuri.app.shared.resources.tracker_rule_reread_hint
import com.sumizuri.app.shared.resources.tracker_rule_status_follows
import com.sumizuri.app.shared.resources.tracker_rule_status_follows_hint
import com.sumizuri.app.shared.resources.tracker_rule_wifi
import com.sumizuri.app.shared.resources.tracker_rule_wifi_hint
import com.sumizuri.app.shared.resources.tracker_rules_adding
import com.sumizuri.app.shared.resources.tracker_rules_both
import com.sumizuri.app.shared.resources.tracker_rules_both_hint
import com.sumizuri.app.shared.resources.tracker_rules_reading
import com.sumizuri.app.shared.resources.tracker_rules_removing
import com.sumizuri.app.shared.resources.tracker_rules_when
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// The most minutes the slider of how often it syncs goes to.
private const val MostMinutes = 120f

// The rules of the sync with the trackers, the same for each of them, in the order they matter most: when it syncs, what reading changes, how titles are added and removed, and last which side wins when both changed.
@Composable
internal fun TrackerRulesSections() {
    val prefs = LocalAppContainer.current.settings
    val scope = rememberCoroutineScope()
    val base = remember { TrackerRules() }

    @Composable
    fun flag(key: String, fallback: Boolean) =
        remember(prefs, key) { prefs.flag(key, fallback) }.collectAsStateWithLifecycle(fallback).value

    @Composable
    fun text(key: String) = remember(prefs, key) { prefs.text(key) }.collectAsStateWithLifecycle(null).value
    val setFlag = { key: String, on: Boolean -> scope.launch { prefs.setFlag(key, on) } }
    val setText = { key: String, value: String -> scope.launch { prefs.setText(key, value) } }

    SettingsSection(Res.string.tracker_rules_when) {
        padded {
            val every by remember(
                prefs,
            ) { prefs.number(SettingKey.TrackerEveryMinutes, SettingKey.DefaultTrackerMinutes) }
                .collectAsStateWithLifecycle(SettingKey.DefaultTrackerMinutes)
            SliderSetting(Res.string.sync_every, every.toFloat(), 0f..MostMinutes, {
                intervalText(it.roundToInt())
            }, hint = Res.string.tracker_every_hint, icon = Icons.Outlined.Schedule) {
                scope.launch { prefs.setNumber(SettingKey.TrackerEveryMinutes, it.roundToInt()) }
            }
        }
        padded {
            SwitchSetting(
                Res.string.tracker_rule_after_reading,
                flag(
                    SettingKey.TrackerAfterReading,
                    base.afterReading,
                ),
                {
                    setFlag(SettingKey.TrackerAfterReading, it)
                },
                Res.string.tracker_rule_after_reading_hint,
                Icons.Outlined.Timer,
            )
        }
        // Only a system that can sync while the app is closed offers it.
        if (TrackerPlatform.canPlan) {
            padded {
                SwitchSetting(Res.string.tracker_rule_background, flag(SettingKey.TrackerBackground, true), {
                    setFlag(SettingKey.TrackerBackground, it)
                }, Res.string.tracker_rule_background_hint, Icons.Outlined.Bedtime)
            }
        }
        padded {
            SwitchSetting(Res.string.tracker_rule_wifi, flag(SettingKey.TrackerWifiOnly, base.wifiOnly), {
                setFlag(SettingKey.TrackerWifiOnly, it)
            }, Res.string.tracker_rule_wifi_hint, Icons.Outlined.Wifi)
        }
    }
    val moves = flag(SettingKey.TrackerReadingMoves, base.readingMoves)
    SettingsSection(Res.string.tracker_rules_reading) {
        padded {
            SwitchSetting(Res.string.tracker_rule_reading_moves, moves, {
                setFlag(SettingKey.TrackerReadingMoves, it)
            }, Res.string.tracker_rule_reading_moves_hint, Icons.Outlined.AutoStories)
        }
        // The status and rereads only follow reading while reading moves progress.
        padded {
            SwitchSetting(
                Res.string.tracker_rule_status_follows,
                flag(SettingKey.TrackerStatusFollows, base.statusFollows),
                { setFlag(SettingKey.TrackerStatusFollows, it) },
                Res.string.tracker_rule_status_follows_hint,
                Icons.Outlined.Flag,
                enabled = moves,
            )
        }
        padded {
            SwitchSetting(Res.string.tracker_rule_reread, flag(SettingKey.TrackerReread, base.reread), {
                setFlag(SettingKey.TrackerReread, it)
            }, Res.string.tracker_rule_reread_hint, Icons.Outlined.Replay, enabled = moves)
        }
    }
    SettingsSection(Res.string.tracker_rules_adding) {
        padded {
            SwitchSetting(Res.string.tracker_rule_match, flag(SettingKey.TrackerMatchList, base.matchList), {
                setFlag(SettingKey.TrackerMatchList, it)
            }, Res.string.tracker_rule_match_hint, Icons.Outlined.JoinInner)
        }
        padded {
            SwitchSetting(Res.string.tracker_rule_add_new, flag(SettingKey.TrackerAddNew, base.addNew), {
                setFlag(SettingKey.TrackerAddNew, it)
            }, Res.string.tracker_rule_add_new_hint, Icons.AutoMirrored.Outlined.PlaylistAdd)
        }
        padded {
            val now = Keep.of(text(SettingKey.TrackerOnLink), base.onLink)
            ChoiceSetting(
                Res.string.tracker_rule_on_link,
                Keep.ForProgress,
                now,
                { keepLabel(it) },
                icon = Icons.Outlined.Link,
            ) {
                setText(SettingKey.TrackerOnLink, it.code)
            }
        }
    }
    SettingsSection(Res.string.tracker_rules_removing) {
        padded {
            val now = WhenGone.of(text(SettingKey.TrackerGone))
            ChoiceSetting(
                Res.string.tracker_rule_gone,
                WhenGone.entries,
                now,
                { goneLabel(it) },
                icon = Icons.Outlined.LinkOff,
            ) {
                setText(SettingKey.TrackerGone, it.code)
            }
        }
        padded {
            val now = OnRemove.of(text(SettingKey.TrackerOnRemove))
            ChoiceSetting(
                Res.string.tracker_rule_on_remove,
                OnRemove.entries,
                now,
                { onRemoveLabel(it) },
                icon = Icons.Outlined.DeleteOutline,
            ) {
                setText(SettingKey.TrackerOnRemove, it.code)
            }
        }
    }
    SettingsSection(Res.string.tracker_rules_both, Res.string.tracker_rules_both_hint) {
        padded {
            val now = Keep.of(text(SettingKey.TrackerBothProgress), base.bothProgress)
            ChoiceSetting(Res.string.tracker_rule_both_progress, Keep.ForProgress, now, {
                keepLabel(it)
            }, icon = Icons.Outlined.Timeline) {
                setText(SettingKey.TrackerBothProgress, it.code)
            }
        }
        padded {
            val now = Keep.of(text(SettingKey.TrackerBothOther), base.bothOther)
            ChoiceSetting(Res.string.tracker_rule_both_other, Keep.ForOther, now, {
                keepLabel(it)
            }, icon = Icons.Outlined.Visibility) {
                setText(SettingKey.TrackerBothOther, it.code)
            }
        }
    }
}

@Composable
private fun keepLabel(keep: Keep): String = stringResource(
    when (keep) {
        Keep.Higher -> Res.string.tracker_keep_higher
        Keep.Newer -> Res.string.tracker_keep_newer
        Keep.Tracker -> Res.string.tracker_keep_tracker
        Keep.Here -> Res.string.tracker_keep_here
    },
)

@Composable
private fun goneLabel(gone: WhenGone): String = stringResource(
    when (gone) {
        WhenGone.Ask -> Res.string.tracker_gone_ask
        WhenGone.Unlink -> Res.string.tracker_gone_unlink
        WhenGone.AddBack -> Res.string.tracker_gone_add_back
    },
)

@Composable
private fun onRemoveLabel(rule: OnRemove): String = stringResource(
    when (rule) {
        OnRemove.Ask -> Res.string.tracker_gone_ask
        OnRemove.Keep -> Res.string.tracker_removing_keep
        OnRemove.Remove -> Res.string.tracker_removing_delete
    },
)
