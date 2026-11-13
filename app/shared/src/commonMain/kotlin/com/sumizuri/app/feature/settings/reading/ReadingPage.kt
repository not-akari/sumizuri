package com.sumizuri.app.feature.settings.reading

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.reader.ReaderBackground
import com.sumizuri.app.data.model.reader.ReaderDual
import com.sumizuri.app.data.model.reader.ReaderFont
import com.sumizuri.app.data.model.reader.ReaderGap
import com.sumizuri.app.data.model.reader.ReaderLookup
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.data.model.reader.ReaderOrientation
import com.sumizuri.app.data.model.reader.ReaderProgressBar
import com.sumizuri.app.data.model.reader.ReaderQuality
import com.sumizuri.app.data.model.reader.ReaderScale
import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.data.model.reader.ReaderTextAlign
import com.sumizuri.app.data.model.reader.ReaderZoomStart
import com.sumizuri.app.feature.reader.controls.PageTurnSetting
import com.sumizuri.app.feature.reader.controls.ReaderLight
import com.sumizuri.app.feature.reader.controls.fill
import com.sumizuri.app.feature.reader.controls.ink
import com.sumizuri.app.feature.reader.controls.stripWidth
import com.sumizuri.app.feature.reader.novel.novelStyle
import com.sumizuri.app.feature.settings.GlobalReaderViewModel
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_percent
import com.sumizuri.app.shared.resources.manga_group_appearance
import com.sumizuri.app.shared.resources.manga_group_mode
import com.sumizuri.app.shared.resources.manga_group_pages
import com.sumizuri.app.shared.resources.novel_group_spacing
import com.sumizuri.app.shared.resources.novel_group_text
import com.sumizuri.app.shared.resources.reader_auto_speed
import com.sumizuri.app.shared.resources.reader_background
import com.sumizuri.app.shared.resources.reader_brightness
import com.sumizuri.app.shared.resources.reader_control_shade
import com.sumizuri.app.shared.resources.reader_crop_borders
import com.sumizuri.app.shared.resources.reader_crop_borders_hint
import com.sumizuri.app.shared.resources.reader_default_mode
import com.sumizuri.app.shared.resources.reader_dual
import com.sumizuri.app.shared.resources.reader_font
import com.sumizuri.app.shared.resources.reader_gap
import com.sumizuri.app.shared.resources.reader_grayscale
import com.sumizuri.app.shared.resources.reader_hide_bars
import com.sumizuri.app.shared.resources.reader_inline_next
import com.sumizuri.app.shared.resources.reader_invert_colors
import com.sumizuri.app.shared.resources.reader_invert_taps
import com.sumizuri.app.shared.resources.reader_keep_on
import com.sumizuri.app.shared.resources.reader_line_height
import com.sumizuri.app.shared.resources.reader_lookup
import com.sumizuri.app.shared.resources.reader_orientation
import com.sumizuri.app.shared.resources.reader_page_number
import com.sumizuri.app.shared.resources.reader_page_strip
import com.sumizuri.app.shared.resources.reader_panel_zoom
import com.sumizuri.app.shared.resources.reader_panel_zoom_hint
import com.sumizuri.app.shared.resources.reader_paragraph_gap
import com.sumizuri.app.shared.resources.reader_part_general
import com.sumizuri.app.shared.resources.reader_part_manga
import com.sumizuri.app.shared.resources.reader_part_novel
import com.sumizuri.app.shared.resources.reader_preview_one
import com.sumizuri.app.shared.resources.reader_preview_two
import com.sumizuri.app.shared.resources.reader_progress_bar
import com.sumizuri.app.shared.resources.reader_quality
import com.sumizuri.app.shared.resources.reader_scale
import com.sumizuri.app.shared.resources.reader_text_align
import com.sumizuri.app.shared.resources.reader_text_size
import com.sumizuri.app.shared.resources.reader_warmth
import com.sumizuri.app.shared.resources.reader_wpm
import com.sumizuri.app.shared.resources.reader_zoom_start
import com.sumizuri.app.shared.resources.reading_group_screen
import com.sumizuri.app.shared.resources.reading_group_scroll
import com.sumizuri.app.shared.resources.reading_group_speed
import com.sumizuri.app.shared.resources.settings_reading
import com.sumizuri.app.shared.resources.settings_reading_hint
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.PartTabs
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// The parts of the page of the reader, one shown at a time.
private enum class ReaderPart(val label: StringResource) {
    General(Res.string.reader_part_general),
    Manga(Res.string.reader_part_manga),
    Novel(Res.string.reader_part_novel),
}

// The one page for every reader, in three parts: what every reader shares, how the pictures of a manga are shown, and how the text of a novel is set with a preview of it. What a title sets for itself in the reader wins over these.
@Composable
fun ReadingRoute(onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val model = viewModel { GlobalReaderViewModel(container.reading) }
    val settings by model.settings.collectAsStateWithLifecycle()
    var part by rememberSaveable { mutableStateOf(ReaderPart.General) }
    SettingsPageFrame(Res.string.settings_reading, onBack, subtitle = Res.string.settings_reading_hint, onReset = {
        model.update { ReaderSettings() }
    }) {
        PartTabs(ReaderPart.entries, part, { stringResource(it.label) }) { part = it }
        when (part) {
            ReaderPart.General -> GeneralPart(settings, model)
            ReaderPart.Manga -> MangaPart(settings, model)
            ReaderPart.Novel -> NovelPart(settings, model)
        }
    }
}

@Composable
private fun GeneralPart(settings: ReaderSettings, model: GlobalReaderViewModel) {
    SettingsSection(Res.string.manga_group_mode) {
        padded {
            ChoiceSetting(Res.string.reader_default_mode, ReaderMode.entries, settings.mode, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(mode = value) } }
        }
    }
    SettingsSection(Res.string.reading_group_screen) {
        padded {
            SwitchSetting(
                Res.string.reader_keep_on,
                settings.keepScreenOn,
                { on -> model.update { it.copy(keepScreenOn = on) } },
            )
        }
        padded {
            SwitchSetting(Res.string.reader_hide_bars, settings.hideSystemBars, { on ->
                model.update {
                    it.copy(hideSystemBars = on)
                }
            })
        }
        padded {
            ChoiceSetting(Res.string.reader_orientation, ReaderOrientation.entries, settings.orientation, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(orientation = value) } }
        }
        padded {
            PageTurnSetting(settings) { next ->
                model.update {
                    it.copy(animatePages = next.animatePages, pageTurn = next.pageTurn)
                }
            }
        }
        padded {
            SwitchSetting(Res.string.reader_panel_zoom, settings.panelZoom, { on ->
                model.update { it.copy(panelZoom = on) }
            }, Res.string.reader_panel_zoom_hint)
        }
        // Brightness is the opposite of how much the screen is dimmed, as the slider in the reader shows it.
        padded {
            SliderSetting(Res.string.reader_brightness, 1f - settings.dim, 0f..1f, {
                stringResource(
                    Res.string.display_percent,
                    (
                        it *
                            100
                        ).roundToInt(),
                )
            }) { value -> model.update { it.copy(dim = 1f - value) } }
        }
        padded {
            SliderSetting(Res.string.reader_warmth, settings.warmth, 0f..1f, {
                stringResource(
                    Res.string.display_percent,
                    (
                        it *
                            100
                        ).roundToInt(),
                )
            }) { value -> model.update { it.copy(warmth = value) } }
        }
    }
    SettingsSection(Res.string.reading_group_scroll) {
        padded {
            ChoiceSetting(Res.string.reader_progress_bar, ReaderProgressBar.entries, settings.progressBar, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(progressBar = value) } }
        }
        padded {
            SwitchSetting(
                Res.string.reader_page_number,
                settings.pageNumber,
                { on -> model.update { it.copy(pageNumber = on) } },
            )
        }
        padded {
            SwitchSetting(
                Res.string.reader_page_strip,
                settings.pageStrip,
                { on -> model.update { it.copy(pageStrip = on) } },
            )
        }
        padded {
            SliderSetting(Res.string.reader_control_shade, settings.controlShade, 0f..1f, {
                stringResource(
                    Res.string.display_percent,
                    (
                        it *
                            100
                        ).roundToInt(),
                )
            }) { value ->
                model.update { it.copy(controlShade = value) }
            }
        }
        padded {
            SwitchSetting(
                Res.string.reader_inline_next,
                settings.inlineNext,
                { on -> model.update { it.copy(inlineNext = on) } },
            )
        }
        padded {
            SwitchSetting(
                Res.string.reader_invert_taps,
                settings.invertTaps,
                { on -> model.update { it.copy(invertTaps = on) } },
            )
        }
        padded {
            SliderSetting(Res.string.reader_auto_speed, settings.autoSpeed.toFloat(), 20f..600f, {
                it.roundToInt().toString()
            }) { value -> model.update { it.copy(autoSpeed = value.roundToInt()) } }
        }
    }
    BedtimeSection(settings, model)
}

@Composable
private fun MangaPart(settings: ReaderSettings, model: GlobalReaderViewModel) {
    SettingsSection(Res.string.manga_group_pages) {
        padded {
            ChoiceSetting(Res.string.reader_scale, ReaderScale.entries, settings.scale, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(scale = value) } }
        }
        padded {
            ChoiceSetting(Res.string.reader_dual, ReaderDual.entries, settings.dual, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(dual = value) } }
        }
        padded {
            ChoiceSetting(Res.string.reader_gap, ReaderGap.entries, settings.gap, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(gap = value) } }
        }
        stripWidth(settings) { changed -> model.update { changed } }
    }
    SettingsSection(Res.string.manga_group_appearance) {
        padded {
            ChoiceSetting(Res.string.reader_background, ReaderBackground.entries, settings.background, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(background = value) } }
        }
        padded {
            ChoiceSetting(Res.string.reader_quality, ReaderQuality.entries, settings.quality, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(quality = value) } }
        }
        padded {
            ChoiceSetting(Res.string.reader_zoom_start, ReaderZoomStart.entries, settings.zoomStart, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(zoomStart = value) } }
        }
        padded {
            SwitchSetting(Res.string.reader_crop_borders, settings.cropBorders, { on ->
                model.update {
                    it.copy(cropBorders = on)
                }
            }, Res.string.reader_crop_borders_hint)
        }
        padded {
            SwitchSetting(
                Res.string.reader_grayscale,
                settings.grayscale,
                { on -> model.update { it.copy(grayscale = on) } },
            )
        }
        padded {
            SwitchSetting(Res.string.reader_invert_colors, settings.invertColors, { on ->
                model.update {
                    it.copy(invertColors = on)
                }
            })
        }
        padded { PageColorFilters(settings, model) }
    }
}

@Composable
private fun NovelPart(settings: ReaderSettings, model: GlobalReaderViewModel) {
    // The preview sits over the choices that change it.
    ReaderPreview(settings)
    SettingsSection(Res.string.novel_group_text) {
        padded {
            ChoiceSetting(Res.string.reader_font, ReaderFont.entries, settings.font, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(font = value) } }
        }
        padded {
            ChoiceSetting(Res.string.reader_text_align, ReaderTextAlign.entries, settings.textAlign, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(textAlign = value) } }
        }
        padded {
            SliderSetting(Res.string.reader_text_size, settings.fontSize.toFloat(), 12f..40f, {
                it.roundToInt().toString()
            }) { value -> model.update { it.copy(fontSize = value.roundToInt()) } }
        }
        padded {
            ChoiceSetting(Res.string.reader_background, ReaderBackground.entries, settings.background, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(background = value) } }
        }
        padded {
            ChoiceSetting(Res.string.reader_lookup, ReaderLookup.entries, settings.lookup, {
                stringResource(it.label)
            }) { value -> model.update { it.copy(lookup = value) } }
        }
    }
    SettingsSection(Res.string.novel_group_spacing) {
        padded {
            SliderSetting(Res.string.reader_line_height, settings.lineHeight, 1f..3f, {
                (
                    (it * 10).roundToInt() /
                        10f
                    ).toString()
            }) { value -> model.update { it.copy(lineHeight = value) } }
        }
        padded {
            SliderSetting(Res.string.reader_paragraph_gap, settings.paragraphGap.toFloat(), 0f..40f, {
                it.roundToInt().toString()
            }) { value -> model.update { it.copy(paragraphGap = value.roundToInt()) } }
        }
    }
    SettingsSection(Res.string.reading_group_speed) {
        padded {
            SliderSetting(Res.string.reader_wpm, settings.readingWpm.toFloat(), 80f..600f, {
                it.roundToInt().toString()
            }) { value -> model.update { it.copy(readingWpm = value.roundToInt()) } }
        }
    }
}

// A few lines set the way a chapter of a novel will be: the typeface, size, spacing and alignment on the chosen background, under the brightness and warmth of the reader.
@Composable
private fun ReaderPreview(settings: ReaderSettings) {
    val shape = MaterialTheme.shapes.large
    val style = novelStyle(settings, settings.background.ink())
    Box(
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(settings.background.fill())
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, shape),
    ) {
        Column(
            Modifier.padding(horizontal = 18.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(settings.paragraphGap.dp),
        ) {
            Text(stringResource(Res.string.reader_preview_one), style = style)
            Text(stringResource(Res.string.reader_preview_two), style = style)
        }
        ReaderLight(settings.dim, settings.warmth, Modifier.matchParentSize())
    }
}
