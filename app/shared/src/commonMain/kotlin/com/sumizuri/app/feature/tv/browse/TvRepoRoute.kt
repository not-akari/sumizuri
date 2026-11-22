package com.sumizuri.app.feature.tv.browse

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.feature.browse.repo.RemoveSourceDialog
import com.sumizuri.app.feature.browse.repo.RepoState
import com.sumizuri.app.feature.browse.repo.RepoViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.try_again
import com.sumizuri.app.shared.resources.tv_adult
import com.sumizuri.app.shared.resources.tv_all_languages
import com.sumizuri.app.shared.resources.tv_install
import com.sumizuri.app.shared.resources.tv_installed
import com.sumizuri.app.shared.resources.tv_off
import com.sumizuri.app.shared.resources.tv_on
import com.sumizuri.app.shared.resources.tv_repo_no_video
import com.sumizuri.app.shared.resources.tv_update
import com.sumizuri.app.shared.resources.tv_update_all
import com.sumizuri.app.shared.resources.tv_working
import com.sumizuri.app.source.repo.RepoSource
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.text.languageName
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.TvRow
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// The sources of one repo on a TV, videos only. The languages are a list down the left with how many sources each has, and the switch for sources for adults under them, so a filter is a move up or down. The sources fill the right, and OK installs one, updates one that has a newer version, or asks before removing an installed one.
@Composable
internal fun TvRepoRoute(repo: Repo) {
    val container = LocalAppContainer.current
    val model =
        viewModel(
            key = "repo_${repo.url}",
        ) { RepoViewModel(repo, container.sources, container.manager, container.library) }
    val state by model.state.collectAsStateWithLifecycle()
    // Only the video sources show on a TV.
    LaunchedEffect(state.kinds) {
        if (Kind.Anime in state.kinds &&
            state.chosenKind != Kind.Anime
        ) {
            model.onKind(Kind.Anime)
        }
    }
    val first = remember { FocusRequester() }
    LaunchedEffect(state.loading) {
        if (state.loading) return@LaunchedEffect
        repeat(4) {
            delay(150)
            runCatching { first.requestFocus() }
        }
    }
    Column(
        Modifier.fillMaxSize().padding(start = 48.dp, end = 48.dp, top = 32.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(
                    repo.name,
                    fontSize = 34.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(repo.url, fontSize = 14.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
            }
            if (state.updates.any { it.kind == Kind.Anime }) {
                TvButton(
                    stringResource(Res.string.tv_update_all),
                    model::onUpdateAll,
                )
            }
        }
        when {
            state.loading -> Unit

            state.error != null -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(state.error.orEmpty(), fontSize = 17.sp, color = MaterialTheme.colorScheme.error)
                TvButton(stringResource(Res.string.try_again), model::onLoad, Modifier.focusRequester(first))
            }

            Kind.Anime !in state.kinds -> Text(
                stringResource(Res.string.tv_repo_no_video),
                fontSize = 18.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            else -> Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                Filters(state, first, model::onLanguage, model::onShowNsfw)
                LazyVerticalGrid(
                    GridCells.Adaptive(300.dp),
                    Modifier.weight(1f).fillMaxHeight(),
                    contentPadding = PaddingValues(bottom = 48.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    items(state.groups.flatMap { it.sources }, key = { it.id }) { source ->
                        SourceRow(source, state) {
                            val have = state.installed[source.id]
                            when {
                                have == null || have.version < source.version -> model.onInstall(source)
                                else -> model.onRemove(have.id, source.name)
                            }
                        }
                    }
                }
            }
        }
    }
    state.removing?.let { RemoveSourceDialog(it, model::onConfirmRemove, model::onCancelRemove) }
}

// The languages, all first, each with how many video sources it has, the one on show lit, and the switch for sources for adults when the repo has any.
@Composable
private fun Filters(
    state: RepoState,
    first: FocusRequester,
    onLanguage: (String?) -> Unit,
    onAdult: (Boolean) -> Unit,
) {
    val videos = state.available.filter { it.kind == Kind.Anime && (state.showNsfw || !it.nsfw) }
    val counts = videos.groupingBy { it.lang }.eachCount()
    LazyColumn(
        Modifier.width(250.dp).fillMaxHeight(),
        contentPadding = PaddingValues(bottom = 48.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item {
            FilterRow(
                stringResource(Res.string.tv_all_languages),
                videos.size,
                state.language == null,
                Modifier.focusRequester(first),
            ) {
                onLanguage(null)
            }
        }
        items(state.languages, key = { it }) { language ->
            FilterRow(
                languageName(language),
                counts[language] ?: 0,
                state.language == language,
            ) { onLanguage(language) }
        }
        if (state.hasNsfw) {
            item {
                Spacer(Modifier.padding(top = 6.dp))
                TvRow({ onAdult(!state.showNsfw) }, chosen = state.showNsfw) {
                    Text(stringResource(Res.string.tv_adult), Modifier.weight(1f), fontSize = 16.sp)
                    Text(
                        stringResource(if (state.showNsfw) Res.string.tv_on else Res.string.tv_off),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary,
                    )
                }
            }
        }
    }
}

@Composable
private fun FilterRow(name: String, count: Int, chosen: Boolean, modifier: Modifier = Modifier, onPick: () -> Unit) {
    TvRow(onPick, modifier, chosen = chosen) {
        Text(
            name,
            Modifier.weight(1f),
            fontSize = 16.sp,
            fontWeight = if (chosen) FontWeight.SemiBold else FontWeight.Normal,
            color = if (chosen) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(count.toString(), fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

// One source with its mark, name, language and version, and what OK does to it now.
@Composable
private fun SourceRow(source: RepoSource, state: RepoState, onPress: () -> Unit) {
    val have = state.installed[source.id]
    val status = when {
        source.id in state.busy || have?.id in state.busy -> stringResource(Res.string.tv_working)
        have == null -> stringResource(Res.string.tv_install)
        have.version < source.version -> stringResource(Res.string.tv_update)
        else -> stringResource(Res.string.tv_installed)
    }
    TvRow(onPress, chosen = have != null) {
        SourceMark(source.iconUrl, size = 40.dp, sourceId = source.id)
        Column(Modifier.weight(1f).padding(start = 6.dp)) {
            Text(
                source.name,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                languageName(source.lang),
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
            )
        }
        Text(status, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.primary)
    }
}
