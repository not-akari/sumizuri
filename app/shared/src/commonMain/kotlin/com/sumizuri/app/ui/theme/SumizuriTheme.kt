package com.sumizuri.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import com.sumizuri.app.ui.theme.spec.AccentSource
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.tv.LocalTv

// The look of the app from the theme in use: its colors in the light or dark mode, the corners of its pieces and its fonts. Pieces with a look of their own beyond those read the theme from LocalThemeSpec.
@Composable
fun SumizuriTheme(
    mode: ThemeMode,
    themeSpec: AppThemeSpec,
    oled: Boolean = false,
    oledGlow: Boolean = false,
    // Whether a change of look fades from the old one, which a preview that changes as a slider moves leaves out.
    fade: Boolean = true,
    content: @Composable () -> Unit,
) {
    val dark = when (mode) {
        ThemeMode.System -> isSystemInDarkTheme()
        ThemeMode.Light -> false
        ThemeMode.Dark -> true
    }
    // A theme can take its accent from the system or from the time of day instead of its own colors.
    val seed = when (themeSpec.options.accentFrom) {
        AccentSource.System -> rememberSystemAccent()
        AccentSource.Clock -> rememberClockAccent()
        AccentSource.Theme -> null
    }
    // On a black page the theme is drawn without what would light the screen, unless the person keeps it.
    val spec = remember(themeSpec, dark, oled, oledGlow, seed) {
        val accented = seed?.let { themeSpec.withAccent(it) } ?: themeSpec
        if (dark && oled) accented.onBlack(oledGlow) else accented
    }
    val scheme = remember(spec, dark) { spec.colorScheme(dark) }
    val shapes = remember(spec.shapes) { spec.shapes.toMaterial() }
    CompositionLocalProvider(LocalThemeSpec provides spec) {
        MaterialTheme(colorScheme = scheme, shapes = shapes, typography = themedTypography(spec.options.typography)) {
            // Text that is not on a Material surface takes the color of the page text, since the default would be black.
            CompositionLocalProvider(LocalContentColor provides scheme.onBackground) {
                // A TV changes its look with ink over the screen instead, since a picture of the screen is not a true copy on Android.
                if (fade && !LocalTv.current) ThemeFade(scheme, content = content) else content()
            }
        }
    }
}
