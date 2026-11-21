package com.sumizuri.app.feature.player.picker

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.dock.PanelHead

// A choice of the player as a panel the island grows to hold, the same as the panels of the reader: a head with the title and a cross, and the lines of the choice under it, scrolling within the room the island gives.
@Composable
internal fun PickerPanel(
    title: String,
    onClose: () -> Unit,
    state: LazyListState = rememberLazyListState(),
    // Something that stays above the lines, such as tabs that pick which lines show.
    top: (@Composable () -> Unit)? = null,
    content: LazyListScope.() -> Unit,
) {
    Column {
        PanelHead(title, onClose)
        top?.let { Box(Modifier.padding(horizontal = 8.dp, vertical = 4.dp)) { it() } }
        LazyColumn(
            Modifier.fillMaxWidth().weight(1f, fill = false),
            state = state,
            contentPadding = PaddingValues(horizontal = 4.dp, vertical = 4.dp),
            content = content,
        )
    }
}
