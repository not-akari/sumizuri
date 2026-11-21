package com.sumizuri.app.setup

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.softFill
import org.jetbrains.compose.resources.stringResource

// A wide soft bar that fills with the work, with a light that runs along the filled part while it goes on. With no share known it runs along the whole bar.
@Composable
internal fun InstallBar(progress: Float?, modifier: Modifier = Modifier) {
    val fill by animateFloatAsState(progress ?: 1f, tween(500), label = "fill")
    val run by rememberInfiniteTransition(label = "shine").animateFloat(
        0f,
        1f,
        infiniteRepeatable(tween(1_600, easing = LinearEasing)),
        label = "run",
    )
    val accent = MaterialTheme.colorScheme.primary
    val track = softFill(strong = true)
    Canvas(modifier.fillMaxWidth().height(12.dp).clip(CircleShape)) {
        val round = CornerRadius(size.height / 2)
        drawRoundRect(track, cornerRadius = round)
        val width = size.width * fill.coerceIn(0f, 1f)
        if (width <= 0f) return@Canvas
        drawRoundRect(if (progress == null) track else accent, size = Size(width, size.height), cornerRadius = round)
        // The light is a soft band a third as wide as the bar, running from the start of the fill to its end.
        val band = size.width / 3
        val left = -band + (width + band) * run
        drawRoundRect(
            Brush.horizontalGradient(
                listOf(
                    Color.Transparent,
                    Color.White.copy(
                        alpha = if (progress ==
                            null
                        ) {
                            0.35f
                        } else {
                            0.28f
                        },
                    ),
                    Color.Transparent,
                ),
                startX = left,
                endX = left + band,
            ),
            topLeft = Offset(0f, 0f),
            size = Size(width, size.height),
            cornerRadius = round,
        )
    }
}

// The parts of the work as small chips that turn when one runs and get a tick once it is done.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun PhaseChips(phases: Map<SetupPhase, PhaseState>, modifier: Modifier = Modifier) {
    FlowRow(
        modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        for (phase in phases.keys.sortedBy { it.ordinal }) PhaseChip(phase, phases[phase] ?: PhaseState.Waiting)
    }
}

@Composable
private fun PhaseChip(phase: SetupPhase, state: PhaseState) {
    val colors = MaterialTheme.colorScheme
    val back by animateColorAsState(
        when (state) {
            PhaseState.Running -> softFill(strong = true)
            PhaseState.Done -> colors.primary.copy(alpha = 0.16f)
            PhaseState.Waiting -> softFill()
        },
        label = "chip",
    )
    val text by animateColorAsState(
        when (state) {
            PhaseState.Running -> colors.onSurface
            PhaseState.Done -> colors.primary
            PhaseState.Waiting -> colors.outline
        },
        label = "chip text",
    )
    Row(
        Modifier.clip(CircleShape).background(back).padding(start = 8.dp, end = 12.dp, top = 6.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(Modifier.size(16.dp), contentAlignment = Alignment.Center) {
            AnimatedContent(state, transitionSpec = {
                (scaleIn(spring(dampingRatio = 0.45f, stiffness = 400f)) + fadeIn()) togetherWith
                    (scaleOut() + fadeOut())
            }, label = "mark") { shown ->
                when (shown) {
                    PhaseState.Waiting -> Box(Modifier.size(6.dp).clip(CircleShape).background(colors.outlineVariant))

                    PhaseState.Running -> InkCircularProgressIndicator(
                        Modifier.size(14.dp),
                        strokeWidth = 2.dp,
                        color = colors.primary,
                    )

                    PhaseState.Done -> Icon(Icons.Rounded.Check, null, Modifier.size(16.dp), tint = colors.primary)
                }
            }
        }
        Text(
            stringResource(phase.label()),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = if (state == PhaseState.Running) FontWeight.SemiBold else FontWeight.Medium,
            color = text,
        )
    }
}
