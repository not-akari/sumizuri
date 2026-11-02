package com.sumizuri.app.playback

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.skiaCanvas
import org.jetbrains.skia.FilterMipmap
import org.jetbrains.skia.FilterMode
import org.jetbrains.skia.FilterTileMode
import org.jetbrains.skia.ImageFilter
import org.jetbrains.skia.MipmapMode
import org.jetbrains.skia.Paint
import org.jetbrains.skia.Rect

actual val touchPlayer: Boolean = false

// How soft the copy of the picture in the bars is, and how much it is darkened so the picture stays the brightest part.
private const val BlurSigma = 48f
private const val BackdropDim = 0.45f

// A desktop window keeps its shape and the computer is left to its own sleep.
@Composable
actual fun PlayerWindow() = Unit

@Composable
actual fun PlayerSystemUi(keepOn: Boolean) = Unit

@Composable
actual fun rememberPlayerEngine(style: SubtitleStyle): PlayerEngine {
    val engine = remember { MpvEngine(style) }
    DisposableEffect(engine) { onDispose { engine.release() } }
    return engine
}

@Composable
actual fun PlayerSurface(engine: PlayerEngine, aspect: AspectMode, modifier: Modifier) {
    val mpv = engine as? MpvEngine ?: return
    val lit by mpv.lit.collectAsState()
    val soft =
        remember { Paint().apply { imageFilter = ImageFilter.makeBlur(BlurSigma, BlurSigma, FilterTileMode.CLAMP) } }
    Canvas(modifier.background(Color.Black)) {
        val image = mpv.frame.value ?: return@Canvas
        val picture = image.width.toFloat() / image.height
        val space = size.width / size.height
        // The part of the picture shown and the part of the space it is drawn in, by how the picture fills the space.
        var source = Rect.makeWH(image.width.toFloat(), image.height.toFloat())
        var target = Rect.makeWH(size.width, size.height)
        when (aspect) {
            AspectMode.Fit -> {
                val wide = if (picture > space) size.width else size.height * picture
                val high = if (picture > space) size.width / picture else size.height
                target = Rect.makeXYWH((size.width - wide) / 2, (size.height - high) / 2, wide, high)
            }

            AspectMode.Fill -> {
                val wide = if (picture > space) image.height * space else image.width.toFloat()
                val high = if (picture > space) image.height.toFloat() else image.width / space
                source = Rect.makeXYWH((image.width - wide) / 2, (image.height - high) / 2, wide, high)
            }

            AspectMode.Stretch -> Unit
        }
        // The bars show the picture itself, grown to fill the space, blurred and darkened, so they glow in the colors of the scene.
        if (lit && (target.width < size.width - 1 || target.height < size.height - 1)) {
            val grow = maxOf(size.width / image.width, size.height / image.height)
            val wide = image.width * grow
            val high = image.height * grow
            val around = Rect.makeXYWH((size.width - wide) / 2, (size.height - high) / 2, wide, high)
            drawIntoCanvas {
                it.skiaCanvas.drawImageRect(
                    image,
                    Rect.makeWH(image.width.toFloat(), image.height.toFloat()),
                    around,
                    soft,
                )
            }
            drawRect(Color.Black.copy(alpha = BackdropDim))
        }
        drawIntoCanvas { canvas ->
            canvas.skiaCanvas.drawImageRect(
                image,
                source,
                target,
                FilterMipmap(FilterMode.LINEAR, MipmapMode.NONE),
                null,
                true,
            )
        }
        // The frames before this one are freed now, on the thread that draws, as none of them is drawn again.
        mpv.drawn(image)
    }
}
