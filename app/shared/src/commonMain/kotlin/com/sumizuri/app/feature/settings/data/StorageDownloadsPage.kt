package com.sumizuri.app.feature.settings.data

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Downloading
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.db.download.SavedTitle
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.storage_delete_action
import com.sumizuri.app.shared.resources.storage_delete_title
import com.sumizuri.app.shared.resources.storage_delete_title_message
import com.sumizuri.app.shared.resources.storage_downloads_hint
import com.sumizuri.app.shared.resources.storage_downloads_none
import com.sumizuri.app.shared.resources.storage_open_queue
import com.sumizuri.app.shared.resources.storage_open_queue_hint
import com.sumizuri.app.shared.resources.storage_part_downloads
import com.sumizuri.app.shared.resources.storage_title_saved
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The saved chapters by title, the biggest first, each with a bar of its share and a button that deletes them, under a way to the queue.
@Composable
internal fun StorageDownloadsRoute(onBack: () -> Unit, onOpen: (SettingsTarget) -> Unit) {
    val container = LocalAppContainer.current
    val saved by remember(container) { container.storage.savedByTitle() }.collectAsStateWithLifecycle(null)
    val scope = rememberCoroutineScope()
    var asking by remember { mutableStateOf<Pair<SavedTitle, String>?>(null) }
    SettingsPageFrame(Res.string.storage_part_downloads, onBack, subtitle = Res.string.storage_downloads_hint) {
        SettingsSection {
            row {
                SettingRow(
                    stringResource(Res.string.storage_open_queue),
                    subtitle = stringResource(Res.string.storage_open_queue_hint),
                    leading = { SettingIcon(Icons.Outlined.Downloading) },
                    trailing = {
                        Icon(
                            Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                            null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    },
                    onClick = { onOpen(SettingsTarget.Downloads) },
                )
            }
        }
        val list = saved ?: return@SettingsPageFrame
        if (list.isEmpty()) {
            Text(
                stringResource(Res.string.storage_downloads_none),
                Modifier.fillMaxWidth().entrance().padding(16.dp),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            return@SettingsPageFrame
        }
        val biggest = list.maxOf { it.bytes }.coerceAtLeast(1L)
        SettingsSection {
            for (item in list) {
                row {
                    SavedTitleRow(
                        item,
                        item.bytes.toFloat() / biggest,
                    ) { name -> asking = item to name }
                }
            }
        }
    }
    asking?.let { (item, name) ->
        ConfirmDialog(
            stringResource(Res.string.storage_delete_title),
            stringResource(Res.string.storage_delete_title_message, name),
            stringResource(Res.string.storage_delete_action),
            onConfirm = {
                asking = null
                scope.launch { container.downloads.remove(container.storage.savedIdsOf(item.titleId)) }
            },
            onDismiss = { asking = null },
        )
    }
}

// One title with saved chapters: its cover, its name, how many chapters and how big, and a thin bar of its size next to the biggest.
@Composable
private fun SavedTitleRow(item: SavedTitle, share: Float, onDelete: (String) -> Unit) {
    val container = LocalAppContainer.current
    val title by remember(item.titleId) { container.library.title(item.titleId) }.collectAsStateWithLifecycle(null)
    val name = title?.name.orEmpty()
    SettingRow(
        name,
        subtitle = pluralStringResource(
            Res.plurals.storage_title_saved,
            item.chapters,
            item.chapters,
            byteSizeText(item.bytes),
        ),
        leading = {
            Box(Modifier.width(34.dp)) { title?.let { CoverArt(it, Modifier.width(34.dp), letterSize = 12) } }
        },
        trailing = {
            IconButton({ onDelete(name) }) {
                Icon(
                    Icons.Outlined.DeleteOutline,
                    stringResource(Res.string.storage_delete_title),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
    )
    Box(
        Modifier
            .padding(start = 60.dp, end = 64.dp, bottom = 10.dp)
            .fillMaxWidth()
            .height(4.dp)
            .clip(CircleShape)
            .background(softFill()),
    ) {
        Box(
            Modifier
                .fillMaxWidth(share.coerceIn(0.02f, 1f))
                .height(4.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary),
        )
    }
}
