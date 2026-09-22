package com.sumizuri.sumizuri

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import android.view.KeyEvent
import android.view.Surface
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth needs a FragmentActivity host, or its biometric prompt crashes.
class MainActivity : FlutterFragmentActivity() {
    // The reader turns this on while it is open and the volume keys setting is on.
    private var interceptVolume = false
    private var volumeChannel: MethodChannel? = null

    // Asks for the fastest refresh rate, such as 120 Hz, since the system may pick 60 Hz.
    private var preferHighRefresh = true

    // Picture in picture keeps a video playing in a small window over other apps.
    private var pipChannel: MethodChannel? = null
    private var autoPip = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sumizuri/volume_keys")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "intercept" -> {
                    interceptVolume = call.arguments as? Boolean ?: false
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        volumeChannel = channel

        val pip = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sumizuri/pip")
        pip.setMethodCallHandler { call, result ->
            when (call.method) {
                "enter" -> result.success(enterPip())
                "autoEnter" -> {
                    autoPip = call.arguments as? Boolean ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        setPictureInPictureParams(pipParams().setAutoEnterEnabled(autoPip).build())
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        pipChannel = pip

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sumizuri/display")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "highRefresh" -> {
                        preferHighRefresh = call.arguments as? Boolean ?: true
                        result.success(applyRefreshRate())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.O)
    private fun pipParams() = PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9))

    private fun enterPip(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            enterPictureInPictureMode(pipParams().build())
        } catch (e: IllegalStateException) {
            false
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // From Android 12 the system enters by itself once auto enter is set.
        if (autoPip && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) enterPip()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("changed", isInPictureInPictureMode)
    }

    override fun onResume() {
        super.onResume()
        applyRefreshRate()
    }

    // Returns a line that says what the screen offers and what was chosen, for the log.
    private fun applyRefreshRate(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return "Android too old to choose a refresh rate"
        val screen: android.view.Display? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay
        }
        val current = screen ?: return "no display"
        val mode = current.mode
        val pixels = mode.physicalWidth.toLong() * mode.physicalHeight
        // The fastest mode with no more pixels than now, and the sharpest one among equal rates.
        val best = current.supportedModes
            .filter { it.physicalWidth.toLong() * it.physicalHeight <= pixels }
            .sortedWith(
                compareByDescending<android.view.Display.Mode> { it.refreshRate }
                    .thenByDescending { it.physicalWidth.toLong() * it.physicalHeight },
            )
            .firstOrNull() ?: return "no modes"
        val offered = current.supportedModes.joinToString(", ") {
            "${it.refreshRate.toInt()}Hz@${it.physicalWidth}x${it.physicalHeight}"
        }
        val attributes = window.attributes
        // 0 lets the system choose again.
        val wanted = if (preferHighRefresh) best.modeId else 0
        if (attributes.preferredDisplayModeId != wanted) {
            attributes.preferredDisplayModeId = wanted
            window.attributes = attributes
        }
        val hint = hintFrameRate(if (preferHighRefresh) best.refreshRate else 0f)
        val now = "${mode.refreshRate.toInt()}Hz@${mode.physicalWidth}x${mode.physicalHeight}"
        return "now $now, asked for ${if (preferHighRefresh) "${best.refreshRate.toInt()}Hz@${best.physicalWidth}x${best.physicalHeight}" else "the system's choice"}, frame rate hint: $hint, offered: $offered"
    }

    private fun findSurfaceView(view: View): SurfaceView? {
        if (view is SurfaceView) return view
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                findSurfaceView(view.getChildAt(i))?.let { return it }
            }
        }
        return null
    }

    // Tells the system how fast to draw, which some phone makers follow over a mode request.
    private fun hintFrameRate(rate: Float): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return "needs Android 11"
        val surface = findSurfaceView(window.decorView)?.holder?.surface ?: return "no surface yet"
        if (!surface.isValid) return "surface not ready"
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                surface.setFrameRate(rate, Surface.FRAME_RATE_COMPATIBILITY_DEFAULT, Surface.CHANGE_FRAME_RATE_ALWAYS)
            } else {
                surface.setFrameRate(rate, Surface.FRAME_RATE_COMPATIBILITY_DEFAULT)
            }
            "set to ${rate.toInt()}"
        } catch (e: Exception) {
            "refused"
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val code = event.keyCode
        if (interceptVolume && (code == KeyEvent.KEYCODE_VOLUME_UP || code == KeyEvent.KEYCODE_VOLUME_DOWN)) {
            // One page turn per press, and holding the button does not repeat.
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                volumeChannel?.invokeMethod("key", mapOf("up" to (code == KeyEvent.KEYCODE_VOLUME_UP)))
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }
}
