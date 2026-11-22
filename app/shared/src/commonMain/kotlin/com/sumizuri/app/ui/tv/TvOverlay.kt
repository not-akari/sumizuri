package com.sumizuri.app.ui.tv

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import kotlinx.coroutines.delay

// Something that opens over a page of a TV. It paints no background of its own, so the one behind the whole app runs on unbroken past the rail, and the page under it is faded out instead with hiddenUnder. It takes no touches for the page under it, and the remote cannot leave it.
@Composable
fun TvOverlay(modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    Box(
        modifier
            .fillMaxSize()
            .pointerInput(Unit) { awaitPointerEventScope { while (true) awaitPointerEvent() } }
            .keepsFocus(),
        content = content,
    )
}

// Fades a page out while something is open over it, and back in when that closes.
@Composable
fun Modifier.hiddenUnder(covered: Boolean): Modifier {
    val shown by animateFloatAsState(if (covered) 0f else 1f, tween(motionMs(AppMotion.Fast)), label = "hidden")
    return graphicsLayer { alpha = shown }
}

// How often a part that keeps the focus checks it still has it.
private const val KeepCheckMs = 300L

// Keeps the focus of the remote inside this part while it shows: the arrows cannot take it out, and when anything else takes it, such as a page under it asking for it as it loads, it is brought back to the first place in this part.
@Composable
fun Modifier.keepsFocus(): Modifier {
    val keeper = remember { FocusRequester() }
    var inside by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(KeepCheckMs)
            if (!inside) runCatching { keeper.requestFocus() }
        }
    }
    return onFocusChanged { inside = it.hasFocus }
        .focusRequester(keeper)
        .focusProperties { onExit = { cancelFocusChange() } }
        .focusGroup()
}
