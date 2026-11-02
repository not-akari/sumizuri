package com.sumizuri.app.feature.sync.admin

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PersonOff
import androidx.compose.material.icons.outlined.Shield
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.sumizuri.app.feature.settings.PageRow
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.sync.Note
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.feature.sync.account.deviceIcon
import com.sumizuri.app.feature.sync.roleLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_admin_profiles
import com.sumizuri.app.shared.resources.sync_admin_stored
import com.sumizuri.app.shared.resources.sync_device_line
import com.sumizuri.app.shared.resources.sync_devices_section
import com.sumizuri.app.shared.resources.sync_handover
import com.sumizuri.app.shared.resources.sync_handover_confirm
import com.sumizuri.app.shared.resources.sync_handover_message
import com.sumizuri.app.shared.resources.sync_handover_title
import com.sumizuri.app.shared.resources.sync_people_hint
import com.sumizuri.app.shared.resources.sync_people_section
import com.sumizuri.app.shared.resources.sync_person_admin
import com.sumizuri.app.shared.resources.sync_person_admin_hint
import com.sumizuri.app.shared.resources.sync_person_danger
import com.sumizuri.app.shared.resources.sync_person_delete
import com.sumizuri.app.shared.resources.sync_person_delete_message
import com.sumizuri.app.shared.resources.sync_person_delete_title
import com.sumizuri.app.shared.resources.sync_person_deleted
import com.sumizuri.app.shared.resources.sync_person_disabled
import com.sumizuri.app.shared.resources.sync_person_disabled_hint
import com.sumizuri.app.shared.resources.sync_person_no_devices
import com.sumizuri.app.shared.resources.sync_person_restore
import com.sumizuri.app.shared.resources.sync_person_sign_out_all
import com.sumizuri.app.shared.resources.sync_person_since
import com.sumizuri.app.shared.resources.sync_person_title
import com.sumizuri.app.shared.resources.sync_person_two_step
import com.sumizuri.app.shared.resources.sync_two_step_turn_off
import com.sumizuri.app.shared.resources.sync_user_deleted
import com.sumizuri.app.shared.resources.sync_user_devices
import com.sumizuri.app.shared.resources.sync_user_disabled
import com.sumizuri.app.shared.resources.sync_user_never
import com.sumizuri.app.shared.resources.sync_user_seen
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.sync.core.Role
import com.sumizuri.sync.core.UserChange
import com.sumizuri.sync.core.UserEntry
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// Everyone on the server. Tapping a person opens their page.
@Composable
internal fun SyncAdminPeopleRoute(onBack: () -> Unit, onOpen: (SettingsTarget) -> Unit) {
    SettingsPageFrame(Res.string.sync_people_section, onBack, subtitle = Res.string.sync_people_hint) {
        AdminOnly { model, home ->
            SettingsSection {
                for (user in home.users.orEmpty()) {
                    row {
                        PageRow(userIcon(user), user.username, userLine(user), {
                            model.openPerson(user.id)
                            onOpen(SettingsTarget.SyncAdminUser)
                        })
                    }
                }
            }
        }
    }
}

// One person: what they use and their devices, and turning them off, their role, signing them out and deleting them. What the rules do not allow is greyed out.
@Composable
internal fun SyncAdminUserRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_person_title, onBack) {
        AdminOnly { model, home ->
            val detail = home.person ?: return@AdminOnly
            val user = detail.user
            val me = model.role
            // The owner is never managed here, an admin only manages users, and nobody turns off or deletes themselves.
            val canManage =
                user.role != Role.Owner && user.id != model.userId && (me == Role.Owner || user.role == Role.User)
            var deleting by remember { mutableStateOf(false) }
            var handing by remember { mutableStateOf(false) }
            val deleted = user.deletedAt
            SettingsSection(user.username) {
                row {
                    SettingRow(
                        stringResource(
                            roleLabel(user.role),
                        ),
                        subtitle = stringResource(Res.string.sync_person_since, agoText(user.createdAt)),
                        leading = {
                            SettingIcon(userIcon(user))
                        },
                    )
                }
                row {
                    SettingRow(
                        pluralStringResource(Res.plurals.sync_admin_profiles, detail.profiles, detail.profiles),
                        subtitle = stringResource(
                            Res.string.sync_admin_stored,
                            sizeText(detail.storedBytes),
                        ),
                        leading = {
                            SettingIcon(Icons.Outlined.Inventory2)
                        },
                    )
                }
                // A deleted person can only be brought back, for the week the server keeps them.
                if (deleted != null) {
                    padded { Note(stringResource(Res.string.sync_person_deleted, agoText(deleted))) }
                    padded {
                        InkButton(model::restorePerson, enabled = canManage && !home.busy) {
                            Text(stringResource(Res.string.sync_person_restore))
                        }
                    }
                    return@SettingsSection
                }
                padded {
                    SwitchSetting(
                        Res.string.sync_person_disabled,
                        user.disabled,
                        {
                            model.changePerson(UserChange(disabled = it))
                        },
                        Res.string.sync_person_disabled_hint,
                        enabled =
                        canManage && !home.busy,
                    )
                }
                if (me == Role.Owner) {
                    padded {
                        SwitchSetting(
                            Res.string.sync_person_admin,
                            user.role == Role.Admin,
                            {
                                model.changePerson(UserChange(role = if (it) Role.Admin else Role.User))
                            },
                            Res.string.sync_person_admin_hint,
                            enabled =
                            user.role != Role.Owner && !home.busy,
                        )
                    }
                }
                // An admin turns off two-step sign in for someone who lost the phone with their authenticator app.
                if (user.twoStep) {
                    padded { Note(stringResource(Res.string.sync_person_two_step)) }
                    padded {
                        InkOutlinedButton(model::turnOffTwoStepForPerson, enabled = canManage && !home.busy) {
                            Text(stringResource(Res.string.sync_two_step_turn_off))
                        }
                    }
                }
            }
            SettingsSection(Res.string.sync_devices_section) {
                if (detail.devices.isEmpty()) padded { Note(stringResource(Res.string.sync_person_no_devices)) }
                for (device in detail.devices) {
                    row {
                        SettingRow(
                            device.name,
                            subtitle = stringResource(
                                Res.string.sync_device_line,
                                device.appVersion,
                                agoText(device.lastSeen),
                            ),
                            leading = {
                                SettingIcon(deviceIcon(device.type))
                            },
                        )
                    }
                }
                padded {
                    InkOutlinedButton(
                        model::signOutPerson,
                        enabled =
                        detail.devices.isNotEmpty() && user.role != Role.Owner && !home.busy,
                    ) { Text(stringResource(Res.string.sync_person_sign_out_all)) }
                }
            }
            if (deleted == null) {
                SettingsSection(Res.string.sync_person_danger) {
                    // Only the owner hands the server over, and only to someone turned on.
                    if (me == Role.Owner && user.role != Role.Owner && !user.disabled) {
                        padded {
                            InkOutlinedButton(
                                { handing = true },
                                enabled = !home.busy,
                            ) { Text(stringResource(Res.string.sync_handover)) }
                        }
                    }
                    padded {
                        InkOutlinedButton({
                            deleting = true
                        }, enabled = canManage && !home.busy) { Text(stringResource(Res.string.sync_person_delete)) }
                    }
                }
            }
            if (handing) {
                ConfirmDialog(
                    stringResource(Res.string.sync_handover_title, user.username),
                    stringResource(Res.string.sync_handover_message, user.username),
                    stringResource(Res.string.sync_handover_confirm),
                    onConfirm = {
                        handing = false
                        model.handOver(onBack)
                    },
                    onDismiss = { handing = false },
                )
            }
            if (home.busy) Working()
            home.problem?.let { Problem(it) }
            if (deleting) {
                ConfirmDialog(
                    stringResource(Res.string.sync_person_delete_title, user.username),
                    stringResource(Res.string.sync_person_delete_message),
                    stringResource(Res.string.sync_person_delete),
                    onConfirm = {
                        deleting = false
                        model.deletePerson(onBack)
                    },
                    onDismiss = { deleting = false },
                )
            }
        }
    }
}

private fun userIcon(user: UserEntry) = when {
    user.disabled -> Icons.Outlined.PersonOff
    user.role == Role.User -> Icons.Outlined.Person
    else -> Icons.Outlined.Shield
}

// A person's role, devices and when they were last seen, in one line.
@Composable
private fun userLine(user: UserEntry): String {
    val seen =
        user.lastSeen?.let { stringResource(Res.string.sync_user_seen, agoText(it)) }
            ?: stringResource(Res.string.sync_user_never)
    return listOfNotNull(
        stringResource(roleLabel(user.role)),
        stringResource(Res.string.sync_user_devices, user.devices),
        seen,
        if (user.disabled) stringResource(Res.string.sync_user_disabled) else null,
        if (user.deletedAt != null) stringResource(Res.string.sync_user_deleted) else null,
    ).joinToString(" · ")
}
