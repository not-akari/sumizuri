package com.sumizuri.app.ui.kit.art

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonColors
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ButtonElevation
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import com.sumizuri.app.ui.kit.card.softFill

// The buttons of the app, in the look of its first run: always round at the ends, a little larger under the mouse and a little smaller under a press. They take the same words as the buttons of Material, so they stand in for them anywhere. Every button is round.

// Makes a button give: larger under the mouse, smaller under a press, springing back.
@Composable
private fun Modifier.give(source: MutableInteractionSource, enabled: Boolean): Modifier {
    val pressed by source.collectIsPressedAsState()
    val hovered by source.collectIsHoveredAsState()
    val scale by animateFloatAsState(
        if (!enabled) {
            1f
        } else if (pressed) {
            0.95f
        } else if (hovered) {
            1.03f
        } else {
            1f
        },
        spring(stiffness = 600f),
        label = "give",
    )
    return graphicsLayer {
        scaleX = scale
        scaleY = scale
    }
}

// The button of the main thing to do, filled with the accent.
@Composable
fun InkButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    colors: ButtonColors = ButtonDefaults.buttonColors(),
    elevation: ButtonElevation? = ButtonDefaults.buttonElevation(),
    border: BorderStroke? = null,
    contentPadding: PaddingValues = ButtonDefaults.ContentPadding,
    interactionSource: MutableInteractionSource? = null,
    content: @Composable RowScope.() -> Unit,
) {
    val source = interactionSource ?: remember { MutableInteractionSource() }
    Button(
        onClick,
        modifier.give(
            source,
            enabled,
        ),
        enabled, CircleShape, colors, elevation, border, contentPadding, source, content,
    )
}

// A softer filled button, for a thing to do that is not the main one.
@Composable
fun InkTonalButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    colors: ButtonColors = ButtonDefaults.filledTonalButtonColors(),
    elevation: ButtonElevation? = ButtonDefaults.filledTonalButtonElevation(),
    border: BorderStroke? = null,
    contentPadding: PaddingValues = ButtonDefaults.ContentPadding,
    interactionSource: MutableInteractionSource? = null,
    content: @Composable RowScope.() -> Unit,
) {
    val source = interactionSource ?: remember { MutableInteractionSource() }
    FilledTonalButton(
        onClick,
        modifier.give(
            source,
            enabled,
        ),
        enabled, CircleShape, colors, elevation, border, contentPadding, source, content,
    )
}

// The quiet button beside them, drawn as a soft wash of the accent like the cards, with no outline.
@Composable
fun InkOutlinedButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    colors: ButtonColors = ButtonDefaults.outlinedButtonColors(
        containerColor = softFill(),
        contentColor = MaterialTheme.colorScheme.onSurface,
    ),
    elevation: ButtonElevation? = null,
    border: BorderStroke? = null,
    contentPadding: PaddingValues = ButtonDefaults.ContentPadding,
    interactionSource: MutableInteractionSource? = null,
    content: @Composable RowScope.() -> Unit,
) {
    val source = interactionSource ?: remember { MutableInteractionSource() }
    OutlinedButton(
        onClick,
        modifier.give(
            source,
            enabled,
        ),
        enabled, CircleShape, colors, elevation, border, contentPadding, source, content,
    )
}
