package com.sumizuri.app.ui.kit.cover.badge

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.theme.LocalThemeSpec
import com.sumizuri.app.ui.theme.spec.CoverBadgeStyle

// The count of unread chapters on a cover, drawn as the theme says: a ringed circle turned a little like a stamp, a straight one, a pill that grows with the number, or not at all.
@Composable
internal fun UnreadBadge(count: Int, modifier: Modifier = Modifier) {
    val style = LocalThemeSpec.current.options.covers.badgeStyle
    if (style == CoverBadgeStyle.Hidden) return
    val colors = MaterialTheme.colorScheme
    // A round shape on a square is a circle, and it stretches into a pill when the number is long.
    val shape = RoundedCornerShape(50)
    Box(
        modifier
            .then(if (style == CoverBadgeStyle.Tilted) Modifier.rotate(-8f) else Modifier)
            .defaultMinSize(minWidth = 24.dp, minHeight = 24.dp)
            .clip(shape)
            .background(if (style == CoverBadgeStyle.Pill) colors.primary else colors.surface)
            .then(if (style == CoverBadgeStyle.Pill) Modifier else Modifier.border(1.6.dp, colors.primary, shape)),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            count.toString(),
            Modifier.then(
                if (style ==
                    CoverBadgeStyle.Pill
                ) {
                    Modifier.padding(horizontal = 7.dp, vertical = 3.dp)
                } else {
                    Modifier.padding(horizontal = 5.dp)
                },
            ),
            color = if (style == CoverBadgeStyle.Pill) colors.onPrimary else colors.primary,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
        )
    }
}
