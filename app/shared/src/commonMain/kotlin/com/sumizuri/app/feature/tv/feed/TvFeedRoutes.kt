package com.sumizuri.app.feature.tv.feed

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.history.HistoryViewModel
import com.sumizuri.app.feature.title.chapter.continueTargetOf
import com.sumizuri.app.feature.title.toItem
import com.sumizuri.app.feature.tv.library.watchedShare
import com.sumizuri.app.feature.updates.UpdatesViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.nav_history
import com.sumizuri.app.shared.resources.nav_updates
import com.sumizuri.app.shared.resources.tv_cancel
import com.sumizuri.app.shared.resources.tv_history_empty
import com.sumizuri.app.shared.resources.tv_updates_check
import com.sumizuri.app.shared.resources.tv_updates_checking
import com.sumizuri.app.shared.resources.tv_updates_empty
import com.sumizuri.app.shared.resources.tv_updates_failed
import com.sumizuri.app.ui.tv.TvButton
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The new episodes on a TV, a row for each day. OK plays the first new episode of a card, and the button at the top checks the library for more, or stops a check while it runs.
@Composable
internal fun TvUpdatesRoute(onPlay: (Long) -> Unit, onOpenTitle: (Long) -> Unit) {
    val container = LocalAppContainer.current
    val model = viewModel {
        UpdatesViewModel(
            container.library,
            container.sync,
            container.updatesPrefs,
            container.libraryPrefs,
            container.categories,
            container.sources,
        )
    }
    val state by model.state.collectAsStateWithLifecycle()
    if (!state.loaded) return
    val days = remember(state.items, state.now) { tvFeedDays(state.items, state.now) }
    TvFeedPage(
        stringResource(Res.string.nav_updates),
        days,
        stringResource(Res.string.tv_updates_empty),
        shares = null,
        // The lowest new episode of a card is played, so the episodes are watched in order.
        onPlay = { onPlay(it.chapterIds[it.numbers.indexOf(it.numbers.min())]) },
        onOpen = { onOpenTitle(it.title.id) },
    ) { first ->
        val progress = state.progress
        when {
            progress != null -> {
                Text(
                    stringResource(Res.string.tv_updates_checking, progress.done, progress.total),
                    fontSize = 16.sp,
                    color = MaterialTheme.colorScheme.primary,
                )
                TvButton(stringResource(Res.string.tv_cancel), model::onCancelUpdate, first, main = false)
            }

            else -> {
                if (state.failures.isNotEmpty()) {
                    Text(
                        pluralStringResource(Res.plurals.tv_updates_failed, state.failures.size, state.failures.size),
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
                TvButton(stringResource(Res.string.tv_updates_check), model::onUpdate, first)
            }
        }
    }
}

// What was watched on a TV, a row for each day with how far each title has got. OK goes on with the title where it was left, the way the button on its page does.
@Composable
internal fun TvHistoryRoute(onPlay: (Long) -> Unit, onOpenTitle: (Long) -> Unit) {
    val container = LocalAppContainer.current
    val model = viewModel { HistoryViewModel(container.library, container.historyPrefs, container.libraryPrefs) }
    val state by model.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    // The titles of the history come without their episode counts, so how far each has got is read from the library.
    val shares by remember(container) {
        container.library.entries().map { list -> list.associate { it.title.id to watchedShare(it.title) } }
    }.collectAsStateWithLifecycle(emptyMap())
    if (!state.loaded) return
    val days = remember(state.items, state.now) { tvFeedDays(state.items, state.now) }
    TvFeedPage(
        stringResource(Res.string.nav_history),
        days,
        stringResource(Res.string.tv_history_empty),
        shares = shares,
        onPlay = { item ->
            scope.launch {
                val next = runCatching {
                    continueTargetOf(
                        container.library
                            .chapters(item.title.id)
                            .first()
                            .map { it.toItem() },
                        nowMillis(),
                    )
                }.getOrNull()
                onPlay(next?.id ?: item.chapterIds.first())
            }
        },
        onOpen = { onOpenTitle(it.title.id) },
    )
}
