package com.sumizuri.app.ui.kit.card

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.shape.CornerBasedShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.motion.motionMs

// The space between soft cards in a list, so each stands on its own like the tracker rows.
val SoftGap = 6.dp

// The fill of the soft cards, the look of the tracker rows of a title: a wash of the accent over the page, a little stronger under the mouse, and stronger again for the one that stands out, such as the next chapter.
@Composable
fun softFill(lit: Boolean = false, strong: Boolean = false): Color = MaterialTheme.colorScheme.primary.copy(
    alpha = when {
        strong -> 0.24f
        lit -> 0.19f
        else -> 0.13f
    },
)

// Draws a part as a soft card, whose fill moves to a new state.
@Composable
fun Modifier.softCard(
    lit: Boolean = false,
    strong: Boolean = false,
    shape: CornerBasedShape = MaterialTheme.shapes.small,
): Modifier {
    val fill by animateColorAsState(softFill(lit, strong), tween(motionMs(AppMotion.Fast)), label = "soft")
    return clip(shape).background(fill, shape)
}

// A soft card that is pressed like a button: lighter under the mouse and a little smaller under the finger, with an optional long press.
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun Modifier.softPress(onClick: () -> Unit, onLongClick: (() -> Unit)? = null): Modifier {
    val press = remember { MutableInteractionSource() }
    val hovered by press.collectIsHoveredAsState()
    return feedbackScale(press, hover = false)
        .softCard(lit = hovered)
        .combinedClickable(press, indication = null, onLongClick = onLongClick, onClick = onClick)
}

// A small soft card that is a button, a little lighter under the mouse. One that is on, such as a title in the library, says so with its icon and words in the accent, which the caller gives.
@Composable
fun CardButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    on: Boolean = false,
    enabled: Boolean = true,
    shape: CornerBasedShape = MaterialTheme.shapes.small,
    content: @Composable RowScope.() -> Unit,
) {
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    Surface(
        onClick,
        modifier.softCard(lit = hovered && enabled, strong = on && hovered, shape = shape),
        enabled = enabled,
        shape = shape,
        color = Color.Transparent,
        interactionSource = source,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, content = content)
    }
}
