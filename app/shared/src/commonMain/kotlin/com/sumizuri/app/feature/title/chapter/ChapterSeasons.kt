package com.sumizuri.app.feature.title.chapter

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.library.seasonNumber
import com.sumizuri.app.data.library.seasonSlices
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.season_back
import com.sumizuri.app.shared.resources.season_numbered
import com.sumizuri.app.shared.resources.season_other
import com.sumizuri.app.shared.resources.season_progress
import com.sumizuri.app.shared.resources.season_spot
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.text.numberedUnit
import com.sumizuri.app.ui.theme.LocalThemeSpec
import org.jetbrains.compose.resources.stringResource

// A season named only as the first one, such as Season 1 or 1st Season.
private val FirstSeason = Regex("(?i)^(season\\s*0*1|1st\\s+season|s0*1)$")

// The shape of the card of a season that shows a still of an episode.
private const val WideAspect = 16f / 9f

// Stands for the chapters with no season, since the open season is kept as text.
private const val NoSeason = "\u0000"

// One season of a title with its chapters, and whether it is the first season the source left unnamed.
internal class SeasonGroup(
    val key: String?,
    val name: String?,
    val coverUrl: String?,
    val chapters: List<ChapterItem>,
    val isFirst: Boolean,
    // The seasons of the source it is made of. Parts of one season, such as Season 1 Part 1 and Part 2, are shown as one.
    val keys: Set<String?> = setOf(key),
) {
    val merged: Boolean get() = keys.size > 1

    val id: String get() = key ?: NoSeason
    val watched: Int = chapters.count { it.read }
}

// The seasons of the chapters in their order, or nothing when there are fewer than two, which shows the plain list. Each season shows the first picture its chapters have.
internal fun seasonGroups(chapters: List<ChapterItem>): List<SeasonGroup> =
    seasonSlices(chapters, { it.season }, { it.seasonName }).map { slice ->
        SeasonGroup(
            slice.key,
            slice.name,
            slice.items.firstNotNullOfOrNull { it.seasonCoverUrl },
            slice.items,
            slice.isFirst,
            slice.keys,
        )
    }

// The number of each season by its key, read from its name or its key, so a season can be looked up by its number where its name is not known.
internal fun seasonNumbers(seasons: List<Pair<String?, String?>>): Map<String, Int> = seasons
    .groupBy({ it.first }, { it.second })
    .mapNotNull { (key, names) ->
        if (key == null) return@mapNotNull null
        seasonNumber(key, names.firstNotNullOfOrNull { it?.takeIf(String::isNotBlank) })?.let { key to it }
    }.toMap()

// The name each season is looked up by elsewhere, by its key: its own name, the title for the first numbered season, or the title with the number. Nothing when there are fewer than two seasons.
internal fun seasonLookupNames(titleName: String, seasons: List<Pair<String?, String?>>): Map<String, String> {
    val byKey = seasons.groupBy({ it.first }, { it.second })
    if (byKey.size < 2) return emptyMap()
    return byKey
        .mapNotNull { (key, names) ->
            if (key == null) return@mapNotNull null
            val number = key.toDoubleOrNull()
            val own = names.firstNotNullOfOrNull { it?.takeIf(String::isNotBlank) }
            val name = when {
                // A name such as Season 1 Part 2 or OVA says nothing of the show, so the title is put in front of it. The first season is listed under the name of the show alone.
                own != null && FirstSeason.matches(own.trim()) -> titleName

                own != null -> if (own.contains(titleName, ignoreCase = true)) own else "$titleName $own"

                number == 1.0 -> titleName

                number != null -> "$titleName Season ${number.toInt()}"

                else -> "$titleName $key"
            }
            key to name
        }.toMap()
}

// Whether the seasons of a title are shown as wide cards with the stills their source gives. All seasons of a title share one shape, so the rows line up. When at least half of them have a poster found for them, every card is a poster, and one without shows the cover of the title. With fewer, the stills look better than a row of the same cover.
internal fun seasonsAreWide(seasons: List<SeasonGroup>, title: Title, covers: Map<String, String>): Boolean {
    if (title.kind != Kind.Anime || seasons.none { it.coverUrl != null }) return false
    val posters = seasons.count { group -> group.key?.let(covers::get) != null }
    return posters * 2 < seasons.size
}

// The season the list shows, kept across a turn of the screen. Null shows the seasons to pick from.
@Composable
internal fun rememberOpenSeason(): MutableState<String?> = rememberSaveable { mutableStateOf(null) }

@Composable
internal fun seasonTitle(group: SeasonGroup): String = seasonTitle(group.key, group.name, group.isFirst)

@Composable
internal fun seasonTitle(key: String?, name: String?, isFirst: Boolean): String = name ?: when {
    isFirst -> stringResource(Res.string.season_numbered, "1")
    key == null -> stringResource(Res.string.season_other)
    key.toDoubleOrNull() != null -> stringResource(Res.string.season_numbered, key)
    else -> key
}

// A chapter named by its number, with its season in front when the title has seasons.
@Composable
internal fun spotText(kind: Kind, number: Double, season: SeasonTag?): String {
    val numbered = numberedUnit(kind, number)
    return if (season ==
        null
    ) {
        numbered
    } else {
        stringResource(Res.string.season_spot, seasonTitle(season.key, season.name, season.isFirst), numbered)
    }
}

// One season as a card with its picture, a check once every episode is watched, a bar while it is part way, its name and how far it is.
@Composable
internal fun SeasonCard(
    group: SeasonGroup,
    title: Title,
    art: String?,
    wide: Boolean,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = MaterialTheme.colorScheme
    val total = group.chapters.size
    Column(modifier.clip(MaterialTheme.shapes.small).clickable(onClick = onOpen).padding(bottom = 6.dp)) {
        Box {
            // A poster card shows the poster found for the season, or the cover of the title. A wide card shows the still its source gives, or the poster when it has none.
            val picture = if (wide) group.coverUrl ?: art else art
            // A poster found elsewhere is not a picture of the source, so it is asked for without the site of the source and away from its route. The cover of the title shows while it comes.
            val found = picture != null && picture == art
            CoverArt(
                title.copy(coverUrl = picture ?: title.coverUrl, sourceId = if (found) "" else title.sourceId),
                Modifier.fillMaxWidth(),
                letterSize = 28,
                aspect = if (wide) WideAspect else LocalThemeSpec.current.options.covers.aspect.ratio,
                standIn = title.takeIf { picture != null },
            )
            if (total > 0 && group.watched == total) {
                Box(
                    Modifier
                        .align(Alignment.TopEnd)
                        .padding(6.dp)
                        .size(22.dp)
                        .clip(CircleShape)
                        .background(colors.primary),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Outlined.Check, null, Modifier.size(16.dp), tint = colors.onPrimary)
                }
            }
            if (group.watched in 1 until total) {
                InkLinearProgressIndicator({
                    group.watched / total.toFloat()
                }, Modifier.align(Alignment.BottomCenter).fillMaxWidth().height(3.dp))
            }
        }
        Text(
            seasonTitle(group),
            Modifier.padding(top = 6.dp),
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            stringResource(Res.string.season_progress, group.watched, total),
            style = MaterialTheme.typography.bodySmall,
            color = colors.onSurfaceVariant,
        )
    }
}

// A row of season cards, with empty room at the end of a short last row.
@Composable
internal fun SeasonRow(
    row: List<SeasonGroup>,
    columns: Int,
    title: Title,
    covers: Map<String, String>,
    wide: Boolean,
    onOpen: (SeasonGroup) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        for (group in row) {
            SeasonCard(
                group,
                title,
                group.key?.let(covers::get),
                wide,
                { onOpen(group) },
                Modifier.weight(1f),
            )
        }
        repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
    }
}

// Over the episodes of an open season: the way back to all seasons and the name of this one.
@Composable
internal fun SeasonHeading(group: SeasonGroup, onBack: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(MaterialTheme.shapes.small)
            .clickable(onClick = onBack)
            .padding(vertical = 8.dp, horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            Icons.AutoMirrored.Outlined.ArrowBack,
            stringResource(Res.string.season_back),
            Modifier.size(20.dp),
            tint = MaterialTheme.colorScheme.primary,
        )
        Text(
            seasonTitle(group),
            Modifier.padding(start = 10.dp).weight(1f),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            stringResource(Res.string.season_back),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}
