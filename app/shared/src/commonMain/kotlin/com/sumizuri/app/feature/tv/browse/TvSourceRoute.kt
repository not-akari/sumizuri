package com.sumizuri.app.feature.tv.browse

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.feature.browse.asTitle
import com.sumizuri.app.feature.browse.source.CatalogMark
import com.sumizuri.app.feature.browse.source.SourceBrowseViewModel
import com.sumizuri.app.feature.browse.source.TabLatest
import com.sumizuri.app.feature.browse.source.TabPopular
import com.sumizuri.app.feature.browse.source.TabSearch
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_preferences
import com.sumizuri.app.shared.resources.challenge_open
import com.sumizuri.app.shared.resources.try_again
import com.sumizuri.app.shared.resources.tv_latest
import com.sumizuri.app.shared.resources.tv_popular
import com.sumizuri.app.shared.resources.tv_search
import com.sumizuri.app.shared.resources.tv_search_hint
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.hiddenUnder
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// How near the end of the grid the focus comes before the next page is asked for.
private const val MoreAt = 8

// One source on a TV: its lists as buttons at the top, popular, latest, the lists the source names and search, then its settings when it has any, then the titles of the list as posters. OK on a poster opens its page, and the next page comes as the focus nears the end.
@Composable
internal fun TvSourceRoute(source: InstalledSource, onOpenPreview: (InstalledSource, SourceEntry) -> Unit) {
    val container = LocalAppContainer.current
    val model = viewModel(key = "browse_${source.id}") {
        SourceBrowseViewModel(
            source,
            container.library,
            container.sources,
            container.catalogs,
            container.manager,
            container.session,
            container.solver,
        )
    }
    val state by model.state.collectAsStateWithLifecycle()
    val first = remember { FocusRequester() }
    var settings by remember { mutableStateOf(false) }
    val openSettings = {
        model.onOpenPreferences()
        settings = true
    }
    LaunchedEffect(Unit) {
        repeat(4) {
            delay(150)
            runCatching { first.requestFocus() }
        }
    }
    val tabs = buildList {
        add(TabPopular to stringResource(Res.string.tv_popular))
        add(TabLatest to stringResource(Res.string.tv_latest))
        state.catalogs.forEach { add(CatalogMark + it.id to it.name) }
        add(TabSearch to stringResource(Res.string.tv_search))
    }
    Box(Modifier.fillMaxSize()) {
        Column(
            Modifier.fillMaxSize().hiddenUnder(settings).padding(top = 28.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Row(
                Modifier.padding(horizontal = 48.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                SourceMark(source.iconUrl, size = 44.dp, sourceId = source.id)
                Text(
                    source.name,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            LazyRow(
                contentPadding = PaddingValues(horizontal = 48.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                items(tabs, key = { it.first }) { (key, name) ->
                    TvButton(
                        name,
                        { model.onTab(key) },
                        if (key ==
                            tabs.first().first
                        ) {
                            Modifier.focusRequester(first)
                        } else {
                            Modifier
                        },
                        main = key == state.tab,
                    )
                }
                if (state.hasPreferences) {
                    item(key = "settings") {
                        TvButton(stringResource(Res.string.browse_preferences), openSettings, main = false)
                    }
                }
            }
            if (state.tab == TabSearch) {
                AppTextField(
                    state.query,
                    model::onQuery,
                    Modifier.padding(horizontal = 48.dp).fillMaxWidth(),
                    singleLine = true,
                    placeholder = { Text(stringResource(Res.string.tv_search_hint)) },
                )
            }
            when {
                state.error != null && state.entries.isEmpty() -> Column(
                    Modifier.padding(horizontal = 48.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text(state.error.orEmpty(), fontSize = 17.sp, color = MaterialTheme.colorScheme.error)
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        TvButton(stringResource(Res.string.try_again), model::onRetry)
                        if (state.challengeUrl !=
                            null
                        ) {
                            TvButton(stringResource(Res.string.challenge_open), model::onSolve, main = false)
                        }
                        if (state.hasPreferences) {
                            TvButton(stringResource(Res.string.browse_preferences), openSettings, main = false)
                        }
                    }
                }

                else -> LazyVerticalGrid(
                    GridCells.Adaptive(118.dp),
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 48.dp, end = 48.dp, bottom = 48.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    itemsIndexed(state.entries, key = { at, entry -> entry.url + at }) { at, entry ->
                        // The next page is asked for once the focus or the scroll comes near the end of the list.
                        if (at >= state.entries.size - MoreAt && state.hasMore &&
                            !state.loading
                        ) {
                            LaunchedEffect(state.entries.size) { model.onLoadMore() }
                        }
                        EntryPoster(entry, source, entry.url in state.inLibrary) { onOpenPreview(source, entry) }
                    }
                }
            }
        }
        if (settings && state.preferences.isNotEmpty()) {
            TvSourceSettings(state.preferences, state.preferenceValues, model::onPreference) {
                settings = false
                model.onClosePreferences()
            }
        }
    }
}

// One title of the list as a poster with its name, marked when it is in the library already.
@Composable
private fun EntryPoster(entry: SourceEntry, source: InstalledSource, owned: Boolean, onOpen: () -> Unit) {
    val title = remember(entry) { entry.asTitle(source.kind, source.id) }
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(
            Modifier
                .fillMaxWidth()
                .aspectRatio(2f / 3f)
                .tvCard(onOpen, RoundedCornerShape(12.dp), chosen = owned)
                .padding(3.dp)
                .clip(RoundedCornerShape(9.dp)),
        ) { CoverArt(title, Modifier.fillMaxSize(), letterSize = 22, aspect = 2f / 3f) }
        Text(
            entry.title,
            fontSize = 13.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
