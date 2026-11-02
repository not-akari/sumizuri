package com.sumizuri.app.feature.sync.data

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.backup.ImportedTitle
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_bring
import com.sumizuri.app.shared.resources.sync_on_device
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.setting.SettingRow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// What this device has of the titles of the server's copy: the ones it holds, by source and address, and the cover each one shows here, by source and name.
internal class OnDevice(val keys: Set<String>, val covers: Map<String, String>) {
    fun has(title: ImportedTitle): Boolean = "${title.sourceId}|${title.url}" in keys

    fun cover(title: ImportedTitle): String? = covers["${title.sourceId}|${title.name}"]
}

// Reads which titles of the copy this device has, and keeps it up to date while the page is open.
@Composable
internal fun rememberOnDevice(titles: List<ImportedTitle>): State<OnDevice?> {
    val library = LocalAppContainer.current.library
    val sources = titles.mapNotNull { it.sourceId }.distinct()
    // Null until this device has been read, so no row says it is missing here before that is known.
    return produceState<OnDevice?>(null, sources) {
        val saved = if (sources.isEmpty()) {
            flowOf(
                emptyList(),
            )
        } else {
            combine(
                sources.map { id ->
                    library.savedKeys(id).map { keys ->
                        keys.map {
                            "$id|$it"
                        }
                    }
                },
            ) { it.toList().flatten() }
        }
        combine(saved, library.library) { keys, local ->
            OnDevice(
                keys.toSet(),
                local.filter { !it.coverUrl.isNullOrBlank() }.associate {
                    "${it.sourceId}|${it.name}" to
                        it.coverUrl!!
                },
            )
        }.collect { value = it }
    }
}

// One title of the server's copy with its cover, the cover this device shows when it has the title and the address the copy keeps when it does not, and whether this device has it.
@Composable
internal fun CopyTitleRow(title: ImportedTitle, subtitle: String, device: OnDevice?) {
    val here = device?.has(title) == true
    val shown = Title(
        id = 0,
        name = title.name,
        kind = title.kind,
        coverUrl = device?.cover(title) ?: title.coverUrl,
        unread = 0,
        status = title.status ?: Status.Unknown,
        summary = "",
        inLibrary = here,
        sourceId = title.sourceId.orEmpty(),
    )
    SettingRow(
        title.name,
        subtitle = subtitle,
        leading = { CoverArt(shown, Modifier.width(40.dp), letterSize = 16) },
        trailing = {
            if (device == null) return@SettingRow
            if (here) {
                Text(
                    stringResource(Res.string.sync_on_device),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.SemiBold,
                )
            } else {
                // A title only the server has can be put into the library here with one tap. The row says it is here once the library has it.
                val bringer = LocalAppContainer.current.titleFromServer
                val scope = rememberCoroutineScope()
                var adding by remember(title.url) { mutableStateOf(false) }
                InkOutlinedButton(
                    {
                        adding = true
                        scope.launch { bringer.bring(title) }
                    },
                    Modifier.height(34.dp),
                    enabled = !adding,
                    contentPadding = PaddingValues(horizontal = 12.dp),
                ) { Text(stringResource(Res.string.sync_bring), style = MaterialTheme.typography.labelMedium) }
            }
        },
    )
}
