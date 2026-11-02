package com.sumizuri.app.feature.reader.controls

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.feature.reader.BarState

// Whether a panel opens at the side on a wide window. The actions of a page stay in the dock, beside the picture they are about.
fun DockPanel.goesAside(): Boolean = this != DockPanel.None && this != DockPanel.Page

// What the panel of the reader docked at the side of a wide window shows. It keeps the last panel while it slides away, so it never goes out empty.
@Composable
internal fun ReaderAside(
    panel: DockPanel,
    bar: BarState,
    defaultMode: ReaderMode,
    onDefaultMode: (ReaderMode) -> Unit,
    onMode: (ReaderMode) -> Unit,
    onLight: (dim: Float, warmth: Float) -> Unit,
    onLightDone: () -> Unit,
    onClose: () -> Unit,
    panelContent: @Composable (DockPanel) -> Unit,
) {
    var last by remember { mutableStateOf(panel) }
    if (panel.goesAside()) last = panel
    when (last) {
        DockPanel.Light -> LightPanel(bar.dim, bar.warmth, onLight, onLightDone)

        DockPanel.Mode -> ModePanel(bar, defaultMode, onDefaultMode, onClose) {
            onClose()
            onMode(it)
        }

        else -> panelContent(last)
    }
}
