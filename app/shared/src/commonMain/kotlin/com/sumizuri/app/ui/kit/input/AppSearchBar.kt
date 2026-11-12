package com.sumizuri.app.ui.kit.input

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.sumizuri.app.navigation.LocalTabShown
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.clear
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// The texts the field passed on that the page has not given back yet are kept up to this many.
private const val WaitingMost = 64

// The one search field used on every page that has a search. A page that gives a place for its history keeps the searches typed there, and shows them under the field while it is empty.
@Composable
fun AppSearchBar(
    value: String,
    onValueChange: (String) -> Unit,
    hint: String,
    modifier: Modifier = Modifier,
    // How long the typing must pause before the page is told, for a search that works over many items. The field itself shows each key at once.
    pauseMs: Long = 0,
    // The name the searches of this place are kept under, or null for a field that keeps none.
    historyPlace: String? = null,
) {
    // The text in the field, which follows what the page says and is passed on after the pause.
    var text by remember { mutableStateOf(value) }
    // What the field passed on and the page has not given back yet, oldest first. The page gives each text back a moment later, so a value that is one of them is the field's own coming back, and never undoes the keys typed since. Any other value was set from outside, such as a cleared search, and replaces the text.
    val waiting = remember { ArrayDeque<String>() }
    LaunchedEffect(value) {
        val own = waiting.indexOf(value)
        if (own >= 0) {
            repeat(own + 1) { waiting.removeFirst() }
        } else if (value != text) {
            text = value
            waiting.clear()
        }
    }
    fun pass(typed: String) {
        waiting.addLast(typed)
        if (waiting.size > WaitingMost) waiting.removeFirst()
        onValueChange(typed)
    }
    if (pauseMs > 0) {
        LaunchedEffect(text) {
            if (text == value) return@LaunchedEffect
            // Clearing is passed on at once.
            if (text.isNotEmpty()) delay(pauseMs)
            pass(text)
        }
    }
    val change: (String) -> Unit = { typed ->
        text = typed
        if (pauseMs <= 0) pass(typed)
    }
    val history = historyPlace?.let { rememberSearchHistory(it, text) }
    var focused by remember { mutableStateOf(false) }
    val requester = remember { FocusRequester() }
    // Listed while it is on screen, so the shortcut for the search can put the cursor here. A bar on a kept tab out of sight is not.
    val inSight = LocalTabShown.current
    DisposableEffect(requester, inSight) {
        if (inSight) SearchFocus.add(requester)
        onDispose { SearchFocus.remove(requester) }
    }
    Column(modifier.fillMaxWidth()) {
        Surface(
            Modifier.fillMaxWidth().height(44.dp),
            shape = MaterialTheme.shapes.small,
            color = MaterialTheme.colorScheme.surfaceContainerHigh,
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        ) {
            Row(Modifier.padding(start = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.Search, null, tint = MaterialTheme.colorScheme.outline)
                BasicTextField(
                    value = text,
                    onValueChange = change,
                    modifier = Modifier
                        .weight(1f)
                        .padding(horizontal = 10.dp)
                        .focusRequester(requester)
                        .onFocusChanged { focused = it.isFocused },
                    singleLine = true,
                    textStyle = MaterialTheme.typography.bodyMedium.copy(color = MaterialTheme.colorScheme.onSurface),
                    cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
                    // A field that keeps its searches keeps one at once when the search key is pressed.
                    keyboardOptions = if (history ==
                        null
                    ) {
                        KeyboardOptions.Default
                    } else {
                        KeyboardOptions(imeAction = ImeAction.Search)
                    },
                    keyboardActions = KeyboardActions(onSearch = { history?.keep(text) }),
                    decorationBox = { field ->
                        Box(contentAlignment = Alignment.CenterStart) {
                            if (text.isEmpty()) {
                                Text(
                                    hint,
                                    color = MaterialTheme.colorScheme.outline,
                                    style = MaterialTheme.typography.bodyMedium,
                                )
                            }
                            field()
                        }
                    },
                )
                if (text.isNotEmpty()) {
                    IconButton({ change("") }) {
                        Icon(
                            Icons.Outlined.Close,
                            stringResource(Res.string.clear),
                            tint = MaterialTheme.colorScheme.outline,
                        )
                    }
                }
            }
        }
        if (history != null && focused && text.isEmpty()) SearchHistoryChips(history, onPick = change)
    }
}
