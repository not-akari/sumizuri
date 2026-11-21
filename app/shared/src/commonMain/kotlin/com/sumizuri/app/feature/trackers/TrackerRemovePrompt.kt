package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_remove_entries
import com.sumizuri.app.shared.resources.tracker_remove_keep
import com.sumizuri.app.shared.resources.tracker_remove_message
import com.sumizuri.app.shared.resources.tracker_remove_more
import com.sumizuri.app.shared.resources.tracker_remove_remember
import com.sumizuri.app.shared.resources.tracker_remove_remember_hint
import com.sumizuri.app.shared.resources.tracker_remove_there
import com.sumizuri.app.shared.resources.tracker_remove_title
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.input.AppSwitch
import com.sumizuri.app.ui.kit.input.CheckRow
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The most title names the prompt lists before it only counts the rest.
private const val NamesShown = 3

// Asks where the entries of titles just taken out of the library are removed too, with a switch for each tracker they are on. Either way they stop syncing.
@Composable
fun TrackerRemovePrompt() {
    val sync = LocalAppContainer.current.trackerSync
    val scope = rememberCoroutineScope()
    val links by remember(sync) { sync.removing }.collectAsStateWithLifecycle()
    if (links.isEmpty()) return
    val trackers = remember(links) {
        links
            .mapNotNull {
                TrackerId.of(
                    it.tracker,
                )
            }.groupingBy { it }
            .eachCount()
            .toList()
            .sortedBy { it.first.ordinal }
    }
    val names = remember(links) { links.distinctBy { it.titleId }.map { it.remoteName } }
    var picked by remember(links) { mutableStateOf(trackers.map { it.first }.toSet()) }
    var saveRule by remember(links) { mutableStateOf(false) }
    // A rule is all or nothing, so a mixed pick cannot become one.
    val canRemember = picked.isEmpty() || picked.size == trackers.size

    fun settle(removeOn: Set<TrackerId>) = scope.launch { sync.settleRemoved(removeOn, saveRule && canRemember) }
    AppDialog(
        { scope.launch { sync.settleRemoved(emptySet()) } },
        confirmButton = {
            InkButton({ settle(picked) }, enabled = picked.isNotEmpty()) {
                Text(stringResource(Res.string.tracker_remove_there))
            }
        },
        dismissButton = {
            InkOutlinedButton({ settle(emptySet()) }) { Text(stringResource(Res.string.tracker_remove_keep)) }
        },
        title = { Text(stringResource(Res.string.tracker_remove_title)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(pluralStringResource(Res.plurals.tracker_remove_message, names.size, names.size, namesLine(names)))
                Column {
                    for ((tracker, count) in trackers) {
                        TrackerSwitchRow(tracker, count.takeIf { names.size > 1 }, tracker in picked) { on ->
                            picked = if (on) picked + tracker else picked - tracker
                        }
                    }
                }
                CheckRow(
                    stringResource(Res.string.tracker_remove_remember),
                    saveRule && canRemember,
                    { saveRule = it },
                    hint = stringResource(Res.string.tracker_remove_remember_hint),
                    enabled = canRemember,
                )
            }
        },
    )
}

// The names of the titles, the first few in full and the rest as a count.
@Composable
private fun namesLine(names: List<String>): String {
    val shown = names.take(NamesShown).joinToString(", ")
    if (names.size <= NamesShown) return shown
    return stringResource(Res.string.tracker_remove_more, shown, names.size - NamesShown)
}

// One tracker the titles are on, with how many of their entries are there when there are several titles, and a switch for removing them there.
@Composable
private fun TrackerSwitchRow(tracker: TrackerId, count: Int?, on: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(MaterialTheme.shapes.medium)
            .clickable { onChange(!on) }
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        TrackerLogo(tracker, 32.dp)
        Column(Modifier.weight(1f)) {
            Text(tracker.label, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold)
            count?.let {
                Text(
                    pluralStringResource(Res.plurals.tracker_remove_entries, it, it),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        AppSwitch(on, onChange)
    }
}
