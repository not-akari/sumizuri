package com.sumizuri.app

import android.app.Activity
import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Build
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.filterNotNull

private const val Prefs = "start"
private const val Key = "background"

// How long the background has to stay the same before it is kept, so a fade between themes is kept once.
private const val KeepAfterMs = 1500L

// The background of the theme the person uses, kept on the phone, so the window and the next splash screen open in it.
internal object StartLook {
    fun load(activity: Activity) {
        val saved = prefs(activity).getInt(Key, 0).takeIf { it != 0 }
        AppStart.remembered = saved
        saved?.let { activity.window.setBackgroundDrawable(ColorDrawable(it)) }
    }

    suspend fun keep(activity: Activity) {
        var kept = AppStart.remembered
        AppStart.background.filterNotNull().collectLatest { argb ->
            delay(KeepAfterMs)
            if (argb == kept) return@collectLatest
            activity.window.setBackgroundDrawable(ColorDrawable(argb))
            prefs(activity).edit().putInt(Key, argb).apply()
            splashFor(activity, argb)
            kept = argb
        }
    }

    // Android 13 and newer keep a splash screen for the next start, which is dark or light like the app when that differs from the system.
    private fun splashFor(activity: Activity, argb: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val dark = Color.luminance(argb) < 0.5f
        val systemDark =
            (activity.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
        val theme = when {
            dark == systemDark -> 0
            dark -> R.style.Theme_Sumizuri_Start_Dark
            else -> R.style.Theme_Sumizuri_Start_Light
        }
        runCatching { activity.splashScreen.setSplashScreenTheme(theme) }
    }

    private fun prefs(context: Context) = context.getSharedPreferences(Prefs, Context.MODE_PRIVATE)
}
