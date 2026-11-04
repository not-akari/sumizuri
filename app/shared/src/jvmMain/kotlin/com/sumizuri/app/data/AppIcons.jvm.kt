package com.sumizuri.app.data

import java.util.prefs.Preferences

// A computer keeps the icon its installer gave the shortcut, so the icon made is the one of the open window, the taskbar and the dock. The choice is kept in the preferences of the user.
actual object AppIcons {
    actual val supported: Boolean = true

    actual val launcher: Boolean = false

    actual val canPin: Boolean = false

    private val store by lazy { Preferences.userRoot().node("com/sumizuri/app") }

    actual fun current(): AppIcon = AppIcon.Usual

    actual fun choose(icon: AppIcon) = Unit

    actual fun loadDesign(): String? = runCatching { store.get(DesignKey, null) }.getOrNull()

    actual fun saveDesign(text: String) {
        runCatching {
            store.put(DesignKey, text)
            store.flush()
        }
    }

    actual fun pin(design: IconDesign, label: String): Boolean = false

    actual fun refreshPin(design: IconDesign) = Unit

    private const val DesignKey = "appIconDesign"
}
