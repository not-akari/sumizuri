package com.sumizuri.app.ui.kit.cover

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.compose.LocalPlatformContext
import coil3.request.ImageRequest
import coil3.request.SuccessResult
import coil3.size.Precision
import com.sumizuri.app.ui.kit.cover.focus.CoverPixels
import com.sumizuri.app.ui.kit.cover.focus.argbPixels
import com.sumizuri.app.ui.kit.cover.focus.cpuReadable
import com.sumizuri.app.ui.kit.cover.focus.toImageBitmap
import com.sumizuri.app.ui.kit.image.imageRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

// How many soft covers are kept while the app runs before the store starts again.
private const val KeptMost = 64

// How far each pass of the blur reaches, in pixels of the small cover. A few passes of a box come close to a smooth blur.
private const val BlurReach = 3

// The soft covers made so far, so a cover is made soft once. It is used from the main thread only.
private val made = HashMap<String, ImageBitmap>()

// A cover drawn soft, as if blurred, for behind other things. It is loaded a few pixels big, blurred once at that size, and stretched with smooth filtering, which looks like a blur but costs nothing to draw, unlike a real blur that is worked out again on every frame.
@Composable
fun SoftCover(
    url: String,
    sourceId: String?,
    modifier: Modifier = Modifier,
    width: Int = 32,
    height: Int = 48,
    alignment: Alignment = Alignment.Center,
    // How many times the small cover is blurred, fewer for a lighter blur.
    passes: Int = 3,
) {
    val context = LocalPlatformContext.current
    val request = imageRequest(url, sourceId = sourceId)
    val key = "$width $passes $url"
    val soft by produceState(made[key], key) {
        if (value != null) return@produceState
        val small = request
            .newBuilder()
            .size(width, height)
            .precision(Precision.EXACT)
            // A key of its own, so the full cover kept in memory is not given back in its place.
            .memoryCacheKey("$url#soft$width")
            .cpuReadable()
            .build()
        val picture = softPicture(context, small, passes) ?: return@produceState
        if (made.size >= KeptMost) made.clear()
        made[key] = picture
        value = picture
    }
    val picture = soft
    if (picture == null) {
        Box(modifier)
    } else {
        Image(picture, null, modifier, alignment, ContentScale.Crop, filterQuality = FilterQuality.High)
    }
}

// Loads the small cover and blurs it, or null when it cannot be read.
private suspend fun softPicture(context: PlatformContext, request: ImageRequest, passes: Int): ImageBitmap? {
    val image = (SingletonImageLoader.get(context).execute(request) as? SuccessResult)?.image ?: return null
    return withContext(Dispatchers.Default) {
        val pixels = image.argbPixels() ?: return@withContext null
        repeat(passes) { blurOnce(pixels) }
        pixels.toImageBitmap()
    }
}

// Blurs the colors in place with a box across, then a box down, keeping the edges by repeating the last pixel.
private fun blurOnce(pixels: CoverPixels) {
    val w = pixels.width
    val h = pixels.height
    val from = pixels.argb
    val across = IntArray(from.size)
    for (y in 0 until h) {
        for (x in 0 until w) across[y * w + x] = average(w, x) { from[y * w + it] }
    }
    for (x in 0 until w) {
        for (y in 0 until h) from[y * w + x] = average(h, y) { across[it * w + x] }
    }
}

// The average color of the pixels within reach of one place along a line of the given length.
private inline fun average(length: Int, at: Int, pixel: (Int) -> Int): Int {
    var a = 0
    var r = 0
    var g = 0
    var b = 0
    val count = BlurReach * 2 + 1
    for (step in -BlurReach..BlurReach) {
        val c = pixel((at + step).coerceIn(0, length - 1))
        a += (c ushr 24) and 0xFF
        r += (c shr 16) and 0xFF
        g += (c shr 8) and 0xFF
        b += c and 0xFF
    }
    return ((a / count) shl 24) or ((r / count) shl 16) or ((g / count) shl 8) or (b / count)
}
