package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.TrackStatus
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_stats_chapters
import com.sumizuri.app.shared.resources.tracker_stats_episodes
import com.sumizuri.app.shared.resources.tracker_stats_title
import com.sumizuri.app.ui.kit.card.AppCard
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The numbers of the linked titles of a tracker counted once for each change of the list.
private class Stats(val statuses: List<Pair<TrackStatus, Int>>, val chapters: Int, val episodes: Int, val most: Int)

// How the linked titles stand on the tracker: how many have each status, with a bar for each, and the chapters read and episodes watched in all.
@Composable
internal fun TrackerStats(tracker: TrackerId, links: List<TrackerLinkEntity>) {
    if (links.isEmpty()) return
    val stats = remember(links) {
        val counts = statusCounts(links.map { it.status }).toList().filter { it.second > 0 }
        val (shows, books) = links.partition { it.kind == Kind.Anime.code }
        Stats(counts, books.sumOf { it.progress }, shows.sumOf { it.progress }, counts.maxOf { it.second })
    }
    val kind = if (stats.chapters == 0 && stats.episodes > 0) Kind.Anime else Kind.Manga
    val colors = MaterialTheme.colorScheme
    AppCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                stringResource(Res.string.tracker_stats_title, tracker.label),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
            )
            for ((status, count) in stats.statuses) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(statusLabel(status, kind), Modifier.width(96.dp), style = MaterialTheme.typography.bodySmall)
                    Box(
                        Modifier
                            .weight(1f)
                            .height(6.dp)
                            .clip(MaterialTheme.shapes.small)
                            .background(colors.surfaceContainerHighest),
                    ) {
                        Box(
                            Modifier
                                .fillMaxWidth(count.toFloat() / stats.most)
                                .fillMaxHeight()
                                .background(colors.primary),
                        )
                    }
                    Text(
                        count.toString(),
                        Modifier.width(44.dp),
                        style = MaterialTheme.typography.labelMedium,
                        color = colors.onSurfaceVariant,
                        textAlign = TextAlign.End,
                    )
                }
            }
            val totals = buildList {
                if (stats.chapters >
                    0
                ) {
                    add(pluralStringResource(Res.plurals.tracker_stats_chapters, stats.chapters, stats.chapters))
                }
                if (stats.episodes >
                    0
                ) {
                    add(pluralStringResource(Res.plurals.tracker_stats_episodes, stats.episodes, stats.episodes))
                }
            }
            if (totals.isNotEmpty()) {
                Text(totals.joinToString(" · "), style = MaterialTheme.typography.bodySmall, color = colors.outline)
            }
        }
    }
}
