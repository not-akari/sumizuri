package com.sumizuri.app.ui.kit.cover

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import coil3.request.ImageRequest
import coil3.request.crossfade
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.ui.kit.image.ImageFilter
import com.sumizuri.app.ui.kit.image.imageRequest
import com.sumizuri.app.ui.theme.LocalThemeSpec

// The cover picture over a painted stand in. The paint shows while the picture loads and when there is none. The shape is two wide for three high unless another is asked for, and the picture is cut to it around the point that is asked for.
@Composable
fun CoverArt(
    title: Title,
    modifier: Modifier = Modifier,
    letterSize: Int = 34,
    aspect: Float = LocalThemeSpec.current.options.covers.aspect.ratio,
    alignment: Alignment = Alignment.Center,
    // A title whose cover shows while this one is read, such as the cover of a show while the poster of one of its seasons comes.
    standIn: Title? = null,
) {
    // The stand in paint is made once for its color. Its letter is left out once the picture is there, since the picture covers it.
    val paint =
        remember(title.hue) {
            Brush.verticalGradient(
                listOf(Color.hsv(title.hue, 0.42f, 0.62f), Color.hsv((title.hue + 28f) % 360f, 0.55f, 0.30f)),
            )
        }
    val url = title.coverUrl
    var shown by remember(url) { mutableStateOf(false) }
    val behind = standIn?.coverUrl?.takeIf { it.isNotBlank() && it != url }
    var behindShown by remember(behind) { mutableStateOf(false) }
    val theme = LocalThemeSpec.current
    val shape = theme.shapes.cover.toShape()
    Box(
        modifier
            .aspectRatio(aspect)
            .then(if (theme.options.effects.coverShadow) Modifier.shadow(6.dp, shape) else Modifier)
            .clip(shape)
            .background(paint)
            .then(
                if (theme.options.covers.coverBorder) {
                    Modifier.border(
                        BorderStroke(theme.shapes.borderWidth.dp, MaterialTheme.colorScheme.outlineVariant),
                        shape,
                    )
                } else {
                    Modifier
                },
            ),
        contentAlignment = Alignment.Center,
    ) {
        if (!shown && !behindShown) {
            Text(
                title.name.firstOrNull()?.toString() ?: "?",
                color = Color.White.copy(alpha = 0.55f),
                fontSize = letterSize.sp,
                fontWeight = FontWeight.Bold,
            )
        }
        if (behind != null && !shown) {
            AsyncImage(
                model = noFade(imageRequest(behind, sourceId = standIn.sourceId)),
                contentDescription = null,
                modifier = Modifier.matchParentSize(),
                contentScale = ContentScale.Crop,
                alignment = alignment,
                filterQuality = ImageFilter,
                onSuccess = { behindShown = true },
            )
        }
        if (!url.isNullOrBlank()) {
            AsyncImage(
                model = noFade(imageRequest(url, sourceId = title.sourceId)),
                contentDescription = title.name,
                modifier = Modifier.matchParentSize(),
                contentScale = ContentScale.Crop,
                alignment = alignment,
                filterQuality = ImageFilter,
                onSuccess = { shown = true },
                onError = { shown = false },
            )
        }
    }
}

// The same request with no fade, so a cover that comes in while a grid scrolls is drawn once and not on every frame of a fade. It is kept, so the request is not made again on each drawing.
@Composable
private fun noFade(request: ImageRequest): ImageRequest =
    remember(request) { request.newBuilder().crossfade(false).build() }
