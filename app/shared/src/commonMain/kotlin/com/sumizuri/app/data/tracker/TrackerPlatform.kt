package com.sumizuri.app.data.tracker

// What the system does for the trackers besides the app: syncing them while the app is closed, where the system can.
expect object TrackerPlatform {
    // Whether this system can sync while the app is closed, which the rules only offer where it can.
    val canPlan: Boolean

    // Plans the sync for while the app is closed, or stops it when it is off or the minutes are zero.
    fun plan(minutes: Int, inBackground: Boolean, wifiOnly: Boolean)
}
