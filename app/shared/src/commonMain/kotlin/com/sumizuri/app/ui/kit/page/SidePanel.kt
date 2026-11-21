package com.sumizuri.app.ui.kit.page

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs

// The narrowest and widest a panel beside a list gets.
private val SideMin = 320.dp
private val SideMax = 420.dp

// Whether a window this wide has room for a panel beside a readable list.
fun sideFits(width: Dp): Boolean = width >= ReadableWidth + SideMin + PageGutter

// A page with its bar on top and a list under it, with a panel on the right of the list that slides in when it is wanted and the window has room for it. A list keeps a readable width and sits in the middle with its bar and its panel, and a grid takes all the room the panel leaves.
@Composable
fun ListWithSide(
    readable: Boolean,
    side: Boolean,
    width: Dp,
    modifier: Modifier = Modifier,
    // The room at the right of the panel, which a panel that is a page list with its own margin sets to nothing.
    panelGutter: Dp = PageGutter,
    top: @Composable () -> Unit = {},
    panel: @Composable (Modifier) -> Unit,
    content: @Composable () -> Unit,
) {
    val ms = motionMs(AppMotion.Page)
    val room = (width - ReadableWidth - PageGutter).coerceIn(SideMin, SideMax)
    val frame: @Composable () -> Unit = {
        Column(Modifier.fillMaxSize()) {
            top()
            Row(Modifier.weight(1f).fillMaxWidth()) {
                Box(Modifier.weight(1f).fillMaxHeight()) { content() }
                AnimatedVisibility(
                    side,
                    enter = fadeIn(tween(ms)) + slideInHorizontally(tween(ms, easing = AppMotion.Entrance)) { it / 4 },
                    exit = fadeOut(tween(ms)) + slideOutHorizontally(tween(ms, easing = AppMotion.Leave)) { it / 4 },
                ) {
                    panel(Modifier.width(room).fillMaxHeight().padding(end = panelGutter))
                }
            }
        }
    }
    if (readable) {
        ReadableColumn(if (side) ReadableWidth + room else ReadableWidth, modifier) { frame() }
    } else {
        Box(modifier.fillMaxSize()) { frame() }
    }
}
