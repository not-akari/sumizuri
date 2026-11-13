package com.sumizuri.app.feature.library.top

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.outlined.TravelExplore
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.library_search
import com.sumizuri.app.shared.resources.library_search_help
import com.sumizuri.app.shared.resources.library_search_help_text
import com.sumizuri.app.shared.resources.library_search_sources
import com.sumizuri.app.shared.resources.ok
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.setting.SettingIcon
import org.jetbrains.compose.resources.stringResource

// The search with a button beside it that says how to search.
@Composable
internal fun LibrarySearchRow(query: String, onQuery: (String) -> Unit) {
    var help by remember { mutableStateOf(false) }
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        AppSearchBar(
            query,
            onQuery,
            stringResource(Res.string.library_search),
            Modifier.weight(1f),
            pauseMs = 150,
            historyPlace = "library",
        )
        IconButton({
            help = true
        }) { Icon(Icons.AutoMirrored.Outlined.HelpOutline, stringResource(Res.string.library_search_help)) }
    }
    if (help) {
        AppDialog(
            onDismissRequest = { help = false },
            title = { Text(stringResource(Res.string.library_search_help)) },
            text = { Text(stringResource(Res.string.library_search_help_text)) },
            confirmButton = { InkButton({ help = false }) { Text(stringResource(Res.string.ok)) } },
        )
    }
}

// A line under the search of the library that looks for the same words in every source, for a title that is not saved yet.

@Composable
internal fun SearchSourcesRow(query: String, onClick: () -> Unit) {
    AppCard(Modifier.fillMaxWidth(), onClick) {
        Row(
            Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SettingIcon(Icons.Outlined.TravelExplore)

            Text(
                stringResource(Res.string.library_search_sources, query.trim()),
                Modifier.weight(1f),
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )

            ListChevron()
        }
    }
}
