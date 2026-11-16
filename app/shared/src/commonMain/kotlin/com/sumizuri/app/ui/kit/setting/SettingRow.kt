package com.sumizuri.app.ui.kit.setting
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.theme.LocalCompactLists
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// One row inside a section: something at the start, the name with a line under it, and something at the end. It takes a tap when it is given what to do. Inside a page the name has the same weight as the switches and the pickers beside it, and the rows of the home that lead to pages have a stronger one.
@Composable
fun SettingRow(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    subtitleLines: Int = 2,
    leading: (@Composable () -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
    onClick: (() -> Unit)? = null,
    strong: Boolean = false,
) {
    val tight = LocalCompactLists.current
    Row(
        modifier
            .fillMaxWidth()
            .then(
                if (onClick !=
                    null
                ) {
                    Modifier.clickable(onClick = onClick)
                } else {
                    Modifier
                },
            ).padding(horizontal = 14.dp, vertical = if (tight) 6.dp else 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        leading?.invoke()
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (strong) FontWeight.SemiBold else FontWeight.Normal,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (subtitle !=
                null
            ) {
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                    maxLines = subtitleLines,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        trailing?.invoke()
    }
}

// The rows of one section of a settings page, collected so the section can draw them in one card with a line between each.
class SettingsRows {
    internal val items = mutableListOf<@Composable () -> Unit>()

    // A row that sets its own padding, such as a row that opens a page.
    fun row(content: @Composable () -> Unit) {
        items += content
    }

    // A control that has no padding of its own, such as a switch, a slider or a picker.
    fun padded(content: @Composable () -> Unit) {
        items += { Box(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 4.dp)) { content() } }
    }
}

// A group of settings of a page: a heading, the rows together in one card with a thin line between them, and under it an optional line that explains the group.
@Composable
fun SettingsSection(title: StringResource?, hint: StringResource? = null, build: SettingsRows.() -> Unit) {
    SettingsSection(title?.let { stringResource(it) }, hint?.let { stringResource(it) }, build)
}

// A group with no heading, for a page that is only one group.
@Composable
fun SettingsSection(build: SettingsRows.() -> Unit) {
    SettingsSection(null as String?, null, build)
}

// The same with a title and a hint that are already text, such as the name of a source.
@Composable
fun SettingsSection(title: String?, hint: String? = null, build: SettingsRows.() -> Unit) {
    val rows = SettingsRows().apply(build)
    Column(Modifier.entrance()) {
        if (title != null) SettingsHeading(title)
        AppCard {
            CompositionLocalProvider(LocalSettingRoom provides true) {
                Column {
                    rows.items.forEachIndexed { index, row ->
                        if (index >
                            0
                        ) {
                            HorizontalDivider(
                                Modifier.padding(horizontal = 14.dp),
                                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f),
                            )
                        }
                        row()
                    }
                }
            }
        }
        if (hint !=
            null
        ) {
            Text(
                hint,
                Modifier.padding(start = 14.dp, top = 6.dp, end = 14.dp),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline,
            )
        }
    }
}

// The name of a group of settings, quiet and in its own case, as the panels of the reader name theirs. A page that draws its own groups names them with it too.
@Composable
fun SettingsHeading(text: String) {
    Text(
        text,
        Modifier.padding(start = 4.dp, top = 18.dp, bottom = 8.dp),
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

// A row that leads somewhere: its icon, its name with a line under it, and an arrow.
@Composable
fun SettingLinkRow(icon: ImageVector, title: String, hint: String, onClick: () -> Unit) {
    SettingRow(title, subtitle = hint, subtitleLines = 3, leading = {
        SettingIcon(icon)
    }, trailing = { ListChevron() }, onClick = onClick)
}
