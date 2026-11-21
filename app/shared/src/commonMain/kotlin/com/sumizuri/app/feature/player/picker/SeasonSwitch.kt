package com.sumizuri.app.feature.player.picker

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.ArrowDropDown
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.season_next
import com.sumizuri.app.shared.resources.season_previous
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.stringResource

// The room a chip adds around its words, and the gap between two chips.
private val ChipExtra = 34.dp
private val ChipGap = 8.dp

// Picks the season a list shows. When every season fits as a chip in one row they show side by side. With more, or with long names, it is one line instead: the season before and after on arrows, and the name in the middle opens a menu of them all.
@Composable
internal fun SeasonSwitch(names: List<String>, open: Int, onOpen: (Int) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val measurer = rememberTextMeasurer()
        val style = MaterialTheme.typography.labelLarge
        val density = LocalDensity.current
        val needed = with(density) {
            names.sumOf { measurer.measure(it, style, maxLines = 1).size.width } +
                (ChipExtra * names.size + ChipGap * (names.size - 1)).roundToPx()
        }
        if (needed <= constraints.maxWidth) {
            ChipRow { names.forEachIndexed { at, name -> ChoiceChip(name, at == open) { onOpen(at) } } }
            return@BoxWithConstraints
        }
        var menu by remember { mutableStateOf(false) }
        val reduce = LocalReduceMotion.current
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            IconButton({ onOpen(open - 1) }, enabled = open > 0) {
                Icon(Icons.AutoMirrored.Outlined.KeyboardArrowLeft, stringResource(Res.string.season_previous))
            }
            Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                TextButton({ menu = true }) {
                    AnimatedContent(
                        open,
                        transitionSpec = { fadeIn(tween(if (reduce) 100 else 180)) togetherWith fadeOut(tween(90)) },
                        label = "season name",
                    ) { shown ->
                        Text(
                            "${names.getOrElse(shown) { "" }}  ·  ${shown + 1}/${names.size}",
                            style = style,
                            fontWeight = FontWeight.SemiBold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    Icon(Icons.Outlined.ArrowDropDown, null, Modifier.size(20.dp))
                }
                AppMenu(menu, { menu = false }) {
                    names.forEachIndexed { at, name ->
                        AppMenuItem(name, null, {
                            menu = false
                            onOpen(at)
                        }, chosen = at == open)
                    }
                }
            }
            IconButton({ onOpen(open + 1) }, enabled = open < names.size - 1) {
                Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, stringResource(Res.string.season_next))
            }
        }
    }
}
