package com.sumizuri.app.feature.tv.library

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.nav_browse
import com.sumizuri.app.shared.resources.tv_library_empty
import com.sumizuri.app.shared.resources.tv_row_all
import com.sumizuri.app.shared.resources.tv_row_continue
import com.sumizuri.app.shared.resources.tv_row_more
import com.sumizuri.app.shared.resources.tv_row_new
import com.sumizuri.app.shared.resources.tv_row_popular
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// How tall the area for the title in focus is, how wide a poster is, and how long the focus rests before that area follows it.
private val HeroHeight = 230.dp
private val PosterWidth = 112.dp
private const val RestMs = 450L

// The library on a TV, videos only: the title in focus large at the top with its art and a way to play it, and under it rows that scroll sideways, the ones being watched first, then new episodes, the genres the library has most, and every title. Under those come what the video sources offer: more of those genres and each source's popular titles.
@Composable
internal fun TvLibraryRoute(
    onOpenTitle: (Long) -> Unit,
    onPlay: (Long) -> Unit,
    onBrowse: () -> Unit,
    onOpenFound: (Found) -> Unit,
) {
    val container = LocalAppContainer.current
    val model = viewModel { TvLibraryModel(container.library, container.sources, container.manager) }
    val rows by model.rows.collectAsStateWithLifecycle()
    val found by model.found.collectAsStateWithLifecycle()
    val shown = rows ?: return
    if (shown.isEmpty()) {
        // With nothing to show, the way to Browse takes the focus, so the remote always has a place to start.
        val start = remember { FocusRequester() }
        LaunchedEffect(Unit) {
            repeat(4) {
                delay(150)
                runCatching { start.requestFocus() }
            }
        }
        Column(
            Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                stringResource(Res.string.tv_library_empty),
                fontSize = 20.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            TvButton(
                stringResource(Res.string.nav_browse),
                onBrowse,
                Modifier.padding(top = 24.dp).focusRequester(start),
            )
        }
        return
    }
    TvLibraryScreen(shown, found, onOpenTitle, onPlay, onOpenFound)
}

@Composable
private fun TvLibraryScreen(
    rows: List<TvRow>,
    found: List<FoundRow>,
    onOpenTitle: (Long) -> Unit,
    onPlay: (Long) -> Unit,
    onOpenFound: (Found) -> Unit,
) {
    // The hero follows the card the focus rests on, once it has stayed a moment, so moving fast does not load art for every card.
    var resting by remember { mutableStateOf<HeroItem>(HeroItem.Owned(rows.first().entries.first())) }
    var hero by remember { mutableStateOf(resting) }
    LaunchedEffect(resting) {
        delay(RestMs)
        hero = resting
    }
    val first = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        repeat(4) {
            delay(150)
            runCatching { first.requestFocus() }
        }
    }
    val open: (HeroItem) -> Unit = { item ->
        when (item) {
            is HeroItem.Owned -> onOpenTitle(item.entry.title.id)
            is HeroItem.Offered -> onOpenFound(item.found)
        }
    }
    Column(Modifier.fillMaxSize()) {
        AnimatedContent(
            hero,
            Modifier.fillMaxWidth().height(HeroHeight),
            transitionSpec = { fadeIn(tween(320)) togetherWith fadeOut(tween(220)) },
            contentKey = { it.key },
            label = "hero",
        ) { item -> TvHero(item, onPlay) { open(item) } }
        LazyColumn(
            Modifier.fillMaxWidth().weight(1f),
            contentPadding = PaddingValues(bottom = 48.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            itemsIndexed(rows, key = { _, row -> row.key }) { rowAt, row ->
                PosterRow(
                    rowName(row.kind),
                    row.entries.map { HeroItem.Owned(it) },
                    progress = row.kind == TvRowKind.Continue,
                    onRest = { resting = it },
                    onOpen = open,
                    firstFocus = first.takeIf { rowAt == 0 },
                )
            }
            items(found, key = { it.key }) { row ->
                PosterRow(
                    foundName(row.kind),
                    row.items.map { HeroItem.Offered(it) },
                    false,
                    { resting = it },
                    open,
                    null,
                )
            }
        }
    }
}

// The name of a row and its posters in a line that scrolls sideways as the focus moves along it.
@Composable
private fun PosterRow(
    name: String,
    items: List<HeroItem>,
    progress: Boolean,
    onRest: (HeroItem) -> Unit,
    onOpen: (HeroItem) -> Unit,
    firstFocus: FocusRequester?,
) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(name, Modifier.padding(start = 48.dp), fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
        LazyRow(
            contentPadding = PaddingValues(horizontal = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            items(items, key = { it.key }) { item ->
                Poster(
                    item.title,
                    progress = progress,
                    onRest = { onRest(item) },
                    onOpen = { onOpen(item) },
                    modifier = if (firstFocus != null &&
                        item == items.first()
                    ) {
                        Modifier.focusRequester(firstFocus)
                    } else {
                        Modifier
                    },
                )
            }
        }
    }
}

// One title as a poster with its name under it, and in the continue row a bar of how far it was watched. The focus puts a ring around it and lets the hero follow it.
@Composable
private fun Poster(
    title: Title,
    progress: Boolean,
    onRest: () -> Unit,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(12.dp)
    Column(Modifier.width(PosterWidth), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(
            modifier
                .fillMaxWidth()
                .aspectRatio(2f / 3f)
                .onFocusChanged { if (it.isFocused) onRest() }
                .tvCard(onOpen, shape)
                .padding(3.dp)
                .clip(RoundedCornerShape(9.dp)),
        ) {
            CoverArt(title, Modifier.fillMaxSize(), letterSize = 22, aspect = 2f / 3f)
            if (progress) {
                Box(
                    Modifier
                        .align(Alignment.BottomStart)
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(MaterialTheme.colorScheme.scrim.copy(alpha = 0.5f)),
                ) {
                    Box(
                        Modifier
                            .fillMaxWidth(
                                watchedShare(title),
                            ).height(4.dp)
                            .background(MaterialTheme.colorScheme.primary),
                    )
                }
            }
        }
        Text(
            title.name,
            fontSize = 13.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun rowName(kind: TvRowKind): String = when (kind) {
    TvRowKind.Continue -> stringResource(Res.string.tv_row_continue)
    TvRowKind.New -> stringResource(Res.string.tv_row_new)
    is TvRowKind.Genre -> kind.name
    TvRowKind.All -> stringResource(Res.string.tv_row_all)
}

@Composable
private fun foundName(kind: FoundKind): String = when (kind) {
    is FoundKind.Popular -> stringResource(Res.string.tv_row_popular, kind.source)
    is FoundKind.Genre -> stringResource(Res.string.tv_row_more, kind.name)
}
