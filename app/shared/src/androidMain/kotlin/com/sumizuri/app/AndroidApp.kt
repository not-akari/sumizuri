package com.sumizuri.app

import android.content.Context
import android.content.pm.PackageManager
import com.sumizuri.app.data.profile.ProfileHost

// What the parts of the app that run with no screen need from the Android app, such as the check of the library while the app is closed. The app sets both when it starts.
object AndroidApp {
    lateinit var context: Context
    lateinit var profiles: () -> ProfileHost

    // Whether this is the TV app, which says so in its manifest. It always shows the screens of a TV and takes only the TV files of a new version.
    val tvApp: Boolean by lazy {
        runCatching {
            context.packageManager
                .getApplicationInfo(
                    context.packageName,
                    PackageManager.GET_META_DATA,
                ).metaData
                ?.getBoolean(TvAppKey) ==
                true
        }.getOrDefault(false)
    }

    private const val TvAppKey = "sumizuri.tv_app"
}
