package com.sumizuri.app.playback

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.ActivityInfo
import android.view.WindowManager.LayoutParams.ROTATION_ANIMATION_CROSSFADE
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

actual val touchPlayer: Boolean = true

// How long the fade stays the way the screen turns after the player closes, so the turn back fades too.
private const val TurnBackMs = 1500L

@Composable
actual fun PlayerWindow() {
    val view = LocalView.current
    DisposableEffect(view) {
        val activity = view.context.activity()
        val window = activity?.window
        val controller = window?.let { WindowCompat.getInsetsController(it, view) }
        val before = activity?.requestedOrientation
        val turnBefore = window?.attributes?.rotationAnimation
        // The screen fades into its new side instead of spinning.
        window?.let { it.attributes = it.attributes.apply { rotationAnimation = ROTATION_ANIMATION_CROSSFADE } }
        // The video fills a screen turned sideways, and a swipe from the edge shows the bars for a moment.
        activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        controller?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        controller?.hide(WindowInsetsCompat.Type.systemBars())
        onDispose {
            before?.let { activity.requestedOrientation = it }
            controller?.show(WindowInsetsCompat.Type.systemBars())
            if (window != null && turnBefore != null) {
                val back = Runnable { window.attributes = window.attributes.apply { rotationAnimation = turnBefore } }
                window.decorView.postDelayed(back, TurnBackMs)
            }
        }
    }
}

@Composable
actual fun PlayerSystemUi(keepOn: Boolean) {
    val view = LocalView.current
    DisposableEffect(view, keepOn) {
        view.keepScreenOn = keepOn
        onDispose { view.keepScreenOn = false }
    }
}

// The activity that holds a view, which sits under any number of wrappers.
private fun Context.activity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.activity()
    else -> null
}

@Composable
actual fun rememberPlayerEngine(style: SubtitleStyle): PlayerEngine {
    val context = LocalContext.current
    val engine = remember { ExoEngine(context) }
    LaunchedEffect(engine, style) { engine.setSubtitleStyle(style) }
    DisposableEffect(engine) { onDispose { engine.release() } }
    return engine
}
