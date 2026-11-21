package com.sumizuri.app.ui.kit.dock

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.theme.LocalReduceMotion
import kotlinx.coroutines.delay

// From what window width the reader and the player lay their island out for a wide window.
private val WideFrom = 840.dp

// How wide the island grows on a phone or a tablet, and on a wide window.
val IslandWidth = 640.dp
val WideIslandWidth = 1100.dp

// How round the open island is, and the room each action takes in a row of a wide island.
val IslandCorner = 26.dp
val IslandActionWidth = 60.dp

// How wide a panel hanging from the island of a wide window is.
private val HangWidth = 440.dp

// How far the ring of ink spreads out from the island as it opens.
private val RingSpread = 22.dp

// Whether the window is wide enough for the wide island of the reader and the player.
@Composable
fun isWideWindow(): Boolean = with(LocalDensity.current) {
    LocalWindowInfo.current.containerSize.width
        .toDp()
} >= WideFrom

// The body of an island in the colors of the theme, as solid as the person chose, with a ring of ink that spreads out from it once each time it opens.
@Composable
fun IslandSurface(
    open: Boolean,
    shade: Float,
    modifier: Modifier = Modifier,
    corner: Dp = IslandCorner,
    solid: Boolean = false,
    content: @Composable () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    Surface(
        modifier.inkRing(open, LocalReduceMotion.current, colors.primary, corner).keepTaps(),
        shape = RoundedCornerShape(corner),
        color = colors.surfaceContainerHigh.copy(alpha = if (solid) 1f else shade),
        border = BorderStroke(1.dp, colors.outlineVariant.copy(alpha = 0.5f)),
        content = content,
    )
}

// A panel inside the island on a phone, on the side away from the edge the island sits on, so the island grows into the screen and its buttons stay under the finger.
@Composable
fun <T> IslandInside(shown: T, none: T, bottom: Boolean, panelMax: Dp, content: @Composable (T) -> Unit) {
    val reduce = LocalReduceMotion.current
    AnimatedContent(shown, transitionSpec = { panelChange(reduce, none) }, label = "island panel") { now ->
        if (now != none) {
            Column {
                if (!bottom) DockRule()
                Box(Modifier.heightIn(max = panelMax)) { content(now) }
                if (bottom) DockRule()
            }
        }
    }
}

// On a wide window a panel hangs from the end of the island, above it at the bottom and under it at the top, so the island keeps its shape.
@Composable
fun <T> ColumnScope.IslandHang(shown: T, none: T, bottom: Boolean, panelMax: Dp, content: @Composable (T) -> Unit) {
    val reduce = LocalReduceMotion.current
    val colors = MaterialTheme.colorScheme
    AnimatedVisibility(
        shown != none,
        Modifier.align(Alignment.End),
        enter = if (reduce) {
            fadeIn(tween(150))
        } else {
            fadeIn(tween(180)) + slideInVertically(spring(0.8f, 420f)) { if (bottom) it / 5 else -it / 5 }
        },
        exit = fadeOut(tween(120)),
    ) {
        Surface(
            Modifier
                .padding(
                    top = if (bottom) 0.dp else 8.dp,
                    bottom = if (bottom) 8.dp else 0.dp,
                ).width(HangWidth)
                .keepTaps(),
            shape = RoundedCornerShape(24.dp),
            color = colors.surfaceContainerHigh,
            border = BorderStroke(1.dp, colors.outlineVariant.copy(alpha = 0.5f)),
        ) {
            AnimatedContent(shown, transitionSpec = { panelChange(reduce, none) }, label = "hanging panel") { now ->
                if (now != none) {
                    Box(Modifier.heightIn(max = panelMax).padding(horizontal = 8.dp, vertical = 6.dp)) { content(now) }
                }
            }
        }
    }
}

// How a small pill turns into the island and back: the size moves on a spring with a small bounce while the pill fades out and the island fades in just after, so it reads as the same thing swelling.
fun AnimatedContentTransitionScope<Boolean>.islandMorph(reduce: Boolean): ContentTransform {
    val size = SizeTransform(clip = true) { _, _ ->
        if (reduce) tween<IntSize>(150) else spring(dampingRatio = 0.72f, stiffness = 380f)
    }
    val enter = fadeIn(tween(if (reduce) 150 else 200, delayMillis = if (reduce) 0 else 90))
    return (enter togetherWith fadeOut(tween(80))) using size
}

// A row of the open island slides into place a little after the one before it, from the edge of the screen the island sits on.
@Composable
fun Modifier.cascade(index: Int, reduce: Boolean, fromBelow: Boolean): Modifier {
    val rise = remember { Animatable(if (reduce) 1f else 0f) }
    LaunchedEffect(Unit) {
        if (reduce) return@LaunchedEffect
        delay(70L + index * 55L)
        rise.animateTo(1f, spring(dampingRatio = 0.8f, stiffness = 300f))
    }
    return graphicsLayer {
        alpha = rise.value.coerceIn(0f, 1f)
        translationY = (1f - rise.value) * (if (fromBelow) 10.dp else -10.dp).toPx()
    }
}

// A thin ring of ink that spreads out from the edge of the island and fades once each time it opens.
@Composable
private fun Modifier.inkRing(open: Boolean, reduce: Boolean, color: Color, corner: Dp): Modifier {
    val ring = remember { Animatable(1f) }
    LaunchedEffect(open) {
        if (!open || reduce) return@LaunchedEffect
        ring.snapTo(0f)
        ring.animateTo(1f, tween(640, easing = LinearOutSlowInEasing))
    }
    return drawBehind {
        val done = ring.value
        if (done >= 1f) return@drawBehind
        val spread = RingSpread.toPx() * done
        drawRoundRect(
            color.copy(alpha = 0.5f * (1f - done)),
            Offset(-spread, -spread),
            Size(size.width + spread * 2, size.height + spread * 2),
            CornerRadius(corner.toPx() + spread),
            style = Stroke((2.5f * (1f - done) + 0.5f) * density),
        )
    }
}
