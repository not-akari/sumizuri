package com.sumizuri.app.ui.kit.menu

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.ui.kit.card.Hairline
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs

// The menu every button with more choices opens: a soft rounded panel with a little room around its rows, which grows out of its button.
@Composable
fun AppMenu(
    open: Boolean,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    offset: DpOffset = DpOffset(0.dp, 4.dp),
    content: @Composable ColumnScope.() -> Unit,
) {
    DropdownMenu(
        open,
        onDismiss,
        modifier.widthIn(min = 220.dp).padding(horizontal = 6.dp),
        offset = offset,
        shape = MaterialTheme.shapes.large,
        containerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
        tonalElevation = 0.dp,
        shadowElevation = 10.dp,
        content = content,
    )
}

// One row of a menu: an icon, the words and an optional note at the end. A row that takes something away is in the error color, and a row that is on shows a check.
@Composable
fun AppMenuItem(
    text: String,
    icon: ImageVector?,
    onClick: () -> Unit,
    danger: Boolean = false,
    trailing: String? = null,
    chosen: Boolean = false,
    enabled: Boolean = true,
) {
    val colors = MaterialTheme.colorScheme
    val press = remember { MutableInteractionSource() }
    val hovered by press.collectIsHoveredAsState()
    val fill by animateColorAsState(
        if (hovered && enabled) softFill(lit = true) else Color.Transparent,
        tween(motionMs(AppMotion.Fast)),
        label = "menu row",
    )
    val ink = when {
        !enabled -> colors.onSurface.copy(alpha = 0.38f)
        danger -> colors.error
        chosen -> colors.primary
        else -> colors.onSurface
    }
    Row(
        Modifier
            .fillMaxWidth()
            .heightIn(min = 42.dp)
            .clip(MaterialTheme.shapes.small)
            .background(fill)
            .clickable(press, indication = null, enabled = enabled, onClick = onClick)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(20.dp), contentAlignment = Alignment.Center) {
            if (icon != null) {
                Icon(
                    icon,
                    null,
                    Modifier.size(20.dp),
                    tint = if (danger || chosen ||
                        !enabled
                    ) {
                        ink
                    } else {
                        colors.onSurfaceVariant
                    },
                )
            }
        }
        Text(
            text,
            Modifier.weight(1f).padding(end = 8.dp),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (chosen) FontWeight.SemiBold else FontWeight.Medium,
            color = ink,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        if (trailing != null) {
            Text(
                trailing,
                style = MaterialTheme.typography.labelMedium,
                color = colors.outline,
                maxLines = 1,
            )
        }
    }
}

// One row of a menu built from parts, for a row whose words or icon are drawn by the caller, in the same look as the plain row.
@Composable
fun AppMenuItem(
    text: @Composable () -> Unit,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    leadingIcon: (@Composable () -> Unit)? = null,
    trailingIcon: (@Composable () -> Unit)? = null,
    enabled: Boolean = true,
) {
    val colors = MaterialTheme.colorScheme
    val press = remember { MutableInteractionSource() }
    val hovered by press.collectIsHoveredAsState()
    val fill by animateColorAsState(
        if (hovered && enabled) softFill(lit = true) else Color.Transparent,
        tween(motionMs(AppMotion.Fast)),
        label = "menu row",
    )
    val faded = if (enabled) 1f else 0.38f
    Row(
        modifier
            .fillMaxWidth()
            .heightIn(min = 42.dp)
            .clip(MaterialTheme.shapes.small)
            .background(fill)
            .clickable(press, indication = null, enabled = enabled, onClick = onClick)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (leadingIcon != null) {
            CompositionLocalProvider(LocalContentColor provides colors.onSurfaceVariant.copy(alpha = faded)) {
                Box(Modifier.size(20.dp), contentAlignment = Alignment.Center) { leadingIcon() }
            }
        }
        Box(Modifier.weight(1f).padding(end = 8.dp)) {
            CompositionLocalProvider(
                LocalContentColor provides colors.onSurface.copy(alpha = faded),
                LocalTextStyle provides MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
            ) { text() }
        }
        if (trailingIcon != null) {
            CompositionLocalProvider(LocalContentColor provides colors.primary) { trailingIcon() }
        }
    }
}

// A small heading over a group of rows of a menu.
@Composable
fun AppMenuLabel(text: String) {
    Text(
        text.uppercase(),
        Modifier.padding(start = 12.dp, end = 12.dp, top = 8.dp, bottom = 4.dp),
        color = MaterialTheme.colorScheme.outline,
        fontSize = 10.5.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 1.sp,
    )
}

// A thin line between groups of rows of a menu.
@Composable
fun AppMenuDivider() {
    Hairline(Modifier.padding(horizontal = 8.dp, vertical = 4.dp), alpha = 1f)
}
