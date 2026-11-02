package com.sumizuri.app.feature.reader.controls

import com.sumizuri.app.ui.kit.dock.PanelHead
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.reader.ReaderDual
import com.sumizuri.app.data.model.reader.ReaderFont
import com.sumizuri.app.data.model.reader.ReaderGap
import com.sumizuri.app.data.model.reader.ReaderLookup
import com.sumizuri.app.data.model.reader.ReaderQuality
import com.sumizuri.app.data.model.reader.ReaderScale
import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.data.model.reader.ReaderTextAlign
import com.sumizuri.app.data.model.reader.ReaderWidth
import com.sumizuri.app.data.model.reader.ReaderZoomStart
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.manga_group_pages
import com.sumizuri.app.shared.resources.novel_group_spacing
import com.sumizuri.app.shared.resources.novel_group_text
import com.sumizuri.app.shared.resources.reader_crop_borders
import com.sumizuri.app.shared.resources.reader_crop_borders_hint
import com.sumizuri.app.shared.resources.reader_dual
import com.sumizuri.app.shared.resources.reader_font
import com.sumizuri.app.shared.resources.reader_gap
import com.sumizuri.app.shared.resources.reader_line_height
import com.sumizuri.app.shared.resources.reader_lookup
import com.sumizuri.app.shared.resources.reader_only_title
import com.sumizuri.app.shared.resources.reader_only_title_hint
import com.sumizuri.app.shared.resources.reader_panel_zoom
import com.sumizuri.app.shared.resources.reader_panel_zoom_hint
import com.sumizuri.app.shared.resources.reader_paragraph_gap
import com.sumizuri.app.shared.resources.reader_quality
import com.sumizuri.app.shared.resources.reader_scale
import com.sumizuri.app.shared.resources.reader_settings
import com.sumizuri.app.shared.resources.reader_tab_controls
import com.sumizuri.app.shared.resources.reader_tab_look
import com.sumizuri.app.shared.resources.reader_tab_pages
import com.sumizuri.app.shared.resources.reader_tab_text
import com.sumizuri.app.shared.resources.reader_text_align
import com.sumizuri.app.shared.resources.reader_text_size
import com.sumizuri.app.shared.resources.reader_width
import com.sumizuri.app.shared.resources.reader_wpm
import com.sumizuri.app.shared.resources.reader_zoom_start
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.PartTabs
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// The parts of the settings: how the pages or the words are laid out, how they look, and how the reader is worked.
internal enum class SheetPart { Layout, Look, Controls }

// The part that was open last, so the settings open where they were left.
private var lastPart = SheetPart.Layout

// Every choice of the reader that fits what is open, the pictures of a manga or the words of a novel, split in three parts behind tabs, as a panel the dock grows to hold. The head and the tabs stay put and the choices under them scroll within the room it is given.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReaderSettingsPanel(
    settings: ReaderSettings,
    textual: Boolean,
    onSettings: (ReaderSettings) -> Unit,
    onDismiss: () -> Unit,
) {
    var part by remember { mutableStateOf(lastPart) }
    // Whether the choices are kept for this title alone sits by the title of the panel, since it decides where every layout choice below goes.
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
    PanelHead(stringResource(Res.string.reader_settings), onDismiss, trailing = {
        FilterChip(
            settings.override,
            { onSettings(settings.copy(override = !settings.override)) },
            { Text(stringResource(Res.string.reader_only_title)) },
            leadingIcon = if (settings.override) ({ Icon(Icons.Outlined.Check, null, Modifier.size(18.dp)) }) else null,
        )
    })
        PartTabs(SheetPart.entries, part, {
            stringResource(
                when (it) {
                    SheetPart.Layout -> if (textual) Res.string.reader_tab_text else Res.string.reader_tab_pages
                    SheetPart.Look -> Res.string.reader_tab_look
                    SheetPart.Controls -> Res.string.reader_tab_controls
                },
            )
        }) {
            part = it
            lastPart = it
        }
        Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        if (settings.override && part == SheetPart.Layout) {
            Text(
                stringResource(Res.string.reader_only_title_hint),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary,
            )
        }
        when (part) {
            SheetPart.Layout -> if (textual) {
                TextPart(settings, onSettings)
            } else {
                PagesPart(settings, onSettings)
            }

            SheetPart.Look -> LookPart(settings, textual, onSettings)

            SheetPart.Controls -> ControlsPart(settings, onSettings)
        }
        }
    }
}

@Composable
private fun PagesPart(
    settings: ReaderSettings,
    onSettings: (ReaderSettings) -> Unit,
) {
    SettingsSection(Res.string.manga_group_pages) {
        padded {
            ChoiceSetting(Res.string.reader_scale, ReaderScale.entries, settings.scale, {
                stringResource(it.label)
            }) { onSettings(settings.copy(scale = it)) }
        }
        padded {
            ChoiceSetting(Res.string.reader_dual, ReaderDual.entries, settings.dual, {
                stringResource(it.label)
            }) { onSettings(settings.copy(dual = it)) }
        }
        padded {
            ChoiceSetting(Res.string.reader_gap, ReaderGap.entries, settings.gap, {
                stringResource(it.label)
            }) { onSettings(settings.copy(gap = it)) }
        }
        padded {
            ChoiceSetting(Res.string.reader_width, ReaderWidth.entries, settings.width, {
                stringResource(it.label)
            }) { onSettings(settings.copy(width = it)) }
        }
        padded {
            ChoiceSetting(
                Res.string.reader_zoom_start,
                ReaderZoomStart.entries,
                settings.zoomStart,
                { stringResource(it.label) },
            ) {
                onSettings(settings.copy(zoomStart = it))
            }
        }
        padded {
            SwitchSetting(Res.string.reader_crop_borders, settings.cropBorders, {
                onSettings(settings.copy(cropBorders = it))
            }, Res.string.reader_crop_borders_hint)
        }
        padded {
            SwitchSetting(Res.string.reader_panel_zoom, settings.panelZoom, {
                onSettings(settings.copy(panelZoom = it))
            }, Res.string.reader_panel_zoom_hint)
        }
        padded {
            ChoiceSetting(Res.string.reader_quality, ReaderQuality.entries, settings.quality, {
                stringResource(it.label)
            }) { onSettings(settings.copy(quality = it)) }
        }
    }
}

@Composable
private fun TextPart(
    settings: ReaderSettings,
    onSettings: (ReaderSettings) -> Unit,
) {
    SettingsSection(Res.string.novel_group_text) {
        padded {
            ChoiceSetting(Res.string.reader_font, ReaderFont.entries, settings.font, {
                stringResource(it.label)
            }) { onSettings(settings.copy(font = it)) }
        }
        padded {
            ChoiceSetting(
                Res.string.reader_text_align,
                ReaderTextAlign.entries,
                settings.textAlign,
                { stringResource(it.label) },
            ) {
                onSettings(settings.copy(textAlign = it))
            }
        }
        padded {
            SliderSetting(
                Res.string.reader_text_size,
                settings.fontSize.toFloat(),
                12f..40f,
                { it.roundToInt().toString() },
            ) {
                onSettings(settings.copy(fontSize = it.roundToInt()))
            }
        }
        padded {
            ChoiceSetting(Res.string.reader_lookup, ReaderLookup.entries, settings.lookup, {
                stringResource(it.label)
            }) { onSettings(settings.copy(lookup = it)) }
        }
    }
    SettingsSection(Res.string.novel_group_spacing) {
        padded {
            SliderSetting(Res.string.reader_line_height, settings.lineHeight, 1f..3f, {
                ((it * 10).roundToInt() / 10f).toString()
            }) {
                onSettings(settings.copy(lineHeight = it))
            }
        }
        padded {
            SliderSetting(Res.string.reader_paragraph_gap, settings.paragraphGap.toFloat(), 0f..40f, {
                it.roundToInt().toString()
            }) {
                onSettings(settings.copy(paragraphGap = it.roundToInt()))
            }
        }
        padded {
            SliderSetting(
                Res.string.reader_wpm,
                settings.readingWpm.toFloat(),
                80f..600f,
                { it.roundToInt().toString() },
            ) {
                onSettings(settings.copy(readingWpm = it.roundToInt()))
            }
        }
    }
}
