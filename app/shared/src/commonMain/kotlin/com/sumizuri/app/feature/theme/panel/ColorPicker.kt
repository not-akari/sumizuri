package com.sumizuri.app.feature.theme.panel

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.PointerInputScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_color_hex
import com.sumizuri.app.shared.resources.editor_color_reset
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.theme.hsvOf
import com.sumizuri.app.ui.theme.spec.toColor
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

private const val HexDigits = "0123456789abcdefABCDEF"

// The colors of the hue strip, once round the color wheel.
private val Hues = (0..6).map { Color.hsv(it * 60f % 360f, 1f, 1f) }

// A color picker that sits in the page under the color it changes, so the preview stays in sight: a square for how strong and how bright, a strip for the hue, the six hex digits and a way back to the usual color, or another way out such as taking the color away. Dragging shows the color on the preview at once, and letting go keeps it as one change.
@Composable
internal fun ColorPicker(
    color: Color,
    onTry: (Color) -> Unit,
    onPick: (Color) -> Unit,
    onUsual: () -> Unit,
    usualLabel: StringResource = Res.string.editor_color_reset,
) {
    // The presses below are set up once, so they call whatever was given last.
    val tryColor by rememberUpdatedState(onTry)
    val pickColor by rememberUpdatedState(onPick)
    var hue by remember { mutableFloatStateOf(hsvOf(color).first) }
    var saturation by remember { mutableFloatStateOf(hsvOf(color).second) }
    var value by remember { mutableFloatStateOf(hsvOf(color).third) }
    val shown = Color.hsv(hue, saturation, value)
    // A color changed from outside, by an undo or a fix, moves the marks to it. The hue stays put for grays, which have none.
    LaunchedEffect(color) {
        if (color != shown) {
            val (h, s, v) = hsvOf(color)
            if (s > 0f && v > 0f) hue = h
            saturation = s
            value = v
        }
    }
    var text by remember { mutableStateOf(hexOf(color)) }
    LaunchedEffect(shown) { text = hexOf(shown) }
    val shape = RoundedCornerShape(12.dp)
    val outline = MaterialTheme.colorScheme.outlineVariant
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(150.dp)
                .clip(shape)
                .background(Color.hsv(hue, 1f, 1f))
                .background(Brush.horizontalGradient(listOf(Color.White, Color.Transparent)))
                .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black)))
                .border(1.dp, outline, shape)
                .drawWithContent {
                    drawContent()
                    val at = Offset(saturation * size.width, (1f - value) * size.height)
                    drawCircle(Color.White, 9.dp.toPx(), at, style = Stroke(3.dp.toPx()))
                    drawCircle(Color.Black.copy(alpha = 0.4f), 10.5.dp.toPx(), at, style = Stroke(1.dp.toPx()))
                }.pointerInput(Unit) {
                    trackPress(onMove = { at ->
                        saturation = (at.x / size.width).coerceIn(0f, 1f)
                        value = 1f - (at.y / size.height).coerceIn(0f, 1f)
                        tryColor(Color.hsv(hue, saturation, value))
                    }, onEnd = { pickColor(Color.hsv(hue, saturation, value)) })
                },
        )
        Box(
            Modifier
                .fillMaxWidth()
                .height(24.dp)
                .clip(shape)
                .background(Brush.horizontalGradient(Hues))
                .border(1.dp, outline, shape)
                .drawWithContent {
                    drawContent()
                    val x = hue / 360f * size.width
                    drawCircle(
                        Color.White,
                        size.height / 2 - 2.dp.toPx(),
                        Offset(x, size.height / 2),
                        style = Stroke(3.dp.toPx()),
                    )
                }.pointerInput(Unit) {
                    trackPress(onMove = { at ->
                        hue = (at.x / size.width).coerceIn(0f, 1f) * 359.9f
                        tryColor(Color.hsv(hue, saturation, value))
                    }, onEnd = { pickColor(Color.hsv(hue, saturation, value)) })
                },
        )
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            AppTextField(
                text,
                { input ->
                    // Only hex digits are kept, so a pasted #3D8BFF works as well.
                    text = input.filter { it in HexDigits }.take(6).uppercase()
                    if (text.length == 6) text.toLongOrNull(16)?.let { rgb -> onPick((0xFF000000 or rgb).toColor()) }
                },
                Modifier.weight(1f),
                label = { Text(stringResource(Res.string.editor_color_hex)) },
                prefix = { Text("#") },
                singleLine = true,
            )
            TextButton(onUsual) { Text(stringResource(usualLabel)) }
        }
    }
}

// Follows one press from where it lands until it lets go, keeping the moves to itself so the page around does not scroll.
private suspend fun PointerInputScope.trackPress(onMove: (Offset) -> Unit, onEnd: () -> Unit) {
    awaitEachGesture {
        val down = awaitFirstDown()
        down.consume()
        onMove(down.position)
        drag(down.id) { change ->
            change.consume()
            onMove(change.position)
        }
        onEnd()
    }
}
