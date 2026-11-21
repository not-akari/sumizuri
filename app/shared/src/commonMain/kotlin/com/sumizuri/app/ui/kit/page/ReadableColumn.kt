package com.sumizuri.app.ui.kit.page

import androidx.compose.foundation.gestures.ScrollableState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.widthIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import com.sumizuri.app.ui.kit.scroll.LocalScrollTarget
import com.sumizuri.app.ui.kit.scroll.scrollFrom

// Keeps a list readable on a wide window by centering it in a column. The wheel and the fingers still scroll the list from the empty space on both sides of it.
@Composable
fun ReadableColumn(maxWidth: Dp = ReadableWidth, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    var target by remember { mutableStateOf<ScrollableState?>(null) }
    CompositionLocalProvider(LocalScrollTarget provides { target = it }) {
        Box(modifier.fillMaxSize().scrollFrom { target }, contentAlignment = Alignment.TopCenter) {
            Box(Modifier.widthIn(max = maxWidth).fillMaxSize()) { content() }
        }
    }
}

// The readable column for a page that shows a list, or the whole width for one that shows a grid, which uses the room well.
@Composable
fun ReadableWhen(readable: Boolean, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    if (readable) ReadableColumn(modifier = modifier, content = content) else Box(modifier) { content() }
}
