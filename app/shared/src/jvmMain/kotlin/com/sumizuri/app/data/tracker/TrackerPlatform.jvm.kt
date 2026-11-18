package com.sumizuri.app.data.tracker

// A computer syncs while the app runs, also from the tray, so nothing is planned for while it is closed.
actual object TrackerPlatform {
    actual val canPlan: Boolean = false

    actual fun plan(minutes: Int, inBackground: Boolean, wifiOnly: Boolean) = Unit
}
