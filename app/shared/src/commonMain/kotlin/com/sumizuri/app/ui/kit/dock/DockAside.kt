package com.sumizuri.app.ui.kit.dock

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.theme.LocalReduceMotion

// How wide the card of a panel is on a wide window, and from what window width panels open in it instead of in the dock.
private val CardWidth = 440.dp
private val WideFrom = 840.dp

// The least gap between the card and a dock beside it. With less room the card sits above the dock.
private val DockGap = 24.dp

// How long the card takes to slide in or out, and the most of the height it may take before what it holds scrolls.
private const val CardMs = 300
private const val CardShare = 0.75f

// Whether the window is wide enough for the desktop layout of the reader and the player, with the dock in one row and panels in a card.
@Composable
fun isWideWindow(): Boolean = with(LocalDensity.current) {
    LocalWindowInfo.current.containerSize.width
        .toDp()
} >= WideFrom

// The page or the video with a panel open as a card at its bottom right on a wide window, in the look of the dock and only as tall as what it holds. The card lies over what is shown and never moves or shrinks it, nor the dock: it sits beside the dock where there is room and above it where the dock reaches into its corner. It slides in whole from the edge and slides away still showing what it held.
@Composable
fun AsideCard(shown: Boolean, modifier: Modifier, panel: @Composable () -> Unit, content: @Composable () -> Unit) {
    val ms = if (LocalReduceMotion.current) 0 else motionMs(CardMs)
    var drawn by remember { mutableStateOf(shown) }
    val slide = remember { Animatable(if (shown) 1f else 0f) }
    LaunchedEffect(shown, ms) {
        val motion = tween<Float>(ms, easing = FastOutSlowInEasing)
        if (shown) {
            drawn = true
            slide.animateTo(1f, motion)
        } else {
            slide.animateTo(0f, motion)
            drawn = false
        }
    }
    val dock = remember { AsideDock() }
    val above by animateDpAsState(if (dock.inTheWay) dock.height else 0.dp, tween(ms, easing = FastOutSlowInEasing))
    // Above the dock the card lines up with its right end, and beside it the card keeps to the edge of the window.
    val end by animateDpAsState(if (dock.inTheWay) dock.end else DockMargin, tween(ms, easing = FastOutSlowInEasing))
    val bottom = WindowInsets.safeDrawing.asPaddingValues().calculateBottomPadding()
    Box(modifier) {
        CompositionLocalProvider(LocalAsideDock provides dock) { content() }
        if (drawn) {
            val colors = MaterialTheme.colorScheme
            Surface(
                Modifier
                    .align(Alignment.BottomEnd)
                    .fillMaxHeight(CardShare)
                    .graphicsLayer { translationX = (1f - slide.value) * size.width }
                    .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.End))
                    .padding(
                        top = DockMargin,
                        end = end,
                        bottom = if (above >
                            0.dp
                        ) {
                            above
                        } else {
                            bottom + DockMargin
                        },
                        // The width comes after the gaps, so a card lined up with the end of a narrow dock keeps its full width.
                    ).width(CardWidth)
                    .wrapContentHeight(Alignment.Bottom),
                shape = DockShape,
                color = colors.surfaceContainerHigh,
                border = BorderStroke(1.dp, colors.outlineVariant.copy(alpha = 0.5f)),
            ) {
                Box(Modifier.padding(horizontal = 8.dp, vertical = 6.dp)) { panel() }
            }
        }
    }
}

// What the dock along the bottom tells an open card: how tall it is with its margins, whether it reaches into the corner of the card, and how far its right end is from the right of the window.
class AsideDock {
    var height by mutableStateOf(0.dp)
    var inTheWay by mutableStateOf(false)
    var end by mutableStateOf(0.dp)
}

val LocalAsideDock = staticCompositionLocalOf<AsideDock?> { null }

// Put on the dock along the bottom, centered in the given room, so an open card knows whether to sit beside it or above it.
@Composable
fun Modifier.tellsAsideCard(dockWidth: Dp, roomWidth: Dp): Modifier {
    val dock = LocalAsideDock.current ?: return this
    val density = LocalDensity.current
    val inTheWay = (roomWidth + dockWidth) / 2 + DockGap > roomWidth - CardWidth
    SideEffect {
        dock.inTheWay = inTheWay
        dock.end = ((roomWidth - dockWidth) / 2).coerceAtLeast(DockMargin)
    }
    return onSizeChanged { dock.height = with(density) { it.height.toDp() } }
}

// Shows the last value that was not null, so a panel that closes slides away still showing what it held.
@Composable
fun <T : Any> KeepLast(value: T?, content: @Composable (T) -> Unit) {
    var last by remember { mutableStateOf(value) }
    if (value != null) last = value
    last?.let { content(it) }
}
