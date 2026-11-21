package com.sumizuri.app.feature.reader.controls

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.reader.ReaderBackground
import com.sumizuri.app.data.text.localOffsetMillis
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_brightness
import com.sumizuri.app.shared.resources.reader_warmth
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.text.percentText
import com.sumizuri.app.ui.theme.FixedColors
import kotlinx.coroutines.delay

// Two sliders, how bright the screen is and how warm, each with its icon and its number. The page changes as they move and the choice is kept when they are let go.
@Composable
fun LightPanel(
    dim: Float,
    warmth: Float,
    onLight: (dim: Float, warmth: Float) -> Unit,
    onDone: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier.padding(horizontal = 14.dp, vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        // The slider shows brightness, which is the opposite of how much the screen is dimmed.
        SliderSetting(Res.string.reader_brightness, 1f - dim, 0f..1f, {
            percentText(it)
        }, onMove = { onLight(1f - it, warmth) }) { onDone() }
        SliderSetting(Res.string.reader_warmth, warmth, 0f..1f, {
            percentText(it)
        }, onMove = { onLight(dim, it) }) { onDone() }
    }
}

// How strong the amber tint is at its fullest.
private const val WarmestTint = 0.4f

// How dark the screen gets at its fullest.
private const val DarkestDim = 0.85f

// The dark layer and the amber layer laid over the pages. Neither takes a touch, so the page under them still answers.
@Composable
fun ReaderLight(dim: Float, warmth: Float, modifier: Modifier = Modifier) {
    if (warmth > 0f) Box(modifier.fillMaxSize().background(FixedColors.WarmLight.copy(alpha = warmth * WarmestTint)))
    if (dim > 0f) Box(modifier.fillMaxSize().background(Color.Black.copy(alpha = dim * DarkestDim)))
}

// What is drawn behind the pages. The theme gives its own background when none was chosen.
@Composable
fun ReaderBackground.fill(): Color = color?.let { Color(it) } ?: MaterialTheme.colorScheme.background

// The color of text on that background, light on a dark one and dark on a light one.
@Composable
fun ReaderBackground.ink(): Color = when {
    color == null -> MaterialTheme.colorScheme.onBackground
    dark -> FixedColors.InkOnDark
    else -> FixedColors.InkOnLight
}

// Whether the bedtime hours are on now, looked at again each minute. From and to are hours of the day, and hours that run past midnight work too.
@Composable
fun rememberBedtime(on: Boolean, from: Int, to: Int): State<Boolean> = produceState(false, on, from, to) {
    if (!on || from == to) {
        value = false
        return@produceState
    }
    while (true) {
        val now = nowMillis()
        val hour = (((now + localOffsetMillis(now)) / 3_600_000L) % 24).toInt()
        value = if (from < to) hour in from until to else hour >= from || hour < to
        delay(60_000L)
    }
}
