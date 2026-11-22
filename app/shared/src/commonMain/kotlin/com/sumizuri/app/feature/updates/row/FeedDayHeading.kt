package com.sumizuri.app.feature.updates.row

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.feed.FeedHeading
import com.sumizuri.app.data.model.feed.HeadingKind
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.data.model.feed.coarseHeading
import com.sumizuri.app.data.model.feed.listHeading
import com.sumizuri.app.data.text.dateText
import com.sumizuri.app.data.text.monthYearText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.day_last_week
import com.sumizuri.app.shared.resources.day_this_week
import com.sumizuri.app.shared.resources.day_today
import com.sumizuri.app.shared.resources.day_yesterday
import com.sumizuri.app.shared.resources.feed_mark_day_read
import com.sumizuri.app.ui.kit.card.Hairline
import com.sumizuri.app.ui.motion.RollingCount
import org.jetbrains.compose.resources.stringResource

// The heading over the titles of one day, or of one week or month in a grid: the name in small capitals, how many titles are under it, a thin line, and when asked a button that marks all of them read. The time is one that belongs to the group, for the headings that are a date or a month.
@Composable
internal fun FeedDayHeading(
    heading: FeedHeading,
    at: Long,
    count: Int,
    onMarkAllRead: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    val text = feedHeadingText(heading, at)
    val colors = MaterialTheme.colorScheme
    Row(
        modifier.fillMaxWidth().heightIn(min = 30.dp).padding(top = 6.dp, bottom = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text.uppercase(),
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = colors.outline,
        )
        // The count rolls as titles are marked read or come in.
        RollingCount(
            count,
            Modifier
                .clip(RoundedCornerShape(10.dp))
                .background(colors.surfaceContainerHighest)
                .padding(horizontal = 7.dp, vertical = 1.dp),
        ) {
            Text(it.toString(), style = MaterialTheme.typography.labelSmall, color = colors.onSurfaceVariant)
        }
        Hairline(Modifier.weight(1f).padding(start = 4.dp), alpha = 1f)
        if (onMarkAllRead !=
            null
        ) {
            // A small button, so the heading stays a thin line over its rows.
            TextButton(onMarkAllRead, Modifier.height(30.dp), contentPadding = PaddingValues(horizontal = 10.dp)) {
                Text(stringResource(Res.string.feed_mark_day_read), style = MaterialTheme.typography.labelMedium)
            }
        }
    }
}

// The words of a heading: today, yesterday, a date, the week or the month of the time given.
@Composable
internal fun feedHeadingText(heading: FeedHeading, at: Long): String = when (heading.kind) {
    HeadingKind.Today -> stringResource(Res.string.day_today)
    HeadingKind.Yesterday -> stringResource(Res.string.day_yesterday)
    HeadingKind.Date -> dateText(at)
    HeadingKind.ThisWeek -> stringResource(Res.string.day_this_week)
    HeadingKind.LastWeek -> stringResource(Res.string.day_last_week)
    HeadingKind.Month -> monthYearText(at)
}

// The items in the order they came, under the heading of today, yesterday, the week or the month, or only the week or the month in a grid.
internal fun groupByHeading(
    items: List<UpdateItem>,
    grid: Boolean,
    now: Long,
): List<Pair<FeedHeading, List<UpdateItem>>> {
    val groups = mutableListOf<Pair<FeedHeading, MutableList<UpdateItem>>>()
    for (item in items) {
        val heading = if (grid) coarseHeading(now, item.at) else listHeading(now, item.at)
        if (groups.isEmpty() || groups.last().first != heading) groups += heading to mutableListOf()
        groups.last().second += item
    }
    return groups
}
