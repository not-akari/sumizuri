package com.sumizuri.app.ui.kit.setting

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.input.AppSwitch
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.theme.LocalCompactLists
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// Whether a setting stands in a group of settings, where one with no icon keeps the room of one so its name lines up with the others. Elsewhere, such as in a dialog, it takes no room.
internal val LocalSettingRoom = compositionLocalOf { false }

// The icon of a setting, or empty room the size of one inside a group of settings.
@Composable
internal fun SettingIconOrRoom(icon: ImageVector?) {
    when {
        icon != null -> SettingIcon(icon)
        LocalSettingRoom.current -> Spacer(Modifier.size(22.dp))
    }
}

// The small icon at the start of a setting, in the color of the theme.
@Composable
fun SettingIcon(icon: ImageVector, modifier: Modifier = Modifier) {
    Icon(icon, null, modifier.size(22.dp), tint = MaterialTheme.colorScheme.primary)
}

// A name, a line that explains it and a switch, without padding of its own so it fits in a section or in a panel. A tap anywhere on it flips the switch. The icon comes from the list of icons of the settings unless one is given.
@Composable
fun SwitchSetting(
    title: StringResource,
    checked: Boolean,
    onChange: (Boolean) -> Unit,
    hint: StringResource? = null,
    icon: ImageVector? = settingIconOf(title),
    enabled: Boolean = true,
) = SwitchSetting(stringResource(title), checked, onChange, hint?.let { stringResource(it) }, icon, enabled)

// The same with a name and a line that are already words, such as the switches a source gives.
@Composable
fun SwitchSetting(
    title: String,
    checked: Boolean,
    onChange: (Boolean) -> Unit,
    hint: String? = null,
    icon: ImageVector? = null,
    enabled: Boolean = true,
) {
    val tight = LocalCompactLists.current
    Row(
        Modifier
            .fillMaxWidth()
            .clickable(enabled = enabled) {
                onChange(!checked)
            }.padding(vertical = if (tight) 2.dp else 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SettingIconOrRoom(icon)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                title,
                style = MaterialTheme.typography.bodyLarge,
                color = if (enabled) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outline,
            )
            if (hint !=
                null
            ) {
                Text(hint, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
            }
        }
        AppSwitch(checked, onChange, enabled = enabled)
    }
}
