package com.sumizuri.app.feature.sync.admin

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ConfirmationNumber
import androidx.compose.material.icons.outlined.Devices
import androidx.compose.material.icons.outlined.Dns
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.feature.settings.PageRow
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.sync.Note
import com.sumizuri.app.feature.sync.account.rememberSyncHome
import com.sumizuri.app.feature.sync.home.SyncHome
import com.sumizuri.app.feature.sync.home.SyncHomeModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_admin_manage
import com.sumizuri.app.shared.resources.sync_admin_open_invites
import com.sumizuri.app.shared.resources.sync_admin_overview
import com.sumizuri.app.shared.resources.sync_admin_people
import com.sumizuri.app.shared.resources.sync_admin_people_line
import com.sumizuri.app.shared.resources.sync_admin_profiles
import com.sumizuri.app.shared.resources.sync_admin_server_line
import com.sumizuri.app.shared.resources.sync_admin_signup
import com.sumizuri.app.shared.resources.sync_admin_stored
import com.sumizuri.app.shared.resources.sync_devices_count
import com.sumizuri.app.shared.resources.sync_error_not_allowed
import com.sumizuri.app.shared.resources.sync_invites_section
import com.sumizuri.app.shared.resources.sync_log
import com.sumizuri.app.shared.resources.sync_log_hint
import com.sumizuri.app.shared.resources.sync_people_section
import com.sumizuri.app.shared.resources.sync_server_settings
import com.sumizuri.app.shared.resources.sync_signup_closed
import com.sumizuri.app.shared.resources.sync_signup_invite
import com.sumizuri.app.shared.resources.sync_signup_open
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.sync.core.Role
import com.sumizuri.sync.core.SignupMode
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The Admin tab: the server at a glance, then rows that open the pages where the people and the invite codes are managed.
@Composable
internal fun AdminTab(home: SyncHome, onOpen: (SettingsTarget) -> Unit) {
    val overview = home.overview
    if (overview != null) {
        SettingsSection(Res.string.sync_admin_overview) {
            row {
                SettingRow(
                    overview.serverName,
                    subtitle = stringResource(
                        Res.string.sync_admin_server_line,
                        overview.version,
                        overview.database,
                        agoText(overview.startedAt),
                    ),
                    leading = {
                        SettingIcon(Icons.Outlined.Dns)
                    },
                )
            }
            row {
                SettingRow(
                    pluralStringResource(Res.plurals.sync_admin_people, overview.users, overview.users),
                    subtitle = stringResource(
                        Res.string.sync_admin_people_line,
                        overview.admins,
                        overview.disabled,
                        overview.activeToday,
                    ),
                    leading = {
                        SettingIcon(Icons.Outlined.Group)
                    },
                )
            }
            row {
                SettingRow(
                    pluralStringResource(Res.plurals.sync_devices_count, overview.devices, overview.devices),
                    subtitle = stringResource(
                        Res.string.sync_admin_signup,
                        stringResource(signupLabel(overview.signupMode)),
                    ),
                    leading = {
                        SettingIcon(Icons.Outlined.Devices)
                    },
                )
            }
            row {
                SettingRow(
                    pluralStringResource(Res.plurals.sync_admin_profiles, overview.profiles, overview.profiles),
                    subtitle = stringResource(Res.string.sync_admin_stored, sizeText(overview.storedBytes)),
                    leading = {
                        SettingIcon(Icons.Outlined.Inventory2)
                    },
                )
            }
        }
    }
    SettingsSection(Res.string.sync_admin_manage) {
        row {
            PageRow(
                Icons.Outlined.Group,
                stringResource(Res.string.sync_people_section),
                overview
                    ?.let {
                        pluralStringResource(Res.plurals.sync_admin_people, it.users, it.users)
                    }.orEmpty(),
                { onOpen(SettingsTarget.SyncAdminPeople) },
            )
        }
        row {
            PageRow(
                Icons.Outlined.ConfirmationNumber,
                stringResource(Res.string.sync_invites_section),
                overview
                    ?.let {
                        stringResource(Res.string.sync_admin_open_invites, it.openInvites)
                    }.orEmpty(),
                { onOpen(SettingsTarget.SyncAdminInvites) },
            )
        }
        row {
            PageRow(
                Icons.Outlined.Tune,
                stringResource(Res.string.sync_server_settings),
                overview
                    ?.let {
                        stringResource(Res.string.sync_admin_signup, stringResource(signupLabel(it.signupMode)))
                    }.orEmpty(),
                { onOpen(SettingsTarget.SyncAdminSettings) },
            )
        }
        row {
            PageRow(
                Icons.Outlined.History,
                stringResource(
                    Res.string.sync_log,
                ),
                stringResource(Res.string.sync_log_hint),
                {
                    onOpen(SettingsTarget.SyncAdminLog)
                },
            )
        }
    }
}

// An admin page needs a signed in owner or admin. Anyone else sees why it is empty.
@Composable
internal fun AdminOnly(content: @Composable (SyncHomeModel, SyncHome) -> Unit) {
    val account by LocalProfiles.current.syncAccounts.account
        .collectAsStateWithLifecycle()
    val signed = account
    if (signed == null || (signed.role != Role.Owner && signed.role != Role.Admin)) {
        SettingsSection { padded { Note(stringResource(Res.string.sync_error_not_allowed)) } }
        return
    }
    val model = rememberSyncHome(signed)
    val home by model.home.collectAsStateWithLifecycle()
    content(model, home)
}

private fun signupLabel(mode: SignupMode) = when (mode) {
    SignupMode.Open -> Res.string.sync_signup_open
    SignupMode.Invite -> Res.string.sync_signup_invite
    SignupMode.Closed -> Res.string.sync_signup_closed
}

// A size in bytes as B, KB, MB or GB.
internal fun sizeText(bytes: Long): String = when {
    bytes < 1024 -> "$bytes B"
    bytes < 1024L * 1024 -> "${bytes / 1024} KB"
    bytes < 1024L * 1024 * 1024 -> "${(bytes * 10 / (1024 * 1024)) / 10.0} MB"
    else -> "${(bytes * 10 / (1024L * 1024 * 1024)) / 10.0} GB"
}
