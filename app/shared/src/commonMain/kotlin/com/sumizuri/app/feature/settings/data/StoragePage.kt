package com.sumizuri.app.feature.settings.data

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil3.SingletonImageLoader
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.storage.StorageUse
import com.sumizuri.app.data.storage.freeBytes
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.settings_storage
import com.sumizuri.app.shared.resources.settings_storage_hint
import com.sumizuri.app.shared.resources.storage_clear_all
import com.sumizuri.app.shared.resources.storage_downloads_none
import com.sumizuri.app.shared.resources.storage_downloads_summary
import com.sumizuri.app.shared.resources.storage_library_data
import com.sumizuri.app.shared.resources.storage_library_data_hint
import com.sumizuri.app.shared.resources.storage_part_downloads
import com.sumizuri.app.shared.resources.storage_part_images
import com.sumizuri.app.shared.resources.storage_part_reader
import com.sumizuri.app.shared.resources.storage_usage
import com.sumizuri.app.ui.kit.card.PageTile
import com.sumizuri.app.ui.kit.card.TileGrid
import com.sumizuri.app.ui.kit.image.PageCache
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The home of the storage: a bar of what the app takes on the drive, a tile for each kind that opens its own page, a button that clears every cache, and the folders folded at the end.
@Composable
fun StorageRoute(onBack: () -> Unit, onOpen: (SettingsTarget) -> Unit) {
    val context = LocalPlatformContext.current
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val diskMb by settings.imageDiskMb.collectAsStateWithLifecycle()
    val pageMb by settings.pageMemoryMb.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    // Counted again after each clear.
    var round by remember { mutableIntStateOf(0) }
    val images = rememberImageBytes(round, diskMb)
    val data by produceState(StorageUse(), round) { value = container.storage.use() }
    val saved by remember(container) { container.storage.savedByTitle() }.collectAsStateWithLifecycle(emptyList())
    val downloads = remember(saved) { saved.sumOf { it.bytes } }
    val pages = remember(round) { PageCache.bytes() }
    val database = container.databasePath
    val free by produceState<Long?>(
        null,
        round,
        database,
    ) { value = withContext(Dispatchers.IO) { freeBytes(database) } }
    val imageFolder = remember(diskMb) {
        SingletonImageLoader
            .get(context)
            .diskCache
            ?.directory
            ?.toString()
            .orEmpty()
    }
    val dataFolder = remember(database) { database.substringBeforeLast('/', database.substringBeforeLast('\\', "")) }
    val colors = MaterialTheme.colorScheme
    val downloadsLabel = stringResource(Res.string.storage_part_downloads)
    val imagesLabel = stringResource(Res.string.storage_part_images)
    val dataLabel = stringResource(Res.string.storage_library_data)
    SettingsPageFrame(Res.string.settings_storage, onBack, subtitle = Res.string.settings_storage_hint, onReset = {
        container.settings.reset("cache.")
    }) {
        UsageCard(
            listOf(
                UsePart(downloadsLabel, downloads, colors.primary),
                UsePart(imagesLabel, images, colors.tertiary),
                UsePart(dataLabel, data.databaseBytes, colors.primary.copy(alpha = 0.45f)),
            ),
            free,
        )
        val downloadsLine = if (saved.isEmpty()) {
            stringResource(Res.string.storage_downloads_none)
        } else {
            pluralStringResource(Res.plurals.storage_downloads_summary, saved.size, byteSizeText(downloads), saved.size)
        }
        val imagesLine =
            stringResource(Res.string.storage_usage, byteSizeText(images), byteSizeText(diskMb * 1024L * 1024L))
        val readerLine =
            stringResource(Res.string.storage_usage, byteSizeText(pages), byteSizeText(pageMb * 1024L * 1024L))
        val dataLine = byteSizeText(data.databaseBytes) + ", " +
            stringResource(Res.string.storage_library_data_hint, data.titles, data.chapters)
        BoxWithConstraints(Modifier.fillMaxWidth().entrance()) {
            TileGrid(
                if (this.maxWidth >= 440.dp) 2 else 1,
                listOf(
                    {
                        PageTile(
                            Icons.Outlined.Download,
                            downloadsLabel,
                            downloadsLine,
                            { onOpen(SettingsTarget.StorageDownloads) },
                            it,
                        )
                    },
                    {
                        PageTile(
                            Icons.Outlined.Image,
                            imagesLabel,
                            imagesLine,
                            { onOpen(SettingsTarget.StorageImages) },
                            it,
                        )
                    },
                    {
                        PageTile(
                            Icons.AutoMirrored.Outlined.MenuBook,
                            stringResource(Res.string.storage_part_reader),
                            readerLine,
                            { onOpen(SettingsTarget.StorageReader) },
                            it,
                        )
                    },
                    {
                        PageTile(
                            Icons.Outlined.Storage,
                            dataLabel,
                            dataLine,
                            { onOpen(SettingsTarget.StorageData) },
                            it,
                        )
                    },
                ),
            )
        }
        SettingsSection {
            row {
                SettingRow(
                    stringResource(Res.string.storage_clear_all),
                    leading = { SettingIcon(Icons.Outlined.DeleteSweep) },
                    onClick = {
                        clearImageCaches(context)
                        scope.launch { container.seasonCovers.clear() }
                        PageCache.clear()
                        round++
                    },
                )
            }
        }
        LocationsFold(database, dataFolder, imageFolder)
    }
}
