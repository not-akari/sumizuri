package com.sumizuri.app.feature.theme.panel

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.theme.ThemeEditorState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_bg_add_color
import com.sumizuri.app.shared.resources.editor_bg_count
import com.sumizuri.app.shared.resources.editor_bg_drift
import com.sumizuri.app.shared.resources.editor_bg_hint
import com.sumizuri.app.shared.resources.editor_bg_page_strength
import com.sumizuri.app.shared.resources.editor_bg_pages_still
import com.sumizuri.app.shared.resources.editor_bg_palette
import com.sumizuri.app.shared.resources.editor_bg_remove_color
import com.sumizuri.app.shared.resources.editor_bg_ring
import com.sumizuri.app.shared.resources.editor_bg_scale
import com.sumizuri.app.shared.resources.editor_bg_fps
import com.sumizuri.app.shared.resources.editor_bg_speed
import com.sumizuri.app.shared.resources.editor_bg_still
import com.sumizuri.app.shared.resources.editor_bg_style
import com.sumizuri.app.shared.resources.editor_bg_vignette
import com.sumizuri.app.shared.resources.editor_glow
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.theme.LocalReduceMotion
import com.sumizuri.app.ui.theme.background.backdropColors
import com.sumizuri.app.ui.theme.background.BackdropPainter
import com.sumizuri.app.ui.theme.background.drawCovers
import com.sumizuri.app.ui.theme.background.rememberBackdropCovers
import com.sumizuri.app.ui.theme.background.rememberBackdropClock
import com.sumizuri.app.ui.theme.colorScheme
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.theme.spec.BackgroundPalette
import com.sumizuri.app.ui.theme.spec.BackgroundStyle
import com.sumizuri.app.ui.theme.spec.ThemeBackground
import com.sumizuri.app.ui.theme.spec.toColor
import com.sumizuri.app.ui.theme.spec.toLong
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt
import com.sumizuri.app.ui.text.percentText

// The most colors of its own a background can have.
private const val MostColors = 6

// The small drawings of the styles move at this many steps a second, so each style shows how it moves.
private const val TileFps = 10

// The tab of the moving background: its style picked from small live drawings, how strong, fast, many, large and restless it is, its colors, the ring and shaded edges.
@Composable
internal fun BackdropPanel(state: ThemeEditorState) {
    val look = state.draft.options.background

    // The theme with the background changed, for the sliders and the switches.
    fun backdrop(theme: AppThemeSpec, edit: (ThemeBackground) -> ThemeBackground) = theme.copy(options = theme.options.copy(background = edit(theme.options.background)))
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(stringResource(Res.string.editor_bg_hint), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
        AppSectionLabel(Res.string.editor_bg_style)
        StyleTiles(state)
        ThemeSlider(state, Res.string.editor_glow, state.draft.options.effects.bloom, 0f..3f, { percentText(it) }) { theme, value -> theme.copy(options = theme.options.copy(effects = theme.options.effects.copy(bloom = value))) }
        ThemeSlider(state, Res.string.editor_bg_speed, look.speed, 0f..3f, { if (it < 0.05f) stringResource(Res.string.editor_bg_still) else percentText(it) }) { theme, value -> backdrop(theme) { it.copy(speed = if (value < 0.05f) 0f else value) } }
        val fps = look.fps.toFloat()
        ThemeSlider(state, Res.string.editor_bg_fps, fps, 2f..30f, { it.roundToInt().toString() }) { theme, value ->
            backdrop(theme) { it.copy(fps = value.roundToInt()) }
        }
        ThemeSlider(state, Res.string.editor_bg_count, look.count.toFloat(), 1f..24f, { it.roundToInt().toString() }) { theme, value -> backdrop(theme) { it.copy(count = value.roundToInt()) } }
        ThemeSlider(state, Res.string.editor_bg_scale, look.scale, 0.3f..2.5f, { percentText(it) }) { theme, value -> backdrop(theme) { it.copy(scale = value) } }
        ThemeSlider(state, Res.string.editor_bg_drift, look.drift, 0f..2.5f, { percentText(it) }) { theme, value -> backdrop(theme) { it.copy(drift = value) } }
        ThemeSlider(state, Res.string.editor_bg_vignette, look.vignette, 0f..1f, { percentText(it) }) { theme, value -> backdrop(theme) { it.copy(vignette = value) } }
        ThemeSlider(state, Res.string.editor_bg_page_strength, look.pageStrength, 0f..1.5f, { percentText(it) }) { theme, value ->
            backdrop(theme) { it.copy(pageStrength = value) }
        }
        SwitchSetting(Res.string.editor_bg_pages_still, look.pagesStill, { on -> state.change(backdrop(state.draft) { it.copy(pagesStill = on) }) })
        SwitchSetting(Res.string.editor_bg_ring, look.ring, { on -> state.change(backdrop(state.draft) { it.copy(ring = on) }) })
        ChoiceSetting(Res.string.editor_bg_palette, BackgroundPalette.entries, look.palette, { choiceLabel(it) }) { palette ->
            // Own colors start from the accents of the theme, so the background does not change color the moment they are picked.
            val scheme = state.draft.colorScheme(state.dark)
            state.change(backdrop(state.draft) { it.copy(palette = palette, colors = it.colors.ifEmpty { listOf(scheme.primary, scheme.secondary, scheme.tertiary).map { color -> color.toLong() } }) })
        }
        AnimatedVisibility(look.palette == BackgroundPalette.Own) { OwnColors(state) }
    }
}

// Each style as a small page of the theme with the style moving on it, so the choice is seen and not read.
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun StyleTiles(state: ThemeEditorState) {
    val look = state.draft.options.background
    val scheme = remember(state.draft, state.dark) { state.draft.colorScheme(state.dark) }
    val colors = backdropColors(look, scheme)
    val clock = rememberBackdropClock(look.speed.coerceAtLeast(0.6f), TileFps, still = LocalReduceMotion.current)
    val outline = MaterialTheme.colorScheme
    val tileCovers = rememberBackdropCovers(8)
    FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp), maxItemsInEachRow = 3) {
        for (style in BackgroundStyle.entries) {
            val chosen = style == look.style
            val shape = MaterialTheme.shapes.medium
            // A tile is small, so its shapes are drawn stronger than on a page and sized for the tile, the grids of dots and waves finer and the rest larger.
            val tileScale = when (style) {
                BackgroundStyle.Dots, BackgroundStyle.Waves -> 0.45f
                BackgroundStyle.Strokes -> 0.8f
                else -> 1.2f
            }
            val painter = remember(style) { BackdropPainter() }
            val tileLook = look.copy(style = style, ring = false, vignette = 0f, scale = look.scale * tileScale, count = look.count.coerceIn(3, 8))
            Column(Modifier.weight(1f).clip(shape).clickable { state.change(state.draft.copy(options = state.draft.options.copy(background = look.copy(style = style)))) }, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Spacer(
                    Modifier
                        .fillMaxWidth()
                        .height(64.dp)
                        .clip(shape)
                        .background(scheme.background)
                        .drawBehind {
                            if (style == BackgroundStyle.Covers) drawCovers(clock.value, tileLook.copy(scale = 0.4f), tileCovers, 2.5f) else with(painter) { draw(clock.value, tileLook, colors, 1.6f, false) }
                        }
                        .border(if (chosen) 2.dp else 1.dp, if (chosen) outline.primary else outline.outlineVariant, shape),
                )
                Text(choiceLabel(style), Modifier.padding(bottom = 4.dp), style = MaterialTheme.typography.labelMedium, fontWeight = if (chosen) FontWeight.SemiBold else FontWeight.Normal)
            }
        }
    }
}

// The colors of a background of its own: a swatch for each, a tap opening the picker under them, a button in the picker taking a color away, and a button to add one.
@Composable
private fun OwnColors(state: ThemeEditorState) {
    val look = state.draft.options.background
    var open by remember { mutableStateOf<Int?>(null) }
    fun withColors(theme: AppThemeSpec, colors: List<Long>) = theme.copy(options = theme.options.copy(background = theme.options.background.copy(colors = colors)))
    fun replaced(theme: AppThemeSpec, index: Int, color: Color): AppThemeSpec = withColors(
        theme,
        theme.options.background.colors
            .toMutableList()
            .also { if (index in it.indices) it[index] = color.toLong() },
    )
    Column(Modifier.padding(top = 4.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            look.colors.forEachIndexed { index, value ->
                val chosen = open == index
                Box(
                    Modifier
                        .size(38.dp)
                        .clip(CircleShape)
                        .clickable { open = if (chosen) null else index }
                        .border(if (chosen) 3.dp else 1.dp, if (chosen) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outlineVariant, CircleShape)
                        .padding(if (chosen) 5.dp else 0.dp)
                        .clip(CircleShape)
                        .background(value.toColor()),
                )
            }
            if (look.colors.size < MostColors) {
                Box(
                    Modifier.size(38.dp).clip(CircleShape).border(1.dp, MaterialTheme.colorScheme.outlineVariant, CircleShape).clickable {
                        val last = look.colors.lastOrNull() ?: 0xFF808080
                        state.change(withColors(state.draft, look.colors + last))
                        open = look.colors.size
                    },
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.Outlined.Add, stringResource(Res.string.editor_bg_add_color), tint = MaterialTheme.colorScheme.onSurfaceVariant) }
            }
        }
        val index = open
        if (index != null && index in look.colors.indices) {
            key(index) {
                ColorPicker(
                    look.colors[index].toColor(),
                    onTry = { state.tryOut(replaced(state.draft, index, it)) },
                    onPick = { state.change(replaced(state.draft, index, it)) },
                    onUsual = {
                        state.change(withColors(state.draft, look.colors.filterIndexed { at, _ -> at != index }))
                        open = null
                    },
                    usualLabel = Res.string.editor_bg_remove_color,
                )
            }
        }
    }
}
