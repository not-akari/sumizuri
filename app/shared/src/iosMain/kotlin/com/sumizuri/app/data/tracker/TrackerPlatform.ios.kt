package com.sumizuri.app.data.tracker

// An iPhone syncs while the app is open, as it does for the sync server.
actual object TrackerPlatform {
    actual val canPlan: Boolean = false

    actual fun plan(minutes: Int, inBackground: Boolean, wifiOnly: Boolean) = Unit
}
