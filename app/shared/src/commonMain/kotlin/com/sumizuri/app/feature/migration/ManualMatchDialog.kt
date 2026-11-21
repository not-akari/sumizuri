package com.sumizuri.app.feature.migration

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogProperties
import com.sumizuri.app.data.migration.MigrationItem
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.SourceChoice
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_hand_empty
import com.sumizuri.app.shared.resources.mig_hand_search
import com.sumizuri.app.shared.resources.mig_hand_title
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.input.MenuButton
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// Searches one source by hand for a title the work did not find. The source is picked from the ones of the kind of the title, the name can be changed, and an entry that is tapped becomes the place the title moves to.
@Composable
internal fun ManualMatchDialog(
    item: MigrationItem,
    sources: List<SourceChoice>,
    session: MigrationSession,
    onDismiss: () -> Unit,
) {
    val usable = remember(sources) { sources.filter { it.source.kind == item.title.kind }.map { it.source } }
    var source by remember { mutableStateOf(usable.firstOrNull()) }
    var query by remember { mutableStateOf(item.title.name) }
    var results by remember { mutableStateOf<List<SourceEntry>?>(null) }
    var message by remember { mutableStateOf<String?>(null) }
    var loading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    AppDialog(
        onDismissRequest = onDismiss,
        modifier = Modifier.fillMaxWidth(0.94f).width(560.dp),
        properties = DialogProperties(usePlatformDefaultWidth = false),
        title = { Text(stringResource(Res.string.mig_hand_title)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                source?.let { current ->
                    MenuButton(usable, current, { it.name }) {
                        source = it
                        results = null
                    }
                }
                AppTextField(query, { query = it }, Modifier.fillMaxWidth(), singleLine = true)
                if (loading) InkCircularProgressIndicator(Modifier.width(24.dp), strokeWidth = 2.dp)
                message?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
                results?.let { found ->
                    if (found.isEmpty()) {
                        Text(
                            stringResource(Res.string.mig_hand_empty),
                            color = MaterialTheme.colorScheme.outline,
                        )
                    }
                    LazyColumn(Modifier.heightIn(max = 320.dp)) {
                        items(found, key = { it.url }) { entry ->
                            Column(
                                Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        val chosen = source ?: return@clickable
                                        loading = true
                                        scope.launch {
                                            val failure = session.manualMatch(item.id, chosen, entry)
                                            loading = false
                                            if (failure == null) onDismiss() else message = failure
                                        }
                                    }.padding(vertical = 8.dp),
                            ) {
                                Text(
                                    entry.title,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    maxLines = 2,
                                    overflow = TextOverflow.Ellipsis,
                                )
                                entry.author
                                    ?.takeIf {
                                        it.isNotBlank()
                                    }?.let {
                                        Text(
                                            it,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.outline,
                                        )
                                    }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            InkButton({
                val chosen = source ?: return@InkButton
                loading = true
                message = null
                scope.launch {
                    when (val answer = session.manualSearch(chosen, query.trim())) {
                        is SourceResult.Ok -> results = answer.value
                        is SourceResult.Err -> message = answer.error.message
                    }
                    loading = false
                }
            }, enabled = source != null && query.isNotBlank() && !loading) {
                Text(
                    stringResource(Res.string.mig_hand_search),
                )
            }
        },
        dismissButton = { CancelButton(onDismiss) },
    )
}
