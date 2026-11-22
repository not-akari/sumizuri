package com.sumizuri.app.feature.tv.browse

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.data.sources.RepoMigration
import com.sumizuri.app.data.sources.UpdatesState
import com.sumizuri.app.feature.browse.extensions.ExtensionsViewModel
import com.sumizuri.app.feature.browse.extensions.RemoveRepoDialog
import com.sumizuri.app.feature.browse.extensions.RepoMoveDialog
import com.sumizuri.app.feature.browse.extensions.SourceFileImporter
import com.sumizuri.app.feature.tv.pair.TvPhonePair
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.nav_browse
import com.sumizuri.app.shared.resources.tv_add_repo
import com.sumizuri.app.shared.resources.tv_add_repo_hint
import com.sumizuri.app.shared.resources.tv_cancel
import com.sumizuri.app.shared.resources.tv_no_video_sources
import com.sumizuri.app.shared.resources.tv_pair_card
import com.sumizuri.app.shared.resources.tv_pair_card_hint
import com.sumizuri.app.shared.resources.tv_repo_hold_hint
import com.sumizuri.app.shared.resources.tv_repo_installed
import com.sumizuri.app.shared.resources.tv_repo_menu_move
import com.sumizuri.app.shared.resources.tv_repo_menu_remove
import com.sumizuri.app.shared.resources.tv_repo_menu_update
import com.sumizuri.app.shared.resources.tv_repo_updates
import com.sumizuri.app.shared.resources.tv_repos
import com.sumizuri.app.shared.resources.tv_sources
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.text.languageName
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.TvOverlay
import com.sumizuri.app.ui.tv.TvRow
import com.sumizuri.app.ui.tv.TvShape
import com.sumizuri.app.ui.tv.hiddenUnder
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// Browse on a TV: the video sources as big tiles at the top, OK opening one, and under them the repos as wide cards, OK opening the sources a repo offers, with a card at the end to add a repo on a page made for typing with a remote.
@Composable
internal fun TvBrowseRoute(onOpenSource: (InstalledSource) -> Unit, onOpenRepo: (Repo) -> Unit) {
    val container = LocalAppContainer.current
    val installed by remember(container) { container.sources.installed }.collectAsStateWithLifecycle(emptyList())
    val repos by remember(container) { container.repos.repos }.collectAsStateWithLifecycle(emptyList())
    val updates by remember(container) { container.updates.state }.collectAsStateWithLifecycle(UpdatesState())
    var adding by rememberSaveable { mutableStateOf(false) }
    var pairing by rememberSaveable { mutableStateOf(false) }
    // The repo whose card was held, with its panel of what can be done to it, and the model that removes and moves repos with the usual prompts.
    var holding by remember { mutableStateOf<Repo?>(null) }
    val repoModel = viewModel {
        ExtensionsViewModel(
            container.repos,
            container.updates,
            SourceFileImporter(container.manager, container.sources),
            RepoMigration(container.manager.repos, container.sources, container.database),
        )
    }
    val repoState by repoModel.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val videos = installed.filter { it.kind == Kind.Anime && it.enabled }
    val first = remember { FocusRequester() }
    LaunchedEffect(adding, pairing) {
        if (adding || pairing) return@LaunchedEffect
        repeat(4) {
            delay(150)
            runCatching { first.requestFocus() }
        }
    }
    Box(Modifier.fillMaxSize()) {
        LazyColumn(
            Modifier.fillMaxSize().hiddenUnder(adding || pairing),
            contentPadding = PaddingValues(top = 32.dp, bottom = 48.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item { Heading(stringResource(Res.string.nav_browse), 34) }
            item { Heading(stringResource(Res.string.tv_sources), 20) }
            item {
                if (videos.isEmpty()) {
                    Text(
                        stringResource(Res.string.tv_no_video_sources),
                        Modifier.padding(horizontal = 48.dp),
                        fontSize = 16.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                } else {
                    LazyRow(
                        contentPadding = PaddingValues(horizontal = 48.dp),
                        horizontalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        items(videos, key = { it.id }) { source ->
                            SourceTile(
                                source,
                                { onOpenSource(source) },
                                if (source ==
                                    videos.first()
                                ) {
                                    Modifier.focusRequester(first)
                                } else {
                                    Modifier
                                },
                            )
                        }
                    }
                }
            }
            item { Heading(stringResource(Res.string.tv_repos), 20, top = 14) }
            item {
                Text(
                    stringResource(Res.string.tv_repo_hold_hint),
                    Modifier.padding(horizontal = 48.dp),
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            items(repos, key = { it.url }) { repo ->
                val mine = installed.count { it.repoUrl == repo.url }
                val newer = updates.updates.count { it.repoUrl == repo.url }
                val repoFirst = if (videos.isEmpty() &&
                    repo == repos.first()
                ) {
                    Modifier.focusRequester(first)
                } else {
                    Modifier
                }
                TvRow({ onOpenRepo(repo) }, Modifier.padding(horizontal = 48.dp).then(repoFirst), onLongClick = {
                    holding =
                        repo
                }) {
                    Icon(
                        Icons.Outlined.Inventory2,
                        null,
                        Modifier.size(26.dp),
                        tint = MaterialTheme.colorScheme.primary,
                    )
                    Column(Modifier.weight(1f).padding(start = 8.dp)) {
                        Text(
                            repo.name,
                            fontSize = 19.sp,
                            fontWeight = FontWeight.SemiBold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                        Text(
                            repo.url,
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    Text(
                        pluralStringResource(Res.plurals.tv_repo_installed, mine, mine),
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    if (newer > 0) {
                        Text(
                            pluralStringResource(Res.plurals.tv_repo_updates, newer, newer),
                            Modifier.padding(start = 12.dp),
                            fontSize = 15.sp,
                            color = MaterialTheme.colorScheme.primary,
                        )
                    }
                }
            }
            item {
                val addFirst = if (videos.isEmpty() && repos.isEmpty()) Modifier.focusRequester(first) else Modifier
                TvRow({ adding = true }, Modifier.padding(horizontal = 48.dp).then(addFirst)) {
                    Icon(Icons.Outlined.Add, null, Modifier.size(26.dp), tint = MaterialTheme.colorScheme.primary)
                    Column(Modifier.weight(1f).padding(start = 8.dp)) {
                        Text(stringResource(Res.string.tv_add_repo), fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
                        Text(
                            stringResource(Res.string.tv_add_repo_hint),
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
            item {
                TvRow({ pairing = true }, Modifier.padding(horizontal = 48.dp)) {
                    Icon(
                        Icons.Outlined.PhoneAndroid,
                        null,
                        Modifier.size(26.dp),
                        tint = MaterialTheme.colorScheme.primary,
                    )
                    Column(Modifier.weight(1f).padding(start = 8.dp)) {
                        Text(
                            stringResource(Res.string.tv_pair_card),
                            fontSize = 19.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Text(
                            stringResource(Res.string.tv_pair_card_hint),
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
        }
        AnimatedVisibility(adding, enter = fadeIn(), exit = fadeOut()) {
            NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) {
                adding =
                    false
            }
            TvOverlay {
                TvAddRepo(
                    onCheck = { address -> container.manager.repos.fetchIndex(address) },
                    onAdd = { address ->
                        scope.launch {
                            if (container.repos.add(address) == null) adding = false
                        }
                    },
                )
            }
        }
        AnimatedVisibility(pairing, enter = fadeIn(), exit = fadeOut()) {
            NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) {
                pairing =
                    false
            }
            TvOverlay { TvPhonePair { pairing = false } }
        }
        holding?.let { repo ->
            NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) {
                holding =
                    null
            }
            val newer = updates.updates.filter { it.repoUrl == repo.url }
            RepoPanel(
                repo,
                onUpdate = newer.takeIf { it.isNotEmpty() }?.let { list -> { list.forEach(repoModel::onUpdate) } },
                onMove = { repoModel.onMoveAsk(repo) },
                onRemove = { repoModel.onRemoveAsk(repo) },
                onClose = { holding = null },
            )
        }
    }
    repoState.removing?.let { RemoveRepoDialog(it, repoModel::onRemoveConfirm, repoModel::onRemoveDismiss) }
    repoState.moving?.let { moving ->
        RepoMoveDialog(
            moving,
            repoState.repos.filter { it.url != moving.from.url },
            repoModel::onMoveTarget,
            repoModel::onMoveRemoveOld,
            repoModel::onMoveConfirm,
            repoModel::onMoveDismiss,
        )
    }
}

// What can be done to a repo whose card was held: update its sources that have newer versions, move its sources to another repo, or remove it. Each closes the panel, and the move and the removal ask first.
@Composable
private fun RepoPanel(
    repo: Repo,
    onUpdate: (() -> Unit)?,
    onMove: () -> Unit,
    onRemove: () -> Unit,
    onClose: () -> Unit,
) {
    val first = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        repeat(4) {
            delay(120)
            runCatching { first.requestFocus() }
        }
    }
    fun then(action: () -> Unit): () -> Unit = {
        onClose()
        action()
    }
    Box(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.scrim.copy(alpha = 0.6f)),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            Modifier.width(420.dp).background(MaterialTheme.colorScheme.surfaceContainerHigh, TvShape).padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                repo.name,
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            val start = Modifier.fillMaxWidth().focusRequester(first)
            if (onUpdate != null) TvButton(stringResource(Res.string.tv_repo_menu_update), then(onUpdate), start)
            TvButton(
                stringResource(Res.string.tv_repo_menu_move),
                then(onMove),
                if (onUpdate ==
                    null
                ) {
                    start
                } else {
                    Modifier.fillMaxWidth()
                },
                main = false,
            )
            TvButton(
                stringResource(Res.string.tv_repo_menu_remove),
                then(onRemove),
                Modifier.fillMaxWidth(),
                main = false,
            )
            TvButton(stringResource(Res.string.tv_cancel), onClose, Modifier.fillMaxWidth(), main = false)
        }
    }
}

@Composable
private fun Heading(text: String, size: Int, top: Int = 0) {
    Text(text, Modifier.padding(start = 48.dp, top = top.dp), fontSize = size.sp, fontWeight = FontWeight.SemiBold)
}

// One video source as a big tile: its mark, its name and its language.
@Composable
private fun SourceTile(source: InstalledSource, onOpen: () -> Unit, modifier: Modifier) {
    Column(
        modifier
            .width(170.dp)
            .height(150.dp)
            .tvCard(onOpen)
            .padding(14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
    ) {
        SourceMark(source.iconUrl, size = 52.dp, sourceId = source.id)
        Text(
            source.name,
            Modifier.fillMaxWidth(),
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
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
}
