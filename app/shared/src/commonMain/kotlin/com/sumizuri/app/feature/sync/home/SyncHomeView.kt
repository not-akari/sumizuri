package com.sumizuri.app.feature.sync.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AdminPanelSettings
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.CloudQueue
import androidx.compose.material.icons.outlined.Devices
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.SwitchAccount
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.account.SyncAccount
import com.sumizuri.app.data.account.SyncProblem
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.account.DefaultSyncMinutes
import com.sumizuri.app.feature.sync.account.WhatSyncs
import com.sumizuri.app.feature.sync.account.intervalText
import com.sumizuri.app.feature.sync.account.rememberSyncHome
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_background_short
import com.sumizuri.app.shared.resources.sync_details
import com.sumizuri.app.shared.resources.sync_details_hint
import com.sumizuri.app.shared.resources.sync_devices_count
import com.sumizuri.app.shared.resources.sync_devices_section
import com.sumizuri.app.shared.resources.sync_link_none
import com.sumizuri.app.shared.resources.sync_link_title
import com.sumizuri.app.shared.resources.sync_offline_hint
import com.sumizuri.app.shared.resources.sync_offline_retry
import com.sumizuri.app.shared.resources.sync_offline_title
import com.sumizuri.app.shared.resources.sync_tile_account
import com.sumizuri.app.shared.resources.sync_tile_admin
import com.sumizuri.app.shared.resources.sync_tile_admin_hint
import com.sumizuri.app.shared.resources.sync_tile_server
import com.sumizuri.app.shared.resources.sync_tile_server_hint
import com.sumizuri.app.shared.resources.sync_two_step
import com.sumizuri.app.shared.resources.sync_two_step_hint
import com.sumizuri.app.shared.resources.sync_two_step_off
import com.sumizuri.app.shared.resources.sync_two_step_on
import com.sumizuri.app.shared.resources.sync_what_none
import com.sumizuri.app.shared.resources.sync_what_section
import com.sumizuri.app.shared.resources.sync_when_title
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.card.PageTile
import com.sumizuri.app.ui.kit.card.TileGrid
import com.sumizuri.app.ui.motion.entrance
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The signed in sync page: how the sync stands with its button on top, then a tile for each part, which opens its own page: the profile it syncs with, what and when it syncs, the devices, what is on the server, past syncs, the account, and the server itself for its owner and admins.
@Composable
internal fun SyncHomeView(account: SyncAccount, onOpen: (SettingsTarget) -> Unit) {
    val container = LocalAppContainer.current
    val prefs = container.settings
    val model = rememberSyncHome(account)
    val home by model.home.collectAsStateWithLifecycle()
    val linked by remember(container) {
        container.settings.text(SettingKey.SyncLibraryId)
    }.collectAsStateWithLifecycle(null)
    // Until the libraries of the server are read, which needs the server, what this profile links to is not known.
    val linkName = home.libraries
        ?.let { list ->
            list.firstOrNull { it.id.toString() == linked }?.name
                ?: stringResource(Res.string.sync_link_none)
        }.orEmpty()
    val on = WhatSyncs.filter { (key) ->
        remember(prefs, key) {
            prefs.flag(key, true)
        }.collectAsStateWithLifecycle(true).value
    }
    val what = on.map { (_, title) -> stringResource(title) }.joinToString(", ").ifEmpty {
        stringResource(Res.string.sync_what_none)
    }
    val every by remember(prefs) {
        prefs.number(SettingKey.SyncEveryMinutes, DefaultSyncMinutes)
    }.collectAsStateWithLifecycle(DefaultSyncMinutes)
    val background by remember(prefs) { prefs.flag(SettingKey.SyncBackground, true) }.collectAsStateWithLifecycle(true)
    val whenText =
        intervalText(every) +
            if (every > 0 && background) " · " + stringResource(Res.string.sync_background_short) else ""
    val devices = home.devices
        ?.size
        ?.let { pluralStringResource(Res.plurals.sync_devices_count, it, it) }
        .orEmpty()
    val twoStep = stringResource(
        when (home.twoStep) {
            true -> Res.string.sync_two_step_on
            false -> Res.string.sync_two_step_off
            null -> Res.string.sync_two_step_hint
        },
    )
    val accountLine = account.username + " · " + stringResource(Res.string.sync_two_step) + ": " + twoStep
    val tiles = buildList<@Composable (Modifier) -> Unit> {
        add {
            PageTile(
                Icons.Outlined.SwitchAccount,
                stringResource(Res.string.sync_link_title),
                linkName,
                {
                    onOpen(SettingsTarget.SyncLink)
                },
                it,
                alert =
                home.libraries != null && linked == null,
            )
        }
        add {
            PageTile(Icons.Outlined.Inventory2, stringResource(Res.string.sync_what_section), what, {
                onOpen(SettingsTarget.SyncWhat)
            }, it)
        }
        add {
            PageTile(Icons.Outlined.Schedule, stringResource(Res.string.sync_when_title), whenText, {
                onOpen(SettingsTarget.SyncWhen)
            }, it)
        }
        add {
            PageTile(Icons.Outlined.Devices, stringResource(Res.string.sync_devices_section), devices, {
                onOpen(SettingsTarget.SyncDevices)
            }, it)
        }
        add {
            PageTile(
                Icons.Outlined.CloudQueue,
                stringResource(
                    Res.string.sync_tile_server,
                ),
                stringResource(Res.string.sync_tile_server_hint),
                {
                    onOpen(SettingsTarget.SyncServer)
                },
                it,
            )
        }
        add {
            PageTile(
                Icons.Outlined.History,
                stringResource(
                    Res.string.sync_details,
                ),
                stringResource(Res.string.sync_details_hint),
                {
                    onOpen(SettingsTarget.SyncDetails)
                },
                it,
            )
        }
        add {
            PageTile(Icons.Outlined.Person, stringResource(Res.string.sync_tile_account), accountLine, {
                onOpen(SettingsTarget.SyncAccount)
            }, it)
        }
        if (model.isAdmin) {
            add {
                PageTile(
                    Icons.Outlined.AdminPanelSettings,
                    stringResource(
                        Res.string.sync_tile_admin,
                    ),
                    stringResource(Res.string.sync_tile_admin_hint),
                    {
                        onOpen(SettingsTarget.SyncAdmin)
                    },
                    it,
                )
            }
        }
    }
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val columns = when {
            maxWidth >= 860.dp -> 3
            maxWidth >= 520.dp -> 2
            else -> 1
        }
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            // A server that is down says so first, as nothing under it can load until it is back.
            home.down?.let {
                ServerDown(
                    it,
                    checking = home.status == ServerStatus.Checking,
                    onRetry = model::checkServer,
                )
            }
            SyncStatusCard(home, linked != null, model.syncRun, model::syncNow, model::checkServer)
            TileGrid(columns, tiles, Modifier.entrance())
            if (home.busy) Working()
            home.problem?.let { Problem(it) }
        }
    }
}

// The sync page is this wide at most.
internal val SyncPageWidth = 1100.dp

// The server is down: what that means for this device, why it could not be reached, and a way to ask again now. While it is being asked the button waits.
@Composable
private fun ServerDown(problem: SyncProblem, checking: Boolean, onRetry: () -> Unit) {
    AppCard(Modifier.fillMaxWidth().padding(bottom = 12.dp)) {
        Row(Modifier.padding(14.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(Icons.Outlined.CloudOff, null, tint = MaterialTheme.colorScheme.error)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    stringResource(Res.string.sync_offline_title),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    stringResource(Res.string.sync_offline_hint),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                problem.message
                    ?.takeIf {
                        it.isNotBlank()
                    }?.let {
                        Text(
                            it,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.outline,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                InkOutlinedButton(onRetry, Modifier.padding(top = 6.dp), enabled = !checking) {
                    if (checking) {
                        InkCircularProgressIndicator(
                            Modifier.size(16.dp),
                            strokeWidth = 2.dp,
                        )
                    } else {
                        Text(stringResource(Res.string.sync_offline_retry))
                    }
                }
            }
        }
    }
}
