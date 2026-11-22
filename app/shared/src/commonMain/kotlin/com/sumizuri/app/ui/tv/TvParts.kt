package com.sumizuri.app.ui.tv

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs

// The round corners of the cards and rows of the TV screens.
val TvShape = RoundedCornerShape(16.dp)

// Something the remote can reach and press, and hold for more when it has a long press. While it has the focus an accent ring and a lit fill fade in, and nothing changes size. A chosen one keeps a soft wash.
@Composable
fun Modifier.tvCard(
    onClick: () -> Unit,
    shape: Shape = TvShape,
    chosen: Boolean = false,
    onLongClick: (() -> Unit)? = null,
): Modifier {
    val press = remember { MutableInteractionSource() }
    val focused by press.collectIsFocusedAsState()
    val ms = motionMs(AppMotion.Fast)
    val ring by animateFloatAsState(if (focused) 1f else 0f, tween(ms), label = "ring")
    val colors = MaterialTheme.colorScheme
    val rest = if (chosen) colors.primary.copy(alpha = 0.16f) else colors.onSurface.copy(alpha = 0.06f)
    val fill by animateColorAsState(lerp(rest, colors.primary.copy(alpha = 0.24f), ring), tween(ms), label = "fill")
    return rememberedFocus()
        .clip(shape)
        .background(fill, shape)
        .border(2.5.dp, colors.primary.copy(alpha = ring), shape)
        .combinedClickable(press, indication = null, onLongClick = onLongClick, onClick = onClick)
}

// The main button of a TV step, filled with the accent, with a ring around it while it has the focus.
@Composable
fun TvButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, main: Boolean = true) {
    val press = remember { MutableInteractionSource() }
    val focused by press.collectIsFocusedAsState()
    val colors = MaterialTheme.colorScheme
    val ms = motionMs(AppMotion.Fast)
    val ring by animateFloatAsState(if (focused) 1f else 0f, tween(ms), label = "ring")
    val shape = RoundedCornerShape(50)
    val fill = if (main) {
        colors.primary
    } else {
        lerp(
            colors.onSurface.copy(alpha = 0.08f),
            colors.primary.copy(alpha = 0.24f),
            ring,
        )
    }
    Box(
        modifier
            .rememberedFocus()
            .widthIn(min = 96.dp)
            .border(2.5.dp, colors.onSurface.copy(alpha = 0.85f * ring), shape)
            .padding(3.dp)
            .clip(shape)
            .background(fill, shape)
            .clickable(press, indication = null, onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text,
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (main) colors.onPrimary else colors.onSurface,
        )
    }
}

// A row with a name and its choice, changed with left and right on the remote, or with OK, which takes the next one. The choice slides the way it moved.
@Composable
fun <T> TvChoiceRow(
    name: String,
    options: List<T>,
    chosen: T,
    label: @Composable (T) -> String,
    onChoose: (T) -> Unit,
    modifier: Modifier = Modifier,
) {
    val at = options.indexOf(chosen).coerceAtLeast(0)
    val step: (Int) -> Unit = { by -> onChoose(options[(at + by + options.size) % options.size]) }
    TvRow(
        onClick = { step(1) },
        modifier = modifier.onPreviewKeyEvent { event ->
            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
            when (event.key) {
                Key.DirectionLeft -> step(-1).let { true }
                Key.DirectionRight -> step(1).let { true }
                else -> false
            }
        },
    ) {
        Text(name, Modifier.weight(1f), fontSize = 18.sp, color = MaterialTheme.colorScheme.onSurface, maxLines = 1)
        Icon(Icons.AutoMirrored.Rounded.KeyboardArrowLeft, null, Modifier.size(22.dp).alpha(0.6f))
        AnimatedContent(
            at,
            Modifier.widthIn(min = 120.dp),
            transitionSpec = {
                val ahead = targetState > initialState
                val ms = 200
                (slideInHorizontally(tween(ms)) { if (ahead) it / 3 else -it / 3 } + fadeIn(tween(ms))) togetherWith
                    (slideOutHorizontally(tween(ms)) { if (ahead) -it / 3 else it / 3 } + fadeOut(tween(ms / 2)))
            },
            contentAlignment = Alignment.Center,
            label = "choice",
        ) { shown ->
            Text(
                label(options[shown]),
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary,
            )
        }
        Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, null, Modifier.size(22.dp).alpha(0.6f))
    }
}

// A row that opens something: its name, what it is set to now when that is known, and an arrow.
@Composable
fun TvLinkRow(name: String, value: String?, onClick: () -> Unit, modifier: Modifier = Modifier) {
    TvRow(onClick, modifier) {
        Text(name, Modifier.weight(1f), fontSize = 18.sp, color = MaterialTheme.colorScheme.onSurface, maxLines = 1)
        if (value != null) {
            Text(value, fontSize = 16.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
        }
        Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, null, Modifier.size(22.dp).alpha(0.6f))
    }
}

// A wide row the remote can reach, with what goes in it laid out across.
@Composable
fun TvRow(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    onLongClick: (() -> Unit)? = null,
    chosen: Boolean = false,
    content: @Composable RowScope.() -> Unit,
) {
    Row(
        modifier
            .fillMaxWidth()
            .tvCard(onClick, chosen = chosen, onLongClick = onLongClick)
            .padding(horizontal = 22.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        content = content,
    )
}
