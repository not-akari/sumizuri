package com.sumizuri.app.ui.kit.card

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs

// How tall the strip of actions is.
private val StripHeight = 46.dp

// A strip of actions split evenly across its width with thin lines between them, such as the foot of the continue card of a title. Ink is the color of its words and icons, which the card it sits on gives.
@Composable
fun ActionStrip(
    ink: Color,
    modifier: Modifier = Modifier,
    shade: Color = Color.Black.copy(alpha = 0.14f),
    content: @Composable RowScope.(Color) -> Unit,
) {
    Row(
        modifier.fillMaxWidth().height(StripHeight).background(shade),
        verticalAlignment = Alignment.CenterVertically,
    ) { content(ink) }
}

// One action of a strip: an icon and a word in the middle of its share. One that is on has a filled icon, which the caller gives, and bolder words. It lightens under the mouse, and a small dot asks for a look. Every action but the first has a thin line before it.
@Composable
fun RowScope.StripAction(
    label: String,
    on: Boolean,
    ink: Color,
    onClick: () -> Unit,
    first: Boolean = false,
    enabled: Boolean = true,
    alert: Boolean = false,
    // The color of the icon of an action that is on, the accent where the strip is plain.
    accent: Color = ink,
    icon: @Composable (tint: Color) -> Unit,
) {
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val ms = motionMs(AppMotion.Fast)
    val glow by animateColorAsState(ink.copy(alpha = if (hovered && enabled) 0.1f else 0f), tween(ms), label = "glow")
    val words by animateColorAsState(
        when {
            !enabled -> ink.copy(alpha = 0.4f)
            on -> ink
            else -> ink.copy(alpha = 0.8f)
        },
        tween(ms),
        label = "words",
    )
    if (!first) {
        Box(
            Modifier
                .width(1.dp)
                .fillMaxHeight()
                .padding(vertical = 12.dp)
                .background(ink.copy(alpha = 0.22f)),
        )
    }
    Box(
        Modifier
            .weight(1f)
            .fillMaxHeight()
            .background(glow)
            .clickable(source, indication = null, enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Row(
            Modifier.padding(horizontal = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(7.dp),
        ) {
            Box {
                icon(if (on && enabled) accent else words)
                if (alert) {
                    Box(
                        Modifier
                            .align(Alignment.TopEnd)
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.error),
                    )
                }
            }
            Text(
                label,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = if (on) FontWeight.SemiBold else FontWeight.Medium,
                color = words,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}
