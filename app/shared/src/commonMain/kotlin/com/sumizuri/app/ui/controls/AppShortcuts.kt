package com.sumizuri.app.ui.controls

import androidx.compose.foundation.focusable
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import com.sumizuri.app.data.model.controls.AppShortcut
import com.sumizuri.app.ui.tv.LocalTv
import com.sumizuri.app.ui.tv.TvFocusMemory
import kotlinx.coroutines.delay

// How long the focus may rest on nothing on a TV before it is moved into the page.
private const val TvRefocusMs = 400L

// The keys of a remote that move the focus or press what has it.
private val RemoteKeys = setOf(
    Key.DirectionUp,
    Key.DirectionDown,
    Key.DirectionLeft,
    Key.DirectionRight,
    Key.DirectionCenter,
    Key.Enter,
)

// Listens for the shortcut keys over everything under it, before the page under it hears them. The callback says whether it did the shortcut, and a key it did not use goes on to the page. On a TV it also keeps the focus from being lost: a touch or a click clears it, so it comes back here and moves into the page again after a moment, or at once with the next key of the remote.
@Composable
fun Modifier.appShortcuts(onShortcut: (AppShortcut) -> Boolean): Modifier {
    val focus = remember { FocusRequester() }
    val gestures by rememberUpdatedState(LocalAppGestures.current)
    val act by rememberUpdatedState(onShortcut)
    val tv = LocalTv.current
    val manager = LocalFocusManager.current
    // Whether this holds the focus itself, with nothing under it holding it.
    var holding by remember { mutableStateOf(false) }
    // Counts the times the focus left everything, to take it back each time.
    var lost by remember { mutableIntStateOf(0) }
    // Keys only reach a window that holds the focus somewhere, so this holds it until a page takes it.
    LaunchedEffect(lost) { runCatching { focus.requestFocus() } }
    // On a TV the focus goes back by itself once the screen has settled, such as after going back from a page, to where it last was or else to the first place on the page.
    LaunchedEffect(tv && holding) {
        if (!tv || !holding) return@LaunchedEffect
        delay(TvRefocusMs)
        if (!TvFocusMemory.restore()) manager.moveFocus(FocusDirection.Next)
    }
    return this
        .mouseChords { chord -> gestures.shortcutFor(chord)?.let(act) ?: false }
        .onFocusChanged { state ->
            holding = state.isFocused
            if (tv && !state.hasFocus) lost++
        }.focusRequester(focus)
        .focusable()
        .onPreviewKeyEvent { event ->
            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
            if (tv && holding && event.key in RemoteKeys) {
                manager.moveFocus(FocusDirection.Next)
                return@onPreviewKeyEvent true
            }
            val shortcut = event.toChord()?.let { gestures.shortcutFor(it) } ?: return@onPreviewKeyEvent false
            act(shortcut)
        }
}
