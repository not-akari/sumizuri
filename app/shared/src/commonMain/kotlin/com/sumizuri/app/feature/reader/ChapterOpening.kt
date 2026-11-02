package com.sumizuri.app.feature.reader

import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.sumizuri.app.ui.kit.image.imageRequest
import com.sumizuri.app.ui.kit.input.BackButton
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.motion.motionMs
import kotlinx.coroutines.delay

// How long a chapter or an episode may take before the card shows, so one that is quick to open never flashes it.
private const val ShowAfterMs = 90L

// How long the finish takes: the card lifts away first, then the backdrop fades and what is ready comes in under it, settling from a touch bigger. Both are done before the end, so no gray is left on the page.
private const val FinishMs = 340
private const val CardGoneAt = 0.45f
private const val BackdropFrom = 0.25f
private const val BackdropTo = 0.8f
private const val ContentFrom = 0.15f
private const val ContentTo = 0.7f
private const val ContentZoom = 0.02f
private val CardLift = 12.dp

// How soft the cover behind the card is.
private val BackdropBlur = 28.dp

// Below this height the cover on the card is smaller, and how wide a cover is for its height.
private val ShortScreen = 480.dp
private const val CoverShape = 0.7f

// How long one piece of the step bar is.
private val StepWidth = 36.dp

// How far the opening is along its way out, from nothing to gone, which the card reads to leave first.
private val LocalOpeningLeaving = staticCompositionLocalOf<() -> Float> { { 0f } }

// The opening of a chapter or an episode over what will show once it is ready. The content is made under it and stays clear until done. Then the card lifts away, the backdrop fades and the first page or the first frame comes in under it. The reader and the player share it, so both open the same way.
@Composable
internal fun OpeningLayer(done: Boolean, opening: @Composable () -> Unit, content: @Composable () -> Unit) {
    val shown by animateFloatAsState(
        if (done) 1f else 0f,
        tween(motionMs(FinishMs), easing = FastOutSlowInEasing),
        label = "opening done",
    )
    Box(Modifier.fillMaxSize()) {
        Box(
            Modifier.fillMaxSize().graphicsLayer {
                alpha = ((shown - ContentFrom) / (ContentTo - ContentFrom)).coerceIn(0f, 1f)
                scaleX = 1f + ContentZoom * (1f - shown)
                scaleY = scaleX
            },
        ) { content() }
        if (shown < 1f) {
            // The backdrop fades away after the card has started to go, which shows a video drawn apart from the app as well.
            Box(
                Modifier.fillMaxSize().graphicsLayer {
                    alpha = 1f - ((shown - BackdropFrom) / (BackdropTo - BackdropFrom)).coerceIn(0f, 1f)
                },
            ) { CompositionLocalProvider(LocalOpeningLeaving provides { shown }) { opening() } }
        }
    }
}

// What the person sees while a chapter or an episode comes in: the cover of the title across the screen, blurred and dimmed, and over it a card with the cover, the name of the chapter, the title, and under them a thin moving line or what is given in its place, such as why it failed. Nothing is written until the names are known.
@Composable
internal fun ChapterOpening(
    cover: String?,
    sourceId: String?,
    heading: String?,
    titleName: String?,
    onBack: () -> Unit,
    note: String? = null,
    // Shown at once instead of after the short wait, such as a failure.
    now: Boolean = false,
    // Keeps the card back while the screen still turns, so it comes in once on the new side.
    hold: Boolean = false,
    steps: OpeningSteps? = null,
    bottom: (@Composable () -> Unit)? = null,
) {
    var waited by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(ShowAfterMs)
        waited = true
    }
    val leaving = LocalOpeningLeaving.current
    Box(Modifier.fillMaxSize()) {
        OpeningBackdrop(cover, sourceId)
        ReadableColumn {
            Column(Modifier.fillMaxSize()) {
                Row(
                    Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    BackButton(onBack)
                }
                BoxWithConstraints(Modifier.fillMaxSize().padding(PageGutter), contentAlignment = Alignment.Center) {
                    // A short screen, such as a phone turned for a video, gets a smaller cover so the whole card fits.
                    val coverHeight = if (maxHeight < ShortScreen) 84.dp else 136.dp
                    // The card rises a little as it fades in, the way the pages settle.
                    androidx.compose.animation.AnimatedVisibility(
                        (waited && heading != null && !hold) || now,
                        Modifier.graphicsLayer {
                            val gone = (leaving() / CardGoneAt).coerceAtMost(1f)
                            alpha = 1f - gone
                            translationY = -CardLift.toPx() * gone
                            scaleX = 1f - 0.03f * gone
                            scaleY = scaleX
                        },
                        enter = fadeIn(tween(motionMs(320))) + slideInVertically(tween(motionMs(320))) { it / 12 },
                    ) {
                        OpeningCard(cover, sourceId, heading, titleName, note, coverHeight, steps, bottom)
                    }
                }
            }
        }
    }
}

@Composable
private fun OpeningCard(
    cover: String?,
    sourceId: String?,
    heading: String?,
    titleName: String?,
    note: String?,
    coverHeight: Dp,
    steps: OpeningSteps?,
    bottom: (@Composable () -> Unit)?,
) {
    val colors = MaterialTheme.colorScheme
    Column(
        Modifier.widthIn(max = 360.dp).fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        if (cover != null) {
            AsyncImage(
                imageRequest(cover, sourceId = sourceId),
                null,
                Modifier
                    .padding(
                        bottom = 14.dp,
                    ).size(width = coverHeight * CoverShape, height = coverHeight)
                    .clip(RoundedCornerShape(14.dp)),
                contentScale = ContentScale.Crop,
            )
        }
        if (heading != null) {
            Text(
                heading,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        if (!titleName.isNullOrEmpty()) {
            Text(
                titleName,
                style = MaterialTheme.typography.bodySmall,
                color = colors.onSurfaceVariant,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Box(Modifier.padding(top = 18.dp), contentAlignment = Alignment.Center) {
            when {
                bottom != null -> bottom()
                steps != null -> StepBar(steps)
                else -> MovingLine(Modifier.width(120.dp))
            }
        }
        if (note != null && bottom == null) {
            // A new step swaps its words with a short fade, so the line under the card does not jump.
            Crossfade(note, Modifier.padding(top = 6.dp), tween(motionMs(220)), label = "opening note") { words ->
                Text(
                    words,
                    style = MaterialTheme.typography.labelMedium,
                    color = colors.outline,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

// The steps of opening, such as finding the video, opening it and starting it, with the one at work now.
internal class OpeningSteps(val at: Int, val count: Int)

// One short piece per step: done ones are full, the one at work has the moving line, and the ones still to come are faint.
@Composable
private fun StepBar(steps: OpeningSteps) {
    val colors = MaterialTheme.colorScheme
    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        repeat(steps.count) { step ->
            val piece = Modifier.width(StepWidth).height(3.dp).clip(RoundedCornerShape(2.dp))
            if (step == steps.at) {
                MovingLine(piece)
            } else {
                val color by animateColorAsState(
                    if (step < steps.at) colors.primary else colors.primary.copy(alpha = 0.15f),
                    tween(motionMs(260)),
                    label = "opening step",
                )
                Box(piece.background(color))
            }
        }
    }
}

@Composable
private fun MovingLine(modifier: Modifier) {
    val colors = MaterialTheme.colorScheme
    LinearProgressIndicator(
        modifier.height(3.dp).clip(RoundedCornerShape(2.dp)),
        color = colors.primary,
        trackColor = colors.primary.copy(alpha = 0.15f),
    )
}

// The cover of the title across the whole screen behind the opening card, blurred and dimmed in the page colour, so the cover of the title page flows on into the chapter instead of going away.
@Composable
internal fun OpeningBackdrop(cover: String?, sourceId: String?) {
    val page = MaterialTheme.colorScheme.background
    Box(Modifier.fillMaxSize()) {
        if (cover != null) {
            AsyncImage(
                imageRequest(cover, sourceId = sourceId),
                null,
                Modifier.fillMaxSize().blur(BackdropBlur),
                contentScale = ContentScale.Crop,
            )
        }
        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(
                    0f to page.copy(alpha = 0.72f),
                    1f to page.copy(alpha = 0.92f),
                ),
            ),
        )
    }
}
