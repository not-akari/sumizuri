package com.sumizuri.app.feature.updates

import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.library.ReleasePlan
import com.sumizuri.app.data.library.UpcomingTitle
import com.sumizuri.app.data.text.dateText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.updates_calendar
import com.sumizuri.app.shared.resources.updates_list
import com.sumizuri.app.shared.resources.updates_upcoming
import com.sumizuri.app.shared.resources.updates_upcoming_empty
import com.sumizuri.app.shared.resources.updates_upcoming_hint
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.page.LocalBottomClearance
import com.sumizuri.app.ui.kit.setting.PartTabs
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.stringResource

// What comes next as a sheet, for a window too narrow for the panel beside the updates.
@Composable
internal fun UpcomingSheet(onOpenTitle: (Long) -> Unit, onDismiss: () -> Unit) {
    AppSheet(onDismiss, spacing = 4.dp, title = stringResource(Res.string.updates_upcoming)) {
        var calendar by rememberSaveable { mutableStateOf(true) }
        UpcomingBody(onOpenTitle, calendar, { calendar = it })
    }
}

// What comes next beside the updates on a wide window, so the room right of the list is not empty. It scrolls on its own, and is read again when the new chapters change.
@Composable
internal fun UpcomingPanel(
    onOpenTitle: (Long) -> Unit,
    refresh: Any?,
    calendar: Boolean,
    onView: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier
            .verticalScroll(rememberScrollState())
            .padding(top = 8.dp, bottom = 8.dp + LocalBottomClearance.current),
    ) {
        // The card starts level with the first row of the list, and names itself like the headings of the days.
        Column(Modifier.softCard().padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(
                stringResource(Res.string.updates_upcoming).uppercase(),
                Modifier.padding(start = 2.dp),
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.outline,
            )
            UpcomingBody(onOpenTitle, calendar, onView, refresh)
        }
    }
}

// The titles of the library whose next chapter is expected, as a month of releases or as a list with the soonest first, each with the day it is due. The day is a guess from how often the title came out before, and a title with too few dated chapters has none.
@Composable
private fun UpcomingBody(
    onOpenTitle: (Long) -> Unit,
    calendar: Boolean,
    onView: (Boolean) -> Unit,
    refresh: Any? = Unit,
) {
    val library = LocalAppContainer.current.library
    val upcoming by produceState<List<UpcomingTitle>?>(null, refresh) { value = library.upcoming() }
    val plans by produceState<List<ReleasePlan>?>(null, refresh) { value = library.releasePlans() }
    // The month of releases or the list of what comes next, as the one showing it keeps.
    PartTabs(listOf(true, false), calendar, {
        stringResource(if (it) Res.string.updates_calendar else Res.string.updates_list)
    }, onSelect = onView)
    Crossfade(calendar, animationSpec = tween(motionMs(AppMotion.Medium)), label = "upcoming") { month ->
        if (month) {
            plans?.let { ReleaseCalendar(it, onOpenTitle) }
            return@Crossfade
        }
        val list = upcoming
        when {
            list == null -> Unit

            list.isEmpty() -> Text(
                stringResource(Res.string.updates_upcoming_empty),
                color = MaterialTheme.colorScheme.outline,
            )

            else -> Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    stringResource(Res.string.updates_upcoming_hint),
                    Modifier.padding(bottom = 4.dp),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )
                for (item in list) UpcomingRow(item, onOpenTitle)
            }
        }
    }
}

// One title that has a chapter coming, which glows under the mouse.
@Composable
private fun UpcomingRow(item: UpcomingTitle, onOpenTitle: (Long) -> Unit) {
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val glow by animateColorAsState(
        MaterialTheme.colorScheme.onSurface.copy(alpha = if (hovered) 0.06f else 0f),
        tween(motionMs(AppMotion.Fast)),
        label = "glow",
    )
    Row(
        Modifier
            .fillMaxWidth()
            .feedbackScale(source, hover = false)
            .background(glow, MaterialTheme.shapes.small)
            .clickable(source, indication = null) { onOpenTitle(item.title.id) }
            .padding(horizontal = 6.dp, vertical = 5.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CoverArt(item.title, Modifier.width(36.dp), letterSize = 13)
        Text(
            item.title.name,
            Modifier.weight(1f),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            style = MaterialTheme.typography.bodyMedium,
        )
        Text(
            dateText(item.at),
            color = MaterialTheme.colorScheme.outline,
            style = MaterialTheme.typography.bodySmall,
        )
    }
}
