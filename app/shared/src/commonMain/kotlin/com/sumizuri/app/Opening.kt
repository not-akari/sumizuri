package com.sumizuri.app

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.opening_fade
import com.sumizuri.app.shared.resources.opening_handoff
import com.sumizuri.app.shared.resources.opening_off
import com.sumizuri.app.ui.kit.art.AppIconArt
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.theme.LocalReduceMotion
import com.sumizuri.app.ui.tv.LocalTv
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.map
import org.jetbrains.compose.resources.StringResource
import kotlin.math.PI
import kotlin.math.cos

// How the app opens: the logo of the splash closes its ring and gives way to the first screen, a plain fade, or nothing at all.
internal enum class OpeningStyle(val key: String, val label: StringResource) {
    Handoff("handoff", Res.string.opening_handoff),
    Fade("fade", Res.string.opening_fade),
    Off("off", Res.string.opening_off),
    ;

    companion object {
        fun of(key: String?): OpeningStyle = entries.firstOrNull { it.key == key } ?: Handoff
    }
}

// The lengths of the opening: the ring closing, the cover leaving, and the plain fade.
private const val RingMs = 320
private const val LeaveMs = 440
private const val FadeMs = 220

// The ink of a TV opening spreading behind the logo, and its fade into the first screen.
private const val InkMs = 460
private const val InkLeaveMs = 260

// A start that takes longer than this shows a small moving bar under the name, so a slow first load never looks stuck.
private const val SlowMs = 600L

// Where the opening is. It plays once for each start of the app, so turning a phone or a new language does not play it again.
internal class OpeningState(private val chosen: State<OpeningStyle?>, val tv: Boolean) {
    val ring = Animatable(0f)

    // How far the ink of a TV opening has spread, from 0 to 1.
    val ink = Animatable(0f)
    val leave = Animatable(0f)
    var done by mutableStateOf(AppStart.opened)

    // The style in use, or null until the setting is read.
    val style: OpeningStyle? get() = chosen.value

    // The height of the bar of a desktop window in pixels, which the cover leaves free so the window can still be moved and closed.
    var barHeight by mutableIntStateOf(0)

    fun finish() {
        AppStart.opened = true
        done = true
    }
}

// Reads the style the person chose and plays the opening once the first screen is ready. Less motion means no opening.
@Composable
internal fun rememberOpening(ready: Boolean): OpeningState {
    val container = LocalAppContainer.current
    val saved by remember(container) { container.settings.text(SettingKey.Opening).map { OpeningStyle.of(it) } }
        .collectAsStateWithLifecycle(null)
    val chosen = rememberUpdatedState(if (LocalReduceMotion.current) OpeningStyle.Off else saved)
    val tv = LocalTv.current
    val state = remember { OpeningState(chosen, tv) }
    val style = chosen.value
    // A TV starts its ink at once, so the logo is drawn in while the first screen loads.
    LaunchedEffect(style) {
        if (tv && !state.done && style != null &&
            style != OpeningStyle.Off
        ) {
            state.ink.animateTo(1f, tween(InkMs, easing = FastOutSlowInEasing))
        }
    }
    LaunchedEffect(ready, style) {
        if (state.done || !ready || style == null) return@LaunchedEffect
        when {
            style == OpeningStyle.Off -> Unit

            // A TV keeps it short: the ink finishes, then the cover fades into the first screen.
            tv -> {
                state.ink.animateTo(1f, tween(((1f - state.ink.value) * InkMs).toInt(), easing = FastOutSlowInEasing))
                state.leave.animateTo(1f, tween(InkLeaveMs))
            }

            style == OpeningStyle.Handoff -> {
                state.ring.animateTo(1f, tween(RingMs, easing = FastOutSlowInEasing))
                state.leave.animateTo(1f, tween(LeaveMs, easing = AppMotion.Entrance))
            }

            else -> state.leave.animateTo(1f, tween(FadeMs))
        }
        state.finish()
    }
    return state
}

// The first screen rises a little into place as the logo gives way to it.
internal fun Modifier.openingRise(state: OpeningState): Modifier = graphicsLayer {
    if (state.done || state.tv || state.style != OpeningStyle.Handoff) return@graphicsLayer
    val left = 1f - state.leave.value
    translationY = left * 24.dp.toPx()
    scaleX = 1f - left * 0.02f
    scaleY = scaleX
}

// The cover over the app while it opens: the page color with the logo and name in the middle, as the splash had them, and a moving bar when the start is slow. It sits under the bar of a desktop window, which stays usable.
@Composable
internal fun OpeningCover(state: OpeningState, ready: Boolean) {
    if (state.done) return
    val style = state.style
    if (style == OpeningStyle.Off) return
    var slow by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(SlowMs)
        slow = true
    }
    BoxWithConstraints(
        Modifier
            .fillMaxSize()
            .padding(top = with(LocalDensity.current) { state.barHeight.toDp() })
            .graphicsLayer { alpha = 1f - state.leave.value }
            .background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center,
    ) {
        if (state.tv && style != null) {
            TvInk(state)
            return@BoxWithConstraints
        }
        // Until the style is read only the page shows, so a person who turned the opening off never sees the logo flash.
        if (style != OpeningStyle.Handoff) return@BoxWithConstraints
        // A phone shows a bigger logo, closer to the one on its own splash screen.
        val logo = if (maxWidth < 600.dp) 96.dp else 80.dp
        Column(
            Modifier.graphicsLayer {
                val shrink = 1f - 0.25f * state.leave.value
                scaleX = shrink
                scaleY = shrink
            },
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(Modifier.size(logo * 1.4f), contentAlignment = Alignment.Center) {
                ClosingRing(state)
                Image(AppIconArt, null, Modifier.size(logo))
            }
            Spacer(Modifier.height(10.dp))
            Text(
                "Sumizuri",
                Modifier.graphicsLayer { alpha = 1f - state.leave.value * 2f },
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onBackground,
            )
            Box(Modifier.height(28.dp), contentAlignment = Alignment.Center) {
                androidx.compose.animation.AnimatedVisibility(
                    slow && !ready,
                    enter = fadeIn(tween(AppMotion.Medium)),
                    exit = fadeOut(tween(AppMotion.Fast)),
                ) {
                    LoadingBar()
                }
            }
        }
    }
}

// The opening of a TV: a pool of the accent spreads from the middle and the logo is drawn in inside it, then the name comes under it. Nothing grows or shrinks.
@Composable
private fun TvInk(state: OpeningState) {
    val color = MaterialTheme.colorScheme.primary
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier.size(TvLogo * 2.2f).drawBehind {
                val spread = state.ink.value
                if (spread > 0f) drawCircle(color.copy(alpha = 0.16f * spread), radius = size.minDimension / 2 * spread)
            },
            contentAlignment = Alignment.Center,
        ) {
            Image(
                AppIconArt,
                null,
                Modifier.size(TvLogo).drawWithContent {
                    val shown = (state.ink.value * 1.4f).coerceAtMost(1f)
                    clipPath(
                        Path().apply {
                            addOval(Rect(center, size.maxDimension * 0.75f * shown))
                        },
                    ) { this@drawWithContent.drawContent() }
                },
            )
        }
        Text(
            "Sumizuri",
            Modifier.graphicsLayer { alpha = ((state.ink.value - 0.5f) * 2f).coerceIn(0f, 1f) },
            fontSize = 30.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onBackground,
        )
    }
}

// How big the logo of a TV opening is.
private val TvLogo = 104.dp

// A ring of the accent round the logo that closes from the top, for the moment the app is ready.
@Composable
private fun ClosingRing(state: OpeningState) {
    val color = MaterialTheme.colorScheme.primary
    Canvas(Modifier.fillMaxSize()) {
        val sweep = 360f * state.ring.value
        if (sweep <= 0f) return@Canvas
        val stroke = 2.5.dp.toPx()
        drawArc(
            color,
            -90f,
            sweep,
            false,
            topLeft = Offset(stroke, stroke),
            size = Size(size.width - stroke * 2, size.height - stroke * 2),
            style = Stroke(stroke, cap = StrokeCap.Round),
        )
    }
}

// A short bar that eases from one end of its line to the other and back, as the desktop splash does.
@Composable
private fun LoadingBar() {
    val colors = MaterialTheme.colorScheme
    val time by rememberInfiniteTransition(label = "loading").animateFloat(
        0f,
        1f,
        infiniteRepeatable(tween(2_800, easing = LinearEasing)),
        label = "pass",
    )
    Canvas(Modifier.width(72.dp).height(4.dp)) {
        val stroke = size.height
        val bar = size.width * 0.3f
        drawLine(
            colors.outlineVariant,
            Offset(stroke / 2, size.height / 2),
            Offset(
                size.width - stroke / 2,
                size.height / 2,
            ),
            stroke,
            StrokeCap.Round,
        )
        val eased = ((1 - cos(time * 2 * PI)) / 2).toFloat()
        val left = stroke / 2 + (size.width - stroke - bar) * eased
        drawLine(
            colors.primary,
            Offset(left, size.height / 2),
            Offset(left + bar, size.height / 2),
            stroke,
            StrokeCap.Round,
        )
    }
}
