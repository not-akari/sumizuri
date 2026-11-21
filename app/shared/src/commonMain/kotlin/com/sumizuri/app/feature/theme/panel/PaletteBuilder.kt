package com.sumizuri.app.feature.theme.panel

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.theme.AccentSwatches
import com.sumizuri.app.feature.theme.ColorHarmony
import com.sumizuri.app.feature.theme.ThemeEditorState
import com.sumizuri.app.feature.theme.paletteFrom
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_harmony
import com.sumizuri.app.shared.resources.editor_harmony_analogous
import com.sumizuri.app.shared.resources.editor_harmony_complementary
import com.sumizuri.app.shared.resources.editor_harmony_monochrome
import com.sumizuri.app.shared.resources.editor_harmony_split
import com.sumizuri.app.shared.resources.editor_harmony_triadic
import com.sumizuri.app.shared.resources.editor_palette_from
import com.sumizuri.app.shared.resources.editor_palette_from_hint
import com.sumizuri.app.shared.resources.editor_seed_custom
import com.sumizuri.app.shared.resources.editor_vibrance
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.text.percentText
import com.sumizuri.app.ui.theme.roleColor
import org.jetbrains.compose.resources.stringResource

// Builds both modes of the palette from one color, a harmony and a vibrance, folded away until it is wanted. Every choice shows at once and can be undone like any other change.
@Composable
internal fun PaletteBuilder(state: ThemeEditorState) {
    var open by remember { mutableStateOf(false) }
    var seed by remember { mutableStateOf(state.draft.roleColor(state.dark, "primary")) }
    var harmony by remember { mutableStateOf(ColorHarmony.Complementary) }
    var vibrance by remember { mutableFloatStateOf(1f) }
    var custom by remember { mutableStateOf(false) }
    fun build() = state.change(state.draft.paletteFrom(seed, harmony, vibrance), group = "palette")
    Column(
        Modifier
            .fillMaxWidth()
            .clip(MaterialTheme.shapes.medium)
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, MaterialTheme.shapes.medium),
    ) {
        Row(
            Modifier.fillMaxWidth().clickable { open = !open }.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(Icons.Outlined.Palette, null, tint = MaterialTheme.colorScheme.primary)
            Column(Modifier.weight(1f)) {
                Text(stringResource(Res.string.editor_palette_from), style = MaterialTheme.typography.bodyLarge)
                Text(
                    stringResource(Res.string.editor_palette_from_hint),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
            Icon(
                if (open) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore,
                null,
                tint = MaterialTheme.colorScheme.outline,
            )
        }
        AnimatedVisibility(open) {
            Column(
                Modifier.padding(start = 12.dp, end = 12.dp, bottom = 12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    for (swatch in AccentSwatches) {
                        Dot(swatch, swatch == seed) {
                            seed = swatch
                            custom = false
                            build()
                        }
                    }
                    Dot(seed, custom, label = stringResource(Res.string.editor_seed_custom)) { custom = !custom }
                }
                AnimatedVisibility(custom) {
                    ColorPicker(seed, onTry = { seed = it }, onPick = {
                        seed = it
                        build()
                    }, onUsual = { custom = false })
                }
                ChoiceSetting(
                    Res.string.editor_harmony,
                    ColorHarmony.entries,
                    harmony,
                    { stringResource(harmonyName(it)) },
                ) {
                    harmony = it
                    build()
                }
                SliderSetting(Res.string.editor_vibrance, vibrance, 0.3f..1.6f, { percentText(it) }, onMove = {
                    vibrance = it
                    state.tryOut(state.draft.paletteFrom(seed, harmony, it))
                }) {
                    vibrance = it
                    build()
                }
            }
        }
    }
}

private fun harmonyName(harmony: ColorHarmony) = when (harmony) {
    ColorHarmony.Complementary -> Res.string.editor_harmony_complementary
    ColorHarmony.Analogous -> Res.string.editor_harmony_analogous
    ColorHarmony.Triadic -> Res.string.editor_harmony_triadic
    ColorHarmony.SplitComplementary -> Res.string.editor_harmony_split
    ColorHarmony.Monochrome -> Res.string.editor_harmony_monochrome
}

// A round color to pick, ringed when it is the one in use.
@Composable
private fun Dot(color: Color, chosen: Boolean, label: String? = null, onClick: () -> Unit) {
    val ring = if (chosen) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outlineVariant
    Box(
        Modifier
            .size(32.dp)
            .clip(CircleShape)
            .background(color)
            .border(if (chosen) 3.dp else 1.dp, ring, CircleShape)
            .clickable(onClickLabel = label, onClick = onClick),
    )
}
