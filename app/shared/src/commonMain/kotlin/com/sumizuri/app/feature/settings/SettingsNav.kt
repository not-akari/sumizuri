package com.sumizuri.app.feature.settings

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.settings_new
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.theme.LocalThemeSpec
import org.jetbrains.compose.resources.stringResource

// The list of the settings, the same on a phone and beside an open page: each group under its name as one soft card, and each page a row with its icon on a round wash, its name and what it is set to. The page open beside the list is lit, and alone on a phone an arrow shows a row opens a page when the theme has them.
@Composable
internal fun NavGroups(pages: List<SettingsPage>, selected: SettingsTarget?, arrows: Boolean = false) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        for (group in SettingsGroup.entries) {
            val here = pages.filter { it.group == group }
            if (here.isEmpty()) continue
            Text(
                stringResource(group.label).uppercase(),
                Modifier.padding(start = 6.dp, top = 12.dp, bottom = 2.dp),
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.outline,
            )
            Column(
                Modifier
                    .fillMaxWidth()
                    .entrance()
                    .softCard(shape = MaterialTheme.shapes.medium)
                    .padding(4.dp),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                for (page in here) {
                    NavRow(page.icon, page.title, page.summary, page.target == selected, page.fresh, arrows, page.open)
                }
            }
        }
    }
}

@Composable
private fun NavRow(
    icon: ImageVector,
    title: String,
    summary: String,
    on: Boolean,
    fresh: Boolean,
    arrow: Boolean,
    onClick: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val press = remember { MutableInteractionSource() }
    val hovered by press.collectIsHoveredAsState()
    val fill by animateColorAsState(
        when {
            on -> colors.primary.copy(alpha = 0.18f)
            hovered -> colors.primary.copy(alpha = 0.08f)
            else -> Color.Transparent
        },
        tween(motionMs(AppMotion.Fast)),
        label = "row",
    )
    Row(
        Modifier
            .fillMaxWidth()
            .clip(MaterialTheme.shapes.small)
            .background(fill)
            .clickable(press, indication = null, onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            Modifier.size(36.dp).clip(CircleShape).background(if (on) colors.primary else softFill(strong = true)),
            contentAlignment = Alignment.Center,
        ) { Icon(icon, null, Modifier.size(19.dp), tint = if (on) colors.onPrimary else colors.primary) }
        Column(Modifier.weight(1f)) {
            Text(
                title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (on) FontWeight.Bold else FontWeight.Medium,
                color = colors.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                summary,
                style = MaterialTheme.typography.bodySmall,
                color = colors.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        if (fresh) {
            Text(
                stringResource(Res.string.settings_new),
                Modifier.background(colors.primary, CircleShape).padding(horizontal = 8.dp, vertical = 2.dp),
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = colors.onPrimary,
            )
        }
        if (arrow && LocalThemeSpec.current.options.components.listChevron) ListChevron()
    }
}
