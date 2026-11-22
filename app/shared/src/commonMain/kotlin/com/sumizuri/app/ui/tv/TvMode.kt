package com.sumizuri.app.ui.tv

import androidx.compose.runtime.staticCompositionLocalOf

// Whether the app runs on a TV, where it is used from a couch with a remote and gets screens of its own.
expect fun isTvDevice(): Boolean

// Whether the screens are the ones made for a TV, set once at the root of the app.
val LocalTv = staticCompositionLocalOf { false }
