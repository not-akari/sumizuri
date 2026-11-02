package com.sumizuri.app.data.account

// When the system runs a sync while the app is closed, as the settings of When to sync say.
data class SyncPlan(val minutes: Int, val inBackground: Boolean, val wifiOnly: Boolean, val charging: Boolean)

// What the system does for sync besides the app: running it while the app is closed, where the system can.
expect object SyncPlatform {
    // Plans the sync for while the app is closed, or stops it when it is off or the minutes are zero.
    fun plan(plan: SyncPlan)

    // Shows a notice that a sync did not finish, which opens the app when tapped, and takes it away again.
    suspend fun showFailure(title: String, text: String)

    fun clearFailure()
}
