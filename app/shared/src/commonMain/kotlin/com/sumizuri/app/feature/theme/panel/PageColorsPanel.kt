package com.sumizuri.app.feature.theme.panel

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import com.sumizuri.app.feature.theme.ThemeEditorState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_chapter_marks
import com.sumizuri.app.shared.resources.editor_chapter_marks_hint
import com.sumizuri.app.shared.resources.editor_page_colors
import com.sumizuri.app.shared.resources.editor_page_colors_count
import com.sumizuri.app.shared.resources.editor_page_colors_hint
import com.sumizuri.app.shared.resources.editor_page_colors_mode
import com.sumizuri.app.shared.resources.editor_page_colors_strength
import com.sumizuri.app.shared.resources.editor_page_colors_vibrance
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.percentText
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.theme.spec.CoverColorMode
import com.sumizuri.app.ui.theme.spec.ThemePageColors
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// How the page of a title takes the colors of its cover: how much of it follows the cover, how strongly the page leans, how many colors of the cover it uses and how vivid they are.
@Composable
internal fun PageColorsPanel(state: ThemeEditorState) {
    val look = state.draft.options.pageColors
    fun paged(theme: AppThemeSpec, edit: (ThemePageColors) -> ThemePageColors): AppThemeSpec {
        val options = theme.options
        return theme.copy(options = options.copy(pageColors = edit(options.pageColors)))
    }
    Column {
        AppSectionLabel(Res.string.editor_page_colors)
        Text(
            stringResource(Res.string.editor_page_colors_hint),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.outline,
        )
        ChoiceSetting(
            Res.string.editor_page_colors_mode,
            CoverColorMode.entries,
            look.mode,
            { choiceLabel(it) },
        ) { mode ->
            state.change(paged(state.draft) { it.copy(mode = mode) })
        }
        SwitchSetting(Res.string.editor_chapter_marks, look.chapterMarks, { on ->
            state.change(paged(state.draft) { it.copy(chapterMarks = on) })
        }, Res.string.editor_chapter_marks_hint)
        AnimatedVisibility(look.mode != CoverColorMode.Off) {
            Column {
                if (look.mode == CoverColorMode.Tinted || look.mode == CoverColorMode.Immersive) {
                    ThemeSlider(state, Res.string.editor_page_colors_strength, look.strength, 0f..2.5f, {
                        percentText(it)
                    }) { theme, value ->
                        paged(theme) { it.copy(strength = value) }
                    }
                }
                ThemeSlider(state, Res.string.editor_page_colors_count, look.colors.toFloat(), 1f..3f, {
                    it.roundToInt().toString()
                }) { theme, value ->
                    paged(theme) { it.copy(colors = value.roundToInt()) }
                }
                ThemeSlider(state, Res.string.editor_page_colors_vibrance, look.vibrance, 0.4f..1.6f, {
                    percentText(it)
                }) { theme, value ->
                    paged(theme) { it.copy(vibrance = value) }
                }
            }
        }
    }
}
