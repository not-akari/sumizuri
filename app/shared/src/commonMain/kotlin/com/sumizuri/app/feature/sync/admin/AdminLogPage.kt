package com.sumizuri.app.feature.sync.admin

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.History
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.sync.Problem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_log
import com.sumizuri.app.shared.resources.sync_log_empty
import com.sumizuri.app.shared.resources.sync_log_hint
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.text.NoteText
import com.sumizuri.app.ui.text.agoText
import org.jetbrains.compose.resources.stringResource

// What was done on the server, newest first: who did it, what, to whom, and when. The server writes each line in its own words.
@Composable
internal fun SyncAdminLogRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.sync_log, onBack, subtitle = Res.string.sync_log_hint) {
        AdminOnly { model, home ->
            LaunchedEffect(model) { model.loadLog() }
            val log = home.log
            SettingsSection {
                if (log != null && log.isEmpty()) padded { NoteText(stringResource(Res.string.sync_log_empty)) }
                for (line in log.orEmpty()) {
                    row {
                        SettingRow(
                            listOf(line.actor, line.action, line.target).filter { it.isNotBlank() }.joinToString(" "),
                            subtitle = listOf(
                                agoText(line.at),
                                line.detail,
                            ).filter { it.isNotBlank() }.joinToString(", "),
                            leading = { SettingIcon(Icons.Outlined.History) },
                        )
                    }
                }
            }
            home.problem?.let { Problem(it) }
        }
    }
}
