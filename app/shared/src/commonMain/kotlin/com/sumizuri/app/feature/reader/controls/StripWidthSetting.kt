package com.sumizuri.app.feature.reader.controls

import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.data.model.reader.ReaderWidth
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_width
import com.sumizuri.app.shared.resources.reader_width_custom
import com.sumizuri.app.shared.resources.reader_width_dp
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsRows
import com.sumizuri.app.ui.kit.setting.SliderSetting
import org.jetbrains.compose.resources.stringResource

// The slider moves the own width by this many dp at a time.
private const val WidthStep = 50

// How wide the long scroll grows: a size to pick, and with Custom a slider of its own width. The reader panel and the reading settings both show it.
internal fun SettingsRows.stripWidth(settings: ReaderSettings, onChange: (ReaderSettings) -> Unit) {
    padded {
        ChoiceSetting(Res.string.reader_width, ReaderWidth.entries, settings.width, {
            stringResource(it.label)
        }) { onChange(settings.copy(width = it)) }
    }
    if (settings.width != ReaderWidth.Custom) return
    padded {
        SliderSetting(
            Res.string.reader_width_custom,
            settings.customWidth.toFloat(),
            ReaderWidth.CustomLeast.toFloat()..ReaderWidth.CustomMost.toFloat(),
            { stringResource(Res.string.reader_width_dp, it.toInt() / WidthStep * WidthStep) },
            steps = (ReaderWidth.CustomMost - ReaderWidth.CustomLeast) / WidthStep - 1,
        ) { onChange(settings.copy(customWidth = it.toInt() / WidthStep * WidthStep)) }
    }
}
