package com.sumizuri.app.core.perf

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.pointerInput
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first

// A frame that takes longer than this is slow, about two frames at 60 a second.
private const val SlowFrameMs = 33f

// How often the numbers are passed on, so showing them does not itself cost a frame each time.
private const val ReportEveryMs = 500L

// The frames are counted for this long after the last touch, move of the mouse or scroll, and the meter rests after it.
private const val ActiveForMs = 2_000L

// The frames drawn while the meter is on: how many a second, how long they took on average, the slowest, and how many were slow since it began. Idle says the meter is resting while nothing is used.
data class FrameStats(
    val fps: Float = 0f,
    val averageMs: Float = 0f,
    val worstMs: Float = 0f,
    val slow: Int = 0,
    val total: Int = 0,
    val idle: Boolean = true,
)

// When the app was last used, which the root of the app passes on for every touch, move of the mouse and scroll, and when it was last acted on, by a press or a scroll, which a move of the mouse alone is not.
object FrameActivity {
    internal val last = MutableStateFlow(0L)
    internal val lastAction = MutableStateFlow(0L)

    fun poke(action: Boolean = true) {
        val now = nowMillis()
        last.value = now
        if (action) lastAction.value = now
    }
}

// Counts the frames while the app is in use. Waiting for a frame asks for the next one, so a meter that counted all the time would keep the whole window drawing on every frame of the screen. It counts only from a use of the app until a moment after the last one, and rests between, when the app draws nothing of its own anyway.
@Composable
fun rememberFrameStats(): State<FrameStats> {
    val stats = remember { mutableStateOf(FrameStats()) }
    LaunchedEffect(Unit) {
        var slow = 0
        var total = 0
        var worst = 0f
        try {
            while (true) {
                FrameActivity.last.first { nowMillis() - it < ActiveForMs }
                var last = withFrameNanos { it }
                var windowStart = last
                var frames = 0
                var sumMs = 0f
                // The slowest frame of each report, for the watch, which judges a drop by the frames of that moment and not of the whole time.
                var worstNow = 0f
                while (nowMillis() - FrameActivity.last.value < ActiveForMs) {
                    val now = withFrameNanos { it }
                    val ms = (now - last) / 1_000_000f
                    last = now
                    frames++
                    total++
                    sumMs += ms
                    if (ms > worst) worst = ms
                    if (ms > worstNow) worstNow = ms
                    if (ms > SlowFrameMs) slow++
                    PerfWatch.slowFrame(ms)
                    val windowMs = (now - windowStart) / 1_000_000f
                    if (windowMs >= ReportEveryMs) {
                        stats.value =
                            FrameStats(frames * 1000f / windowMs, sumMs / frames, worst, slow, total, idle = false)
                        PerfWatch.frames(
                            FrameStats(frames * 1000f / windowMs, sumMs / frames, worstNow, slow, total, idle = false),
                        )
                        windowStart = now
                        frames = 0
                        sumMs = 0f
                        worstNow = 0f
                    }
                }
                stats.value = stats.value.copy(idle = true)
                PerfWatch.framesStopped()
            }
        } finally {
            PerfWatch.framesStopped()
        }
    }
    return stats
}

// Tells the frame meter the app is in use on every touch, move of the mouse and scroll anywhere under this piece. It only looks at the events and leaves them to the pieces they are for.
fun Modifier.reportActivity(): Modifier = pointerInput(Unit) {
    awaitPointerEventScope {
        while (true) {
            val event = awaitPointerEvent(PointerEventPass.Initial)
            FrameActivity.poke(
                event.type != PointerEventType.Move && event.type != PointerEventType.Enter &&
                    event.type != PointerEventType.Exit,
            )
        }
    }
}
