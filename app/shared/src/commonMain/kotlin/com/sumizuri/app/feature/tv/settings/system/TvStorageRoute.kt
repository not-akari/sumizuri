package com.sumizuri.app.feature.tv.settings.system

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.storage.StorageUse
import com.sumizuri.app.data.storage.freeBytes
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.feature.settings.data.UsageCard
import com.sumizuri.app.feature.settings.data.UsePart
import com.sumizuri.app.feature.settings.data.clearImageCaches
import com.sumizuri.app.feature.settings.data.rememberImageBytes
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.settings_storage
import com.sumizuri.app.shared.resources.settings_storage_hint
import com.sumizuri.app.shared.resources.storage_clear
import com.sumizuri.app.shared.resources.storage_clear_all
import com.sumizuri.app.shared.resources.storage_downloads_none
import com.sumizuri.app.shared.resources.storage_downloads_summary
import com.sumizuri.app.shared.resources.storage_images_hint
import com.sumizuri.app.shared.resources.storage_library_data
import com.sumizuri.app.shared.resources.storage_library_data_hint
import com.sumizuri.app.shared.resources.storage_part_downloads
import com.sumizuri.app.shared.resources.storage_part_images
import com.sumizuri.app.shared.resources.storage_part_reader
import com.sumizuri.app.shared.resources.storage_reader_hint
import com.sumizuri.app.shared.resources.storage_usage
import com.sumizuri.app.shared.resources.tv_storage_remove
import com.sumizuri.app.shared.resources.tv_storage_sure
import com.sumizuri.app.ui.kit.image.PageCache
import com.sumizuri.app.ui.text.byteSizeText
import com.sumizuri.app.ui.tv.TvButton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// What the app takes on a TV: a bar of it, then a row for each part. OK on a cache clears it, and the saved episodes go only on a second press, since they are slow to get back.
@Composable
internal fun TvStorageRoute() {
    val context = LocalPlatformContext.current
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val diskMb by settings.imageDiskMb.collectAsStateWithLifecycle()
    val pageMb by settings.pageMemoryMb.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    // Counted again after each clear.
    var round by remember { mutableIntStateOf(0) }
    var sure by remember { mutableStateOf(false) }
    val images = rememberImageBytes(round, diskMb)
    val data by produceState(StorageUse(), round) { value = container.storage.use() }
    val saved by remember(container) { container.storage.savedByTitle() }.collectAsStateWithLifecycle(emptyList())
    val downloads = remember(saved) { saved.sumOf { it.bytes } }
    val pages = remember(round) { PageCache.bytes() }
    val database = container.databasePath
    val free by produceState<Long?>(null, round, database) {
        value = withContext(Dispatchers.IO) { freeBytes(database) }
    }
    val colors = MaterialTheme.colorScheme
    val downloadsLabel = stringResource(Res.string.storage_part_downloads)
    val imagesLabel = stringResource(Res.string.storage_part_images)
    val dataLabel = stringResource(Res.string.storage_library_data)
    val clear = stringResource(Res.string.storage_clear)
    TvSystemPage(
        stringResource(Res.string.settings_storage),
        stringResource(Res.string.settings_storage_hint),
    ) { first ->
        UsageCard(
            listOf(
                UsePart(downloadsLabel, downloads, colors.primary),
                UsePart(imagesLabel, images, colors.tertiary),
                UsePart(dataLabel, data.databaseBytes, colors.primary.copy(alpha = 0.45f)),
            ),
            free,
        )
        TvInfoRow(
            downloadsLabel,
            if (saved.isEmpty()) {
                stringResource(Res.string.storage_downloads_none)
            } else {
                pluralStringResource(
                    Res.plurals.storage_downloads_summary,
                    saved.size,
                    byteSizeText(downloads),
                    saved.size,
                )
            },
            when {
                saved.isEmpty() -> null
                sure -> stringResource(Res.string.tv_storage_sure)
                else -> stringResource(Res.string.tv_storage_remove)
            },
            {
                when {
                    saved.isEmpty() -> Unit

                    !sure -> sure = true

                    else -> {
                        sure = false
                        val titles = saved.map { it.titleId }
                        scope.launch {
                            for (title in titles) container.downloads.remove(container.storage.savedIdsOf(title))
                        }
                    }
                }
            },
            Modifier.padding(top = 4.dp).focusRequester(first),
            valueColor = if (sure) colors.error else Color.Unspecified,
        )
        TvInfoRow(
            imagesLabel,
            stringResource(Res.string.storage_usage, byteSizeText(images), byteSizeText(diskMb * 1024L * 1024L)) +
                ". " + stringResource(Res.string.storage_images_hint),
            clear,
            {
                clearImageCaches(context)
                scope.launch { container.seasonCovers.clear() }
                round++
            },
        )
        TvInfoRow(
            stringResource(Res.string.storage_part_reader),
            stringResource(Res.string.storage_usage, byteSizeText(pages), byteSizeText(pageMb * 1024L * 1024L)) +
                ". " + stringResource(Res.string.storage_reader_hint),
            clear,
            {
                PageCache.clear()
                round++
            },
        )
        TvInfoRow(
            dataLabel,
            byteSizeText(data.databaseBytes) + ", " +
                stringResource(Res.string.storage_library_data_hint, data.titles, data.chapters),
            null,
            {},
        )
        TvButton(
            stringResource(Res.string.storage_clear_all),
            {
                clearImageCaches(context)
                scope.launch { container.seasonCovers.clear() }
                PageCache.clear()
                round++
            },
            Modifier.padding(top = 6.dp),
            main = false,
        )
    }
}
