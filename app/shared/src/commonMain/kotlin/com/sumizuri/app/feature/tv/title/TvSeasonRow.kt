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
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.chapter.SeasonGroup
import com.sumizuri.app.feature.title.chapter.seasonTitle
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.season_progress
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.focus.focusAlignment
import com.sumizuri.app.ui.kit.cover.focus.rememberCoverFocus
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// How wide a season card is, the same as an episode card so the two rows line up.
private val CardWidth = 216.dp

// The seasons of a title as wide cards, each with its poster, its name and how much of it was watched, as the title page of a phone shows them. OK opens a season. The season given takes the focus when asked, such as on coming back from its episodes.
@Composable
internal fun TvSeasonRow(
    seasons: List<SeasonGroup>,
    title: Title,
    covers: Map<String, String>,
    focusOn: String?,
    takeFocus: Boolean,
    onOpen: (SeasonGroup) -> Unit,
) {
    val list = rememberLazyListState()
    val start = seasons.indexOfFirst { it.id == focusOn }.coerceAtLeast(0)
    val focus = remember { FocusRequester() }
    LaunchedEffect(takeFocus) {
        if (start > 0) list.scrollToItem(start)
        if (!takeFocus) return@LaunchedEffect
        repeat(10) {
            delay(80)
            if (runCatching { focus.requestFocus() }.getOrDefault(false)) return@LaunchedEffect
        }
    }
    LazyRow(
        state = list,
        contentPadding = PaddingValues(horizontal = 48.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        itemsIndexed(seasons, key = { _, group -> group.id }) { at, group ->
            val art = group.key?.let(covers::get) ?: group.coverUrl
            SeasonCard(
                group,
                remember(title, art) { if (art != null) title.copy(coverUrl = art) else title },
                { onOpen(group) },
                if (at == start) Modifier.focusRequester(focus) else Modifier,
            )
        }
    }
}

@Composable
private fun SeasonCard(group: SeasonGroup, art: Title, onOpen: () -> Unit, modifier: Modifier) {
    val colors = MaterialTheme.colorScheme
    val total = group.chapters.size
    val share = if (total > 0) group.watched.toFloat() / total else 0f
    Column(Modifier.width(CardWidth), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        BoxWithConstraints(
            modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .tvCard(onOpen, RoundedCornerShape(12.dp))
                .padding(3.dp)
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
                    .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.78f)))),
            )
            Text(
                seasonTitle(group),
                Modifier.align(Alignment.BottomStart).padding(start = 10.dp, end = 10.dp, bottom = 12.dp),
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (share > 0f) {
                Box(
                    Modifier
                        .align(
                            Alignment.BottomStart,
                        ).fillMaxWidth()
                        .height(4.dp)
                        .background(colors.scrim.copy(alpha = 0.5f)),
                ) {
                    Box(Modifier.fillMaxWidth(share.coerceIn(0f, 1f)).height(4.dp).background(colors.primary))
                }
            }
        }
        Text(
            stringResource(Res.string.season_progress, group.watched, total),
            fontSize = 13.sp,
            color = colors.onSurfaceVariant,
            maxLines = 1,
        )
    }
}
