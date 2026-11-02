package com.sumizuri.app.feature.sync.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Badge
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.Devices
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.Key
import androidx.compose.material.icons.outlined.Password
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PersonRemove
import androidx.compose.material.icons.outlined.PhonelinkLock
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.SwitchAccount
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.account.SyncAccount
import com.sumizuri.app.data.account.SyncProblem
import com.sumizuri.app.data.account.SyncRun
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.IconTile
import com.sumizuri.app.feature.settings.PageRow
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.SideBySide
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.account.DefaultSyncMinutes
import com.sumizuri.app.feature.sync.account.WhatSyncs
import com.sumizuri.app.feature.sync.account.intervalText
import com.sumizuri.app.feature.sync.account.rememberSyncHome
import com.sumizuri.app.feature.sync.admin.AdminTab
import com.sumizuri.app.feature.sync.data.HistoryData
import com.sumizuri.app.feature.sync.data.LibraryData
import com.sumizuri.app.feature.sync.data.UpdatesData
import com.sumizuri.app.feature.sync.roleLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_account_section
import com.sumizuri.app.shared.resources.sync_background_short
import com.sumizuri.app.shared.resources.sync_delete_account
import com.sumizuri.app.shared.resources.sync_delete_account_hint
import com.sumizuri.app.shared.resources.sync_details
import com.sumizuri.app.shared.resources.sync_details_hint
import com.sumizuri.app.shared.resources.sync_devices_count
import com.sumizuri.app.shared.resources.sync_devices_section
import com.sumizuri.app.shared.resources.sync_link_none
import com.sumizuri.app.shared.resources.sync_link_title
import com.sumizuri.app.shared.resources.sync_offline_hint
import com.sumizuri.app.shared.resources.sync_offline_retry
import com.sumizuri.app.shared.resources.sync_offline_title
import com.sumizuri.app.shared.resources.sync_password_change
import com.sumizuri.app.shared.resources.sync_password_row_hint
import com.sumizuri.app.shared.resources.sync_recovery_new
import com.sumizuri.app.shared.resources.sync_recovery_new_hint
import com.sumizuri.app.shared.resources.sync_settings_section
import com.sumizuri.app.shared.resources.sync_sign_out
import com.sumizuri.app.shared.resources.sync_sign_out_message
import com.sumizuri.app.shared.resources.sync_sign_out_title
import com.sumizuri.app.shared.resources.sync_signed_in_as
import com.sumizuri.app.shared.resources.sync_tab_account
import com.sumizuri.app.shared.resources.sync_tab_admin
import com.sumizuri.app.shared.resources.sync_tab_history
import com.sumizuri.app.shared.resources.sync_tab_library
import com.sumizuri.app.shared.resources.sync_tab_server
import com.sumizuri.app.shared.resources.sync_tab_updates
import com.sumizuri.app.shared.resources.sync_two_step
import com.sumizuri.app.shared.resources.sync_two_step_hint
import com.sumizuri.app.shared.resources.sync_two_step_off
import com.sumizuri.app.shared.resources.sync_two_step_on
import com.sumizuri.app.shared.resources.sync_username_change
import com.sumizuri.app.shared.resources.sync_username_change_hint
import com.sumizuri.app.shared.resources.sync_what_none
import com.sumizuri.app.shared.resources.sync_what_section
import com.sumizuri.app.shared.resources.sync_when_title
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.page.ReadableWidth
import com.sumizuri.app.ui.kit.setting.PartTabs
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import kotlinx.coroutines.flow.StateFlow
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The signed in sync page: tabs for the account and its sync settings, the server's copy of the library, its updates and history, and for the owner and admins the server itself.
@Composable
internal fun SyncHomeView(account: SyncAccount, onOpen: (SettingsTarget) -> Unit) {
    val container = LocalAppContainer.current
    val model = rememberSyncHome(account)
    val home by model.home.collectAsStateWithLifecycle()
    val linked by remember(container) { container.settings.text(SettingKey.SyncLibraryId) }.collectAsStateWithLifecycle(null)
    val tabs = listOf(SyncTab.Account, SyncTab.Library) + if (model.isAdmin) listOf(SyncTab.Admin) else emptyList()
    // The data tab last open, which the server tab opens again.
    var lastData by remember { mutableStateOf(SyncTab.Library) }
    // A wide window puts the parts of a tab beside each other, so the page does not leave the sides empty.
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val wide = maxWidth >= SideBySideWidth
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            // A server that is down says so above every tab, as nothing on the tabs can load until it is back.
            home.down?.let { ServerDown(it, checking = home.status == ServerStatus.Checking, onRetry = model::checkServer) }
            // Three tabs at the top, so they fit a phone whole: the account, what is on the server, and the server itself for its admins. The server side holds the library, the updates and the history, with their own smaller tabs.
            val top = if (home.tab in DataTabs) SyncTab.Library else home.tab
            PartTabs(tabs, top, { stringResource(tabLabel(it)) }, Modifier.padding(horizontal = 16.dp).padding(bottom = 8.dp), onSelect = { picked ->
                model.open(if (picked == SyncTab.Library) lastData else picked)
            })
            if (home.tab in DataTabs) {
                lastData = home.tab
                PartTabs(DataTabs, home.tab, { stringResource(dataLabel(it)) }, Modifier.padding(horizontal = 16.dp).widthIn(max = 420.dp), height = 34.dp, onSelect = model::open)
            }
            when (home.tab) {
                SyncTab.Account -> AccountTab(account, home, linked, wide, onOpen, model::checkServer, model::signOut, model::syncNow, model.syncRun)

                SyncTab.Library -> LibraryData(home, linked != null, wide, model::syncNow, model::refreshCopy)

                SyncTab.Updates -> UpdatesData(home, linked != null, wide, model::syncNow, model::refreshCopy)

                SyncTab.History -> HistoryData(home, linked != null, wide, model::syncNow, model::refreshCopy)

                // The settings of the server read best in one column, so they keep the readable width.
                SyncTab.Admin -> Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
                    Column(Modifier.widthIn(max = ReadableWidth).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) { AdminTab(home, onOpen) }
                }
            }
            if (home.busy) Working()
            home.problem?.let { Problem(it) }
        }
    }
}

// The sync page is this wide at most, and from this width its tabs show their parts side by side.
internal val SyncPageWidth = 1100.dp
private val SideBySideWidth = 860.dp

// The state of the sync with its button first, then the sync settings of this profile as rows that open their own pages, each saying what it is set to now, and the account last, as it is changed the least.
@Composable
private fun AccountTab(account: SyncAccount, home: SyncHome, linked: String?, wide: Boolean, onOpen: (SettingsTarget) -> Unit, onCheck: () -> Unit, onSignOut: () -> Unit, onSyncNow: () -> Unit, syncRun: StateFlow<SyncRun>) {
    var signingOut by remember { mutableStateOf(false) }
    val prefs = LocalAppContainer.current.settings
    SideBySide(wide, {
        SyncStatusCard(home, linked != null, syncRun, onSyncNow, onCheck)
        SettingsSection(Res.string.sync_settings_section) {
            row {
                // Until the libraries of the server are read, which needs the server, what this profile links to is not known.
                val name = home.libraries?.let { list -> list.firstOrNull { it.id.toString() == linked }?.name ?: stringResource(Res.string.sync_link_none) }.orEmpty()
                PageRow(Icons.Outlined.SwitchAccount, stringResource(Res.string.sync_link_title), name, { onOpen(SettingsTarget.SyncLink) })
            }
            row {
                val on = WhatSyncs.filter { (key) -> remember(prefs, key) { prefs.flag(key, true) }.collectAsStateWithLifecycle(true).value }
                val summary = on.map { (_, title) -> stringResource(title) }.joinToString(", ").ifEmpty { stringResource(Res.string.sync_what_none) }
                PageRow(Icons.Outlined.Inventory2, stringResource(Res.string.sync_what_section), summary, { onOpen(SettingsTarget.SyncWhat) })
            }
            row {
                val every by remember(prefs) { prefs.number(SettingKey.SyncEveryMinutes, DefaultSyncMinutes) }.collectAsStateWithLifecycle(DefaultSyncMinutes)
                val background by remember(prefs) { prefs.flag(SettingKey.SyncBackground, true) }.collectAsStateWithLifecycle(true)
                val summary = intervalText(every) + if (every > 0 && background) " · " + stringResource(Res.string.sync_background_short) else ""
                PageRow(Icons.Outlined.Schedule, stringResource(Res.string.sync_when_title), summary, { onOpen(SettingsTarget.SyncWhen) })
            }
            row {
                val count = home.devices?.size
                PageRow(Icons.Outlined.Devices, stringResource(Res.string.sync_devices_section), count?.let { pluralStringResource(Res.plurals.sync_devices_count, it, it) }.orEmpty(), { onOpen(SettingsTarget.SyncDevices) })
            }
            row { PageRow(Icons.Outlined.History, stringResource(Res.string.sync_details), stringResource(Res.string.sync_details_hint), { onOpen(SettingsTarget.SyncDetails) }) }
        }
    }, {
        SettingsSection(Res.string.sync_account_section) {
            // Who is signed in where, with the same tile as the rows under it so the card reads as one list.
            row {
                SettingRow(
                    stringResource(Res.string.sync_signed_in_as, account.username),
                    subtitle = account.serverName + " · " + stringResource(roleLabel(account.role)),
                    leading = { IconTile(Icons.Outlined.Person) },
                    strong = true,
                )
            }
            row { PageRow(Icons.Outlined.Password, stringResource(Res.string.sync_password_change), stringResource(Res.string.sync_password_row_hint), { onOpen(SettingsTarget.SyncPassword) }) }
            row { PageRow(Icons.Outlined.Badge, stringResource(Res.string.sync_username_change), stringResource(Res.string.sync_username_change_hint), { onOpen(SettingsTarget.SyncUsername) }) }
            row { PageRow(Icons.Outlined.Key, stringResource(Res.string.sync_recovery_new), stringResource(Res.string.sync_recovery_new_hint), { onOpen(SettingsTarget.SyncRecovery) }) }
            row {
                PageRow(
                    Icons.Outlined.PhonelinkLock,
                    stringResource(Res.string.sync_two_step),
                    stringResource(
                        when (home.twoStep) {
                            true -> Res.string.sync_two_step_on
                            false -> Res.string.sync_two_step_off
                            null -> Res.string.sync_two_step_hint
                        },
                    ),
                    { onOpen(SettingsTarget.SyncTwoStep) },
                )
            }
            row { PageRow(Icons.Outlined.PersonRemove, stringResource(Res.string.sync_delete_account), stringResource(Res.string.sync_delete_account_hint), { onOpen(SettingsTarget.SyncDelete) }) }
            padded { InkOutlinedButton({ signingOut = true }) { Text(stringResource(Res.string.sync_sign_out)) } }
        }
    })
    if (signingOut) {
        ConfirmDialog(
            stringResource(Res.string.sync_sign_out_title),
            stringResource(Res.string.sync_sign_out_message),
            stringResource(Res.string.sync_sign_out),
            onConfirm = {
                signingOut = false
                onSignOut()
            },
            onDismiss = { signingOut = false },
        )
    }
}

private fun tabLabel(tab: SyncTab): StringResource = when (tab) {
    SyncTab.Account -> Res.string.sync_tab_account
    SyncTab.Library, SyncTab.Updates, SyncTab.History -> Res.string.sync_tab_server
    SyncTab.Admin -> Res.string.sync_tab_admin
}

// The three parts of what is on the server.
private val DataTabs = listOf(SyncTab.Library, SyncTab.Updates, SyncTab.History)

private fun dataLabel(tab: SyncTab): StringResource = when (tab) {
    SyncTab.Account -> Res.string.sync_tab_account
    SyncTab.Library -> Res.string.sync_tab_library
    SyncTab.Updates -> Res.string.sync_tab_updates
    SyncTab.History -> Res.string.sync_tab_history
    SyncTab.Admin -> Res.string.sync_tab_admin
}

// The server is down: what that means for this device, why it could not be reached, and a way to ask again now. While it is being asked the button waits.
@Composable
private fun ServerDown(problem: SyncProblem, checking: Boolean, onRetry: () -> Unit) {
    AppCard(Modifier.fillMaxWidth().padding(bottom = 12.dp)) {
        Row(Modifier.padding(14.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(Icons.Outlined.CloudOff, null, tint = MaterialTheme.colorScheme.error)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(stringResource(Res.string.sync_offline_title), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                Text(stringResource(Res.string.sync_offline_hint), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                problem.message?.takeIf { it.isNotBlank() }?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline, maxLines = 2, overflow = TextOverflow.Ellipsis) }
                InkOutlinedButton(onRetry, Modifier.padding(top = 6.dp), enabled = !checking) {
                    if (checking) InkCircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp) else Text(stringResource(Res.string.sync_offline_retry))
                }
            }
        }
    }
}
