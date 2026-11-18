package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_anilist
import com.sumizuri.app.shared.resources.tracker_kitsu
import com.sumizuri.app.shared.resources.tracker_mal
import com.sumizuri.app.shared.resources.tracker_mangabaka
import com.sumizuri.app.shared.resources.tracker_rules_hint
import com.sumizuri.app.shared.resources.tracker_rules_title
import com.sumizuri.app.shared.resources.tracker_sign_out
import com.sumizuri.app.shared.resources.tracker_signed_in
import com.sumizuri.app.shared.resources.tracker_page_hint
import com.sumizuri.app.shared.resources.trackers_hint
import com.sumizuri.app.shared.resources.trackers_title
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.page.ReadableWidth
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// How wide the tracker pages may get on a wide window, which they fill with cards and covers, and how wide a card of a tracker is at least.
internal val WideWidth = 1400.dp
private val CardWidth = 340.dp

// The page each tracker opens on, and its name as a page.
internal fun TrackerId.page(): SettingsTarget = when (this) {
    TrackerId.AniList -> SettingsTarget.TrackerAniList
    TrackerId.Mal -> SettingsTarget.TrackerMal
    TrackerId.Kitsu -> SettingsTarget.TrackerKitsu
    TrackerId.MangaBaka -> SettingsTarget.TrackerMangaBaka
}

private fun TrackerId.title(): StringResource = when (this) {
    TrackerId.AniList -> Res.string.tracker_anilist
    TrackerId.Mal -> Res.string.tracker_mal
    TrackerId.Kitsu -> Res.string.tracker_kitsu
    TrackerId.MangaBaka -> Res.string.tracker_mangabaka
}

// Every tracker as a card that says how it stands and syncs or logs in on the spot, the signed in ones first, and under them the rules of the sync, which are the same for all of them.
@Composable
fun TrackersRoute(onBack: () -> Unit, onOpen: (SettingsTarget) -> Unit) {
    val container = LocalAppContainer.current
    val accounts by container.trackers.signedIn.collectAsStateWithLifecycle(null)
    SettingsPageFrame(Res.string.trackers_title, onBack, subtitle = Res.string.trackers_hint, maxWidth = WideWidth, onReset = {
        container.settings.reset("tracker.")
    }) {
        val known = accounts ?: return@SettingsPageFrame
        // The cards side by side on a wide window, up to three in a row.
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val columns = (maxWidth / CardWidth).toInt().coerceIn(1, 3)
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                for (row in TrackerId.entries.sortedBy { if (it in known) 0 else 1 }.chunked(columns)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.height(IntrinsicSize.Max)) {
                        for (tracker in row) TrackerCard(tracker, known[tracker], Modifier.weight(1f).fillMaxHeight()) { onOpen(tracker.page()) }
                        repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }
        Column(Modifier.widthIn(max = ReadableWidth)) { RulesRow(onOpen) }
    }
}

// The row that opens the rules of the sync, on the Trackers page and on the page of each tracker.
@Composable
internal fun RulesRow(onOpen: (SettingsTarget) -> Unit) {
    AppListRow(
        stringResource(Res.string.tracker_rules_title),
        subtitle = stringResource(Res.string.tracker_rules_hint),
        subtitleLines = 2,
        leading = { SettingIcon(Icons.Outlined.Tune) },
        trailing = { ListChevron() },
        onClick = { onOpen(SettingsTarget.TrackerRules) },
    )
}

// The rules of the sync on a page of their own, the same for every tracker. Its reset puts back only the rules.
@Composable
fun TrackerRulesRoute(onBack: () -> Unit) {
    val settings = LocalAppContainer.current.settings
    SettingsPageFrame(Res.string.tracker_rules_title, onBack, subtitle = Res.string.tracker_rules_hint, onReset = {
        settings.reset("tracker.rule.")
        settings.resetNames(SettingKey.TrackerEveryMinutes)
    }) { TrackerRulesSections() }
}

// The page of one tracker: its sync and its titles once signed in, and its card to log in before.
@Composable
internal fun TrackerRoute(tracker: TrackerId, onBack: () -> Unit, onOpen: (SettingsTarget) -> Unit) {
    val trackers = LocalAppContainer.current.trackers
    // Nothing is shown until the accounts are read, so a signed in tracker never shows as signed out first.
    val accounts by trackers.signedIn.collectAsStateWithLifecycle(null)
    SettingsPageFrame(tracker.title(), onBack, subtitle = Res.string.tracker_page_hint, maxWidth = WideWidth) {
        val known = accounts ?: return@SettingsPageFrame
        val account = known[tracker]
        if (account != null) {
            TrackerHome(tracker, account, onOpen = onOpen)
        } else {
            TrackerCard(tracker, null) {}
        }
    }
}

// Who is signed in, with their picture from the tracker, and the button to sign out.
@Composable
internal fun SignedInRow(account: TrackerAccount, onSignOut: () -> Unit) {
    SettingRow(
        account.name,
        subtitle = stringResource(Res.string.tracker_signed_in),
        leading = {
            if (account.avatar != null) {
                AsyncImage(
                    account.avatar,
                    null,
                    Modifier.size(36.dp).clip(CircleShape),
                    contentScale = ContentScale.Crop,
                )
            } else {
                SettingIcon(Icons.Outlined.AccountCircle)
            }
        },
        trailing = { TextButton(onSignOut) { Text(stringResource(Res.string.tracker_sign_out)) } },
    )
}
