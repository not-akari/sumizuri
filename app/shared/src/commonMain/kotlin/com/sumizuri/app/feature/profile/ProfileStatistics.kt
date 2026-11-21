package com.sumizuri.app.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.stats.ReadingStats
import com.sumizuri.app.data.text.weekdayName
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.filter_favorite
import com.sumizuri.app.shared.resources.stats_averages
import com.sumizuri.app.shared.resources.stats_backlog
import com.sumizuri.app.shared.resources.stats_backlog_cleared
import com.sumizuri.app.shared.resources.stats_backlog_eta
import com.sumizuri.app.shared.resources.stats_chapters_count
import com.sumizuri.app.shared.resources.stats_days_count
import com.sumizuri.app.shared.resources.stats_insights
import com.sumizuri.app.shared.resources.stats_library_breakdown
import com.sumizuri.app.shared.resources.stats_longest_streak
import com.sumizuri.app.shared.resources.stats_months_count
import com.sumizuri.app.shared.resources.stats_most_active_day
import com.sumizuri.app.shared.resources.stats_most_active_time
import com.sumizuri.app.shared.resources.stats_per_active_day
import com.sumizuri.app.shared.resources.stats_per_sitting
import com.sumizuri.app.shared.resources.stats_per_week
import com.sumizuri.app.shared.resources.stats_total
import com.sumizuri.app.shared.resources.stats_weeks_count
import com.sumizuri.app.shared.resources.stats_years_count
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.card.TitledCard
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.text.Figure
import com.sumizuri.app.ui.kit.text.FigureSize
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource
import kotlin.math.ceil
import kotlin.math.roundToInt

// The three cards of statistics: the averages, the insights and the breakdown of the library. Side by side on a wide page, and under each other on a narrow one.
@Composable
internal fun ProfileStatistics(stats: ReadingStats, wide: Boolean, modifier: Modifier = Modifier) {
    if (wide) {
        Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(40.dp)) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Averages(stats)
                Insights(stats)
            }
            Column(Modifier.weight(1f)) { Breakdown(stats) }
        }
    } else {
        Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Averages(stats)
            Insights(stats)
            Breakdown(stats)
        }
    }
}

@Composable
private fun Averages(stats: ReadingStats) {
    TitledCard(stringResource(Res.string.stats_averages)) {
        Row(Modifier.fillMaxWidth().height(40.dp), verticalAlignment = Alignment.CenterVertically) {
            Figure(
                oneDecimal(stats.perSitting),
                stringResource(Res.string.stats_per_sitting),
                Modifier.weight(1f),
                FigureSize.Small,
            )
            Rule()
            Figure(
                oneDecimal(stats.perActiveDay),
                stringResource(Res.string.stats_per_active_day),
                Modifier.weight(1f),
                FigureSize.Small,
            )
            Rule()
            Figure(
                oneDecimal(stats.perWeek),
                stringResource(Res.string.stats_per_week),
                Modifier.weight(1f),
                FigureSize.Small,
            )
        }
    }
}

@Composable
private fun Insights(stats: ReadingStats) {
    val eta = stats.weeksToClearBacklog
    TitledCard(stringResource(Res.string.stats_insights)) {
        Insight(
            Icons.Outlined.Inventory2,
            stringResource(Res.string.stats_backlog),
            pluralStringResource(Res.plurals.stats_chapters_count, stats.unreadChapters, stats.unreadChapters),
            caption = when {
                eta == null -> null
                eta == 0.0 -> stringResource(Res.string.stats_backlog_cleared)
                else -> stringResource(Res.string.stats_backlog_eta, lasting(eta))
            },
        )
        if (stats.longestStreak >
            0
        ) {
            Insight(
                Icons.Outlined.LocalFireDepartment,
                stringResource(Res.string.stats_longest_streak),
                pluralStringResource(Res.plurals.stats_days_count, stats.longestStreak, stats.longestStreak),
            )
        }
        stats.busiestWeekday?.let {
            Insight(Icons.Outlined.CalendarToday, stringResource(Res.string.stats_most_active_day), weekdayName(it))
        }
        stats.busiestTime?.let {
            Insight(
                Icons.Outlined.Schedule,
                stringResource(Res.string.stats_most_active_time),
                stringResource(it.label),
            )
        }
    }
}

@Composable
private fun Breakdown(stats: ReadingStats) {
    TitledCard(
        stringResource(Res.string.stats_library_breakdown),
        trailing = stringResource(Res.string.stats_total, stats.libraryTitles),
    ) {
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            for (kind in Kind.entries) Pill(stringResource(kind.label), stats.kindCounts[kind] ?: 0)
            if (stats.favorites > 0) Pill(stringResource(Res.string.filter_favorite), stats.favorites, star = true)
        }
    }
}

@Composable
private fun Rule() {
    Box(Modifier.fillMaxHeight().width(1.dp).background(MaterialTheme.colorScheme.outlineVariant))
}

@Composable
private fun Insight(icon: ImageVector, label: String, value: String, caption: String? = null) {
    // The icon at the start, as the rows of the settings have it.
    Row(
        Modifier.fillMaxWidth().padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SettingIcon(icon)
        Column(Modifier.weight(1f)) {
            Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            if (caption !=
                null
            ) {
                Text(
                    caption,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
        }
        Text(
            value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

@Composable
private fun Pill(label: String, count: Int, star: Boolean = false) {
    AppCard {
        Row(
            Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            if (star) Icon(Icons.Outlined.Star, null, Modifier.size(15.dp), tint = MaterialTheme.colorScheme.primary)
            Text(
                label,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(count.toString(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
        }
    }
}

private fun oneDecimal(value: Double): String {
    val tenths = (value * 10).roundToInt()
    return "${tenths / 10}.${tenths % 10}"
}

// A length of time in the biggest unit that reads well: weeks for a couple of months, then months, then years.
@Composable
private fun lasting(weeks: Double): String = when {
    weeks < 8 -> ceil(weeks).toInt().let { pluralStringResource(Res.plurals.stats_weeks_count, it, it) }
    weeks < 104 -> (weeks / 4.345).roundToInt().let { pluralStringResource(Res.plurals.stats_months_count, it, it) }
    else -> (weeks / 52).roundToInt().let { pluralStringResource(Res.plurals.stats_years_count, it, it) }
}
