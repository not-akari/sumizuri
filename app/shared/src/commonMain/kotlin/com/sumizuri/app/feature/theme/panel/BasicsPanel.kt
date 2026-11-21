package com.sumizuri.app.feature.theme.panel

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Casino
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.RestartAlt
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.theme.AccentSwatches
import com.sumizuri.app.feature.theme.EditorSection
import com.sumizuri.app.feature.theme.ThemeEditorState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_accent
import com.sumizuri.app.shared.resources.editor_accent_hint
import com.sumizuri.app.shared.resources.editor_author
import com.sumizuri.app.shared.resources.editor_hint
import com.sumizuri.app.shared.resources.editor_more_colors
import com.sumizuri.app.shared.resources.editor_name
import com.sumizuri.app.shared.resources.editor_oled
import com.sumizuri.app.shared.resources.editor_random_accent
import com.sumizuri.app.shared.resources.editor_start_from
import com.sumizuri.app.shared.resources.editor_start_over
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.theme.readableOn
import com.sumizuri.app.ui.theme.roleColor
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.theme.spec.ThemePresets
import com.sumizuri.app.ui.theme.withAccent
import org.jetbrains.compose.resources.stringResource
import kotlin.random.Random

// The first tab, enough to make a theme of one's own in a few taps: its name and who made it, one accent for both modes, the colors of a built in theme to start from, the character of the corners and a black dark mode.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun BasicsPanel(state: ThemeEditorState) {
    val draft = state.draft
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            stringResource(Res.string.editor_hint),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.outline,
        )
        AppTextField(draft.name, {
            state.change(draft.copy(name = it.take(40)), group = "name")
        }, Modifier.fillMaxWidth(), label = { Text(stringResource(Res.string.editor_name)) }, singleLine = true)
        AppTextField(draft.author, {
            state.change(draft.copy(author = it.take(40)), group = "author")
        }, Modifier.fillMaxWidth(), label = { Text(stringResource(Res.string.editor_author)) }, singleLine = true)
        AppSectionLabel(Res.string.editor_accent)
        Text(
            stringResource(Res.string.editor_accent_hint),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.outline,
        )
        val current = draft.roleColor(state.dark, "primary")
        val page = draft.roleColor(state.dark, "surface")
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            // A swatch is the one in use when the accent is that color moved to stand out on the page, as picking it does.
            for (swatch in AccentSwatches) {
                Swatch(swatch, readableOn(swatch, page) == current) {
                    state.change(draft.withAccent(swatch))
                }
            }
            RoundIcon(Icons.Outlined.Casino, stringResource(Res.string.editor_random_accent)) {
                state.change(
                    draft.withAccent(
                        Color.hsv(
                            Random.nextFloat() * 360f,
                            0.55f + Random.nextFloat() * 0.35f,
                            0.6f + Random.nextFloat() * 0.3f,
                        ),
                    ),
                )
            }
            RoundIcon(
                Icons.Outlined.Palette,
                stringResource(Res.string.editor_more_colors),
            ) { state.open(EditorSection.Colors) }
        }
        AppSectionLabel(Res.string.editor_start_from)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            for (preset in ThemePresets) {
                PresetColors(preset, state.dark) {
                    state.change(draft.copy(light = preset.light, dark = preset.dark))
                }
            }
        }
        CornerCharacters(state)
        SwitchSetting(Res.string.editor_oled, draft.options.effects.oledDark, { on ->
            state.options {
                it.copy(effects = it.effects.copy(oledDark = on))
            }
        })
        InkOutlinedButton(state::resetAll, Modifier.padding(top = 8.dp), enabled = state.changed) {
            Icon(Icons.Outlined.RestartAlt, null, Modifier.size(18.dp))
            Text(stringResource(Res.string.editor_start_over), Modifier.padding(start = 8.dp))
        }
    }
}

// One accent to pick, ringed when it is the one in use.
@Composable
private fun Swatch(color: Color, chosen: Boolean, onClick: () -> Unit) {
    val ring = MaterialTheme.colorScheme.onSurface
    Box(
        Modifier
            .size(38.dp)
            .clip(CircleShape)
            .clickable(onClick = onClick)
            .border(
                if (chosen) 3.dp else 1.dp,
                if (chosen) ring else MaterialTheme.colorScheme.outlineVariant,
                CircleShape,
            ).padding(if (chosen) 5.dp else 0.dp)
            .clip(CircleShape)
            .background(color),
    )
}

// A round button the size of a swatch, for the choices beside the swatches.
@Composable
private fun RoundIcon(icon: ImageVector, label: String, onClick: () -> Unit) {
    Box(
        Modifier
            .size(38.dp)
            .clip(CircleShape)
            .clickable(onClick = onClick)
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, CircleShape),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, label, Modifier.size(20.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant) }
}

// The colors of a built in theme as a small page with its accents on it and its name under it.
@Composable
private fun PresetColors(preset: AppThemeSpec, dark: Boolean, onClick: () -> Unit) {
    val page = remember(preset, dark) { preset.roleColor(dark, "surface") }
    val accents =
        remember(preset, dark) { listOf("primary", "secondary", "tertiary").map { preset.roleColor(dark, it) } }
    val shape = MaterialTheme.shapes.medium
    Column(
        Modifier.width(76.dp).clip(shape).clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .clip(shape)
                .background(page)
                .border(1.dp, MaterialTheme.colorScheme.outlineVariant, shape)
                .padding(vertical = 14.dp),
            horizontalArrangement = Arrangement.Center,
        ) {
            for (accent in accents) {
                Box(
                    Modifier
                        .padding(horizontal = 2.dp)
                        .size(14.dp)
                        .clip(CircleShape)
                        .background(accent),
                )
            }
        }
        Text(preset.name, style = MaterialTheme.typography.labelMedium, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}
