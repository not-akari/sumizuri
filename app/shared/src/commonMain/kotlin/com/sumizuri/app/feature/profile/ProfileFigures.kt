package com.sumizuri.app.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.stats.ReadingStats
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.library_title
import com.sumizuri.app.shared.resources.profile_chapters_read
import com.sumizuri.app.shared.resources.stats_current_streak
import com.sumizuri.app.shared.resources.stats_last_month
import com.sumizuri.app.shared.resources.stats_most_active_time
import com.sumizuri.app.ui.kit.text.Figure
import com.sumizuri.app.ui.kit.text.FigureSize
import org.jetbrains.compose.resources.stringResource

// The numbers that matter, set large in a row with thin rules between them and no boxes. Five across where there is room, and on a phone three and then two.
@Composable
internal fun ProfileFigures(stats: ReadingStats, modifier: Modifier = Modifier) {
    val time = stats.busiestTime?.let { stringResource(it.label) } ?: "—"
    val figures = listOf(
        stats.currentStreak.toString() to stringResource(Res.string.stats_current_streak),
        stats.chaptersRead.toString() to stringResource(Res.string.profile_chapters_read),
        stats.chaptersThisMonth.toString() to stringResource(Res.string.stats_last_month),
        stats.libraryTitles.toString() to stringResource(Res.string.library_title),
        time to stringResource(Res.string.stats_most_active_time),
    )
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val perRow = if (maxWidth >= 560.dp) 5 else 3
        Column(
            verticalArrangement = androidx.compose.foundation.layout.Arrangement
                .spacedBy(16.dp),
        ) {
            for (row in figures.chunked(perRow)) {
                Row(Modifier.height(IntrinsicSize.Min)) {
                    row.forEachIndexed { index, figure ->
                        if (index >
                            0
                        ) {
                            Box(
                                Modifier
                                    .fillMaxHeight()
                                    .width(
                                        1.dp,
                                    ).background(MaterialTheme.colorScheme.outlineVariant),
                            )
                        }
                        Figure(
                            figure.first,
                            figure.second,
                            Modifier.weight(1f).padding(
                                start = if (index ==
                                    0
                                ) {
                                    0.dp
                                } else {
                                    14.dp
                                },
                            ),
                            FigureSize.Large,
                        )
                    }
                    // A short last row keeps the width of the others.
                    repeat(perRow - row.size) { Box(Modifier.weight(1f)) }
                }
            }
        }
    }
}
