package com.sumizuri.app.ui.kit.image

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.FilterQuality
import coil3.PlatformContext
import coil3.compose.LocalPlatformContext
import coil3.network.NetworkHeaders
import coil3.network.httpHeaders
import coil3.request.ImageRequest
import coil3.request.crossfade
import coil3.request.maxBitmapSize
import coil3.size.Dimension
import coil3.size.Precision
import coil3.size.Size
import com.sumizuri.app.data.net.SiteKinds
import com.sumizuri.app.source.repo.BrowserPictureHeaders

// The start of an address up to its host, made once.
private val OriginPattern = Regex("^(https?://[^/]+)")

// Many sites refuse a picture asked for from elsewhere, so the request names the picture's own site as the referrer unless the source says otherwise.
@Composable
fun imageRequest(
    url: String,
    extra: Map<String, String> = emptyMap(),
    original: Boolean = false,
    maxWidth: Int? = null,
    sourceId: String? = null,
): ImageRequest {
    val context = LocalPlatformContext.current
    // The site of the source wins over the picture's own host, and what the source asks for wins over both.
    val site = SourceReferers.of(sourceId)
    // The host of the picture takes the way of the kind of its source.
    remember(url, sourceId) { SiteKinds.markFor(url, sourceId) }
    val headers = remember(extra, site) {
        if (site == null ||
            extra.keys.any { it.equals("Referer", ignoreCase = true) }
        ) {
            extra
        } else {
            mapOf("Referer" to site) + extra
        }
    }
    // Kept while the address and the choices stay the same, so a cover that is drawn again does not build its request again.
    return remember(context, url, headers, original, maxWidth) {
        buildImageRequest(context, url, headers, original, maxWidth)
    }
}

// The same request for code that runs outside of composition, such as loading pages ahead of the reader.
fun buildImageRequest(
    context: PlatformContext,
    url: String,
    extra: Map<String, String> = emptyMap(),
    original: Boolean = false,
    maxWidth: Int? = null,
): ImageRequest {
    val origin = OriginPattern.find(url)?.value
    val headers = NetworkHeaders
        .Builder()
        .apply {
            if (origin != null) add("Referer", "$origin/")
            BrowserPictureHeaders.forEach { (name, value) -> set(name, value) }
            // What the source asks for wins, including its own referrer.
            extra.forEach { (name, value) -> set(name, value) }
        }.build()
    return ImageRequest
        .Builder(context)
        .data(url)
        .httpHeaders(headers)
        .crossfade(true)
        // A page of a chapter is read at the size it came in, and is never cut down to fit the view or the usual size limit.
        .apply {
            if (original) {
                // A page wider than the limit of the quality is brought down to it, and its height follows. A page is only ever brought down to the limit, never made bigger. With an exact size, a strip narrower than the limit would be stretched to it, which is a bitmap many times the size of the page.
                size(
                    if (maxWidth ==
                        null
                    ) {
                        Size.ORIGINAL
                    } else {
                        Size(Dimension(maxWidth), Dimension.Undefined)
                    },
                ).precision(Precision.INEXACT).maxBitmapSize(Size.ORIGINAL)
            }
        }.build()
}

// How every picture is drawn, with the best filter, so a big picture shown small keeps clean edges and does not look jagged.
val ImageFilter = FilterQuality.High

// How a picture takes the room it is given. It fits whole inside it, fills its width, fills its height, or keeps its own pixels.
enum class ImageFit { Screen, Width, Height, Original }

// The site of each installed source, sent as the referrer for its covers, since many picture hosts only answer their own site. Kept as state so covers drawn before the sources load ask again with it.
object SourceReferers {
    var bySource: Map<String, String> by mutableStateOf(emptyMap())

    fun of(sourceId: String?): String? = sourceId?.takeIf { it.isNotEmpty() }?.let { bySource[it] }
}
