package com.sumizuri.app.feature.title.layout

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.motion.LocalPageMotion
import kotlinx.coroutines.delay

// A little longer than the glide, so the chapters start after it has come to rest, and the room kept for them until then.
private const val SettleExtraMs = 60L
private val WaitHeight = 320.dp

// Whether the page has glided in. The chapters and the details are a lot to make, so they wait until then and are not made in the middle of the motion. A page come back to is settled at once.
@Composable
internal fun rememberSettled(): Boolean {
    var settled by rememberSaveable { mutableStateOf(false) }
    val glideMs = LocalPageMotion.current.pageMs()
    LaunchedEffect(Unit) {
        if (!settled) {
            delay(glideMs + SettleExtraMs)
            settled = true
        }
    }
    return settled
}

// The room the chapters will take, kept empty while the page glides in.
internal fun LazyListScope.chaptersWait() {
    item(key = "chapters-wait") { Spacer(Modifier.fillMaxWidth().height(WaitHeight)) }
}
