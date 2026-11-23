package com.sumizuri.app.feature.tv.title

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.library.EpisodeStill
import com.sumizuri.app.data.library.showNameOf
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.chapter.seasonGroups
import com.sumizuri.app.feature.title.chapter.seasonLookupNames
import com.sumizuri.app.feature.title.chapter.seasonNumbers
import com.sumizuri.app.feature.title.chapter.seasonTitle
import com.sumizuri.app.feature.tv.library.meltLeftAndDown
import com.sumizuri.app.feature.tv.library.rememberWideArt
import com.sumizuri.app.feature.tv.onboarding.firstFocus
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.episodes_count
import com.sumizuri.app.shared.resources.player_episodes
import com.sumizuri.app.shared.resources.refresh
import com.sumizuri.app.shared.resources.title_add
import com.sumizuri.app.shared.resources.title_in_library
import com.sumizuri.app.shared.resources.try_again
import com.sumizuri.app.shared.resources.tv_play
import com.sumizuri.app.shared.resources.tv_resume_button
import com.sumizuri.app.shared.resources.tv_title_loading
import com.sumizuri.app.shared.resources.tv_title_seasons
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.focus.focusAlignment
import com.sumizuri.app.ui.kit.cover.focus.rememberCoverFocus
import com.sumizuri.app.ui.text.numberedUnit
import com.sumizuri.app.ui.theme.CoverTheme
import com.sumizuri.app.ui.tv.TvButton
import kotlinx.coroutines.flow.first
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// What the page of a title can ask for on a TV.
internal class TvTitleCalls(
    val onPlay: (ChapterItem) -> Unit,
    val onToggleLibrary: () -> Unit,
    val onRefresh: () -> Unit,
    // Marks an episode watched or not, which a preview cannot do yet.
    val onToggleWatched: ((ChapterItem) -> Unit)?,
)

// A title on a TV, laid out like the library: its art melting in from the right, and on the left its name, a line about it, its genres and summary, and buttons to go on watching, keep it in the library or ask its source again. Under them come its seasons, when it has more than one, and the episodes of the season in focus as a row of wide cards. The focus starts on the first button.
@Composable
internal fun TvTitleScreen(state: TitleState, calls: TvTitleCalls) {
    val title = state.title ?: return
    // The page takes the colors of the cover, as the title page does on a phone and a computer.
    CoverTheme(title.coverUrl) { TitleBody(state, title, calls) }
}

@Composable
private fun TitleBody(state: TitleState, title: Title, calls: TvTitleCalls) {
    val first = firstFocus()
    val seasons = remember(state.reading) { seasonGroups(state.reading) }
    // The pictures of the episodes are looked up by the names of the seasons, when season covers may be looked up.
    val container = LocalAppContainer.current
    val stills by produceState(emptyMap<String, List<EpisodeStill>>(), title.name, seasons.size) {
        if (!container.settings.flag(SettingKey.AniListSeasonCovers, true).first()) return@produceState
        val pairs = state.reading.map { it.season to it.seasonName }
        // With seasons, the show is named without a season of its own at the end, so each season is looked up by its own name.
        val show = if (pairs.map { it.first }.distinct().size >
            1
        ) {
            showNameOf(title.name)
        } else {
            title.name
        }
        value = container.episodeStills.stills(show, seasonLookupNames(show, pairs), seasonNumbers(pairs))
    }
    // A title with seasons shows them first, as on a phone, and OK on one opens its episodes in the same place. Back goes from the episodes to the seasons again, with the season just left in focus.
    val targetSeason = seasons.firstOrNull { group -> group.chapters.any { it.id == state.target?.id } }?.id
    val withSeasons = seasons.size > 1
    // A source may name a show of many seasons after its last one, so with seasons the heading is the show alone.
    val heading = if (withSeasons) showNameOf(title.name) else title.name
    var opened by rememberSaveable { mutableStateOf<String?>(null) }
    var left by rememberSaveable { mutableStateOf<String?>(null) }
    val open = if (withSeasons) seasons.firstOrNull { it.id == opened } else null
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = open != null) {
        left = opened
        opened = null
    }
    val episodes = open?.chapters ?: state.reading
    val next = state.reading.firstOrNull { it.id == state.target?.id } ?: state.reading.firstOrNull()
    Box(Modifier.fillMaxSize()) {
        Art(title)
        Column(Modifier.fillMaxSize().padding(top = 36.dp, bottom = 28.dp)) {
            Column(Modifier.padding(horizontal = 48.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    heading,
                    Modifier.widthIn(max = 560.dp),
                    fontSize = 30.sp,
                    lineHeight = 36.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    listOfNotNull(
                        stringResource(title.status.label),
                        state.reading.size.takeIf { it > 0 }?.let {
                            pluralStringResource(
                                Res.plurals.episodes_count,
                                it,
                                it,
                            )
                        },
                        state.sourceName,
                    ).joinToString("  ·  "),
                    fontSize = 15.sp,
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 1,
                )
                if (title.genres.isNotEmpty()) {
                    Text(
                        title.genres.take(5).joinToString("   "),
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                    )
                }
                if (title.summary.isNotBlank()) {
                    Text(
                        title.summary,
                        Modifier.widthIn(max = 460.dp),
                        fontSize = 14.sp,
                        lineHeight = 20.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                Row(Modifier.padding(top = 10.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    val resume = state.reading.any { it.read || (it.progress ?: 0f) > 0f }
                    val playText = stringResource(if (resume) Res.string.tv_resume_button else Res.string.tv_play)
                    TvButton(
                        next?.let { "$playText  ·  ${numberedUnit(Kind.Anime, it.number)}" } ?: playText,
                        { next?.let(calls.onPlay) },
                        Modifier.focusRequester(first),
                    )
                    TvButton(
                        stringResource(if (title.inLibrary) Res.string.title_in_library else Res.string.title_add),
                        calls.onToggleLibrary,
                        main = false,
                    )
                    TvButton(stringResource(Res.string.refresh), calls.onRefresh, main = false)
                }
            }
            Spacer(Modifier.weight(1f))
            when {
                state.reading.isEmpty() && state.error != null -> Column(
                    Modifier.padding(horizontal = 48.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Text(state.error, fontSize = 16.sp, color = MaterialTheme.colorScheme.error, maxLines = 2)
                    TvButton(stringResource(Res.string.try_again), calls.onRefresh, main = false)
                }

                state.reading.isEmpty() -> Text(
                    stringResource(Res.string.tv_title_loading),
                    Modifier.padding(horizontal = 48.dp),
                    fontSize = 16.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )

                else -> Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        open?.let { seasonTitle(it) }
                            ?: stringResource(
                                if (withSeasons) Res.string.tv_title_seasons else Res.string.player_episodes,
                            ),
                        Modifier.padding(horizontal = 48.dp),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Box(Modifier.height(EpisodeRowHeight)) {
                        if (withSeasons && open == null) {
                            TvSeasonRow(
                                seasons,
                                title,
                                state.seasonCovers,
                                left ?: targetSeason,
                                takeFocus =
                                left != null,
                            ) { group ->
                                opened = group.id
                            }
                        } else {
                            TvEpisodeRow(
                                episodes,
                                title,
                                state.seasonCovers,
                                stills,
                                next,
                                calls,
                                takeFocus =
                                open != null,
                            )
                        }
                    }
                }
            }
        }
    }
}

// The art of the title over the right of the page, fading out to the left and down so the words stay clear.
@Composable
private fun Art(shown: Title) {
    val title = rememberWideArt(shown)
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopEnd) {
        BoxWithConstraints(Modifier.fillMaxWidth(0.62f).fillMaxHeight(0.72f).meltLeftAndDown()) {
            val focus by rememberCoverFocus(title.coverUrl)
            CoverArt(
                title,
                Modifier.fillMaxSize(),
                letterSize = 48,
                aspect = maxWidth / maxHeight,
                alignment = focusAlignment(focus, maxWidth.value, maxHeight.value),
            )
        }
    }
}

// How tall the row of seasons or episodes is, with the line under each card.
private val EpisodeRowHeight = 160.dp
