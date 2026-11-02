package com.sumizuri.app.feature.reader.controls

import androidx.compose.foundation.layout.RowScope
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.outlined.LightMode
import androidx.compose.material.icons.outlined.PauseCircle
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.runtime.Composable
import com.sumizuri.app.feature.reader.BarState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_auto
import com.sumizuri.app.shared.resources.reader_auto_stop
import com.sumizuri.app.shared.resources.reader_chapters
import com.sumizuri.app.shared.resources.reader_light
import com.sumizuri.app.shared.resources.reader_mode_button
import com.sumizuri.app.shared.resources.reader_options
import com.sumizuri.app.ui.kit.dock.DockAction
import org.jetbrains.compose.resources.stringResource

// The actions of the reader, one button each, which the dock of a phone and the top of a wide window both show.
@Composable
internal fun RowScope.ReaderActions(
    bar: BarState,
    panel: DockPanel,
    onToggle: (DockPanel) -> Unit,
    onAuto: () -> Unit,
) {
    DockAction(
        Icons.AutoMirrored.Outlined.FormatListBulleted,
        stringResource(Res.string.reader_chapters),
        panel == DockPanel.Chapters,
        { onToggle(DockPanel.Chapters) },
    )
    // The button shows the picture of the mode in use, and the modes open like every other panel.
    DockAction(bar.mode.icon(), stringResource(Res.string.reader_mode_button), panel == DockPanel.Mode, {
        onToggle(DockPanel.Mode)
    })
    DockAction(Icons.Outlined.LightMode, stringResource(Res.string.reader_light), panel == DockPanel.Light, {
        onToggle(DockPanel.Light)
    })
    if (bar.canAuto) {
        DockAction(
            if (bar.auto) Icons.Outlined.PauseCircle else Icons.Outlined.PlayCircle,
            stringResource(if (bar.auto) Res.string.reader_auto_stop else Res.string.reader_auto),
            bar.auto,
            onAuto,
        )
    }
    DockAction(Icons.Outlined.Tune, stringResource(Res.string.reader_options), panel == DockPanel.Settings, {
        onToggle(DockPanel.Settings)
    })
}
