package com.sumizuri.app.feature.sync.admin

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ConfirmationNumber
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.sync.Form
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.feature.sync.Working
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_invite_days
import com.sumizuri.app.shared.resources.sync_invite_days_hint
import com.sumizuri.app.shared.resources.sync_invite_ended
import com.sumizuri.app.shared.resources.sync_invite_ends_in
import com.sumizuri.app.shared.resources.sync_invite_line
import com.sumizuri.app.shared.resources.sync_invite_make
import com.sumizuri.app.shared.resources.sync_invite_new
import com.sumizuri.app.shared.resources.sync_invite_new_hint
import com.sumizuri.app.shared.resources.sync_invite_no_end
import com.sumizuri.app.shared.resources.sync_invite_open
import com.sumizuri.app.shared.resources.sync_invite_remove
import com.sumizuri.app.shared.resources.sync_invite_used
import com.sumizuri.app.shared.resources.sync_invites_hint
import com.sumizuri.app.shared.resources.sync_invites_none
import com.sumizuri.app.shared.resources.sync_invites_section
import com.sumizuri.app.shared.resources.sync_recovery_copy
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.text.NoteText
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.sync.core.InviteEntry
import org.jetbrains.compose.resources.stringResource

// The most days a typed invite length takes, ten years.
private const val MaxInviteDays = 3650

// The invite codes: a new one for any number of days, or no end when left empty, and every code made with who used it.
@Composable
internal fun SyncAdminInvitesRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_invites_section, onBack, subtitle = Res.string.sync_invites_hint) {
        AdminOnly { model, home ->
            var days by remember { mutableStateOf("7") }
            val copy = rememberCopyText()
            SettingsSection(Res.string.sync_invite_make) {
                // A code just made, shown this once to pass on.
                home.newInvite?.let { code ->
                    padded {
                        Form {
                            Text(
                                stringResource(Res.string.sync_invite_new),
                                style = MaterialTheme.typography.labelLarge,
                            )
                            Text(
                                code,
                                style = MaterialTheme.typography.titleLarge,
                                fontFamily = FontFamily.Monospace,
                                fontWeight = FontWeight.SemiBold,
                            )
                            Text(
                                stringResource(Res.string.sync_invite_new_hint),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.outline,
                            )
                            InkOutlinedButton({ copy(code) }) { Text(stringResource(Res.string.sync_recovery_copy)) }
                        }
                    }
                }
                padded {
                    Form(home.busy) {
                        AppTextField(
                            days,
                            { typed -> days = typed.filter(Char::isDigit).take(4) },
                            Modifier.fillMaxWidth(),
                            enabled = !home.busy,
                            label = { Text(stringResource(Res.string.sync_invite_days)) },
                            supportingText = { Text(stringResource(Res.string.sync_invite_days_hint)) },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        )
                        InkButton({
                            model.makeInvite(
                                days
                                    .toIntOrNull()
                                    ?.takeIf {
                                        it > 0
                                    }?.coerceAtMost(MaxInviteDays),
                            )
                        }, enabled = !home.busy) { Text(stringResource(Res.string.sync_invite_make)) }
                    }
                }
            }
            SettingsSection(Res.string.sync_invites_section) {
                if (home.invites?.isEmpty() == true) padded { NoteText(stringResource(Res.string.sync_invites_none)) }
                for (invite in home.invites.orEmpty()) {
                    row {
                        SettingRow(
                            stringResource(Res.string.sync_invite_line, invite.createdBy, agoText(invite.createdAt)),
                            subtitle = inviteState(invite),
                            leading = { SettingIcon(Icons.Outlined.ConfirmationNumber) },
                            trailing = if (invite.usedBy !=
                                null
                            ) {
                                null
                            } else {
                                (
                                    {
                                        TextButton({
                                            model.removeInvite(invite.id)
                                        }, enabled = !home.busy) { Text(stringResource(Res.string.sync_invite_remove)) }
                                    }
                                    )
                            },
                        )
                    }
                }
            }
            if (home.busy) Working()
            home.problem?.let { Problem(it) }
        }
    }
}

// Whether an invite was used, by whom, or how long it still works.
@Composable
private fun inviteState(invite: InviteEntry): String {
    invite.usedBy?.let { return stringResource(Res.string.sync_invite_used, it) }
    val ends = invite.expiresAt
    val left = ends?.let { ((it - nowMillis()) / 86_400_000L).toInt() }
    val time = when {
        ends == null -> stringResource(Res.string.sync_invite_no_end)
        left != null && left < 0 -> stringResource(Res.string.sync_invite_ended)
        else -> stringResource(Res.string.sync_invite_ends_in, (left ?: 0) + 1)
    }
    return "${stringResource(Res.string.sync_invite_open)} · $time"
}
