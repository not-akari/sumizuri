package com.sumizuri.app.feature.settings.about

import androidx.compose.runtime.Composable
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.about_licenses
import com.sumizuri.app.shared.resources.about_licenses_note
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection

// The libraries and fonts the app is built with, each with what it does for the app.
internal val Libraries = listOf(
    "Kotlin and Kotlin Multiplatform" to "Kotlin, JetBrains",
    "Compose Multiplatform and Material 3" to "JetBrains, Google",
    "Room and SQLite" to "Google",
    "Coil" to "Colin White and contributors",
    "Ktor" to "JetBrains",
    "kotlinx.coroutines and kotlinx.serialization" to "JetBrains",
    "Okio" to "Block, Inc.",
    "QuickJS for Kotlin" to "dokar3 and contributors",
    "cryptography-kotlin" to "Oleg Yukhnevich and contributors",
    "QRose" to "Alexander Zhirkevich and contributors",
    "OpenDyslexic" to "Abbie Gonzalez",
)

// The page of the open source work the app stands on. Each library keeps its own license.
@Composable
fun LicensesRoute(onBack: () -> Unit) {
    SettingsPageFrame(Res.string.about_licenses, onBack, subtitle = Res.string.about_licenses_note) {
        SettingsSection { for ((name, by) in Libraries) row { SettingRow(name, subtitle = by) } }
    }
}
