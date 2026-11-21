package com.sumizuri.app.ui.motion

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.ui.theme.LocalReduceMotion
import kotlinx.coroutines.delay

// How long a piece takes to rise in, as the steps of the first run of the app rise.
private const val RiseMs = 460

// How long one piece waits after the one before it, and how many pieces of a burst move at all.
private const val Step = 60
private const val Limit = 8

// A burst only begins after this long with nothing new on screen, which is when a page has just opened, never while a list is being scrolled.
private const val Quiet = 800L

// Only what shows up this soon after the burst began moves. Rows scrolled into view later are simply there.
private const val Window = 400L

// Hands out the wait of each piece that comes in, so what a page puts up when it opens arrives one after the other.
private object EntranceQueue {
    private var last = 0L
    private var start = 0L
    private var count = 0

    // The wait in milliseconds, or -1 when the piece should not move.
    fun claim(now: Long): Int {
        if (now - last > Quiet) {
            start = now
            count = 0
        }
        last = now
        return if (now - start > Window || count >= Limit) -1 else Step * count++
    }
}

// Lets a piece rise a little and fade in when a page opens, after the ones that came before it.
@Composable
fun Modifier.entrance(): Modifier {
    if (LocalReduceMotion.current || !LocalStagger.current) return this
    val ms = motionMs(RiseMs)
    val wait = remember { EntranceQueue.claim(nowMillis()) }
    // A piece that does not move gets no layer and no work at all.
    if (wait < 0) return this
    val progress = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(wait.toLong())
        progress.animateTo(1f, tween(ms, easing = AppMotion.Entrance))
    }
    val rise = with(LocalDensity.current) { 16.dp.toPx() }
    return graphicsLayer {
        alpha = progress.value
        translationY = (1f - progress.value) * rise
    }
}

// Shows what is given by letting it rise from the bottom edge with a fade, and lets it sink back when it goes. It is a function of its own so it can be used inside any layout.
@Composable
fun Rise(visible: Boolean, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val ms = motionMs(AppMotion.Fast)
    AnimatedVisibility(
        visible,
        modifier,
        enter = slideInVertically(tween(ms, easing = AppMotion.Entrance)) { it } + fadeIn(tween(ms)),
        exit = slideOutVertically(tween(ms, easing = AppMotion.Leave)) { it } + fadeOut(tween(ms)),
    ) { content() }
}

// Shows what is given by unfolding it downward with a fade, and folds it away when it goes, for the notes that come and go above a list.
@Composable
fun Unfold(visible: Boolean, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val ms = motionMs(AppMotion.Medium)
    AnimatedVisibility(
        visible,
        modifier,
        enter = fadeIn(tween(ms)) + expandVertically(tween(ms, easing = AppMotion.Entrance)),
        exit = fadeOut(tween(ms)) + shrinkVertically(tween(ms, easing = AppMotion.Leave)),
    ) { content() }
}
