package com.sumizuri.app.feature.theme

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.theme.panel.BackdropPanel
import com.sumizuri.app.feature.theme.panel.BasicsPanel
import com.sumizuri.app.feature.theme.panel.ColorsPanel
import com.sumizuri.app.feature.theme.panel.CoverPanel
import com.sumizuri.app.feature.theme.panel.ListsPanel
import com.sumizuri.app.feature.theme.panel.MotionPanel
import com.sumizuri.app.feature.theme.panel.PiecesPanel
import com.sumizuri.app.feature.theme.panel.TextPanel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_reset_section
import com.sumizuri.app.ui.kit.card.Hairline
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.stringResource

// The settings of the editor: a row of tabs that is always on show, the settings of the open tab under it, and a button that takes the tab back to how it was.
@Composable
internal fun EditorControls(state: ThemeEditorState, modifier: Modifier) {
    val fast = motionMs(AppMotion.Fast)
    Surface(
        modifier.padding(start = 8.dp, end = 8.dp, bottom = 8.dp),
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
    ) {
        Column {
            SectionTabs(state.section, state::open, Modifier.padding(horizontal = 4.dp, vertical = 4.dp))
            Hairline(alpha = 0.5f)
            AnimatedContent(state.section, Modifier.weight(1f), transitionSpec = {
                fadeIn(tween(fast)) togetherWith
                    fadeOut(tween(fast))
            }, label = "section") { shown ->
                // Each tab starts at its top.
                key(shown) {
                    Column(
                        Modifier
                            .fillMaxWidth()
                            .verticalScroll(
                                rememberScrollState(),
                            ).padding(horizontal = 16.dp, vertical = 8.dp),
                    ) {
                        when (shown) {
                            EditorSection.Basics -> BasicsPanel(state)
                            EditorSection.Colors -> ColorsPanel(state)
                            EditorSection.Text -> TextPanel(state)
                            EditorSection.Covers -> CoverPanel(state)
                            EditorSection.Lists -> ListsPanel(state)
                            EditorSection.Pieces -> PiecesPanel(state)
                            EditorSection.Motion -> MotionPanel(state)
                            EditorSection.Backdrop -> BackdropPanel(state)
                        }
                        TextButton(
                            { state.reset(shown) },
                            Modifier.padding(top = 8.dp),
                            enabled = state.sectionChanged(shown),
                        ) {
                            Text(stringResource(Res.string.editor_reset_section, stringResource(shown.label)))
                        }
                    }
                }
            }
        }
    }
}
