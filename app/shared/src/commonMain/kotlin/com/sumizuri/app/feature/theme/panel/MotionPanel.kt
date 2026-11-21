package com.sumizuri.app.feature.theme.panel

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.theme.ThemeEditorState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_cover_drift
import com.sumizuri.app.shared.resources.editor_cover_drift_hint
import com.sumizuri.app.shared.resources.editor_hover_scale
import com.sumizuri.app.shared.resources.editor_press_scale
import com.sumizuri.app.shared.resources.editor_transition_speed
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.percentText
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.theme.spec.ThemeMotion

// The tab of motion: how much a piece grows when the pointer rests on it, how much it shrinks when pressed, and how fast pages and parts change.
@Composable
internal fun MotionPanel(state: ThemeEditorState) {
    val motion = state.draft.options.motion
    fun moving(
        edit: (ThemeMotion, Float) -> ThemeMotion,
    ): (
        AppThemeSpec,
        Float,
    ) -> AppThemeSpec =
        { theme, value -> theme.copy(options = theme.options.copy(motion = edit(theme.options.motion, value))) }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ThemeSlider(state, Res.string.editor_hover_scale, motion.hoverScale, 1f..1.12f, {
            percentText(it)
        }, moving { was, value -> was.copy(hoverScale = value) })
        ThemeSlider(state, Res.string.editor_press_scale, motion.pressScale, 0.8f..1f, {
            percentText(it)
        }, moving { was, value -> was.copy(pressScale = value) })
        ThemeSlider(state, Res.string.editor_transition_speed, motion.transitionSpeed, 0.5f..2f, {
            percentText(it)
        }, moving { was, value -> was.copy(transitionSpeed = value) })
        SwitchSetting(Res.string.editor_cover_drift, motion.coverDrift, { on ->
            state.options { it.copy(motion = it.motion.copy(coverDrift = on)) }
        }, Res.string.editor_cover_drift_hint)
    }
}
