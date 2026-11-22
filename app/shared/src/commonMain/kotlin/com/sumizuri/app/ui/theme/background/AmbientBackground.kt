package com.sumizuri.app.ui.theme.background

import androidx.compose.foundation.background
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.luminance
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.ui.theme.LocalReduceMotion
import com.sumizuri.app.ui.theme.LocalThemeSpec
import com.sumizuri.app.ui.theme.spec.BackgroundPalette
import com.sumizuri.app.ui.theme.spec.BackgroundStyle
import com.sumizuri.app.ui.theme.spec.ThemeBackground
import com.sumizuri.app.ui.theme.spec.toColor
import com.sumizuri.app.ui.tv.LocalTv
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.shareIn

// How strong the background is on a dark page, against a light one. The accents of a dark theme are bright, and at full strength they would light the page above the cards on it, which then look like holes.
private const val DarkInk = 0.45f

// The clocks every background moves by, one for each number of steps a second. All the backgrounds of a window step at the same moment, so the window is drawn once for a step however many backgrounds it holds, and a clock stops when no background uses it.
private object BackdropTicks {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val clocks = HashMap<Int, SharedFlow<Long>>()

    fun at(fps: Int): SharedFlow<Long> = clocks.getOrPut(fps) {
        val stepMs = 1000L / fps
        flow {
            while (true) {
                emit(nowMillis())
                delay(stepMs)
            }
        }.shareIn(scope, SharingStarted.WhileSubscribed(), replay = 1)
    }
}

// A background that something drawn over it can hide. While a page or a part of one covers it from edge to edge, it draws nothing at all and its clock stops.
class BackdropSlot {
    internal var covers by mutableIntStateOf(0)
}

// The background the page being drawn sits on, which a background drawn over the whole of it hides.
val LocalBackdropSlot = compositionLocalOf<BackdropSlot?> { null }

// Hides the background behind this page while it covers it from edge to edge, so the window does not paint a background nobody sees. A page that is still sliding in leaves it shown.
@Composable
fun HideBackdropBehind(covering: Boolean = true) {
    val behind = LocalBackdropSlot.current ?: return
    DisposableEffect(behind, covering) {
        if (covering) behind.covers++
        onDispose { if (covering) behind.covers-- }
    }
}

// The page behind every screen, in the colors of the theme, moving in the style the theme picked. The glow of the theme sets how strong it is, and a theme with none and no shaded edges, as one drawn on true black usually is, keeps its page plain. It stands still while the app is out of sight or its window is not the one in use, when its speed is nothing, or when the person asked for less motion, and it is not drawn at all while something covers its slot. On a page opened over the tabs it takes the strength and the stillness the theme sets for pages.
@Composable
fun Modifier.ambientBackground(slot: BackdropSlot? = null, onPage: Boolean = false): Modifier {
    if (slot != null && slot.covers > 0) return this
    val options = LocalThemeSpec.current.options
    val look = options.background
    val scheme = MaterialTheme.colorScheme
    // On a dark page the background is fainter and lies on the page color itself, so the cards stand out above it.
    val dark = scheme.background.luminance() < 0.5f
    val page = if (dark) scheme.background else scheme.surfaceContainerLow
    if (options.effects.bloom <= 0f && look.vignette <= 0f) return background(page)
    // A TV keeps it still, since redrawing the whole big screen makes a TV box lag.
    val still = LocalReduceMotion.current || LocalTv.current || (onPage && look.pagesStill)
    val clock = rememberBackdropClock(look.speed, look.fps, still)
    val colors = backdropColors(look, scheme)
    val strength = (if (dark) DarkInk else 1f) * options.effects.bloom * (if (onPage) look.pageStrength else 1f)
    // The covers of the library need their pictures loaded, so they are drawn by a layer of their own.
    if (look.style == BackgroundStyle.Covers) {
        val covers = rememberBackdropCovers(look.count.coerceIn(6, 30))
        return background(page).drawBehind { drawCovers(clock.value, look, covers, strength) }
    }
    // The painter keeps what it made between frames, so it lives as long as the page.
    val painter = remember { BackdropPainter() }
    return background(page).drawBehind { with(painter) { draw(clock.value, look, colors, strength, dark) } }
}

// The colors a background is drawn in, from the theme or its own.
internal fun backdropColors(look: ThemeBackground, scheme: ColorScheme): List<Color> = when (look.palette) {
    BackgroundPalette.Accents -> listOf(scheme.primary, scheme.secondary, scheme.tertiary)
    BackgroundPalette.Accent -> listOf(scheme.primary)
    BackgroundPalette.Gray -> listOf(lerp(scheme.onSurface, scheme.background, 0.3f))
    BackgroundPalette.Own -> look.colors.map { it.toColor() }.ifEmpty { listOf(scheme.primary) }
}

// The time the background is drawn at, sped up or slowed down by its speed. Every background reads the one shared clock, so the page over another and the one under it always agree and step together.
@Composable
internal fun rememberBackdropClock(speed: Float, fps: Int, still: Boolean): State<Long> {
    val steps = fps.coerceIn(1, 60)
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    val stopped = still || speed <= 0f
    // The time is counted in doubles, since a float this large would only move in jumps of minutes.
    return produceState((nowMillis() * speed.toDouble()).toLong(), stopped, speed, steps, lifecycle) {
        if (stopped) return@produceState
        lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) {
            BackdropTicks.at(steps).collect { now -> value = (now * speed.toDouble()).toLong() }
        }
    }
}
