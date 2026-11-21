package com.sumizuri.app.feature.sync.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Badge
import androidx.compose.material.icons.outlined.Key
import androidx.compose.material.icons.outlined.Password
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PersonRemove
import androidx.compose.material.icons.outlined.PhonelinkLock
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.IconTile
import com.sumizuri.app.feature.settings.PageRefresh
import com.sumizuri.app.feature.settings.PageRow
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.account.SignedIn
import com.sumizuri.app.feature.sync.account.rememberSyncHome
import com.sumizuri.app.feature.sync.admin.AdminTab
import com.sumizuri.app.feature.sync.data.HistoryData
import com.sumizuri.app.feature.sync.data.LibraryData
import com.sumizuri.app.feature.sync.data.UpdatesData
import com.sumizuri.app.feature.sync.roleLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_account_section
import com.sumizuri.app.shared.resources.sync_delete_account
import com.sumizuri.app.shared.resources.sync_delete_account_hint
import com.sumizuri.app.shared.resources.sync_password_change
import com.sumizuri.app.shared.resources.sync_password_row_hint
import com.sumizuri.app.shared.resources.sync_recovery_new
import com.sumizuri.app.shared.resources.sync_recovery_new_hint
import com.sumizuri.app.shared.resources.sync_sign_out
import com.sumizuri.app.shared.resources.sync_sign_out_message
import com.sumizuri.app.shared.resources.sync_sign_out_title
import com.sumizuri.app.shared.resources.sync_signed_in_as
import com.sumizuri.app.shared.resources.sync_tab_history
import com.sumizuri.app.shared.resources.sync_tab_library
import com.sumizuri.app.shared.resources.sync_tab_updates
import com.sumizuri.app.shared.resources.sync_tile_account
import com.sumizuri.app.shared.resources.sync_tile_admin
import com.sumizuri.app.shared.resources.sync_tile_admin_hint
import com.sumizuri.app.shared.resources.sync_tile_server
import com.sumizuri.app.shared.resources.sync_tile_server_hint
import com.sumizuri.app.shared.resources.sync_two_step
import com.sumizuri.app.shared.resources.sync_two_step_hint
import com.sumizuri.app.shared.resources.sync_two_step_off
import com.sumizuri.app.shared.resources.sync_two_step_on
import com.sumizuri.app.shared.resources.sync_username_change
import com.sumizuri.app.shared.resources.sync_username_change_hint
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.chips.FilterTabs
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import org.jetbrains.compose.resources.stringResource

// The three parts of what is on the server.
private val DataTabs = listOf(SyncTab.Library, SyncTab.Updates, SyncTab.History)

// What is on the server for this profile: its library, the updates of it and its history, as plain tabs. Pulling the page down fetches it again.
@Composable
internal fun SyncServerRoute(onBack: () -> Unit) {
    val account by LocalProfiles.current.syncAccounts.account
        .collectAsStateWithLifecycle()
    val model = account?.let { rememberSyncHome(it) }
    val home = model?.home?.collectAsStateWithLifecycle()?.value
    SettingsPageFrame(
        Res.string.sync_tile_server,
        onBack,
        subtitle = Res.string.sync_tile_server_hint,
        maxWidth = SyncPageWidth,
        refresh = if (model != null && home != null) PageRefresh(home.busy, model::refreshCopy) else null,
    ) {
        if (model == null || home == null) return@SettingsPageFrame
        LaunchedEffect(model) { if (model.home.value.tab !in DataTabs) model.open(SyncTab.Library) }
        val container = LocalAppContainer.current
        val linked by remember(container) {
            container.settings.text(SettingKey.SyncLibraryId)
        }.collectAsStateWithLifecycle(null)
        val tab = home.tab.takeIf { it in DataTabs } ?: SyncTab.Library
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val wide = maxWidth >= 860.dp
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                FilterTabs(DataTabs.map { it to stringResource(dataLabel(it)) }, tab, model::open)
                when (tab) {
                    SyncTab.Updates -> UpdatesData(home, linked != null, wide, model::syncNow, model::refreshCopy)
                    SyncTab.History -> HistoryData(home, linked != null, wide, model::syncNow, model::refreshCopy)
                    else -> LibraryData(home, linked != null, wide, model::syncNow, model::refreshCopy)
                }
                if (home.busy) Working()
                home.problem?.let { Problem(it) }
            }
        }
    }
}

private fun dataLabel(tab: SyncTab) = when (tab) {
    SyncTab.Updates -> Res.string.sync_tab_updates
    SyncTab.History -> Res.string.sync_tab_history
    else -> Res.string.sync_tab_library
}

// The account: who is signed in where, the ways to change the password, the name, the recovery key and two-step sign in, to delete the account, and to sign out, which asks first.
@Composable
internal fun SyncAccountRoute(onBack: () -> Unit, onOpen: (SettingsTarget) -> Unit) {
    SettingsPageFrame(Res.string.sync_tile_account, onBack) {
        SignedIn { account ->
            val model = rememberSyncHome(account)
            val home by model.home.collectAsStateWithLifecycle()
            var signingOut by remember { mutableStateOf(false) }
            SettingsSection(Res.string.sync_account_section) {
                row {
                    SettingRow(
                        stringResource(Res.string.sync_signed_in_as, account.username),
                        subtitle = account.serverName + " · " + stringResource(roleLabel(account.role)),
                        leading = { IconTile(Icons.Outlined.Person) },
                        strong = true,
                    )
                }
                row {
                    PageRow(
                        Icons.Outlined.Password,
                        stringResource(
                            Res.string.sync_password_change,
                        ),
                        stringResource(Res.string.sync_password_row_hint),
                        {
                            onOpen(SettingsTarget.SyncPassword)
                        },
                    )
                }
                row {
                    PageRow(
                        Icons.Outlined.Badge,
                        stringResource(
                            Res.string.sync_username_change,
                        ),
                        stringResource(Res.string.sync_username_change_hint),
                        {
                            onOpen(SettingsTarget.SyncUsername)
                        },
                    )
                }
                row {
                    PageRow(
                        Icons.Outlined.Key,
                        stringResource(
                            Res.string.sync_recovery_new,
                        ),
                        stringResource(Res.string.sync_recovery_new_hint),
                        {
                            onOpen(SettingsTarget.SyncRecovery)
                        },
                    )
                }
                row {
                    val twoStep = when (home.twoStep) {
                        true -> Res.string.sync_two_step_on
                        false -> Res.string.sync_two_step_off
                        null -> Res.string.sync_two_step_hint
                    }
                    PageRow(
                        Icons.Outlined.PhonelinkLock,
                        stringResource(
                            Res.string.sync_two_step,
                        ),
                        stringResource(twoStep),
                        {
                            onOpen(SettingsTarget.SyncTwoStep)
                        },
                    )
                }
                row {
                    PageRow(
                        Icons.Outlined.PersonRemove,
                        stringResource(
                            Res.string.sync_delete_account,
                        ),
                        stringResource(Res.string.sync_delete_account_hint),
                        {
                            onOpen(SettingsTarget.SyncDelete)
                        },
                    )
                }
                padded { InkOutlinedButton({ signingOut = true }) { Text(stringResource(Res.string.sync_sign_out)) } }
            }
            if (signingOut) {
                ConfirmDialog(
                    stringResource(Res.string.sync_sign_out_title),
                    stringResource(Res.string.sync_sign_out_message),
                    stringResource(Res.string.sync_sign_out),
                    onConfirm = {
                        signingOut = false
                        model.signOut()
                        onBack()
                    },
                    onDismiss = { signingOut = false },
                )
            }
        }
    }
}

// The server itself, for its owner and admins: how it stands, its people, invites, settings and log.
@Composable
internal fun SyncAdminRoute(onBack: () -> Unit, onOpen: (SettingsTarget) -> Unit) {
    SettingsPageFrame(Res.string.sync_tile_admin, onBack, subtitle = Res.string.sync_tile_admin_hint) {
        SignedIn { account ->
            val model = rememberSyncHome(account)
            val home by model.home.collectAsStateWithLifecycle()
            LaunchedEffect(model) { model.open(SyncTab.Admin) }
            AdminTab(home, onOpen)
            if (home.busy) Working()
            home.problem?.let { Problem(it) }
        }
    }
}
