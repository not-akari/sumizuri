package com.sumizuri.app.feature.tv.feed

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
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
import com.sumizuri.app.data.library.ChapterLock
import com.sumizuri.app.data.library.chapterLock
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.feed.FeedHeading
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.feature.updates.row.feedChapterText
import com.sumizuri.app.feature.updates.row.feedHeadingText
import com.sumizuri.app.feature.updates.row.feedSpanText
import com.sumizuri.app.feature.updates.row.groupByHeading
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_locked
import com.sumizuri.app.shared.resources.chapter_locked_left
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.focus.focusAlignment
import com.sumizuri.app.ui.kit.cover.focus.rememberCoverFocus
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// How wide an episode card is.
private val CardWidth = 216.dp

// The videos of a feed under the heading of their day, the newest day first.
internal fun tvFeedDays(items: List<UpdateItem>, now: Long): List<Pair<FeedHeading, List<UpdateItem>>> =
    groupByHeading(items.filter { it.title.kind == Kind.Anime }, grid = false, now = now)

// A feed on a TV: the name of the page with its buttons, then a row of episode cards for each day that scrolls sideways. OK on a card plays it and holding OK opens the page of its title. The first card takes the focus, or the first button when there are no cards.
@Composable
internal fun TvFeedPage(
    name: String,
    days: List<Pair<FeedHeading, List<UpdateItem>>>,
    empty: String,
    shares: Map<Long, Float>?,
    onPlay: (UpdateItem) -> Unit,
    onOpen: (UpdateItem) -> Unit,
    actions: @Composable RowScope.(first: Modifier) -> Unit = {},
) {
    val first = remember { FocusRequester() }
    LaunchedEffect(days.isEmpty()) {
        repeat(4) {
            delay(150)
            runCatching { first.requestFocus() }
        }
    }
    val start = Modifier.focusRequester(first)
    Column(Modifier.fillMaxSize().padding(top = 28.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 48.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(name, fontSize = 32.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.weight(1f))
            actions(if (days.isEmpty()) start else Modifier)
        }
        if (days.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(horizontal = 48.dp), contentAlignment = Alignment.Center) {
                Text(empty, fontSize = 19.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            return@Column
        }
        LazyColumn(
            Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 48.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            itemsIndexed(
                days,
                key = { _, (heading, group) -> "${heading.kind}-${heading.stamp}-${group.first().at}" },
            ) { at, (heading, group) ->
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(Modifier.padding(start = 48.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            feedHeadingText(heading, group.first().at),
                            fontSize = 18.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Text(
                            "  ·  ${group.size}",
                            fontSize = 16.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    LazyRow(
                        contentPadding = PaddingValues(horizontal = 48.dp),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                    ) {
                        items(group, key = { "${it.title.id}-${it.at}" }) { item ->
                            EpisodeCard(
                                item,
                                shares?.let { it[item.title.id] ?: 0f },
                                { onPlay(item) },
                                { onOpen(item) },
                                if (at == 0 && item === group.first()) start else Modifier,
                            )
                        }
                    }
                }
            }
        }
    }
}

// One title of one day as a wide card: its art with the episode on it, the new ones with a mark of how many, the watched ones with the last episode and a bar of how far the title has got, and its name under it.
@Composable
private fun EpisodeCard(item: UpdateItem, share: Float?, onPlay: () -> Unit, onOpen: () -> Unit, modifier: Modifier) {
    val colors = MaterialTheme.colorScheme
    val title = item.title
    val watched = share != null
    val lock = remember(item.name) { chapterLock(item.name) }
    Column(Modifier.width(CardWidth), verticalArrangement = Arrangement.spacedBy(7.dp)) {
        BoxWithConstraints(
            modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .tvCard(onPlay, RoundedCornerShape(12.dp), onLongClick = onOpen)
                .padding(3.dp)
                .clip(RoundedCornerShape(9.dp)),
        ) {
            val focus by rememberCoverFocus(title.coverUrl)
            CoverArt(
                title,
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
                    .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.78f)))),
            )
            Text(
                episodeText(item, watched, lock),
                Modifier
                    .align(
                        Alignment.BottomStart,
                    ).padding(start = 10.dp, end = 10.dp, bottom = if (watched) 12.dp else 8.dp),
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (lock != null) {
                Text(
                    lock.left?.let { stringResource(Res.string.chapter_locked_left, it) }
                        ?: stringResource(Res.string.chapter_locked),
                    Modifier
                        .align(Alignment.TopStart)
                        .padding(7.dp)
                        .background(Color.Black.copy(alpha = 0.6f), RoundedCornerShape(50))
                        .padding(horizontal = 8.dp, vertical = 2.dp),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                )
            }
            if (!watched && item.count > 1) {
                Text(
                    "+${item.count}",
                    Modifier
                        .align(Alignment.TopEnd)
                        .padding(7.dp)
                        .background(colors.primary, RoundedCornerShape(50))
                        .padding(horizontal = 8.dp, vertical = 2.dp),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = colors.onPrimary,
                )
            }
            if (share != null) {
                Box(
                    Modifier
                        .align(Alignment.BottomStart)
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(colors.scrim.copy(alpha = 0.5f)),
                ) {
                    Box(Modifier.fillMaxWidth(share).height(4.dp).background(colors.primary))
                }
            }
        }
        Text(
            title.name,
            fontSize = 14.sp,
            color = colors.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

// What a card is called: the last episode of what was watched, or the new episodes, with the note of a lock left out.
@Composable
private fun episodeText(item: UpdateItem, watched: Boolean, lock: ChapterLock?): String {
    val top = item.numbers.max()
    // The name belongs to the first episode, so it is only shown with that one.
    val named = (lock?.name ?: item.name).takeIf { !watched || item.numbers.first() == top }
    return if (watched) feedChapterText(Kind.Anime, top, named) else feedSpanText(Kind.Anime, item.numbers, named)
}
