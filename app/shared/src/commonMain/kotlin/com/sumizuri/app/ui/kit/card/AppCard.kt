package com.sumizuri.app.ui.kit.card

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.shape.CornerBasedShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.motion.feedbackScale

// The corners of every card, those the theme gives to cards: soft and even, unless a theme of its own has others.
val CardShape: CornerBasedShape
    @Composable get() = MaterialTheme.shapes.medium

// How long a card takes to brighten under the mouse, quick enough to follow a pointer moving down a list.
private const val HoverMs = 120

// Whether the page is dark, where cards and the ink behind them are drawn a little differently.
@Composable
internal fun darkPage(): Boolean = MaterialTheme.colorScheme.background.luminance() < 0.5f

// How every card is filled, the same in every theme but for its colors: one flat color a step off the page, a little lighter under the mouse. A little of what is behind shows through: very little on a dark page, where more would look like glass, and a bit more on a light one.
@Composable
fun cardFill(lit: Boolean = false): Color {
    val colors = MaterialTheme.colorScheme
    return if (darkPage()) {
        if (lit) colors.surfaceContainerHighest.copy(alpha = 0.9f) else colors.surfaceContainerHigh.copy(alpha = 0.85f)
    } else {
        colors.surfaceContainerHigh.copy(alpha = if (lit) 0.75f else 0.55f)
    }
}

// The light border of every card, firmer under the mouse.
@Composable
fun cardEdge(lit: Boolean = false): Color =
    MaterialTheme.colorScheme.outlineVariant.copy(alpha = if (lit) 0.9f else 0.5f)

// A card, the base of every list row. One that can be tapped brightens under the mouse and gives under a press. It never grows or rises under the mouse, which would cover the cards beside it and blur its words.
@Composable
fun AppCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    // A long press, which only a card that can be tapped has.
    onLongClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    if (onClick == null) {
        Surface(
            modifier.background(cardFill(), CardShape),
            CardShape,
            Color.Transparent,
            border = BorderStroke(1.dp, cardEdge()),
        ) {
            Column(content = content)
        }
    } else {
        val source = remember { MutableInteractionSource() }
        val hovered by source.collectIsHoveredAsState()
        val edge by animateColorAsState(cardEdge(hovered), tween(HoverMs), label = "edge")
        val fill by animateColorAsState(cardFill(hovered), tween(HoverMs), label = "fill")
        if (onLongClick != null) {
            Surface(
                modifier
                    .feedbackScale(source, hover = false)
                    .background(fill, CardShape)
                    .clip(CardShape)
                    .combinedClickable(
                        interactionSource = source,
                        indication = LocalIndication.current,
                        onClick = onClick,
                        onLongClick = onLongClick,
                    ),
                shape = CardShape,
                color = Color.Transparent,
                border = BorderStroke(1.dp, edge),
            ) {
                Column(content = content)
            }
            return
        }
        Surface(
            onClick,
            modifier.feedbackScale(source, hover = false).background(fill, CardShape),
            shape = CardShape,
            color = Color.Transparent,
            border = BorderStroke(1.dp, edge),
            interactionSource = source,
        ) {
            Column(content = content)
        }
    }
}
