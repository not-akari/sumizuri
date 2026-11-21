package com.sumizuri.app.feature.reader.view

import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import com.sumizuri.app.data.model.controls.ReaderAction
import com.sumizuri.app.data.model.controls.TapLayout
import com.sumizuri.app.feature.reader.at
import com.sumizuri.app.ui.controls.LocalReaderControls
import com.sumizuri.app.ui.controls.mouseChords
import com.sumizuri.app.ui.controls.toChord
import kotlinx.coroutines.Job
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// Turns the keys and the taps into the actions the person bound to them. A tap is looked up in the grid of the layout by how far across and down it landed. The callback says whether it did the action and is told whether it came from a tap, since a tap and a key may move by different steps.
@Composable
fun Modifier.readerInput(layout: TapLayout, onAction: (action: ReaderAction, tap: Boolean) -> Boolean): Modifier {
    val focus = remember { FocusRequester() }
    val controls by rememberUpdatedState(LocalReaderControls.current)
    val act by rememberUpdatedState(onAction)
    LaunchedEffect(Unit) { focus.requestFocus() }
    return this
        .mouseChords { chord -> controls.actionForKey(chord)?.let { act(it, false) } ?: false }
        .focusRequester(focus)
        .focusable()
        .onPreviewKeyEvent { event ->
            // The volume keys are taken whole while they turn pages, so the phone does not change its volume as well.
            if (controls.volumeKeys && (event.key == Key.VolumeDown || event.key == Key.VolumeUp)) {
                if (event.type == KeyEventType.KeyDown) {
                    val forward = (event.key == Key.VolumeDown) != controls.volumeInverted
                    act(if (forward) ReaderAction.NextPage else ReaderAction.PreviousPage, false)
                }
                return@onPreviewKeyEvent true
            }
            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
            val action = event.toChord()?.let { controls.actionForKey(it) } ?: return@onPreviewKeyEvent false
            act(action, false)
        }.pointerInput(Unit) {
            // A tap that shows or hides the controls waits a moment for a second tap, since two taps zoom the page and should not bring the controls up as well.
            coroutineScope {
                var pending: Job? = null
                detectTapGestures(
                    onPress = { pending?.cancel() },
                    onLongPress = { if (controls.longTapMenu) act(ReaderAction.PageMenu, true) },
                    onTap = { at ->
                        val action = controls.actionForTap(layout, at.x / size.width, at.y / size.height)
                        if (action == ReaderAction.ToggleControls) {
                            pending = launch {
                                delay(viewConfiguration.doubleTapTimeoutMillis)
                                act(action, true)
                            }
                        } else if (action != null) {
                            act(action, true)
                        }
                    },
                )
            }
        }
}
