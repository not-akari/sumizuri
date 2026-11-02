package com.sumizuri.app.feature.settings.look

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.AppIcon
import com.sumizuri.app.data.AppIcons
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.allStringResources
import com.sumizuri.app.shared.resources.app_icon
import com.sumizuri.app.shared.resources.app_icon_hint
import com.sumizuri.app.ui.kit.setting.SettingsSection
import org.jetbrains.compose.resources.stringResource

// Whether people can pick the icon yet. It stays off until the icons are ready to be shown to everyone.
internal const val AppIconsReady = false

// The icon of the app in the launcher, each shown as the round of its color with the dark circle of the book in it. Only shown where the system lets the app change its icon.
@Composable
internal fun AppIconSection() {
    if (!AppIconsReady || !AppIcons.supported) return
    var current by remember { mutableStateOf(AppIcons.current()) }
    SettingsSection(Res.string.app_icon, Res.string.app_icon_hint) {
        padded {
            FlowRow(Modifier.padding(vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                for (icon in AppIcon.entries) {
                    val chosen = icon == current
                    Column(
                        Modifier.clip(MaterialTheme.shapes.medium).clickable {
                            AppIcons.choose(icon)
                            current = icon
                        }.padding(4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Box(
                            Modifier
                                .size(48.dp)
                                .clip(CircleShape)
                                .background(Color(icon.color))
                                .border(if (chosen) 3.dp else 1.dp, if (chosen) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant, CircleShape),
                            contentAlignment = Alignment.Center,
                        ) {
                            Box(Modifier.size(26.dp).clip(CircleShape).background(Color(0xFF1C1E24)).border(2.dp, Color(0xFFE6DDB0), CircleShape))
                        }
                        Text(
                            stringResource(Res.allStringResources.getValue("app_icon_${icon.name.lowercase()}")),
                            Modifier.padding(top = 4.dp),
                            style = MaterialTheme.typography.labelSmall,
                        )
                    }
                }
            }
        }
    }
}
