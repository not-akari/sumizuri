package com.sumizuri.app.feature.migration

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import com.sumizuri.app.data.migration.MigrationRules
import com.sumizuri.app.data.migration.Strictness
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_group_preset
import com.sumizuri.app.shared.resources.mig_preset_balanced_hint
import com.sumizuri.app.shared.resources.mig_preset_careful
import com.sumizuri.app.shared.resources.mig_preset_careful_hint
import com.sumizuri.app.shared.resources.mig_preset_custom
import com.sumizuri.app.shared.resources.mig_preset_custom_hint
import com.sumizuri.app.shared.resources.mig_preset_fast
import com.sumizuri.app.shared.resources.mig_preset_fast_hint
import com.sumizuri.app.shared.resources.mig_strict_balanced
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.setting.SettingsSection
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// Ready mixes of the rules for matching and pace. The rules for moving are left as they are.
internal enum class RulePreset(val label: StringResource, val hint: StringResource) {
    Careful(Res.string.mig_preset_careful, Res.string.mig_preset_careful_hint),
    Balanced(Res.string.mig_strict_balanced, Res.string.mig_preset_balanced_hint),
    Fast(Res.string.mig_preset_fast, Res.string.mig_preset_fast_hint),
    ;

    fun applyTo(rules: MigrationRules): MigrationRules = when (this) {
        Careful -> rules.copy(
            strictness = Strictness.Strict,
            autoAccept = false,
            readChapters = true,
            looksAt = 4,
            compareAll = true,
            parallel = 1,
            delayMs = 600,
        )

        Balanced -> rules.copy(
            strictness = Strictness.Balanced,
            autoAccept = true,
            readChapters = false,
            looksAt = 3,
            compareAll = false,
            parallel = 2,
            delayMs = 300,
        )

        Fast -> rules.copy(
            strictness = Strictness.Loose,
            autoAccept = true,
            readChapters = false,
            looksAt = 3,
            compareAll = false,
            parallel = 4,
            delayMs = 100,
        )
    }
}

// A chip for each preset and one for a mix of your own, lit for the one the rules match now, with a line on what it does.
@Composable
internal fun PresetSection(rules: MigrationRules, onChange: (MigrationRules) -> Unit) {
    val now = RulePreset.entries.firstOrNull { it.applyTo(rules) == rules }
    SettingsSection(
        stringResource(Res.string.mig_group_preset),
        stringResource(now?.hint ?: Res.string.mig_preset_custom_hint),
    ) {
        padded {
            ChipRow(wrap = true) {
                for (preset in RulePreset.entries) {
                    SoftChip(now == preset, { onChange(preset.applyTo(rules)) }, { Text(stringResource(preset.label)) })
                }
                SoftChip(now == null, {}, { Text(stringResource(Res.string.mig_preset_custom)) }, enabled = now == null)
            }
        }
    }
}
