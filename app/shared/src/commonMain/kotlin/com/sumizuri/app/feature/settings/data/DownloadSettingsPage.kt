package com.sumizuri.app.feature.settings.data

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Downloading
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.download.AheadChoices
import com.sumizuri.app.data.download.DeleteAfterChoices
import com.sumizuri.app.data.download.DownloadPrefs
import com.sumizuri.app.data.download.NewLimitChoices
import com.sumizuri.app.data.download.PagesAtOnceChoices
import com.sumizuri.app.data.download.canTellNetwork
import com.sumizuri.app.data.download.downloadPrefs
import com.sumizuri.app.data.download.shelfText
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapters_count
import com.sumizuri.app.shared.resources.count_off
import com.sumizuri.app.shared.resources.download_ahead
import com.sumizuri.app.shared.resources.download_ahead_saved
import com.sumizuri.app.shared.resources.download_ahead_saved_hint
import com.sumizuri.app.shared.resources.download_delete_after
import com.sumizuri.app.shared.resources.download_delete_keep
import com.sumizuri.app.shared.resources.download_delete_never
import com.sumizuri.app.shared.resources.download_delete_now
import com.sumizuri.app.shared.resources.download_delete_on_mark
import com.sumizuri.app.shared.resources.download_delete_on_mark_hint
import com.sumizuri.app.shared.resources.download_group_ahead
import com.sumizuri.app.shared.resources.download_group_ahead_hint
import com.sumizuri.app.shared.resources.download_group_delete
import com.sumizuri.app.shared.resources.download_group_new
import com.sumizuri.app.shared.resources.download_group_queue
import com.sumizuri.app.shared.resources.download_keep_bookmarked
import com.sumizuri.app.shared.resources.download_keep_bookmarked_hint
import com.sumizuri.app.shared.resources.download_new
import com.sumizuri.app.shared.resources.download_new_hint
import com.sumizuri.app.shared.resources.download_new_limit
import com.sumizuri.app.shared.resources.download_new_started
import com.sumizuri.app.shared.resources.download_new_started_hint
import com.sumizuri.app.shared.resources.download_no_limit
import com.sumizuri.app.shared.resources.download_pages_at_once
import com.sumizuri.app.shared.resources.download_pause
import com.sumizuri.app.shared.resources.download_paused
import com.sumizuri.app.shared.resources.download_queue_open
import com.sumizuri.app.shared.resources.download_queue_state
import com.sumizuri.app.shared.resources.download_settings_hint
import com.sumizuri.app.shared.resources.download_skip_shelves
import com.sumizuri.app.shared.resources.download_skip_shelves_hint
import com.sumizuri.app.shared.resources.download_title
import com.sumizuri.app.shared.resources.download_wifi_only
import com.sumizuri.app.shared.resources.download_wifi_only_hint
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The choices of saving chapters to the device: the queue and how it runs, saving new chapters on its own, saving ahead while reading, and taking read chapters off the device. The queue itself is a page of its own.
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun DownloadSettingsRoute(onBack: () -> Unit, onOpenQueue: () -> Unit) {
    val container = LocalAppContainer.current
    val prefs = container.settings
    val downloads = container.downloads
    val scope = rememberCoroutineScope()
    val now by remember(prefs) { prefs.downloadPrefs() }.collectAsStateWithLifecycle(DownloadPrefs())
    val active by downloads.active.collectAsStateWithLifecycle(0)
    val paused by downloads.paused.collectAsStateWithLifecycle(false)
    val shelves by container.categories.categories.collectAsStateWithLifecycle(emptyList())

    // Each change is kept at once, and the queue looks again in case it was waiting for what changed.
    fun flag(key: String): (Boolean) -> Unit = { on ->
        scope.launch {
            prefs.setFlag(key, on)
            downloads.nudge()
        }
    }
    fun number(key: String): (Int) -> Unit = { value -> scope.launch { prefs.setNumber(key, value) } }
    val chapters: @Composable (
        Int,
    ) -> String = { count -> pluralStringResource(Res.plurals.chapters_count, count, count) }
    SettingsPageFrame(Res.string.download_title, onBack, subtitle = Res.string.download_settings_hint, onReset = {
        prefs.reset("downloads.", except = SettingKey.DownloadsPaused)
    }) {
        SettingsSection(Res.string.download_group_queue) {
            row {
                val state =
                    stringResource(Res.string.download_queue_state, active) +
                        if (paused) " · " + stringResource(Res.string.download_paused) else ""
                SettingRow(stringResource(Res.string.download_queue_open), subtitle = state, leading = {
                    SettingIcon(Icons.Outlined.Downloading)
                }, trailing = { ListChevron() }, onClick = onOpenQueue)
            }
            padded {
                SwitchSetting(Res.string.download_pause, paused, { on ->
                    scope.launch {
                        if (on) downloads.pause() else downloads.resume()
                    }
                })
            }
            if (canTellNetwork) {
                padded {
                    SwitchSetting(
                        Res.string.download_wifi_only,
                        now.wifiOnly,
                        flag(SettingKey.DownloadWifiOnly),
                        Res.string.download_wifi_only_hint,
                    )
                }
            }
            padded {
                ChoiceSetting(Res.string.download_pages_at_once, PagesAtOnceChoices, now.pagesAtOnce, {
                    it.toString()
                }, onSelect = number(SettingKey.DownloadPagesAtOnce))
            }
        }
        SettingsSection(Res.string.download_group_new) {
            padded {
                SwitchSetting(
                    Res.string.download_new,
                    now.newChapters,
                    flag(SettingKey.DownloadNew),
                    Res.string.download_new_hint,
                )
            }
            if (now.newChapters) {
                padded {
                    SwitchSetting(
                        Res.string.download_new_started,
                        now.newOnlyStarted,
                        flag(SettingKey.DownloadNewStarted),
                        Res.string.download_new_started_hint,
                    )
                }
                padded {
                    ChoiceSetting(Res.string.download_new_limit, NewLimitChoices, now.newLimit, {
                        if (it ==
                            0
                        ) {
                            stringResource(Res.string.download_no_limit)
                        } else {
                            chapters(it)
                        }
                    }, onSelect = number(SettingKey.DownloadNewLimit))
                }
                if (shelves.isNotEmpty()) {
                    padded {
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                stringResource(Res.string.download_skip_shelves),
                                style = MaterialTheme.typography.bodyLarge,
                            )
                            Text(
                                stringResource(Res.string.download_skip_shelves_hint),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.outline,
                            )
                            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                for (shelf in shelves) {
                                    val skipped = shelf.id in now.skipShelves
                                    SoftChip(skipped, {
                                        val next = if (skipped) {
                                            now.skipShelves - shelf.id
                                        } else {
                                            now.skipShelves +
                                                shelf.id
                                        }
                                        scope.launch { prefs.setText(SettingKey.DownloadSkipShelves, shelfText(next)) }
                                    }, { Text(shelf.name) })
                                }
                            }
                        }
                    }
                }
            }
        }
        SettingsSection(Res.string.download_group_ahead, hint = Res.string.download_group_ahead_hint) {
            padded {
                ChoiceSetting(Res.string.download_ahead, AheadChoices, now.ahead, {
                    if (it ==
                        0
                    ) {
                        stringResource(Res.string.count_off)
                    } else {
                        chapters(it)
                    }
                }, onSelect = number(SettingKey.DownloadAhead))
            }
            if (now.ahead >
                0
            ) {
                padded {
                    SwitchSetting(
                        Res.string.download_ahead_saved,
                        now.aheadOnlySaved,
                        flag(SettingKey.DownloadAheadSaved),
                        Res.string.download_ahead_saved_hint,
                    )
                }
            }
        }
        SettingsSection(Res.string.download_group_delete) {
            padded {
                ChoiceSetting(Res.string.download_delete_after, DeleteAfterChoices, now.deleteAfter, {
                    deleteAfterLabel(it)
                }, onSelect = number(SettingKey.DownloadDeleteAfter))
            }
            padded {
                SwitchSetting(
                    Res.string.download_delete_on_mark,
                    now.deleteOnMark,
                    flag(SettingKey.DownloadDeleteOnMark),
                    Res.string.download_delete_on_mark_hint,
                )
            }
            if (now.deleteAfter >= 0 || now.deleteOnMark) {
                padded {
                    SwitchSetting(
                        Res.string.download_keep_bookmarked,
                        now.keepBookmarked,
                        flag(SettingKey.DownloadKeepBookmarked),
                        Res.string.download_keep_bookmarked_hint,
                    )
                }
            }
        }
    }
}

// When read chapters leave the device: never, as soon as they are read, or once that many newer ones are read.
@Composable
private fun deleteAfterLabel(kept: Int): String = when {
    kept < 0 -> stringResource(Res.string.download_delete_never)
    kept == 0 -> stringResource(Res.string.download_delete_now)
    else -> pluralStringResource(Res.plurals.download_delete_keep, kept, kept)
}
