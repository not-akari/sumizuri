package com.sumizuri.app.ui.tv

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import com.sumizuri.app.AndroidApp

// The TV app always is one. Otherwise a TV says so through its mode, and a TV box that does not still has the launcher of a TV.
actual fun isTvDevice(): Boolean = AndroidApp.tvApp || runCatching {
    val context = AndroidApp.context
    val mode = (context.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager)?.currentModeType
    mode == Configuration.UI_MODE_TYPE_TELEVISION ||
        context.packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
}.getOrDefault(false)
