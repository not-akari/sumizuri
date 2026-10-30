package com.sumizuri.app.feature.title.layout

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import coil3.compose.AsyncImage
import coil3.request.crossfade
import coil3.size.Scale
import coil3.size.Size
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.rememberTitleFocus
import com.sumizuri.app.ui.kit.cover.coverDrift
import com.sumizuri.app.ui.kit.cover.focus.focusAlignment
import com.sumizuri.app.ui.kit.cover.focus.rememberSoftCover
import com.sumizuri.app.ui.kit.cover.rememberCoverPalette
import com.sumizuri.app.ui.kit.image.ImageFilter
import com.sumizuri.app.ui.kit.image.imageRequest
import kotlin.math.ceil
import kotlin.math.max

// Where along the cover, from its left edge, it starts to melt into the page.
private const val SharpFadeFrom = 0.86f

// How strong the wash of the page color is over the text, and how much of the soft copy of the cover shows through it, so only a little blur is seen.
private const val WashStrong = 0.8f
private const val SoftShown = 0.5f
private const val SoftInMs = 400

// How strong the light in the colors of the cover is in dark and light mode, and how long it takes to come in.
private const val GlowDark = 0.34f
private const val GlowLight = 0.22f
private const val GlowInMs = 500

// The cover is read at its size on the screen in steps of this many pixels, so a window made bigger reads it again, sharper, and a small change does not.
private const val SizeStep = 256

// The art behind the whole wide page. The sharp cover stands at full height on the left in its own shape and melts into the page at its right edge, over a faint soft copy of it, and a wash of the page color lies over the rest where the text is. A tall cover is never stretched to fill the window. The cover opens in full on a tap.
@Composable
internal fun SplitArt(
    title: Title,
    picked: Pair<Float, Float>?,
    cover: Dp,
    textStart: Dp,
    onPreview: () -> Unit,
    onAspect: (Float) -> Unit,
    modifier: Modifier = Modifier,
) {
    val page = MaterialTheme.colorScheme.background
    val url = title.coverUrl
    BoxWithConstraints(modifier) {
        val wide = maxWidth.value.coerceAtLeast(1f)
        if (url.isNullOrBlank()) {
            // The colors of the title stand in for a title that has no cover.
            Box(
                Modifier.fillMaxSize().background(
                    Brush.linearGradient(
                        listOf(Color.hsv(title.hue, 0.42f, 0.42f), Color.hsv((title.hue + 28f) % 360f, 0.55f, 0.22f)),
                    ),
                ),
            )
        } else {
            val request = imageRequest(url, sourceId = title.sourceId)
            val soft = rememberSoftCover(request)
            val focus = rememberTitleFocus(url, picked)
            // The faint copy starts where the cover melts, so the room of the cover stays dark while the cover flies in, and it eases in once read.
            val shown by animateFloatAsState(if (soft != null) SoftShown else 0f, tween(SoftInMs))
            if (soft != null) {
                Image(
                    soft,
                    null,
                    Modifier.fillMaxSize().padding(start = cover * SharpFadeFrom * 0.85f),
                    contentScale = ContentScale.Crop,
                    alpha = shown,
                    filterQuality = FilterQuality.High,
                )
            }
            BoxWithConstraints(
                Modifier
                    .align(Alignment.TopStart)
                    .width(cover)
                    .fillMaxHeight()
                    .fadeOutEnd(SharpFadeFrom)
                    .clickable(onClick = onPreview),
            ) {
                // The biggest size the cover has had, so it is read again only when it grows.
                var asked by remember(url) { mutableIntStateOf(0) }
                val now = max(stepUp(constraints.maxWidth), stepUp(constraints.maxHeight))
                if (now > asked) asked = now
                val sized = remember(request, asked) {
                    // The picture already read for the library shows at once while the sharp one is read, and the sharp one takes its place with no fade, so the cover never fades in after it lands.
                    request
                        .newBuilder()
                        .size(Size(asked, asked))
                        .scale(Scale.FILL)
                        .placeholderMemoryCacheKey(request.memoryCacheKey ?: url)
                        .crossfade(false)
                        .build()
                }
                AsyncImage(
                    model = sized,
                    contentDescription = null,
                    modifier = Modifier
                        .fillMaxSize()
                        .clipToBounds()
                        .coverDrift(),
                    contentScale = ContentScale.Crop,
                    alignment = focusAlignment(focus, maxWidth.value, maxHeight.value, fallbackY = -1f),
                    filterQuality = ImageFilter,
                    // The page sizes the cover by its own shape once it is known.
                    onSuccess = { loaded ->
                        val size = loaded.painter.intrinsicSize
                        if (size.width > 0f && size.height > 0f) onAspect(size.width / size.height)
                    },
                )
            }
        }
        // The wash of the page color, clear over the cover, rising on an eased curve where the cover melts, and strong from where the words begin to the right edge.
        val from = (cover.value * SharpFadeFrom * 0.85f / wide).coerceIn(0f, 0.9f)
        val full = (textStart.value / wide).coerceIn(from + 0.02f, 0.98f)
        val rise = (0..6).map { step ->
            val along = step / 6f
            (from + (full - from) * along) to page.copy(alpha = WashStrong * along * along * (3f - 2f * along))
        }
        Box(
            Modifier.fillMaxSize().background(
                Brush.horizontalGradient(
                    *(
                        listOf(0f to page.copy(alpha = 0f)) + rise +
                            (1f to page.copy(alpha = WashStrong))
                        ).toTypedArray(),
                ),
            ),
        )
        if (!url.isNullOrBlank()) CoverGlow(url, page.luminance() < 0.5f, Modifier.fillMaxSize())
    }
}

// Soft light in the colors of the cover over the side with the text, its main color from the top right and its second from the bottom, so the whole page carries the cover and not only the part behind it. It eases in once the colors are known.
@Composable
private fun CoverGlow(url: String, dark: Boolean, modifier: Modifier) {
    val palette by rememberCoverPalette(url)
    val shown by animateFloatAsState(if (palette != null) 1f else 0f, tween(GlowInMs))
    val colors = palette?.colors ?: return
    val main = colors.first()
    val second = colors.getOrElse(1) { main }
    val strength = if (dark) GlowDark else GlowLight
    Box(
        modifier.drawBehind {
            val reach = max(size.width, size.height)
            drawRect(
                Brush.radialGradient(
                    listOf(main.copy(alpha = strength * shown), Color.Transparent),
                    center = Offset(size.width * 0.82f, size.height * 0.08f),
                    radius = reach * 0.6f,
                ),
            )
            drawRect(
                Brush.radialGradient(
                    listOf(second.copy(alpha = strength * 0.75f * shown), Color.Transparent),
                    center = Offset(size.width * 0.66f, size.height * 1.02f),
                    radius = reach * 0.55f,
                ),
            )
        },
    )
}

// A size rounded up to the next step.
private fun stepUp(px: Int): Int = (ceil(px / SizeStep.toFloat()) * SizeStep).toInt().coerceAtLeast(SizeStep)

// Fades the right side out to clear from a point along the width, on an eased curve so no edge can be seen where it ends.
private fun Modifier.fadeOutEnd(from: Float): Modifier = this
    .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
    .drawWithContent {
        drawContent()
        val stops = (0..8).map { step ->
            val along = step / 8f
            // The eased curve, flat at both ends.
            val eased = along * along * (3f - 2f * along)
            (from + (1f - from) * along) to Color.Black.copy(alpha = 1f - eased)
        }
        drawRect(
            brush = Brush.horizontalGradient(*(listOf(0f to Color.Black) + stops).toTypedArray()),
            blendMode = BlendMode.DstIn,
        )
    }
