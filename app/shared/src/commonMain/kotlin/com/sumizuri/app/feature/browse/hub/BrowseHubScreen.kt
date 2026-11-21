package com.sumizuri.app.feature.browse.hub

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Code
import androidx.compose.material.icons.outlined.FileOpen
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.Storefront
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.reposData
import com.sumizuri.app.feature.browse.extensions.ExtensionsRoute
import com.sumizuri.app.feature.browse.repo.RemoveSourceDialog
import com.sumizuri.app.feature.share.ShareDialog
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_add
import com.sumizuri.app.shared.resources.browse_share_repos
import com.sumizuri.app.shared.resources.browse_title
import com.sumizuri.app.shared.resources.ext_edit_new_row
import com.sumizuri.app.shared.resources.extensions_add_file
import com.sumizuri.app.shared.resources.extensions_add_repo
import com.sumizuri.app.shared.resources.global_search_title
import com.sumizuri.app.shared.resources.share_kind_repos
import com.sumizuri.app.shared.resources.share_title
import com.sumizuri.app.shared.resources.sources_count
import com.sumizuri.app.shared.resources.sources_updates_notice
import com.sumizuri.app.ui.kit.chips.FilterTabs
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.kit.page.ListWithSide
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.page.sideFits
import kotlinx.coroutines.flow.drop
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// Browse: the installed sources on one page and the repos they come from on the other, under the bar the other main pages have, with a button that adds a repo, a file or a source of the person's own from either page. A swipe or a tap on a tab slides from one page to the other, and a wide window shows both side by side.
@Composable
fun BrowseHubScreen(state: BrowseHubState, actions: BrowseHubActions) {
    val tabs = BrowseTab.entries
    val pager = rememberPagerState(initialPage = state.tab.ordinal) { tabs.size }
    // A tab picked from outside the pager, such as by the notice of updates, slides the pager there, and a page the pager settles on is the tab.
    LaunchedEffect(state.tab) {
        if (pager.currentPage !=
            state.tab.ordinal
        ) {
            pager.animateScrollToPage(state.tab.ordinal)
        }
    }
    // The page the pager starts on is the tab already, so only a page it later settles on is told, which keeps a tab picked meanwhile, such as by a link that adds a repo.
    val latest by rememberUpdatedState(actions)
    LaunchedEffect(pager) {
        snapshotFlow { pager.settledPage }.drop(1).collect { latest.onTab(tabs[it]) }
    }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        // A wide window shows the repos beside the sources, so there are no tabs and no empty side.
        val room = maxWidth
        val both = sideFits(room)
        Column(Modifier.fillMaxSize()) {
            PageTopBar(
                stringResource(Res.string.browse_title),
                subtitle = if (state.loaded) subtitle(state) else null,
            ) {
                if (state.sourceCount > 0) {
                    IconButton(
                        { actions.onOpenSearch("") },
                    ) { Icon(Icons.Outlined.Search, stringResource(Res.string.global_search_title)) }
                }
                AddMenu(actions)
            }
            ListWithSide(false, both, room, Modifier.weight(1f), panelGutter = 0.dp, panel = { place ->
                Box(place) { ExtensionsRoute(actions.onOpenRepo, actions.onNewSource) }
            }) {
                if (both) {
                    SourcesTab(state, actions)
                } else {
                    Tabbed(state, actions, pager)
                }
            }
        }
    }
    state.removing?.let { RemoveSourceDialog(it, actions.onConfirmRemove, actions.onCancelRemove) }
}

// The sources and the repos as two pages under the plain tabs every page has, for a window with no room for both.
@Composable
private fun Tabbed(state: BrowseHubState, actions: BrowseHubActions, pager: PagerState) {
    val tabs = BrowseTab.entries
    Column(Modifier.fillMaxSize()) {
        FilterTabs(
            tabs.map { it to stringResource(it.label) },
            state.tab,
            actions.onTab,
            Modifier.padding(horizontal = PageGutter),
        )
        HorizontalPager(
            pager,
            Modifier.weight(1f).fillMaxWidth(),
            key = { tabs[it] },
            verticalAlignment = Alignment.Top,
        ) { page ->
            when (tabs[page]) {
                // The tiles of the sources fill the width, and the repos are a list that keeps a readable one.
                BrowseTab.Sources -> SourcesTab(state, actions)

                BrowseTab.Extensions -> ReadableColumn { ExtensionsRoute(actions.onOpenRepo, actions.onNewSource) }
            }
        }
    }
}

// The count of sources, and the count of updates when there are any.
@Composable
private fun subtitle(state: BrowseHubState): String {
    val count = pluralStringResource(Res.plurals.sources_count, state.sourceCount, state.sourceCount)
    if (state.updateCount == 0) return count
    return count + ", " +
        pluralStringResource(Res.plurals.sources_updates_notice, state.updateCount, state.updateCount).lowercase()
}

// The ways to get more sources, under one button in the bar, and sharing the repos the person added.
@Composable
private fun AddMenu(actions: BrowseHubActions) {
    var open by remember { mutableStateOf(false) }
    val repos by LocalAppContainer.current.repos.repos
        .collectAsStateWithLifecycle(emptyList())
    var sharing by remember { mutableStateOf(false) }
    if (sharing) {
        val data = remember(repos) { reposData(repos) }
        val name = stringResource(Res.string.share_kind_repos)
        ShareDialog(stringResource(Res.string.share_title, name), "Sumizuri repos", ShareKind.Repos, data) {
            sharing =
                false
        }
    }
    Box {
        IconButton({ open = true }) { Icon(Icons.Outlined.Add, stringResource(Res.string.browse_add)) }
        AppMenu(open, { open = false }) {
            AddItem(Res.string.extensions_add_repo, Icons.Outlined.Storefront) {
                open = false
                actions.onAddRepo()
            }
            AddItem(Res.string.extensions_add_file, Icons.Outlined.FileOpen) {
                open = false
                actions.onAddFile()
            }
            AddItem(Res.string.ext_edit_new_row, Icons.Outlined.Code) {
                open = false
                actions.onNewSource()
            }
            if (repos.isNotEmpty()) {
                AddItem(Res.string.browse_share_repos, Icons.Outlined.Share) {
                    open = false
                    sharing = true
                }
            }
        }
    }
}

@Composable
private fun AddItem(label: StringResource, icon: ImageVector, onClick: () -> Unit) {
    AppMenuItem(text = {
        Text(stringResource(label))
    }, leadingIcon = { Icon(icon, null, Modifier.size(20.dp)) }, onClick = onClick)
}
