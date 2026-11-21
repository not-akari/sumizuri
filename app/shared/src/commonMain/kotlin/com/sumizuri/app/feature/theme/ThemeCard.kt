package com.sumizuri.app.feature.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.theme.panel.CardAction
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.theme.colorScheme
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import org.jetbrains.compose.resources.stringResource

// A theme in the gallery: a small drawing of a page in its colors and corners, its name and who made it, a mark when it is the one in use and a menu of what can be done with it.
@Composable
internal fun ThemeCard(
    spec: AppThemeSpec,
    dark: Boolean,
    selected: Boolean,
    actions: List<CardAction>,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val scheme = remember(spec, dark) { spec.colorScheme(dark) }
    val outline = MaterialTheme.colorScheme.outlineVariant
    val source = remember { MutableInteractionSource() }
    Column(
        modifier.feedbackScale(source).clickable(interactionSource = source, indication = null, onClick = onClick),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(112.dp)
                .clip(spec.shapes.card.toShape())
                .background(scheme.surface)
                .border(
                    if (selected) 2.dp else spec.shapes.borderWidth.dp,
                    if (selected) MaterialTheme.colorScheme.primary else outline,
                    spec.shapes.card.toShape(),
                ),
        ) {
            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Box(
                    Modifier
                        .width(54.dp)
                        .height(7.dp)
                        .clip(CircleShape)
                        .background(scheme.onSurface),
                )
                Box(
                    Modifier
                        .fillMaxWidth(0.8f)
                        .height(5.dp)
                        .clip(CircleShape)
                        .background(scheme.outline),
                )
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Box(
                        Modifier
                            .width(34.dp)
                            .height(20.dp)
                            .clip(CircleShape)
                            .background(scheme.primary),
                    )
                    Box(
                        Modifier
                            .width(26.dp)
                            .height(20.dp)
                            .clip(spec.shapes.chip.toShape())
                            .background(scheme.primaryContainer),
                    )
                    Box(Modifier.size(20.dp).clip(spec.shapes.iconTile.toShape()).background(scheme.tertiary))
                }
                Box(
                    Modifier
                        .fillMaxWidth()
                        .height(22.dp)
                        .clip(spec.shapes.item.toShape())
                        .background(scheme.surfaceContainerHigh)
                        .border(spec.shapes.borderWidth.dp, scheme.outlineVariant, spec.shapes.item.toShape()),
                )
            }
            if (selected) {
                Icon(
                    Icons.Filled.CheckCircle,
                    null,
                    Modifier.align(Alignment.TopEnd).padding(6.dp).size(20.dp),
                    tint = scheme.primary,
                )
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(
                    spec.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (spec.author.isNotBlank()) {
                    Text(
                        spec.author,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.outline,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            if (actions.isNotEmpty()) CardMenu(actions)
        }
    }
}

@Composable
private fun CardMenu(actions: List<CardAction>) {
    var open by remember { mutableStateOf(false) }
    // The menu opens under its button, so the two are in one box.
    Box {
        IconButton({ open = true }, Modifier.size(32.dp)) { Icon(Icons.Outlined.MoreVert, null, Modifier.size(18.dp)) }
        AppMenu(open, { open = false }) {
            for (action in actions) {
                AppMenuItem({ Text(stringResource(action.label)) }, {
                    open = false
                    action.run()
                })
            }
        }
    }
}
