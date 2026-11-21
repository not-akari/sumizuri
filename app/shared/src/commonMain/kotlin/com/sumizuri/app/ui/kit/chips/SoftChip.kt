package com.sumizuri.app.ui.kit.chips

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.motion.motionMs

// A pill that can be on or off, in the soft look of the cards: a light wash of the accent, stronger with the words in the accent while it is on, and a little lighter under the mouse. Every chip of the app is one of these.
@Composable
fun SoftChip(
    selected: Boolean,
    onClick: () -> Unit,
    label: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: (@Composable () -> Unit)? = null,
    trailingIcon: (@Composable () -> Unit)? = null,
) {
    val colors = MaterialTheme.colorScheme
    val press = remember { MutableInteractionSource() }
    val hovered by press.collectIsHoveredAsState()
    val ms = motionMs(AppMotion.Fast)
    val fill by animateColorAsState(
        when {
            selected -> softFill(strong = true)
            hovered && enabled -> softFill(lit = true)
            else -> softFill()
        },
        tween(ms),
        label = "chip fill",
    )
    val ink by animateColorAsState(if (selected) colors.primary else colors.onSurface, tween(ms), label = "chip ink")
    Row(
        modifier
            .height(32.dp)
            .alpha(if (enabled) 1f else 0.4f)
            .feedbackScale(press, hover = false)
            .clip(CircleShape)
            .background(fill)
            .clickable(press, indication = null, enabled = enabled, onClick = onClick)
            .padding(
                start = if (leadingIcon !=
                    null
                ) {
                    10.dp
                } else {
                    14.dp
                },
                end = if (trailingIcon != null) 10.dp else 14.dp,
            ),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        CompositionLocalProvider(
            LocalContentColor provides ink,
            LocalTextStyle provides
                MaterialTheme.typography.labelLarge.copy(
                    fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium,
                ),
        ) {
            if (leadingIcon != null) Box(contentAlignment = Alignment.Center) { leadingIcon() }
            label()
            if (trailingIcon != null) Box(contentAlignment = Alignment.Center) { trailingIcon() }
        }
    }
}

// A pill that does something when tapped, such as opening a choice, in the same soft look and never shown as on.
@Composable
fun SoftActionChip(
    onClick: () -> Unit,
    label: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: (@Composable () -> Unit)? = null,
    trailingIcon: (@Composable () -> Unit)? = null,
) = SoftChip(false, onClick, label, modifier, enabled, leadingIcon, trailingIcon)
