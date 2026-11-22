package com.sumizuri.app.feature.tv.title

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.library.EpisodeStill
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.feature.tv.player.restOfName
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.focus.focusAlignment
import com.sumizuri.app.ui.kit.cover.focus.rememberCoverFocus
import com.sumizuri.app.ui.text.numberedUnit
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay

// How wide an episode card is.
private val CardWidth = 216.dp

// The episodes of one season as wide cards in a row that scrolls sideways, starting at the one to go on with. OK plays an episode and holding OK marks it watched or not.
@Composable
internal fun TvEpisodeRow(
    episodes: List<ChapterItem>,
    title: Title,
    covers: Map<String, String>,
    // The picture of each episode by the key of its season and its number, when one was found.
    stills: Map<String, List<EpisodeStill>>,
    next: ChapterItem?,
    calls: TvTitleCalls,
    // Whether the episode to go on with, or else the first, takes the focus as the row shows, such as on opening a season.
    takeFocus: Boolean = false,
) {
    val list = rememberLazyListState()
    val key = episodes.firstOrNull()?.season.orEmpty()
    val shown = remember(episodes, stills) { stillsOf(episodes, stills[key], single = key.isEmpty()) }
    val focus = remember { FocusRequester() }
    val start = episodes.indexOfFirst { it.id == next?.id }.coerceAtLeast(0)
    LaunchedEffect(episodes.firstOrNull()?.key) {
        if (start > 0) list.scrollToItem(start)
        if (takeFocus) {
            repeat(10) {
                delay(80)
                if (runCatching { focus.requestFocus() }.getOrDefault(false)) return@LaunchedEffect
            }
        }
    }
    LazyRow(
        state = list,
        contentPadding = PaddingValues(horizontal = 48.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        itemsIndexed(episodes, key = { _, episode -> episode.key }) { at, episode ->
            val art = shown[episode.number] ?: episode.seasonCoverUrl ?: episode.season?.let(covers::get)
            EpisodeCard(
                episode,
                remember(title, art) {
                    if (art !=
                        null
                    ) {
                        title.copy(coverUrl = art)
                    } else {
                        title
                    }
                },
                calls,
                if (at ==
                    start
                ) {
                    Modifier.focusRequester(focus)
                } else {
                    Modifier
                },
            )
        }
    }
}

// One episode: the art of its season or the title with its number on it and a bar of how far it was watched, and its name under it.
@Composable
private fun EpisodeCard(episode: ChapterItem, art: Title, calls: TvTitleCalls, modifier: Modifier) {
    val colors = MaterialTheme.colorScheme
    val watched = if (episode.read) 1f else episode.progress ?: 0f
    Column(Modifier.width(CardWidth), verticalArrangement = Arrangement.spacedBy(7.dp)) {
        BoxWithConstraints(
            modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .tvCard(
                    {
                        calls.onPlay(episode)
                    },
                    RoundedCornerShape(
                        12.dp,
                    ),
                    onLongClick = calls.onToggleWatched?.let { toggle -> { toggle(episode) } },
                ).padding(3.dp)
                .clip(RoundedCornerShape(9.dp)),
        ) {
            val focus by rememberCoverFocus(art.coverUrl)
            CoverArt(
                art,
                Modifier.fillMaxSize(),
                letterSize = 28,
                aspect = maxWidth / maxHeight,
                alignment = focusAlignment(focus, maxWidth.value, maxHeight.value),
            )
            Box(
                Modifier
                    .align(Alignment.BottomStart)
                    .fillMaxWidth()
                    .height(maxHeight * 0.6f)
                    .background(
                        Brush.verticalGradient(
                            listOf(Color.Transparent, Color.Black.copy(alpha = if (episode.read) 0.85f else 0.7f)),
                        ),
                    ),
            )
            Text(
                numberedUnit(Kind.Anime, episode.number),
                Modifier.align(Alignment.BottomStart).padding(start = 10.dp, bottom = 12.dp),
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White.copy(alpha = if (episode.read) 0.7f else 1f),
            )
            if (watched > 0f) {
                Box(
                    Modifier
                        .align(
                            Alignment.BottomStart,
                        ).fillMaxWidth()
                        .height(4.dp)
                        .background(colors.scrim.copy(alpha = 0.5f)),
                ) {
                    Box(Modifier.fillMaxWidth(watched.coerceIn(0f, 1f)).height(4.dp).background(colors.primary))
                }
            }
        }
        // The name shows only when it says more than the number on the card.
        val number = numberedUnit(Kind.Anime, episode.number)
        val named = restOfName(episode.name, number)
        if (named != null) {
            Text(
                named,
                fontSize = 13.sp,
                color = colors.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

// The pictures of the episodes of one season by number. An episode is matched by its name first, since a site may number every season on from the last, then by its number where the number counts inside the season, or for a show of one season. An episode nothing fits keeps the picture of its season, as a wrong picture is worse than none.
private fun stillsOf(episodes: List<ChapterItem>, found: List<EpisodeStill>?, single: Boolean): Map<Double, String> {
    if (found.isNullOrEmpty()) return emptyMap()
    val byName = found
        .mapNotNull { still ->
            still.name?.let(::plainName)?.takeIf { it.isNotEmpty() }?.let {
                it to
                    still.url
            }
        }.toMap()
    val byNumber = found
        .filter {
            it.ownSeason || single
        }.mapNotNull { still -> still.number?.let { it to still.url } }
        .toMap()
    return episodes
        .mapNotNull { episode ->
            val name = restOfName(episode.name, numberedName(episode.number))
            val url = name?.let { byName[plainName(it)] } ?: byNumber[episode.number]
            url?.let { episode.number to it }
        }.toMap()
}

// A name with only its letters and digits, in small letters, so the same name written two ways matches.
private fun plainName(name: String): String = name.lowercase().filter { it.isLetterOrDigit() }

// How the number of an episode reads at the start of its name, for taking it off.
private fun numberedName(number: Double): String =
    "Episode " + (if (number % 1.0 == 0.0) number.toLong().toString() else number.toString())
