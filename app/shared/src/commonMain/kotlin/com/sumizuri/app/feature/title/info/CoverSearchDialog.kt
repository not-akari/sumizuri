package com.sumizuri.app.feature.title.info

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.close
import com.sumizuri.app.shared.resources.cover_search_busy
import com.sumizuri.app.shared.resources.cover_search_hint
import com.sumizuri.app.shared.resources.cover_search_none
import com.sumizuri.app.shared.resources.cover_search_title
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.valueOrNull
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.input.AppSearchBar
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import org.jetbrains.compose.resources.stringResource

// How many sources are asked at once, and how many covers each may give.
private const val AtOnce = 3
private const val PerSource = 6

// The typing pauses this long before the sources are asked.
private const val TypingPauseMs = 400L

// One cover a source gave for the name, with the source it came through.
internal class FoundCover(val url: String, val name: String, val sourceId: String, val sourceName: String)

// Asks the other sources of the same kind for the name of the title and shows the covers they give. A tap picks one.
@Composable
internal fun CoverSearchDialog(title: Title, onPick: (FoundCover) -> Unit, onDismiss: () -> Unit) {
    val container = LocalAppContainer.current
    var query by remember { mutableStateOf(title.name) }
    val found = remember { mutableStateListOf<FoundCover>() }
    var busy by remember { mutableStateOf(true) }
    LaunchedEffect(query) {
        found.clear()
        val words = query.trim()
        if (words.isEmpty()) {
            busy = false
            return@LaunchedEffect
        }
        busy = true
        delay(TypingPauseMs)
        val sources = container.sources.installed.first().filter {
            it.enabled && it.kind == title.kind &&
                it.id != title.sourceId
        }
        val gate = Semaphore(AtOnce)
        coroutineScope {
            sources
                .map { source ->
                    async {
                        gate.withPermit {
                            val opened = container.manager.open(source).valueOrNull() ?: return@withPermit
                            val entries = (opened.search(words, 1) as? SourceResult.Ok)?.value.orEmpty()
                            // A picture given twice, such as the stand in a site shows for every title without a cover, is shown once.
                            val shown = found.mapTo(HashSet()) { it.url }
                            found += entries
                                .filter { !it.coverUrl.isNullOrBlank() }
                                .distinctBy { it.coverUrl }
                                .filter { it.coverUrl !in shown }
                                .take(PerSource)
                                .map { FoundCover(it.coverUrl!!, it.title, source.id, source.name) }
                        }
                    }
                }.awaitAll()
        }
        busy = false
    }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.cover_search_title)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                AppSearchBar(query, { query = it }, stringResource(Res.string.cover_search_hint))
                when {
                    found.isEmpty() && busy -> Text(
                        stringResource(Res.string.cover_search_busy),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )

                    found.isEmpty() -> Text(
                        stringResource(Res.string.cover_search_none),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )

                    else -> LazyVerticalGrid(
                        GridCells.Adaptive(96.dp),
                        Modifier.fillMaxWidth().heightIn(max = 420.dp),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        items(found, key = { it.url }) { cover ->
                            Column(
                                Modifier.clickable { onPick(cover) },
                                verticalArrangement = Arrangement.spacedBy(4.dp),
                            ) {
                                CoverArt(cover.asTitle(title), letterSize = 18)
                                Text(
                                    cover.sourceName,
                                    style = MaterialTheme.typography.labelSmall,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = { TextButton(onDismiss) { Text(stringResource(Res.string.close)) } },
    )
}

// A title to draw a found cover with, so the picture loads with the headers of the source that gave it.
private fun FoundCover.asTitle(of: Title) = Title(
    id = 0,
    name = name,
    kind = of.kind,
    coverUrl = url,
    unread = 0,
    status = Status.Unknown,
    summary = "",
    inLibrary = false,
    sourceId = sourceId,
)
