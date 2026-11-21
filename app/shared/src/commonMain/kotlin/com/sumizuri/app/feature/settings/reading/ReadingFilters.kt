package com.sumizuri.app.feature.settings.reading

import androidx.compose.runtime.Composable
import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.feature.settings.GlobalReaderViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_bedtime
import com.sumizuri.app.shared.resources.reader_bedtime_dim
import com.sumizuri.app.shared.resources.reader_bedtime_from
import com.sumizuri.app.shared.resources.reader_bedtime_hint
import com.sumizuri.app.shared.resources.reader_bedtime_to
import com.sumizuri.app.shared.resources.reader_bedtime_warmth
import com.sumizuri.app.shared.resources.reader_contrast
import com.sumizuri.app.shared.resources.reader_hour
import com.sumizuri.app.shared.resources.reader_sepia
import com.sumizuri.app.shared.resources.reading_group_bedtime
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.percentText
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// The colors of the pages: how much of an old paper brown they take and how strong their contrast is.
@Composable
internal fun PageColorFilters(settings: ReaderSettings, model: GlobalReaderViewModel) {
    SliderSetting(Res.string.reader_sepia, settings.sepia, 0f..1f, { percentText(it) }) { value ->
        model.update { it.copy(sepia = value) }
    }
    SliderSetting(Res.string.reader_contrast, settings.contrast, 0.5f..2f, { percentText(it) }) { value ->
        model.update { it.copy(contrast = value) }
    }
}

// The bedtime hours, between which the screen of the reader is warmer and dimmer by itself.
@Composable
internal fun BedtimeSection(settings: ReaderSettings, model: GlobalReaderViewModel) {
    SettingsSection(Res.string.reading_group_bedtime) {
        padded {
            SwitchSetting(Res.string.reader_bedtime, settings.bedtime, { on ->
                model.update {
                    it.copy(bedtime = on)
                }
            }, Res.string.reader_bedtime_hint)
        }
        if (settings.bedtime) {
            padded {
                HourSlider(Res.string.reader_bedtime_from, settings.bedtimeFrom) { hour ->
                    model.update {
                        it.copy(bedtimeFrom = hour)
                    }
                }
            }
            padded {
                HourSlider(
                    Res.string.reader_bedtime_to,
                    settings.bedtimeTo,
                ) { hour -> model.update { it.copy(bedtimeTo = hour) } }
            }
            padded {
                SliderSetting(
                    Res.string.reader_bedtime_warmth,
                    settings.bedtimeWarmth,
                    0f..1f,
                    { percentText(it) },
                ) { value ->
                    model.update { it.copy(bedtimeWarmth = value) }
                }
            }
            padded {
                SliderSetting(
                    Res.string.reader_bedtime_dim,
                    settings.bedtimeDim,
                    0f..1f,
                    { percentText(it) },
                ) { value ->
                    model.update { it.copy(bedtimeDim = value) }
                }
            }
        }
    }
}

// An hour of the day on a slider, shown as a time on the clock.
@Composable
private fun HourSlider(title: org.jetbrains.compose.resources.StringResource, hour: Int, onDone: (Int) -> Unit) {
    SliderSetting(title, hour.toFloat(), 0f..23f, {
        stringResource(Res.string.reader_hour, it.roundToInt())
    }, steps = 22) { value ->
        onDone(value.roundToInt())
    }
}
