package com.sumizuri.app.feature.reader.controls

import androidx.compose.runtime.Composable
import com.sumizuri.app.data.model.reader.ReaderBackground
import com.sumizuri.app.data.model.reader.ReaderControls
import com.sumizuri.app.data.model.reader.ReaderOrientation
import com.sumizuri.app.data.model.reader.ReaderProgressBar
import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.manga_group_appearance
import com.sumizuri.app.shared.resources.reader_auto_speed
import com.sumizuri.app.shared.resources.reader_background
import com.sumizuri.app.shared.resources.reader_contrast
import com.sumizuri.app.shared.resources.reader_control_shade
import com.sumizuri.app.shared.resources.reader_controls
import com.sumizuri.app.shared.resources.reader_grayscale
import com.sumizuri.app.shared.resources.reader_hide_bars
import com.sumizuri.app.shared.resources.reader_incognito_switch
import com.sumizuri.app.shared.resources.reader_inline_next
import com.sumizuri.app.shared.resources.reader_invert_colors
import com.sumizuri.app.shared.resources.reader_invert_taps
import com.sumizuri.app.shared.resources.reader_keep_on
import com.sumizuri.app.shared.resources.reader_orientation
import com.sumizuri.app.shared.resources.reader_page_number
import com.sumizuri.app.shared.resources.reader_progress_bar
import com.sumizuri.app.shared.resources.reader_sepia
import com.sumizuri.app.shared.resources.reading_group_screen
import com.sumizuri.app.shared.resources.reading_group_scroll
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.percentText
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// How the reader looks: what is behind the pages, how a page turns, and the color filters, which only pictures take.
@Composable
internal fun LookPart(settings: ReaderSettings, textual: Boolean, onSettings: (ReaderSettings) -> Unit) {
    SettingsSection(Res.string.reading_group_screen) {
        padded {
            ChoiceSetting(Res.string.reader_background, ReaderBackground.entries, settings.background, {
                stringResource(it.label)
            }) {
                onSettings(settings.copy(background = it))
            }
        }
        padded {
            PageTurnSetting(settings, onSettings)
        }
    }
    if (!textual) {
        SettingsSection(Res.string.manga_group_appearance) {
            padded {
                SwitchSetting(
                    Res.string.reader_grayscale,
                    settings.grayscale,
                    { onSettings(settings.copy(grayscale = it)) },
                )
            }
            padded {
                SwitchSetting(
                    Res.string.reader_invert_colors,
                    settings.invertColors,
                    { onSettings(settings.copy(invertColors = it)) },
                )
            }
            padded {
                SliderSetting(Res.string.reader_sepia, settings.sepia, 0f..1f, {
                    percentText(it)
                }) { onSettings(settings.copy(sepia = it)) }
            }
            padded {
                SliderSetting(Res.string.reader_contrast, settings.contrast, 0.5f..2f, {
                    percentText(it)
                }) { onSettings(settings.copy(contrast = it)) }
            }
        }
    }
}

// How the reader is worked: the page slider and number, the auto scroll, the taps, the screen and whether progress is kept.
@Composable
internal fun ControlsPart(settings: ReaderSettings, onSettings: (ReaderSettings) -> Unit) {
    SettingsSection(Res.string.reading_group_scroll) {
        padded {
            ChoiceSetting(Res.string.reader_controls, ReaderControls.entries, settings.controls, {
                stringResource(it.label)
            }) {
                onSettings(settings.copy(controls = it))
            }
        }
        padded {
            ChoiceSetting(Res.string.reader_progress_bar, ReaderProgressBar.entries, settings.progressBar, {
                stringResource(it.label)
            }) {
                onSettings(settings.copy(progressBar = it))
            }
        }
        padded {
            SwitchSetting(
                Res.string.reader_page_number,
                settings.pageNumber,
                { onSettings(settings.copy(pageNumber = it)) },
            )
        }
        padded {
            SliderSetting(Res.string.reader_control_shade, settings.controlShade, 0f..1f, { percentText(it) }) {
                onSettings(settings.copy(controlShade = it))
            }
        }
        padded {
            SliderSetting(
                Res.string.reader_auto_speed,
                settings.autoSpeed.toFloat(),
                20f..600f,
                { it.roundToInt().toString() },
            ) {
                onSettings(settings.copy(autoSpeed = it.roundToInt()))
            }
        }
        padded {
            SwitchSetting(
                Res.string.reader_invert_taps,
                settings.invertTaps,
                { onSettings(settings.copy(invertTaps = it)) },
            )
        }
        padded {
            SwitchSetting(
                Res.string.reader_inline_next,
                settings.inlineNext,
                { onSettings(settings.copy(inlineNext = it)) },
            )
        }
    }
    SettingsSection(Res.string.reading_group_screen) {
        padded {
            SwitchSetting(
                Res.string.reader_keep_on,
                settings.keepScreenOn,
                { onSettings(settings.copy(keepScreenOn = it)) },
            )
        }
        padded {
            SwitchSetting(
                Res.string.reader_hide_bars,
                settings.hideSystemBars,
                { onSettings(settings.copy(hideSystemBars = it)) },
            )
        }
        padded {
            ChoiceSetting(Res.string.reader_orientation, ReaderOrientation.entries, settings.orientation, {
                stringResource(it.label)
            }) {
                onSettings(settings.copy(orientation = it))
            }
        }
        padded {
            SwitchSetting(
                Res.string.reader_incognito_switch,
                settings.incognito,
                { onSettings(settings.copy(incognito = it)) },
            )
        }
    }
}
