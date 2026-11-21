package com.sumizuri.app.feature.settings.look

import androidx.compose.runtime.Composable
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.app_icon
import com.sumizuri.app.shared.resources.app_icon_hint_short

// The icon of the app on a page of its own, so the look page stays short.
@Composable
fun AppIconRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.app_icon, onBack, subtitle = Res.string.app_icon_hint_short) {
        AppIconSection()
    }
}
