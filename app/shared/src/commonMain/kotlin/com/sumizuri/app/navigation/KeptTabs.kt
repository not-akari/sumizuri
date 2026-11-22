package com.sumizuri.app.navigation

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.zIndex
import com.sumizuri.app.AppStart
import com.sumizuri.app.core.perf.FrameActivity
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.ui.motion.MotionShift
import com.sumizuri.app.ui.motion.PageMotion
import com.sumizuri.app.ui.motion.tabMotion
import com.sumizuri.app.ui.tv.LocalTv
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first

// Whether the tab this is in is the one showing, so a kept tab that is out of sight leaves the search shortcut, the bottom bar and Back to the one in sight.
val LocalTabShown = compositionLocalOf { true }

// How long after the first screen has drawn the tabs not opened yet are made, once the opening is over, and how long the app must be left alone before each one, so making them never gets in the way. Each new tab is also laid out and drawn out of sight for a moment, so its first visit runs code that is already warm.
private const val PrepareAfterMs = 1_200L
private const val QuietMs = 800L
private const val GapMs = 300L
private const val WarmMs = 250L

// The tabs of the app. Each is made once and kept, out of sight and untouchable while another shows, so going back to a tab is only a matter of showing it. The tabs not opened yet are made one at a time once the app has been left alone for a moment after the start, so even the first visit is quick. A change of tab moves the two tabs by hand in the style the person chose.
@Composable
internal fun KeptTabs(
    tab: Destination,
    tabs: List<Destination>,
    style: PageMotion,
    ms: Int,
    shift: MotionShift,
    content: @Composable (Destination) -> Unit,
) {
    // A TV builds only the tab in sight, since hidden tabs still hold places the remote could move to.
    if (LocalTv.current) {
        Box(Modifier.fillMaxSize()) { key(tab) { content(tab) } }
        return
    }
    val made = remember { mutableStateListOf(tab) }
    if (tab !in made) made += tab
    var shown by remember { mutableStateOf(tab) }
    var warming by remember { mutableStateOf<Destination?>(null) }
    val warmed = remember { mutableSetOf(tab) }
    LaunchedEffect(tabs) {
        AppStart.drawn.first { it }
        delay(PrepareAfterMs)
        for (next in tabs) {
            if (next in made) continue
            // A move of the mouse does not hold it back, only a press or a scroll.
            while (nowMillis() - FrameActivity.lastAction.value < QuietMs) delay(QuietMs)
            if (next in made) continue
            // Each tab gets a frame of its own to be made, then a few more to be laid out and drawn where no one sees or touches it.
            made += next
            delay(GapMs)
            if (next != shown) warming = next
            try {
                delay(WarmMs)
                warmed += next
            } finally {
                warming = null
            }
        }
    }
    var leaving by remember { mutableStateOf<Destination?>(null) }
    var toRight by remember { mutableStateOf(true) }
    val time = remember { Animatable(1f) }
    LaunchedEffect(tab) {
        if (tab == shown) return@LaunchedEffect
        // A tab never drawn yet is laid out and drawn out of sight for two frames first, so its slow first frames pass before anything moves.
        if (tab !in warmed) {
            warming = tab
            try {
                repeat(2) { withFrameNanos { } }
                warmed += tab
            } finally {
                warming = null
            }
        }
        toRight = tabs.indexOf(tab) > tabs.indexOf(shown)
        leaving = shown
        shown = tab
        val quick = ms * 3 / 4
        if (quick > 0) {
            time.snapTo(0f)
            time.animateTo(1f, tween(quick, easing = LinearEasing))
        }
        leaving = null
    }
    Box(Modifier.fillMaxSize()) {
        for (each in made) {
            key(each) {
                val inSight = each == shown
                val going = each == leaving
                CompositionLocalProvider(LocalTabShown provides inSight) {
                    Box(
                        Modifier
                            .fillMaxSize()
                            .zIndex(if (inSight) 1f else 0f)
                            .placedWhen(inSight || going, warm = each == warming)
                            .graphicsLayer {
                                if (leaving != null &&
                                    (inSight || going)
                                ) {
                                    tabMotion(style, time.value, going, toRight, shift)
                                }
                            },
                    ) { content(each) }
                }
            }
        }
    }
}

// Measures a tab always, so its lists are ready, but places it only while it is in sight, so a kept tab is neither drawn nor touched. A tab being warmed is placed outside the window, where it is laid out and drawn but never seen or touched.
private fun Modifier.placedWhen(placed: Boolean, warm: Boolean): Modifier = layout { measurable, constraints ->
    val content = measurable.measure(constraints)
    layout(content.width, content.height) {
        when {
            placed -> content.place(0, 0)
            warm -> content.place(-content.width * 2, 0)
        }
    }
}
