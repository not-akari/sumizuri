package com.sumizuri.app.feature.theme.panel

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.theme.ThemeEditorState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.choice_weight_auto
import com.sumizuri.app.shared.resources.editor_density
import com.sumizuri.app.shared.resources.editor_font_body
import com.sumizuri.app.shared.resources.editor_font_display
import com.sumizuri.app.shared.resources.editor_spacing
import com.sumizuri.app.shared.resources.editor_text_scale
import com.sumizuri.app.shared.resources.editor_weight_body
import com.sumizuri.app.shared.resources.editor_weight_heading
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.text.percentText
import com.sumizuri.app.ui.theme.ThemeFonts
import com.sumizuri.app.ui.theme.fontFamilyOf
import com.sumizuri.app.ui.theme.spec.LayoutDensity
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The heaviness a font can be set to, with null for the one the family has.
private val Weights = listOf<Int?>(null, 300, 400, 500, 600, 700, 800, 900)

// The tab of text: the fonts of titles and of text, each written in itself, how big and how heavy the text is, and how much room there is around things.
@Composable
internal fun TextPanel(state: ThemeEditorState) {
    val typography = state.draft.options.typography
    val layout = state.draft.options.layout
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        FontChoice(Res.string.editor_font_display, typography.displayFont) { font ->
            state.options {
                it.copy(typography = it.typography.copy(displayFont = font))
            }
        }
        FontChoice(Res.string.editor_font_body, typography.bodyFont) { font ->
            state.options {
                it.copy(typography = it.typography.copy(bodyFont = font))
            }
        }
        ThemeSlider(state, Res.string.editor_text_scale, typography.textScale, 0.8f..1.4f, {
            percentText(it)
        }) { theme, value ->
            theme.copy(
                options = theme.options.copy(typography = theme.options.typography.copy(textScale = value)),
            )
        }
        ChoiceSetting(Res.string.editor_weight_heading, Weights, typography.headingWeight, {
            it?.toString()
                ?: stringResource(Res.string.choice_weight_auto)
        }) { weight -> state.options { it.copy(typography = it.typography.copy(headingWeight = weight)) } }
        ChoiceSetting(Res.string.editor_weight_body, Weights, typography.bodyWeight, {
            it?.toString()
                ?: stringResource(Res.string.choice_weight_auto)
        }) { weight -> state.options { it.copy(typography = it.typography.copy(bodyWeight = weight)) } }
        ChoiceSetting(Res.string.editor_density, LayoutDensity.entries, layout.density, {
            choiceLabel(it)
        }) { density -> state.options { it.copy(layout = it.layout.copy(density = density)) } }
        ThemeSlider(state, Res.string.editor_spacing, layout.spacing, 0.7f..1.5f, {
            percentText(it)
        }) { theme, value ->
            theme.copy(
                options = theme.options.copy(layout = theme.options.layout.copy(spacing = value)),
            )
        }
    }
}

// The fonts as chips, each name written in its own font, so the choice is seen before it is made.
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FontChoice(title: StringResource, selected: String, onSelect: (String) -> Unit) {
    Column {
        AppSectionLabel(title)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            for (font in ThemeFonts) {
                SoftChip(font == selected, {
                    onSelect(font)
                }, { Text(fontLabel(font), fontFamily = fontFamilyOf(font)) }, Modifier)
            }
        }
    }
}
