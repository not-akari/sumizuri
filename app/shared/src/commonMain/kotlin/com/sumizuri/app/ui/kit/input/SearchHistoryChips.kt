package com.sumizuri.app.ui.kit.input

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.History
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SearchHistory
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.search_history_clear
import com.sumizuri.app.ui.kit.chips.ChipRow
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// How long the words must stay as they are before they count as a search, so the letters typed on the way are not kept.
private const val SettleMs = 2000L

// The searches of one place, and the way to keep, use and forget them.
internal class SearchHistoryOf(
    val recent: List<String>,
    private val place: String,
    private val scope: CoroutineScope,
    private val store: SearchHistory,
) {
    fun keep(words: String) {
        scope.launch { store.add(place, words) }
    }

    fun clear() {
        scope.launch { store.clear(place) }
    }
}

// The history of a place, which keeps the words once they have stayed a moment.
@Composable
internal fun rememberSearchHistory(place: String, text: String): SearchHistoryOf {
    val store = LocalAppContainer.current.searchHistory
    val scope = rememberCoroutineScope()
    val recent by remember(store, place) { store.recent(place) }.collectAsState(emptyList())
    LaunchedEffect(text) {
        if (text.isBlank()) return@LaunchedEffect
        delay(SettleMs)
        store.add(place, text)
    }
    return SearchHistoryOf(recent, place, scope, store)
}

// The searches of the place as chips under the empty field. A tap searches again, and the button at the end forgets them all.
@Composable
internal fun SearchHistoryChips(history: SearchHistoryOf, onPick: (String) -> Unit) {
    if (history.recent.isEmpty()) return
    ChipRow(Modifier.padding(top = 8.dp)) {
        for (words in history.recent) {
            AssistChip(
                onClick = { onPick(words) },
                label = { Text(words) },
                leadingIcon = { Icon(Icons.Outlined.History, null) },
            )
        }
        TextButton(history::clear) { Text(stringResource(Res.string.search_history_clear)) }
    }
}
