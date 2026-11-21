package com.sumizuri.app.feature.theme.panel

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.sumizuri.app.feature.theme.ThemeEditorState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.allStringResources
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.theme.spec.toLong
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The words for a choice of an enum, looked up by the name of the enum and of the choice, so each choice has its text in every language.
@Composable
internal fun choiceLabel(value: Enum<*>): String = stringResource(
    Res.allStringResources.getValue(
        "choice_${value::class.simpleName.orEmpty().lowercase()}_${value.name.lowercase()}",
    ),
)

// The words for a font name of a theme.
@Composable
internal fun fontLabel(name: String): String =
    stringResource(Res.allStringResources.getValue("choice_font_${name.ifEmpty { "inter" }}"))

// The six hex digits of a color, without its alpha.
internal fun hexOf(color: Color): String = (color.toLong() and 0xFFFFFF).toString(16).padStart(6, '0').uppercase()

// A slider of the theme. The preview follows it while it moves, and the value it is let go at is one change that can be undone.
@Composable
internal fun ThemeSlider(
    state: ThemeEditorState,
    title: StringResource,
    value: Float,
    range: ClosedFloatingPointRange<Float>,
    text: @Composable (Float) -> String,
    edit: (AppThemeSpec, Float) -> AppThemeSpec,
) {
    SliderSetting(title, value, range, text, onMove = {
        state.tryOut(edit(state.draft, it))
    }, onDone = { state.change(edit(state.draft, it)) })
}

// One entry a menu of a theme card offers.
internal class CardAction(val label: StringResource, val run: () -> Unit)
