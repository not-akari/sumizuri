package com.sumizuri.app.feature.settings.controls

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.controls.ReaderControls
import com.sumizuri.app.data.model.controls.TapGeometry
import com.sumizuri.app.data.model.controls.TapLayout
import com.sumizuri.app.data.model.controls.TapPreset
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tap_bands_side
import com.sumizuri.app.shared.resources.tap_bands_top
import com.sumizuri.app.shared.resources.tap_mirror
import com.sumizuri.app.shared.resources.tap_presets
import com.sumizuri.app.shared.resources.tap_reset
import com.sumizuri.app.ui.kit.chips.SoftActionChip
import com.sumizuri.app.ui.kit.input.ActionButton
import com.sumizuri.app.ui.kit.setting.PartTabs
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// What a tap on each part of the screen does in the reader, for pages and for the long scroll. Each has a grid to change cell by cell, ready made layouts, a mirror for the other hand, and the size of the bands.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun TapZonesPage(
    controls: ReaderControls,
    onChange: ((ReaderControls) -> ReaderControls) -> Unit,
    onBack: () -> Unit,
) {
    var layout by remember { mutableStateOf(TapLayout.Paged) }
    val sizes = controls.geometryOf(layout)
    ControlsFrame(ControlsPage.TapZones, onBack) {
        PartTabs(TapLayout.entries, layout, { stringResource(it.label) }, accent = true) { layout = it }
        TapGrid(
            controls.tapZones.getValue(layout),
            sizes,
        ) { zone, action -> onChange { it.withTapZone(layout, zone, action) } }
        // Ready made layouts, and the buttons that mirror this one or take it back, in one card.
        SettingsSection(Res.string.tap_presets) {
            padded {
                FlowRow(
                    Modifier.padding(vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    for (preset in TapPreset.entries) {
                        SoftActionChip(
                            { onChange { it.withPreset(layout, preset) } },
                            { Text(stringResource(preset.label)) },
                        )
                    }
                }
            }
            padded {
                Row(Modifier.padding(vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    ActionButton(Res.string.tap_mirror, { onChange { it.withTapMirrored(layout) } })
                    ActionButton(Res.string.tap_reset, { onChange { it.withTapLayoutReset(layout) } })
                }
            }
        }
        val range = TapGeometry.Smallest..TapGeometry.Largest
        SettingsSection {
            padded {
                SliderSetting(Res.string.tap_bands_side, sizes.edgeX, range, {
                    "${(it * 100).roundToInt()} %"
                }) { value -> onChange { it.withGeometry(layout, it.geometryOf(layout).copy(edgeX = value)) } }
            }
            padded {
                SliderSetting(Res.string.tap_bands_top, sizes.edgeY, range, {
                    "${(it * 100).roundToInt()} %"
                }) { value -> onChange { it.withGeometry(layout, it.geometryOf(layout).copy(edgeY = value)) } }
            }
        }
    }
}
