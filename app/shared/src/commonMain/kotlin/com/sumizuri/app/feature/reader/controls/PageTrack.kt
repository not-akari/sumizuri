package com.sumizuri.app.feature.reader.controls

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.layout
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_jump
import com.sumizuri.app.shared.resources.reader_page_of
import com.sumizuri.app.ui.kit.image.PageImages
import com.sumizuri.app.ui.kit.image.buildImageRequest
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// The address and headers of a page picture, for its small preview beside the track.
class PagePreview(val url: String, val headers: Map<String, String>)

// How wide the preview of a page is, and how far from the track it floats.
private val PreviewWidth = 92.dp
private val PreviewGap = 6.dp

// How thick the track is at rest and while held, how big the thumb is, and how much room the ends keep so the thumb is never cut.
private val Track = 4.dp
private val TrackHeld = 6.dp
private val Thumb = 7.dp
private val ThumbHeld = 10.dp
private val EndRoom = 12.dp

// Up to this many pages each get a small dot on the track.
private const val MostDots = 60

// A thin track across the pages of the chapter, along the bottom or down the side. The read part is filled, each page has a small dot when there are not too many, and a round thumb sits at the page. A press or a drag anywhere moves the thumb, a small picture of the page under it floats beside the track, and the reader goes there once the finger or the button is let go, so no page between is loaded on the way.
@Composable
fun PageTrack(
    page: Int,
    total: Int,
    vertical: Boolean,
    preview: (Int) -> PagePreview?,
    onJump: (Int) -> Unit,
    modifier: Modifier = Modifier,
    // The thumb is a small tag with the page and the count in it, so the number rides along the track.
    tagged: Boolean = false,
) {
    var held by remember { mutableStateOf<Float?>(null) }
    val last = (total - 1).coerceAtLeast(1)
    val fraction = held ?: (page.toFloat() / last).coerceIn(0f, 1f)
    val grip by animateFloatAsState(if (held != null) 1f else 0f)
    val colors = MaterialTheme.colorScheme
    val description = stringResource(Res.string.reader_jump)
    // The newest jump and count, since the gesture below lives across many recompositions.
    val jump by rememberUpdatedState(onJump)
    val lastNow by rememberUpdatedState(last)
    BoxWithConstraints(modifier.then(if (vertical) Modifier.width(36.dp) else Modifier.height(36.dp))) {
        val length = (if (vertical) constraints.maxHeight else constraints.maxWidth).toFloat()
        Canvas(
            Modifier
                .matchParentSize()
                .semantics {
                    contentDescription = description
                    progressBarRangeInfo =
                        ProgressBarRangeInfo(page.toFloat(), 0f..last.toFloat(), (last - 1).coerceAtLeast(0))
                    setProgress { target ->
                        onJump(target.roundToInt().coerceIn(0, last))
                        true
                    }
                }.pointerInput(total, vertical, length) {
                    val room = EndRoom.toPx()
                    fun at(spot: Offset): Float =
                        (((if (vertical) spot.y else spot.x) - room) / (length - room * 2)).coerceIn(0f, 1f)
                    awaitEachGesture {
                        val down = awaitFirstDown()
                        down.consume()
                        held = at(down.position)
                        while (true) {
                            val change = awaitPointerEvent().changes.firstOrNull { it.id == down.id } ?: break
                            if (!change.pressed) break
                            change.consume()
                            held = at(change.position)
                        }
                        held?.let { jump((it * lastNow).roundToInt()) }
                        held = null
                    }
                },
        ) {
            val room = EndRoom.toPx()
            val middle = if (vertical) size.width / 2 else size.height / 2
            fun point(share: Float): Offset {
                val along = room + share * (length - room * 2)
                return if (vertical) Offset(middle, along) else Offset(along, middle)
            }
            val thickness = (Track + (TrackHeld - Track) * grip).toPx()
            drawLine(colors.surfaceContainerHighest, point(0f), point(1f), thickness, StrokeCap.Round)
            drawLine(colors.primary, point(0f), point(fraction), thickness, StrokeCap.Round)
            if (total in 2..MostDots) {
                val dot = thickness / 4
                for (each in 0 until total) {
                    val share = each.toFloat() / last
                    val shade = if (share <=
                        fraction
                    ) {
                        colors.onPrimary.copy(alpha = 0.55f)
                    } else {
                        colors.onSurfaceVariant.copy(alpha = 0.5f)
                    }
                    drawCircle(shade, dot, point(share))
                }
            }
            if (!tagged || held != null) {
                val knob = (Thumb + (ThumbHeld - Thumb) * grip).toPx()
                drawCircle(colors.surface, knob + 2.dp.toPx(), point(fraction))
                drawCircle(colors.primary, knob, point(fraction))
            }
        }
        if (tagged && held == null) {
            Box(Modifier.centerOn(fraction, length, EndRoom)) { PageTag(page, total) }
        }
        val at = held?.let { (it * last).roundToInt() }
        AnimatedVisibility(
            at != null,
            Modifier.floatBeside(fraction, length, vertical, EndRoom),
            enter = fadeIn() + scaleIn(initialScale = 0.85f),
            exit = fadeOut() + scaleOut(targetScale = 0.9f),
        ) {
            val shown = at ?: page
            Bubble(shown, preview(shown))
        }
    }
}

// Draws the bubble above a track along the bottom, or to the left of a track down the side, with its middle at the thumb and kept inside the track at both ends. It takes no room, so nothing moves while it shows.
private fun Modifier.floatBeside(fraction: Float, length: Float, vertical: Boolean, endRoom: Dp): Modifier =
    layout { measurable, _ ->
        val bubble = measurable.measure(Constraints())
        layout(0, 0) {
            val room = endRoom.toPx()
            val along = room + fraction * (length - room * 2)
            val gap = PreviewGap.roundToPx()
            if (vertical) {
                val y = (along - bubble.height / 2f).roundToInt().coerceIn(
                    0,
                    (length - bubble.height).roundToInt().coerceAtLeast(0),
                )
                bubble.place(-bubble.width - gap, y)
            } else {
                val x = (along - bubble.width / 2f).roundToInt().coerceIn(
                    0,
                    (length - bubble.width).roundToInt().coerceAtLeast(0),
                )
                bubble.place(x, -bubble.height - gap)
            }
        }
    }

// Puts a tag on a track along the bottom with its middle at the thumb, kept inside the track at both ends. It takes no room.
private fun Modifier.centerOn(fraction: Float, length: Float, endRoom: Dp): Modifier =
    layout { measurable, constraints ->
        val tag = measurable.measure(Constraints())
        layout(0, 0) {
            val room = endRoom.toPx()
            val along = room + fraction * (length - room * 2)
            val x = (along - tag.width / 2f).roundToInt().coerceIn(
                0,
                (length - tag.width).roundToInt().coerceAtLeast(0),
            )
            tag.place(x, (constraints.maxHeight - tag.height) / 2)
        }
    }

// The page and the count in a small filled tag, which stands for the thumb of a tagged track.
@Composable
private fun PageTag(page: Int, total: Int) {
    Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primary, shadowElevation = 2.dp) {
        Text(
            stringResource(Res.string.reader_page_of, page + 1, total),
            Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onPrimary,
        )
    }
}

@Composable
private fun Bubble(page: Int, preview: PagePreview?) {
    val context = LocalPlatformContext.current
    Surface(
        Modifier.width(PreviewWidth),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        shadowElevation = 8.dp,
    ) {
        Column(
            Modifier.padding(4.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            if (preview != null) {
                val request = remember(preview.url) { buildImageRequest(context, preview.url, preview.headers) }
                Box(Modifier.fillMaxWidth().aspectRatio(0.7f).clip(MaterialTheme.shapes.small)) {
                    AsyncImage(
                        request,
                        null,
                        PageImages.get(context),
                        Modifier.fillMaxWidth().aspectRatio(0.7f),
                        contentScale = ContentScale.Crop,
                    )
                }
            }
            Text((page + 1).toString(), style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold)
        }
    }
}
