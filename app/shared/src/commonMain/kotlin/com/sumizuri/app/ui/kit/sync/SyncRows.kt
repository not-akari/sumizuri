package com.sumizuri.app.ui.kit.sync

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.list_show_more
import com.sumizuri.app.shared.resources.list_show_rest
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.agoText
import org.jetbrains.compose.resources.stringResource

// One sync of a log: when, whether it worked, and what it did in a line each.
class RunLogRow(val at: Long, val ok: Boolean, val lines: List<String>)

// The past syncs of a page that syncs, newest first.
@Composable
fun RunLogSection(title: String, empty: String, rows: List<RunLogRow>) {
    SettingsSection(title) {
        if (rows.isEmpty()) {
            padded {
                Text(
                    empty,
                    Modifier.fillMaxWidth().padding(vertical = 4.dp),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
        }
        for (entry in rows) {
            row {
                SettingRow(
                    agoText(entry.at),
                    subtitle = entry.lines.joinToString("\n"),
                    subtitleLines = entry.lines.size.coerceAtLeast(1) + 1,
                    leading = {
                        SettingIcon(
                            if (entry.ok) Icons.Outlined.CheckCircle else Icons.Outlined.ErrorOutline,
                        )
                    },
                )
            }
        }
    }
}

// One title of a sync with its cover, a line about it, and what it offers on the right.
@Composable
fun CoverRow(
    name: String,
    kind: Kind,
    cover: String?,
    subtitle: String,
    trailing: (@Composable () -> Unit)? = null,
    onClick: (() -> Unit)? = null,
) {
    // Made once for its name and cover, so a long list does not make it again at each change.
    val shown = remember(name, kind, cover) {
        Title(
            id = 0,
            name = name,
            kind = kind,
            coverUrl = cover,
            unread = 0,
            status = Status.Unknown,
            summary = "",
            inLibrary = false,
        )
    }
    SettingRow(
        name,
        subtitle = subtitle,
        leading = { CoverArt(shown, Modifier.width(40.dp), letterSize = 16) },
        trailing = trailing,
        onClick = onClick,
    )
}

// How many rows a long list of a sync page shows at first, and how many more each tap of its button adds, so a big library stays quick to draw.
const val ListStep = 50

// The button under a long list that shows more of it, saying how many are left.
@Composable
fun MoreRows(left: Int, onMore: () -> Unit) {
    TextButton(onMore, Modifier.fillMaxWidth()) {
        Text(
            if (left >
                ListStep
            ) {
                stringResource(Res.string.list_show_more, ListStep, left)
            } else {
                stringResource(Res.string.list_show_rest, left)
            },
        )
    }
}
