package com.sumizuri.app.ui.kit.art

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

// Lets a piece of a page rise a little and fade in when the page opens, after the pieces before it.
@Composable
internal fun Modifier.rise(order: Int): Modifier {
    val progress = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(60L * order)
        progress.animateTo(1f, tween(460, easing = FastOutSlowInEasing))
    }
    return graphicsLayer {
        alpha = progress.value
        translationY = (1f - progress.value) * 16.dp.toPx()
    }
}

// The icon, springing in when the setup opens, with a ring of light turning round it and a glow that breathes.
@Composable
internal fun AnimatedLogo(size: Dp, modifier: Modifier = Modifier) {
    val appear = remember { Animatable(0f) }
    LaunchedEffect(Unit) { appear.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = 110f)) }
    val transition = rememberInfiniteTransition(label = "logo")
    val spin by transition.animateFloat(
        0f,
        360f,
        infiniteRepeatable(tween(8_000, easing = LinearEasing)),
        label = "spin",
    )
    val breathe by transition.animateFloat(
        0.6f,
        1f,
        infiniteRepeatable(tween(2_400, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "breathe",
    )
    val ring = MaterialTheme.colorScheme.primary
    Box(
        modifier.size(size * 1.4f).graphicsLayer {
            val scale = 0.6f + 0.4f * appear.value
            scaleX = scale
            scaleY = scale
            alpha = appear.value.coerceIn(0f, 1f)
        },
        contentAlignment = Alignment.Center,
    ) {
        Canvas(Modifier.fillMaxSize()) {
            drawCircle(
                Brush.radialGradient(listOf(ring.copy(alpha = 0.22f * breathe), Color.Transparent)),
                radius =
                this.size.minDimension / 2,
            )
            val stroke = 2.5.dp.toPx()
            rotate(spin) {
                drawArc(
                    Brush.sweepGradient(listOf(ring.copy(alpha = 0f), ring.copy(alpha = 0.9f), ring.copy(alpha = 0f))),
                    0f,
                    330f * appear.value.coerceIn(0f, 1f),
                    false,
                    topLeft = Offset(stroke, stroke),
                    size = Size(this.size.width - stroke * 2, this.size.height - stroke * 2),
                    style = Stroke(stroke, cap = StrokeCap.Round),
                )
            }
        }
        Image(AppIconArt, null, Modifier.size(size))
    }
}

// How far along the install is, as a ring that fills in the colors of the theme, with a bright spot running round it while the work goes on.
@Composable
internal fun ProgressRing(progress: Float, modifier: Modifier = Modifier, running: Boolean = true) {
    val shown by animateFloatAsState(progress, tween(600, easing = FastOutSlowInEasing), label = "progress")
    val transition = rememberInfiniteTransition(label = "ring")
    val shine by transition.animateFloat(
        0f,
        360f,
        infiniteRepeatable(tween(1_500, easing = LinearEasing)),
        label = "shine",
    )
    val colors = MaterialTheme.colorScheme
    Canvas(modifier) {
        val stroke = 10.dp.toPx()
        val topLeft = Offset(stroke / 2, stroke / 2)
        val arc = Size(size.width - stroke, size.height - stroke)
        drawArc(colors.surfaceVariant.copy(alpha = 0.7f), 0f, 360f, false, topLeft, arc, style = Stroke(stroke))
        if (shown > 0.001f) {
            drawArc(
                Brush.sweepGradient(listOf(colors.tertiary, colors.primary, colors.tertiary)),
                -90f,
                360f * shown,
                false,
                topLeft,
                arc,
                style = Stroke(stroke, cap = StrokeCap.Round),
            )
        }
        if (running) {
            rotate(shine) {
                drawArc(
                    colors.primary.copy(alpha = 0.45f),
                    -90f,
                    26f,
                    false,
                    topLeft,
                    arc,
                    style = Stroke(stroke * 0.45f, cap = StrokeCap.Round),
                )
            }
        }
    }
}

// A ring that draws itself, then a tick inside it, then a burst of ink drops flying out and fading.
@Composable
internal fun DrawnCheck(modifier: Modifier = Modifier, color: Color = MaterialTheme.colorScheme.primary) {
    val circle = remember { Animatable(0f) }
    val tick = remember { Animatable(0f) }
    val burst = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(150)
        circle.animateTo(1f, tween(520, easing = FastOutSlowInEasing))
        tick.animateTo(1f, tween(360, easing = FastOutSlowInEasing))
        burst.animateTo(1f, tween(700, easing = FastOutSlowInEasing))
    }
    Canvas(modifier) {
        val stroke = 6.dp.toPx()
        val inner = size.minDimension * 0.7f
        val corner = Offset((size.width - inner) / 2, (size.height - inner) / 2)
        drawArc(
            color,
            -90f,
            360f * circle.value,
            false,
            corner + Offset(stroke / 2, stroke / 2),
            Size(
                inner - stroke,
                inner - stroke,
            ),
            style = Stroke(stroke, cap = StrokeCap.Round),
        )
        if (tick.value > 0f) {
            val path = Path().apply {
                moveTo(corner.x + inner * 0.28f, corner.y + inner * 0.52f)
                lineTo(corner.x + inner * 0.44f, corner.y + inner * 0.67f)
                lineTo(corner.x + inner * 0.73f, corner.y + inner * 0.36f)
            }
            val measure = PathMeasure().apply { setPath(path, false) }
            val part = Path()
            measure.getSegment(0f, measure.length * tick.value, part, true)
            drawPath(part, color, style = Stroke(stroke, cap = StrokeCap.Round, join = StrokeJoin.Round))
        }
        if (burst.value > 0f && burst.value < 1f) {
            val center = Offset(size.width / 2, size.height / 2)
            for (i in 0 until 12) {
                val angle = i * (2 * PI / 12).toFloat() + 0.3f
                val reach = inner / 2 + (size.minDimension / 2 - inner / 2) * burst.value
                drawCircle(
                    color.copy(alpha = 1f - burst.value),
                    radius =
                    (
                        if (i % 2 ==
                            0
                        ) {
                            4.dp
                        } else {
                            2.5.dp
                        }
                        ).toPx() * (1f - burst.value * 0.5f),
                    center =
                    center + Offset(cos(angle) * reach, sin(angle) * reach),
                )
            }
        }
    }
}
