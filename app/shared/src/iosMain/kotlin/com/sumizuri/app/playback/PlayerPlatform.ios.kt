package com.sumizuri.app.playback

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.UIKitViewController
import platform.AVFoundation.*
import platform.AVKit.*
import platform.UIKit.*

actual val touchPlayer: Boolean = true

// Turning the screen sideways and hiding the bars are done by the view controller of the app, which is not written yet.
@Composable
actual fun PlayerWindow() = Unit

// The screen stays on while a video plays.
@Composable
actual fun PlayerSystemUi(keepOn: Boolean) {
    DisposableEffect(keepOn) {
        UIApplication.sharedApplication.idleTimerDisabled = keepOn
        onDispose { UIApplication.sharedApplication.idleTimerDisabled = false }
    }
}

@Composable
actual fun rememberPlayerEngine(style: SubtitleStyle): PlayerEngine {
    val engine = remember { AvEngine() }
    DisposableEffect(engine) { onDispose { engine.release() } }
    return engine
}

// The picture, in the view of the player of the system with its own controls turned off, which the screen of the app draws instead.
@Composable
actual fun PlayerSurface(engine: PlayerEngine, aspect: AspectMode, modifier: Modifier) {
    val av = engine as? AvEngine ?: return
    val controller = remember(av) {
        AVPlayerViewController().apply {
            player = av.player
            showsPlaybackControls = false
        }
    }
    UIKitViewController(
        factory = { controller },
        modifier = modifier,
        update = {
            it.videoGravity = when (aspect) {
                AspectMode.Fit -> AVLayerVideoGravityResizeAspect
                AspectMode.Fill -> AVLayerVideoGravityResizeAspectFill
                AspectMode.Stretch -> AVLayerVideoGravityResize
            }
        },
    )
}
