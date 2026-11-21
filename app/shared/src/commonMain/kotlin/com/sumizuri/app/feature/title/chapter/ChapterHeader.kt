package com.sumizuri.app.feature.title.chapter

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CopyAll
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapters_duplicates
import com.sumizuri.app.shared.resources.chapters_hide_duplicates
import com.sumizuri.app.shared.resources.chapters_show_duplicates
import com.sumizuri.app.shared.resources.title_newest_first
import com.sumizuri.app.shared.resources.title_oldest_first
import com.sumizuri.app.shared.resources.title_view_chapters
import com.sumizuri.app.shared.resources.title_view_volumes
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.chips.SortChip
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The order of the chapters as a chip that turns it around. The buttons for the options, asking the source again and the menu are in the bar at the top. The count is left out, since the page already says it.
@Composable
internal fun ChapterHeader(state: TitleState, calls: TitleCallbacks) {
    // The switch sits over the row, as the page puts the header in a box that would lay the two on top of each other.
    Column(Modifier.fillMaxWidth()) {
        // A source that lists the title both by chapter and by volume gets a switch between the two over the list.
        state.volumeSwitch?.let { onVolumes ->
            Row(Modifier.fillMaxWidth().padding(bottom = 4.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ChoiceChip(stringResource(Res.string.title_view_chapters), !onVolumes) { if (onVolumes) calls.onSwitchVolumes() }
                ChoiceChip(stringResource(Res.string.title_view_volumes), onVolumes) { if (!onVolumes) calls.onSwitchVolumes() }
            }
        }
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            SortChip(stringResource(if (state.oldestFirst) Res.string.title_oldest_first else Res.string.title_newest_first), state.oldestFirst, calls.onToggleSort)
        }
    }
}

// Says how many chapters are listed twice, and turns showing them on or off.
@Composable
internal fun DuplicatesBanner(count: Int, hiding: Boolean, onToggle: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(start = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Outlined.CopyAll, null, Modifier.size(16.dp), tint = MaterialTheme.colorScheme.tertiary)
        Text(
            pluralStringResource(Res.plurals.chapters_duplicates, count, count),
            Modifier.weight(1f).padding(start = 8.dp),
            style = MaterialTheme.typography.bodySmall,
        )
        TextButton(onToggle) { Text(stringResource(if (hiding) Res.string.chapters_show_duplicates else Res.string.chapters_hide_duplicates)) }
    }
}
