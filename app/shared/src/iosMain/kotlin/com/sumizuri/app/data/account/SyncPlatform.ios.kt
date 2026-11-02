package com.sumizuri.app.data.account

// Sync while the app is closed needs a task the system schedules, which is not written yet. The app syncs while it is open.
actual object SyncPlatform {
    actual fun plan(plan: SyncPlan) = Unit

    // The sync page says how the last sync went, as notices are not set up on the iPhone yet.
    actual suspend fun showFailure(title: String, text: String) = Unit

    actual fun clearFailure() = Unit
}
