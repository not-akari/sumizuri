package com.sumizuri.app.data

// Custom icons are left out on iPhone and iPad, so the editor does not show there.
actual object AppIcons {
    actual val supported: Boolean = false

    actual val launcher: Boolean = false

    actual val canPin: Boolean = false

    actual fun current(): AppIcon = AppIcon.Usual

    actual fun choose(icon: AppIcon) = Unit

    actual fun loadDesign(): String? = null

    actual fun saveDesign(text: String) = Unit

    actual fun pin(design: IconDesign, label: String): Boolean = false

    actual fun refreshPin(design: IconDesign) = Unit
}
