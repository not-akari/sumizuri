package com.sumizuri.app.ui.motion

import androidx.compose.animation.ContentTransform
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Easing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.GraphicsLayerScope
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.page_motion_fade
import com.sumizuri.app.shared.resources.page_motion_none
import com.sumizuri.app.shared.resources.page_motion_slide
import com.sumizuri.app.shared.resources.page_motion_smooth
import com.sumizuri.app.shared.resources.page_motion_zoom
import org.jetbrains.compose.resources.StringResource

// The ways one page gives way to another, which the person picks on the Interface page. The tabs and the pages beside the settings move the same way.
enum class PageMotion(val label: StringResource, private val baseMs: Int) {
    // Calm: the new page fades in as it glides a short way and settles from a little bigger, while the old one fades out first, so the two never show through each other.
    Smooth(Res.string.page_motion_smooth, 300),

    // The new page is pushed in whole from the edge over the one it covers, which drifts aside.
    Slide(Res.string.page_motion_slide, 360),

    // The new page grows into place as the old one swells and fades.
    Zoom(Res.string.page_motion_zoom, 320),

    // The old page fades out, then the new one fades in.
    Fade(Res.string.page_motion_fade, 260),
    None(Res.string.page_motion_none, 0),
    ;

    // How long a change of page takes, after the speed of the theme, and none when the person asked for less motion.
    @Composable
    fun pageMs(): Int = if (this == None) 0 else motionMs(baseMs)
}

// The motion the person chose, for the parts of the app that move between pages.
val LocalPageMotion = staticCompositionLocalOf { PageMotion.Smooth }

// Whether the page this is in is being closed, so its parts can go back where they came from as it slides away.
val LocalPageLeaving = compositionLocalOf { false }

// Whether the parts of a page rise in one after the other as it opens, which the person can turn on.
val LocalStagger = staticCompositionLocalOf { false }

// The curves of the movements: a quick start that settles gently for what comes in, and a slow start that leaves quickly for what goes.
private val ComeIn = CubicBezierEasing(0.05f, 0.7f, 0.1f, 1f)
private val GoOut = CubicBezierEasing(0.3f, 0f, 0.8f, 0.15f)

// How much of the change of page the fade of the page that opens lasts, and how much bigger it starts before it settles, for the calm reveal.
private const val CalmFade = 0.6f
private const val CalmScale = 1.015f

// How far a page travels in the styles that only nudge it.
private val Nudge = 24.dp

// How far a page travels between two tabs, as they are side by side.
private val TabNudge = 24.dp

// The distances of a nudge in pixels, read once where the transition is made.
class MotionShift(val page: Int, val tab: Int)

@Composable
fun rememberMotionShift(): MotionShift = with(LocalDensity.current) {
    MotionShift(Nudge.roundToPx(), TabNudge.roundToPx())
}

private fun <T> timed(ms: Int, from: Float = 0f, to: Float = 1f, easing: Easing = ComeIn) = tween<T>(
    durationMillis = (
        (
            to -
                from
            ) *
            ms
        ).toInt().coerceAtLeast(1),
    delayMillis = (from * ms).toInt(),
    easing = easing,
)

// One page giving way to the next. Forward is a page opening over the one before, and back is the top page closing.
fun pageTransform(style: PageMotion, ms: Int, forward: Boolean, shift: MotionShift): ContentTransform {
    if (ms == 0) return EnterTransition.None togetherWith ExitTransition.None
    val sign = if (forward) 1 else -1
    return when (style) {
        // A calm reveal: the page that comes fades in over most of the change as it glides a short way and settles from a little bigger, and the one it covers fades out quickly as it drifts aside.
        PageMotion.Smooth ->
            (
                slideInHorizontally(timed<IntOffset>(ms)) { sign * shift.page } +
                    fadeIn(timed(ms, 0f, CalmFade)) +
                    scaleIn(timed(ms), initialScale = CalmScale)
                ) togetherWith
                (
                    slideOutHorizontally(timed<IntOffset>(ms)) { -sign * shift.page / 2 } +
                        fadeOut(timed(ms, 0f, 0.35f, GoOut))
                    )

        PageMotion.Slide ->
            if (forward) {
                slideInHorizontally(timed<IntOffset>(ms)) { it } togetherWith
                    slideOutHorizontally(timed<IntOffset>(ms)) { -it * 3 / 10 }
            } // The page that closes stays on top as it slides away, uncovering the one under it.
            else {
                (
                    slideInHorizontally(timed<IntOffset>(ms)) { -it * 3 / 10 } togetherWith
                        slideOutHorizontally(timed<IntOffset>(ms)) { it }
                    ).apply { targetContentZIndex = -1f }
            }

        PageMotion.Zoom ->
            if (forward) {
                (scaleIn(timed(ms), initialScale = 0.9f) + fadeIn(timed(ms, 0.25f, 1f))) togetherWith
                    (scaleOut(timed(ms), targetScale = 1.06f) + fadeOut(timed(ms, 0f, 0.3f, GoOut)))
            } else {
                // The page that closes shrinks away on top of the one coming back.
                (
                    (scaleIn(timed(ms), initialScale = 1.06f) + fadeIn(timed(ms, 0.25f, 1f))) togetherWith
                        (scaleOut(timed(ms), targetScale = 0.9f) + fadeOut(timed(ms, 0f, 0.3f, GoOut)))
                    ).apply {
                    targetContentZIndex =
                        -1f
                }
            }

        PageMotion.Fade ->
            (fadeIn(timed(ms, 0.35f, 1f)) + scaleIn(timed(ms, 0.35f, 1f), initialScale = 0.97f)) togetherWith
                fadeOut(timed(ms, 0f, 0.35f, GoOut))

        PageMotion.None -> EnterTransition.None togetherWith ExitTransition.None
    }
}

private fun part(t: Float, from: Float, to: Float): Float = ((t - from) / (to - from)).coerceIn(0f, 1f)

// A tab coming in or going out, moved by hand the same way the change of tabs above moves it, for tabs that stay composed. The time is how far the change has gone, from 0 to 1.
fun GraphicsLayerScope.tabMotion(
    style: PageMotion,
    time: Float,
    leaving: Boolean,
    toRight: Boolean,
    shift: MotionShift,
) {
    val sign = if (toRight) 1 else -1
    val far = (if (style == PageMotion.Slide) shift.tab * 3 else shift.tab).toFloat()
    val moved = ComeIn.transform(time)
    when (style) {
        PageMotion.Smooth -> if (leaving) {
            alpha = 1f - GoOut.transform(part(time, 0f, 0.35f))
            translationX = -sign * far / 2f * moved
        } else {
            alpha = ComeIn.transform(part(time, 0f, CalmFade))
            translationX = sign * far * (1f - moved)
            scaleX = CalmScale + (1f - CalmScale) * moved
            scaleY = scaleX
        }

        PageMotion.Slide -> if (leaving) {
            alpha = 1f - GoOut.transform(part(time, 0f, 0.3f))
            translationX = -sign * far * moved
        } else {
            alpha = ComeIn.transform(part(time, 0.3f, 1f))
            translationX = sign * far * (1f - moved)
        }

        PageMotion.Zoom -> if (leaving) {
            alpha = 1f - GoOut.transform(part(time, 0f, 0.3f))
        } else {
            val shown = ComeIn.transform(part(time, 0.3f, 1f))
            alpha = shown
            scaleX = 0.96f + 0.04f * shown
            scaleY = scaleX
        }

        PageMotion.Fade ->
            alpha =
                if (leaving) 1f - GoOut.transform(part(time, 0f, 0.35f)) else ComeIn.transform(part(time, 0.35f, 1f))

        PageMotion.None -> Unit
    }
}

// The page under a page that opens or closes, moved by hand the same way a page that gives way moves, for a layer that stays composed. The time is how far the change has gone, from 0 to 1, and leaving is true while the page on top comes in.
fun GraphicsLayerScope.underMotion(style: PageMotion, time: Float, leaving: Boolean, shift: MotionShift) {
    val moved = ComeIn.transform(time)
    when (style) {
        PageMotion.Smooth -> if (leaving) {
            alpha = 1f - GoOut.transform(part(time, 0f, 0.35f))
            translationX = -shift.page / 2f * moved
        } else {
            alpha = ComeIn.transform(part(time, 0f, CalmFade))
            translationX = -shift.page * (1f - moved)
            scaleX = CalmScale + (1f - CalmScale) * moved
            scaleY = scaleX
        }

        PageMotion.Slide -> translationX = -size.width * 0.3f * (if (leaving) moved else 1f - moved)

        PageMotion.Zoom -> {
            val scale = if (leaving) 1f + 0.06f * moved else 1.06f - 0.06f * moved
            scaleX = scale
            scaleY = scale
            alpha = if (leaving) 1f - GoOut.transform(part(time, 0f, 0.3f)) else ComeIn.transform(part(time, 0.25f, 1f))
        }

        PageMotion.Fade -> {
            val shown = if (leaving) {
                1f - GoOut.transform(
                    part(time, 0f, 0.35f),
                )
            } else {
                ComeIn.transform(part(time, 0.35f, 1f))
            }
            alpha = shown
            if (!leaving) {
                scaleX = 0.97f + 0.03f * shown
                scaleY = scaleX
            }
        }

        PageMotion.None -> Unit
    }
}
