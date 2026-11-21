package com.sumizuri.app.feature.profile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.stats.ReadingStats
import com.sumizuri.app.data.model.stats.ReadingStats.Companion.DayMs
import com.sumizuri.app.data.text.localOffsetMillis
import com.sumizuri.app.data.text.monthYearShort
import com.sumizuri.app.data.text.weekdayOf
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.stats_today
import org.jetbrains.compose.resources.stringResource
import kotlin.math.sqrt

// The last year of reading as one thin strip of days, a column for each week, darker for a heavier day. A year where there is room, and on a phone half of it, so a day stays big enough to see.
@Composable
internal fun YearStrip(stats: ReadingStats, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val weeks = if (maxWidth >= 560.dp) 53 else 26
        val start = stats.today - ((weeks - 1) * 7 + weekdayOf(stats.today) - 1)
        val counts = (start..stats.today).map { stats.daily[it] ?: 0 }
        val empty = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.07f)
        val ink = MaterialTheme.colorScheme.primary
        val label = MaterialTheme.typography.labelSmall
        Column {
            Canvas(Modifier.fillMaxWidth().aspectRatio(weeks / 7f)) {
                val cell = size.width / weeks
                val gap = cell * 0.18f
                val peak = counts.maxOrNull()?.coerceAtLeast(1) ?: 1
                counts.forEachIndexed { index, count ->
                    drawRoundRect(
                        color = if (count ==
                            0
                        ) {
                            empty
                        } else {
                            ink.copy(alpha = 0.25f + 0.75f * sqrt(count.toFloat() / peak))
                        },
                        topLeft = Offset((index / 7) * cell + gap / 2, (index % 7) * cell + gap / 2),
                        size = Size(cell - gap, cell - gap),
                        cornerRadius = CornerRadius(cell * 0.2f),
                    )
                }
            }
            Row(Modifier.fillMaxWidth().padding(top = 6.dp)) {
                // The text of the first day is of local noon, so a zone far from UTC does not change its month.
                val noon = start * DayMs + DayMs / 2
                Text(
                    monthYearShort(noon - localOffsetMillis(noon)),
                    style = label,
                    color = MaterialTheme.colorScheme.outline,
                )
                Spacer(Modifier.weight(1f))
                Text(stringResource(Res.string.stats_today), style = label, color = MaterialTheme.colorScheme.outline)
            }
        }
    }
}
