package com.sumizuri.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

// The start of the app as the splash screen of the phone sees it: whether the first screen has drawn in the look of the person, and the background of that look.
object AppStart {
    private val drawnNow = MutableStateFlow(false)
    val drawn: StateFlow<Boolean> = drawnNow.asStateFlow()

    // The background of the theme in use as one ARGB number, or null until it is known.
    private val backgroundNow = MutableStateFlow<Int?>(null)
    val background: StateFlow<Int?> = backgroundNow.asStateFlow()

    // The background the theme had the last time, kept by the platform, which shows until the look is read again.
    var remembered: Int? = null

    internal fun markDrawn() {
        drawnNow.value = true
    }

    internal fun reportBackground(argb: Int) {
        backgroundNow.value = argb
    }
}

// Tells the start once the first screen is ready and a frame of it has drawn, and keeps the background of the look up to date.
@Composable
internal fun StartShown(ready: Boolean) {
    val background = MaterialTheme.colorScheme.background
    SideEffect { AppStart.reportBackground(background.toArgb()) }
    LaunchedEffect(ready) {
        if (!ready) return@LaunchedEffect
        withFrameNanos { }
        AppStart.markDrawn()
    }
}

// The background the theme had the last time, drawn while the look of the person is still being read, so the first frame is already in their colors.
@Composable
internal fun StartBackdrop() {
    val color = AppStart.remembered ?: return
    Box(Modifier.fillMaxSize().background(Color(color)))
}
