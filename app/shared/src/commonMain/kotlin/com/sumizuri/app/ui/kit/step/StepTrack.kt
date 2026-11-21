package com.sumizuri.app.ui.kit.step

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs

// The steps as one slim bar cut into a segment for each: the ones done filled, the one now filling in with a soft glow round it, and the ones to come faint, with each name small under its segment. A tap on a step opens it when the caller allows it.
@Composable
fun StepTrack(labels: List<String>, current: Int, modifier: Modifier = Modifier, onPick: ((Int) -> Unit)? = null) {
    Row(modifier.fillMaxWidth().padding(vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        labels.forEachIndexed { index, label ->
            val pick = if (onPick !=
                null
            ) {
                Modifier.clip(MaterialTheme.shapes.small).clickable { onPick(index) }
            } else {
                Modifier
            }
            Segment(
                label,
                done = index < current,
                now = index == current,
                busy = false,
                modifier = Modifier.weight(1f).then(pick),
            )
        }
    }
}

// The same track with no names, for a short wait. While busy the step now runs a moving light instead of standing full.
@Composable
fun StepTrack(count: Int, current: Int, modifier: Modifier = Modifier, busy: Boolean = false) {
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        repeat(count) { index ->
            Segment(null, done = index < current, now = index == current, busy = busy, modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun Segment(label: String?, done: Boolean, now: Boolean, busy: Boolean, modifier: Modifier) {
    val colors = MaterialTheme.colorScheme
    val ms = motionMs(AppMotion.Page)
    Column(
        modifier.padding(
            bottom = if (label ==
                null
            ) {
                0.dp
            } else {
                2.dp
            },
        ),
        verticalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        if (now && busy) {
            Box(Modifier.fillMaxWidth().height(10.dp), contentAlignment = Alignment.Center) {
                InkLinearProgressIndicator(
                    Modifier.fillMaxWidth().height(4.dp),
                    colors.primary,
                    colors.outlineVariant.copy(alpha = 0.5f),
                )
            }
        } else {
            Bar(done, now)
        }
        if (label != null) {
            val text by animateColorAsState(
                when {
                    now -> colors.primary
                    done -> colors.onSurfaceVariant
                    else -> colors.outline
                },
                tween(ms),
                label = "name",
            )
            Text(
                label,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = if (now) FontWeight.Bold else FontWeight.Medium,
                color = text,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

// The bar of one step. The step now fills in from its start, and one left behind stays full.
@Composable
private fun Bar(done: Boolean, now: Boolean) {
    val colors = MaterialTheme.colorScheme
    val fill by animateFloatAsState(
        if (done || now) 1f else 0f,
        tween(motionMs(AppMotion.Page), easing = AppMotion.Entrance),
        label = "fill",
    )
    Canvas(Modifier.fillMaxWidth().height(10.dp)) {
        val bar = 4.dp.toPx()
        val top = (size.height - bar) / 2
        val round = CornerRadius(bar / 2)
        drawRoundRect(colors.outlineVariant.copy(alpha = 0.5f), Offset(0f, top), Size(size.width, bar), round)
        val width = size.width * fill
        if (width <= 0f) return@Canvas
        // The glow is a wider and fainter band round the bar of the step now.
        if (now) {
            drawRoundRect(
                colors.primary.copy(alpha = 0.2f),
                Offset(0f, 0f),
                Size(width, size.height),
                CornerRadius(size.height / 2),
            )
        }
        drawRoundRect(colors.primary, Offset(0f, top), Size(width, bar), round)
    }
}
