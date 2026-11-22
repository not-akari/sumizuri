package com.sumizuri.app.ui.theme

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.unit.dp
import com.sumizuri.app.navigation.LocalSideNavWidth
import com.sumizuri.app.ui.kit.cover.LocalCoverPalette
import com.sumizuri.app.ui.kit.cover.rememberCoverPalette
import com.sumizuri.app.ui.theme.background.HideBackdropBehind
import com.sumizuri.app.ui.theme.background.ambientBackground
import com.sumizuri.app.ui.theme.spec.BackgroundPalette
import com.sumizuri.app.ui.theme.spec.CoverColorMode

// The glow behind an immersive page is at least this strong, so the colors of the cover show even in a theme with a faint glow.
private const val ImmersiveGlow = 1.4f

// Gives the page inside the colors of its cover, as the theme in use asks: none, the accents only, a light tint, or the whole page deep in the cover's colors. A grey cover and a cover that is not read yet leave the colors as they are, and the page moves into the cover's colors over a moment once they are known. The page gets its own background, so it is drawn in the new colors from edge to edge.
@Composable
fun CoverTheme(coverUrl: String?, content: @Composable () -> Unit) {
    val spec = LocalThemeSpec.current
    val look = spec.options.pageColors
    // The palette is read even when the page keeps its colors, since the marks of the chapters can still take it.
    val palette by rememberCoverPalette(coverUrl.takeIf { look.mode != CoverColorMode.Off || look.chapterMarks })
    val base = MaterialTheme.colorScheme
    val dark = base.background.luminance() < 0.5f
    val target =
        remember(base, palette, look) {
            palette?.takeIf { look.mode != CoverColorMode.Off }?.let { base.followingCover(it, dark, look) }
                ?: base
        }
    val scheme = target
    // An immersive page lets its glow take the colors of the cover, however the theme colors its glow elsewhere.
    val pageSpec = remember(spec, look.mode) {
        if (look.mode != CoverColorMode.Immersive) {
            spec
        } else {
            val options = spec.options
            val effects = options.effects.copy(bloom = maxOf(options.effects.bloom, ImmersiveGlow))
            spec.copy(
                options = options.copy(
                    effects = effects,
                    background = options.background.copy(palette = BackgroundPalette.Accents),
                ),
            )
        }
    }
    // A page tinted by its cover draws its own background. With the accents alone it keeps the background of the page it is on, which also runs under the tabs at the side.
    val ownBackground = look.mode == CoverColorMode.Tinted || look.mode == CoverColorMode.Immersive
    // The background under it is hidden only when nothing else shows it, which the tabs at the side do.
    if (ownBackground && LocalSideNavWidth.current == 0.dp) HideBackdropBehind()
    CompositionLocalProvider(LocalThemeSpec provides pageSpec, LocalCoverPalette provides palette) {
        MaterialTheme(colorScheme = scheme, shapes = MaterialTheme.shapes, typography = MaterialTheme.typography) {
            // The page fades into the colors of its cover as one picture, so it is not built again for every step.
            ThemeFade(scheme, spread = false) {
                Surface(
                    Modifier.fillMaxSize().then(
                        if (ownBackground) Modifier.ambientBackground(onPage = true) else Modifier,
                    ),
                    color = Color.Transparent,
                    contentColor = MaterialTheme.colorScheme.onBackground,
                    content = content,
                )
            }
        }
    }
}
