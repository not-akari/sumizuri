package com.sumizuri.app.feature.settings.system

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.experimental_profile_banner
import com.sumizuri.app.shared.resources.experimental_profile_banner_hint
import com.sumizuri.app.shared.resources.settings_experimental
import com.sumizuri.app.shared.resources.settings_experimental_hint
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import kotlinx.coroutines.launch

// The page of features still being tried out. Each is off until the person turns it on, and the page itself only shows once it is turned on in Advanced.
@Composable
fun ExperimentalRoute(onBack: () -> Unit) {
    val settings = LocalAppContainer.current.settings
    val scope = rememberCoroutineScope()
    val banner by remember(
        settings,
    ) { settings.flag(SettingKey.ProfileBanner, false) }.collectAsStateWithLifecycle(false)
    SettingsPageFrame(Res.string.settings_experimental, onBack, subtitle = Res.string.settings_experimental_hint) {
        SettingsSection {
            padded {
                SwitchSetting(Res.string.experimental_profile_banner, banner, { on ->
                    scope.launch { settings.setFlag(SettingKey.ProfileBanner, on) }
                }, Res.string.experimental_profile_banner_hint)
            }
        }
    }
}
