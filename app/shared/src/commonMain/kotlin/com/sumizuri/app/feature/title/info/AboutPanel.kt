package com.sumizuri.app.feature.title.info

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoStories
import androidx.compose.material.icons.outlined.Category
import androidx.compose.material.icons.outlined.Event
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.FormatListNumbered
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material.icons.outlined.Update
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.chapter.guessReleaseDay
import com.sumizuri.app.feature.title.chapter.seasonTags
import com.sumizuri.app.feature.title.chapter.spotText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.title_about_description
import com.sumizuri.app.shared.resources.title_about_genres
import com.sumizuri.app.shared.resources.title_details
import com.sumizuri.app.shared.resources.title_fact_new
import com.sumizuri.app.shared.resources.title_fact_usually
import com.sumizuri.app.shared.resources.title_info_author
import com.sumizuri.app.shared.resources.title_info_latest
import com.sumizuri.app.shared.resources.title_info_length
import com.sumizuri.app.shared.resources.title_info_progress
import com.sumizuri.app.shared.resources.title_info_rating
import com.sumizuri.app.shared.resources.title_info_schedule
import com.sumizuri.app.shared.resources.title_info_source
import com.sumizuri.app.shared.resources.title_info_status
import com.sumizuri.app.shared.resources.title_info_type
import com.sumizuri.app.shared.resources.weekday_0
import com.sumizuri.app.shared.resources.weekday_1
import com.sumizuri.app.shared.resources.weekday_2
import com.sumizuri.app.shared.resources.weekday_3
import com.sumizuri.app.shared.resources.weekday_4
import com.sumizuri.app.shared.resources.weekday_5
import com.sumizuri.app.shared.resources.weekday_6
import com.sumizuri.app.ui.kit.cover.sourceName
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.unitCount
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

private val Weekdays =
    listOf(
        Res.string.weekday_0,
        Res.string.weekday_1,
        Res.string.weekday_2,
        Res.string.weekday_3,
        Res.string.weekday_4,
        Res.string.weekday_5,
        Res.string.weekday_6,
    )

// Everything known about the title in cards, as the settings show their groups: the whole description, the facts each with its icon, and the genres. In the side panel of the wide page the description and the genres are left out, since the banner has them.
@Composable
internal fun AboutPanel(state: TitleState, title: Title, panel: Boolean, modifier: Modifier = Modifier) {
    val facts = aboutFacts(state, title)
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        if (!panel && title.summary.isNotBlank()) {
            SettingsSection(Res.string.title_about_description) {
                padded {
                    SelectionContainer {
                        Text(
                            title.summary,
                            Modifier.padding(vertical = 10.dp),
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                }
            }
        }
        if (facts.isNotEmpty()) {
            SettingsSection(Res.string.title_details) {
                for (fact in facts) row { FactRow(fact, panel) }
            }
        }
        // The wide page shows the genres in its banner already.
        if (!panel && title.genres.isNotEmpty()) {
            SettingsSection(Res.string.title_about_genres) {
                padded { Box(Modifier.padding(vertical = 12.dp)) { GenreChips(title.genres) } }
            }
        }
    }
}

// One fact about the title: what it is, with its icon, and what it says.
private class Fact(val icon: ImageVector, val key: StringResource, val label: String, val value: String)

@Composable
private fun FactRow(fact: Fact, panel: Boolean) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SettingIcon(fact.icon)
        Text(
            fact.label,
            Modifier.width(if (panel) 112.dp else 108.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        SelectionContainer(Modifier.weight(1f)) { Text(fact.value, style = MaterialTheme.typography.bodyMedium) }
    }
}

// The facts of the title, left out where nothing is known.
@Composable
private fun aboutFacts(state: TitleState, title: Title): List<Fact> {
    val rows = mutableListOf<Triple<ImageVector, StringResource, String>>()
    if (title.author.isNotBlank()) rows += Triple(Icons.Outlined.Person, Res.string.title_info_author, title.author)
    rows += Triple(Icons.Outlined.Flag, Res.string.title_info_status, stringResource(title.status.label))
    title.rating?.let {
        rows +=
            Triple(Icons.Outlined.StarOutline, Res.string.title_info_rating, ((it * 10).toInt() / 10.0).toString())
    }
    rows += Triple(Icons.Outlined.Category, Res.string.title_info_type, stringResource(title.kind.label))
    if (state.chapters.isNotEmpty()) {
        rows +=
            Triple(
                Icons.Outlined.FormatListNumbered,
                Res.string.title_info_length,
                unitCount(title.kind, state.counted.size),
            )
    }
    // What is worked out from every chapter is kept until the chapters change, as the panel is drawn again whenever anything on the page changes.
    val latest = remember(state.chapters) { state.chapters.maxOfOrNull { it.at } ?: 0L }
    if (latest > 0) rows += Triple(Icons.Outlined.Update, Res.string.title_info_latest, agoText(latest))
    val day = remember(state.chapters) { guessReleaseDay(state.chapters.map { it.at }) }
    val tagOf = remember(state.chapters) { seasonTags(state.chapters) }
    if (day != null &&
        title.status != Status.Completed
    ) {
        rows +=
            Triple(Icons.Outlined.Event, Res.string.title_info_schedule, stringResource(Weekdays[day]))
    }
    // The furthest read goes season by season, so a later season counts as further than a higher number in an earlier one.
    state.furthestRead?.let {
        rows +=
            Triple(
                Icons.Outlined.AutoStories,
                Res.string.title_info_progress,
                it.name ?: spotText(title.kind, it.number, tagOf(it)),
            )
    }
    state.sourceName?.let {
        rows +=
            Triple(Icons.Outlined.Extension, Res.string.title_info_source, sourceName(title.sourceId, it))
    }
    return rows.map { (icon, label, value) -> Fact(icon, label, stringResource(label), value) }
}

// When the latest chapter came and the day chapters usually come, as short words for the line under the name. A finished title has no usual day.
@Composable
internal fun releaseFacts(state: TitleState, title: Title): List<String> {
    val latest = remember(state.chapters) { state.chapters.maxOfOrNull { it.at } ?: 0L }
    val day = remember(state.chapters) { guessReleaseDay(state.chapters.map { it.at }) }
    return buildList {
        if (latest > 0) add(stringResource(Res.string.title_fact_new, agoText(latest)))
        if (day != null &&
            title.status != Status.Completed
        ) {
            add(stringResource(Res.string.title_fact_usually, stringResource(Weekdays[day])))
        }
    }
}
