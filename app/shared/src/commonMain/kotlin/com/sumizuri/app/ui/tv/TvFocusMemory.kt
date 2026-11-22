package com.sumizuri.app.ui.tv

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged

// How many of the last places of the focus are kept.
private const val Kept = 16

// The last places the focus of a TV was on, newest last, so when the focus is lost, such as when a page or a panel closes, it goes back to the newest one still on the screen.
object TvFocusMemory {
    private val recent = ArrayDeque<FocusRequester>()

    internal fun noted(place: FocusRequester) {
        recent.remove(place)
        recent.addLast(place)
        while (recent.size > Kept) recent.removeFirst()
    }

    internal fun gone(place: FocusRequester) {
        recent.remove(place)
    }

    // Gives the focus back to the newest place that can still take it, and says whether one could.
    fun restore(): Boolean {
        for (place in recent.reversed()) {
            if (runCatching { place.requestFocus() }.getOrDefault(false)) return true
        }
        return false
    }
}

// Notes this place each time it gets the focus, and forgets it once it leaves the screen.
@Composable
internal fun Modifier.rememberedFocus(): Modifier {
    val place = remember { FocusRequester() }
    DisposableEffect(place) { onDispose { TvFocusMemory.gone(place) } }
    return focusRequester(place).onFocusChanged { if (it.isFocused) TvFocusMemory.noted(place) }
}
