package com.sumizuri.app

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.Rational
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.lifecycleScope
import com.sumizuri.app.data.AppIcons
import com.sumizuri.app.data.resetWhileHidden
import com.sumizuri.app.navigation.AppLinks
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.navigation.requestedTabOf
import com.sumizuri.app.playback.LocalMiniPlayer
import com.sumizuri.app.playback.MiniPlayerControl
import com.sumizuri.app.playback.PlayingNow
import com.sumizuri.app.ui.requestMaxRefreshRate
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    // The tab a shortcut of the launcher asked for, until the app has opened it.
    private var requestedTab by mutableStateOf<Destination?>(null)

    // Whether the video shows small in picture in picture, which hides the controls of the player.
    private var inPicture by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        // The splash screen stays until the first page has drawn in the colors of the person, or a few seconds at most.
        val opened = SystemClock.uptimeMillis()
        installSplashScreen().setKeepOnScreenCondition {
            !AppStart.drawn.value &&
                SystemClock.uptimeMillis() - opened < SplashMostMs
        }
        StartLook.load(this)
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val profiles = (application as SumizuriApplication).profiles
        // A shortcut asks again only when the app is started by it, not when it comes back after a turn of the screen.
        if (savedInstanceState == null) requestedTab = requestedTabOf(intent.getStringExtra("tab"))
        if (savedInstanceState == null) AppLinks.open(intent.dataString)
        setContent {
            val mini = MiniPlayerControl(inPicture, enter = ::enterPicture, exit = {})
            CompositionLocalProvider(LocalMiniPlayer provides mini) {
                App(profiles, requestedTab = requestedTab, onTabOpened = { requestedTab = null })
            }
        }
        requestMaxRefreshRate()
        lifecycleScope.launch { StartLook.keep(this@MainActivity) }
    }

    override fun onResume() {
        super.onResume()
        requestMaxRefreshRate()
    }

    // The lock counts the time the app is away. A turn of the screen stops the page too, but the app never left.
    override fun onStart() {
        super.onStart()
        (application as SumizuriApplication)
            .profiles.container.value.lock
            .onBack()
    }

    override fun onStop() {
        super.onStop()
        if (!isChangingConfigurations) {
            // Done while the app is away, since changing the icon while it is open can close it on some phones.
            AppIcons.resetWhileHidden()
            (application as SumizuriApplication)
                .profiles.container.value.lock
                .onAway()
        }
    }

    fun enterPicture(aspect: Float) {
        val params = pictureParams(aspect) ?: return
        runCatching { enterPictureInPictureMode(params) }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        PlayingNow.aspect?.let(::enterPicture)
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        inPicture = isInPictureInPictureMode
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        requestedTabOf(intent.getStringExtra("tab"))?.let { requestedTab = it }
        AppLinks.open(intent.dataString)
    }
}

// Leaving the app while a video plays keeps it playing small in a corner.
private fun MainActivity.pictureParams(aspect: Float): PictureInPictureParams? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
    // Android takes shapes from 1 in 2.39 to 2.39 in 1.
    val shape = aspect.coerceIn(0.42f, 2.39f)
    return PictureInPictureParams.Builder().setAspectRatio(Rational((shape * 1000).toInt(), 1000)).build()
}

// The longest the splash screen waits for the first page, so a slow start still opens.
private const val SplashMostMs = 3000L
