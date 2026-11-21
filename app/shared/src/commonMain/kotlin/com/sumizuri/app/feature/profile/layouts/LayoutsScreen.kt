package com.sumizuri.app.feature.profile.layouts

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.blocks.ProfilePreset
import com.sumizuri.app.feature.profile.blocks.BlockEnv
import com.sumizuri.app.feature.profile.blocks.BlockGrid
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.blocks_layouts
import com.sumizuri.app.shared.resources.preset_confirm_message
import com.sumizuri.app.shared.resources.preset_preview
import com.sumizuri.app.shared.resources.preset_use
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.card.CardButton
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.page.LoadStatus
import com.sumizuri.app.ui.kit.page.LocalBottomClearance
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.pageScroll
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.stringResource

// The widest the page grows before it is centered, and the width of the list of layouts beside the preview.
private val PageWidth = 1100.dp
private val ListWidth = 320.dp

// The layouts of the profile, each drawn with the person's own reading. A wide window lists them beside a big preview of the chosen one, and a phone picks with pills above it. The button in the bar puts the chosen one in place of the blocks.
@Composable
internal fun LayoutsScreen(state: LayoutsState, onUse: (ProfilePreset) -> Unit, onBack: () -> Unit) {
    var chosen by rememberSaveable { mutableStateOf(ProfilePreset.Overview) }
    Column(Modifier.fillMaxSize()) {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
            Box(Modifier.widthIn(max = PageWidth).fillMaxWidth()) {
                PageTopBar(stringResource(Res.string.blocks_layouts), onBack = onBack) {
                    InkButton(
                        { onUse(chosen) },
                        Modifier.padding(end = 8.dp),
                    ) { Text(stringResource(Res.string.preset_use)) }
                }
            }
        }
        BoxWithConstraints(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
            val wide = maxWidth >= 860.dp
            val room = Modifier.widthIn(max = PageWidth).fillMaxWidth().padding(horizontal = PageGutter)
            val bottom = 24.dp + LocalBottomClearance.current
            if (wide) {
                Row(room, horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                    Column(
                        Modifier
                            .width(ListWidth)
                            .fillMaxSize()
                            .pageScroll()
                            .padding(top = 8.dp, bottom = bottom),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        for (preset in ProfilePreset.entries) PresetCard(preset, preset == chosen) { chosen = preset }
                        Note()
                    }
                    Column(
                        Modifier
                            .weight(1f)
                            .fillMaxSize()
                            .pageScroll()
                            .padding(top = 8.dp, bottom = bottom),
                    ) {
                        Preview(state, chosen)
                    }
                }
            } else {
                Column(
                    room.fillMaxSize().pageScroll().padding(top = 4.dp, bottom = bottom),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    ChipRow {
                        for (preset in ProfilePreset.entries) {
                            SoftChip(preset == chosen, { chosen = preset }, { Text(stringResource(preset.label)) })
                        }
                    }
                    Text(
                        stringResource(chosen.about),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Preview(state, chosen)
                    Note()
                }
            }
        }
    }
}

// One layout in the list: its name, in the accent while it is chosen, and what it holds.
@Composable
private fun PresetCard(preset: ProfilePreset, chosen: Boolean, onClick: () -> Unit) {
    CardButton(onClick, Modifier.fillMaxWidth(), on = chosen) {
        Column(
            Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(
                stringResource(preset.label),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = if (chosen) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface,
            )
            Text(
                stringResource(preset.about),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

// The chosen layout as the profile would show it, with the person's own figures and covers. It fades from one layout to the next, and takes no taps.
@Composable
private fun Preview(state: LayoutsState, chosen: ProfilePreset) {
    val ms = motionMs(AppMotion.Medium)
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        AppSectionLabel(stringResource(Res.string.preset_preview), Modifier.padding(top = 0.dp))
        AnimatedContent(chosen, transitionSpec = {
            fadeIn(tween(ms)) togetherWith fadeOut(tween(ms))
        }, label = "layout") { preset ->
            val blocks = state.previews[preset]
            Box(
                Modifier
                    .fillMaxWidth()
                    .heightIn(
                        min = 200.dp,
                    ).softCard(shape = MaterialTheme.shapes.large)
                    .padding(14.dp),
            ) {
                if (blocks == null) {
                    LoadStatus(true, null, {})
                } else {
                    BlockGrid(blocks, BlockEnv(state.stats, state.recent, wide = false, onOpenTitle = {}), onAdd = {})
                }
                Box(Modifier.matchParentSize().clickable(remember { MutableInteractionSource() }, indication = null) {})
            }
        }
    }
}

@Composable
private fun Note() {
    Text(
        stringResource(Res.string.preset_confirm_message),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.outline,
    )
}
