package com.sumizuri.app.data.account

import com.sumizuri.app.data.sync.showTrayNotice

// A computer syncs while the app runs, also from the tray, so nothing is planned for while it is closed.
actual object SyncPlatform {
    actual fun plan(plan: SyncPlan) = Unit

    // A tray notice goes away by itself, so there is nothing to take away.
    actual suspend fun showFailure(title: String, text: String) = showTrayNotice(title, text)

    actual fun clearFailure() = Unit
}
