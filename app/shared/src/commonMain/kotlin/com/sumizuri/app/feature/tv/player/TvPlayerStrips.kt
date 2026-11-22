package com.sumizuri.app.feature.tv.player

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.feature.player.SessionState
import com.sumizuri.app.feature.player.VideoChoice
import com.sumizuri.app.feature.player.overlay.speedText
import com.sumizuri.app.feature.player.picker.Picker
import com.sumizuri.app.feature.player.picker.PickerSpeeds
import com.sumizuri.app.feature.player.picker.trackName
import com.sumizuri.app.playback.PlayerState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_audio
import com.sumizuri.app.shared.resources.player_audio_dub
import com.sumizuri.app.shared.resources.player_audio_sub
import com.sumizuri.app.shared.resources.player_quality
import com.sumizuri.app.shared.resources.player_server
import com.sumizuri.app.shared.resources.player_speed
import com.sumizuri.app.shared.resources.player_subtitles
import com.sumizuri.app.shared.resources.player_subtitles_off
import com.sumizuri.app.source.model.SourceVideo
import com.sumizuri.app.ui.text.numberedUnit
import com.sumizuri.app.ui.tv.tvCard
import org.jetbrains.compose.resources.stringResource
import kotlin.math.abs

// One card of a strip: its name, a line under it when there is more to say, whether it is the one in use, and what OK does.
internal class StripCard(
    val key: String,
    val name: String,
    val note: String?,
    val chosen: Boolean,
    val onPick: () -> Unit,
)

// What the strips of the player can change.
internal class StripCalls(
    val onEpisode: (Long) -> Unit,
    val onSubtitle: (String?) -> Unit,
    val onAudio: (String) -> Unit,
    val onVideo: (SourceVideo) -> Unit,
    val onSpeed: (Float) -> Unit,
)

// A choice of the player as a row of cards low over the video, the way the episodes are: its name over the row, and the one in use in focus. OK takes a card.
@Composable
internal fun TvChoiceStrip(
    picker: Picker,
    state: SessionState,
    player: PlayerState,
    first: FocusRequester,
    calls: StripCalls,
) {
    val cards = stripCards(picker, state, player, calls)
    val title = when (picker) {
        Picker.Subtitles -> stringResource(Res.string.player_subtitles)
        Picker.Audio -> stringResource(Res.string.player_audio)
        Picker.Quality -> stringResource(Res.string.player_quality)
        Picker.Speed -> stringResource(Res.string.player_speed)
        else -> null
    }
    Column(Modifier.padding(top = 14.dp)) {
        title?.let {
            Text(
                it,
                Modifier.padding(bottom = 8.dp),
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White.copy(alpha = 0.8f),
            )
        }
        CardRow(cards, first)
    }
}

// The episodes of the title as cards, starting at the one playing.
@Composable
internal fun TvEpisodeStrip(state: SessionState, first: FocusRequester, onEpisode: (Long) -> Unit) {
    val cards = state.episodes.mapIndexed { at, episode ->
        val number = numberedUnit(Kind.Anime, episode.number)
        StripCard(
            episode.id.toString(),
            number,
            restOfName(episode.name, number),
            at == state.index,
        ) { onEpisode(episode.id) }
    }
    Column(Modifier.padding(top = 18.dp)) { CardRow(cards, first) }
}

// The cards in a row that scrolls sideways, starting at the one in use, which takes the focus. One already watched or not in use is a little quieter.
@Composable
private fun CardRow(cards: List<StripCard>, first: FocusRequester) {
    val list = rememberLazyListState()
    val start = cards.indexOfFirst { it.chosen }.coerceAtLeast(0)
    LaunchedEffect(cards.size) { if (start > 0) list.scrollToItem(start) }
    LazyRow(
        state = list,
        contentPadding = PaddingValues(end = 56.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        itemsIndexed(cards, key = { _, card -> card.key }) { at, card ->
            Column(
                Modifier
                    .width(200.dp)
                    .height(if (cards.any { it.note != null }) 92.dp else 64.dp)
                    .then(if (at == start) Modifier.focusRequester(first) else Modifier)
                    .tvCard(card.onPick, RoundedCornerShape(12.dp), chosen = card.chosen)
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                Text(
                    card.name,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                card.note?.let {
                    Text(
                        it,
                        fontSize = 13.sp,
                        color = Color.White.copy(alpha = 0.7f),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}

// The cards of one choice: subtitles off or a track, the audio as sub, dub or a track, the qualities with sub or dub under them, or the speeds.
@Composable
private fun stripCards(picker: Picker, state: SessionState, player: PlayerState, calls: StripCalls): List<StripCard> {
    val video = state.current
    val versions = VideoChoice.versions(state.videos, video)
    val sub = stringResource(Res.string.player_audio_sub)
    val dub = stringResource(Res.string.player_audio_dub)
    return when (picker) {
        Picker.Subtitles -> listOf(
            StripCard(
                "off",
                stringResource(Res.string.player_subtitles_off),
                null,
                player.subtitle == null,
            ) { calls.onSubtitle(null) },
        ) +
            player.subtitles.map { track ->
                StripCard(track.id, trackName(track), null, player.subtitle == track.id) {
                    calls.onSubtitle(track.id)
                }
            }

        Picker.Audio -> buildList {
            versions?.let { (subbed, dubbed) ->
                add(StripCard("sub", sub, null, video != null && VideoChoice.isSub(video)) { calls.onVideo(subbed) })
                add(StripCard("dub", dub, null, video != null && VideoChoice.isDub(video)) { calls.onVideo(dubbed) })
            }
            player.audios.forEach { track ->
                add(
                    StripCard(track.id, trackName(track), null, player.audio == track.id) {
                        calls.onAudio(track.id)
                    },
                )
            }
        }

        Picker.Quality -> state.videos.mapIndexed { at, item ->
            val label = (
                if (versions ==
                    null
                ) {
                    item.quality
                } else {
                    VideoChoice.withoutVersion(item.quality)
                }
                )?.takeIf { it.isNotBlank() }
            val version = versions?.let { if (VideoChoice.isDub(item)) dub else sub }
            StripCard("$at", label ?: stringResource(Res.string.player_server, at + 1), version, item == video) {
                calls.onVideo(item)
            }
        }

        Picker.Speed -> PickerSpeeds.map { speed ->
            StripCard(
                speed.toString(),
                speedText(speed) + "×",
                null,
                abs(player.speed - speed) < 0.001f,
            ) { calls.onSpeed(speed) }
        }

        else -> emptyList()
    }
}

// The name of an episode without the number it starts with, since the card already shows it, or null when nothing is left.
internal fun restOfName(name: String?, number: String): String? {
    val trimmed = name?.trim()?.takeIf { it.isNotBlank() } ?: return null
    if (!trimmed.startsWith(number, ignoreCase = true)) return trimmed
    return trimmed.drop(number.length).trimStart(':', '-', ' ', '·').ifBlank { null }
}
