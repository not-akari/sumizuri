package com.sumizuri.app.feature.settings.look

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BrightnessAuto
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.LightMode
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.feature.theme.ThemeGallery
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.settings_appearance
import com.sumizuri.app.shared.resources.settings_appearance_hint
import com.sumizuri.app.shared.resources.settings_mode
import com.sumizuri.app.shared.resources.settings_oled
import com.sumizuri.app.shared.resources.settings_oled_glow
import com.sumizuri.app.shared.resources.settings_oled_glow_hint
import com.sumizuri.app.shared.resources.settings_oled_hint
import com.sumizuri.app.shared.resources.settings_theme
import com.sumizuri.app.ui.kit.setting.SettingsHeading
import com.sumizuri.app.ui.kit.setting.ChoiceTabsHeight
import com.sumizuri.app.ui.kit.setting.PartTabs
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.theme.ThemeMode
import org.jetbrains.compose.resources.stringResource

// The page for the look of the app: light or dark, and under it the themes to choose from, with the ways to make one and to change one.
@Composable
fun AppearanceRoute(onBack: () -> Unit, onEditTheme: (String) -> Unit) {
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val themeMode by settings.themeMode.collectAsStateWithLifecycle()
    val oled by settings.oled.collectAsStateWithLifecycle()
    val oledGlow by settings.oledGlow.collectAsStateWithLifecycle()
    SettingsPageFrame(Res.string.settings_appearance, onBack, subtitle = Res.string.settings_appearance_hint, onReset = { container.settings.resetLook() }) {
        SettingsSection(Res.string.settings_mode) {
            // Light, dark or as the system is, each with its own icon.
            padded {
                PartTabs(ThemeMode.entries, themeMode, { stringResource(it.label) }, Modifier.padding(vertical = 6.dp), height = ChoiceTabsHeight, icon = { modeIcon(it) }, accent = true) { settings.onThemeMode(it) }
            }
            padded { SwitchSetting(Res.string.settings_oled, oled, settings::onOled, Res.string.settings_oled_hint) }
            if (oled) padded { SwitchSetting(Res.string.settings_oled_glow, oledGlow, settings::onOledGlow, Res.string.settings_oled_glow_hint) }
        }
        SettingsHeading(stringResource(Res.string.settings_theme))
        ThemeGallery(onEditTheme)
    }
}

// The icon of a color mode.
internal fun modeIcon(mode: ThemeMode): ImageVector = when (mode) {
    ThemeMode.System -> Icons.Outlined.BrightnessAuto
    ThemeMode.Light -> Icons.Outlined.LightMode
    ThemeMode.Dark -> Icons.Outlined.DarkMode
}
