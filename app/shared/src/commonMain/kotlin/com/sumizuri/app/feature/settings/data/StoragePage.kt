package com.sumizuri.app.feature.settings.data

import androidx.compose.foundation.layout.Row
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil3.SingletonImageLoader
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.storage.StorageUse
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_percent
import com.sumizuri.app.shared.resources.settings_storage
import com.sumizuri.app.shared.resources.settings_storage_hint
import com.sumizuri.app.shared.resources.storage_anilist_season_covers
import com.sumizuri.app.shared.resources.storage_anilist_season_covers_hint
import com.sumizuri.app.shared.resources.storage_books
import com.sumizuri.app.shared.resources.storage_books_kept
import com.sumizuri.app.shared.resources.storage_clear
import com.sumizuri.app.shared.resources.storage_clear_all
import com.sumizuri.app.shared.resources.storage_copy_path
import com.sumizuri.app.shared.resources.storage_gigabytes
import com.sumizuri.app.shared.resources.storage_group_data
import com.sumizuri.app.shared.resources.storage_group_images
import com.sumizuri.app.shared.resources.storage_group_pages
import com.sumizuri.app.shared.resources.storage_group_paths
import com.sumizuri.app.shared.resources.storage_image_cache
import com.sumizuri.app.shared.resources.storage_image_disk_limit
import com.sumizuri.app.shared.resources.storage_image_memory_limit
import com.sumizuri.app.shared.resources.storage_library_data
import com.sumizuri.app.shared.resources.storage_library_data_hint
import com.sumizuri.app.shared.resources.storage_megabytes
import com.sumizuri.app.shared.resources.storage_minutes
import com.sumizuri.app.shared.resources.storage_open_folder
import com.sumizuri.app.shared.resources.storage_page_cache
import com.sumizuri.app.shared.resources.storage_page_keep
import com.sumizuri.app.shared.resources.storage_page_memory_limit
import com.sumizuri.app.shared.resources.storage_path_data
import com.sumizuri.app.shared.resources.storage_path_database
import com.sumizuri.app.shared.resources.storage_path_images
import com.sumizuri.app.shared.resources.storage_usage
import com.sumizuri.app.ui.kit.canOpenFolders
import com.sumizuri.app.ui.kit.image.PageCache
import com.sumizuri.app.ui.kit.image.PageImages
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.kit.openFolder
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.stringResource

// The choices for each limit of the caches.
private val DiskSizes = listOf(64, 128, 256, 512, 1024, 2048)
private val MemoryShares = listOf(10, 15, 25, 35, 50)
private val PageSizes = listOf(32, 64, 128, 256, 512)
private val KeepTimes = listOf(1, 5, 15, 30, 60, 180)
private val BookCounts = listOf(3, 5, 10, 20)

// The page for the storage of the app: the image cache and the reader page cache, each with how much it holds, its limits and a button to clear it, the size of the library database, and where the files are, which can be copied and, on a computer, opened in the file manager.
@Composable
fun StorageRoute(onBack: () -> Unit) {
    val context = LocalPlatformContext.current
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val diskMb by settings.imageDiskMb.collectAsStateWithLifecycle()
    val memoryPercent by settings.imageMemoryPercent.collectAsStateWithLifecycle()
    val pageMb by settings.pageMemoryMb.collectAsStateWithLifecycle()
    val keepMinutes by settings.pageKeepMinutes.collectAsStateWithLifecycle()
    val booksKept by settings.booksKept.collectAsStateWithLifecycle()
    val aniListCovers by settings.aniListSeasonCovers.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    // Counted again after each clear.
    var round by remember { mutableIntStateOf(0) }
    val images by produceState(0L, round, diskMb) {
        value =
            withContext(Dispatchers.IO) {
                (SingletonImageLoader.get(context).diskCache?.size ?: 0L) +
                    (PageImages.get(context).diskCache?.size ?: 0L)
            }
    }
    val data by produceState(StorageUse(), round) { value = container.storage.use() }
    val pages = remember(round) { PageCache.bytes() }
    val imageFolder = remember(diskMb) {
        SingletonImageLoader
            .get(context)
            .diskCache
            ?.directory
            ?.toString()
            .orEmpty()
    }
    val database = container.databasePath
    val dataFolder = remember(database) { database.substringBeforeLast('/', database.substringBeforeLast('\\', "")) }
    fun clearImages() {
        val loader = SingletonImageLoader.get(context)
        loader.diskCache?.clear()
        loader.memoryCache?.clear()
        PageImages.get(context).diskCache?.clear()
        scope.launch { container.seasonCovers.clear() }
        round++
    }
    SettingsPageFrame(Res.string.settings_storage, onBack, subtitle = Res.string.settings_storage_hint, onReset = {
        container.settings.reset("cache.")
    }) {
        SettingsSection(Res.string.storage_group_images) {
            row {
                SettingRow(
                    stringResource(Res.string.storage_image_cache),
                    leading = { SettingIcon(Icons.Outlined.Image) },
                    subtitle = stringResource(
                        Res.string.storage_usage,
                        byteSizeText(images),
                        byteSizeText(diskMb * 1024L * 1024L),
                    ),
                    trailing = {
                        IconButton(
                            ::clearImages,
                        ) { Icon(Icons.Outlined.DeleteOutline, stringResource(Res.string.storage_clear)) }
                    },
                )
            }
            padded {
                ChoiceSetting(Res.string.storage_image_disk_limit, DiskSizes, diskMb, {
                    sizeLabel(it)
                }) { settings.onImageDiskMb(it) }
            }
            padded {
                ChoiceSetting(Res.string.storage_image_memory_limit, MemoryShares, memoryPercent, {
                    stringResource(Res.string.display_percent, it)
                }) { settings.onImageMemoryPercent(it) }
            }
            padded {
                SwitchSetting(
                    Res.string.storage_anilist_season_covers,
                    aniListCovers,
                    settings::onAniListSeasonCovers,
                    hint = Res.string.storage_anilist_season_covers_hint,
                    icon = Icons.Outlined.Image,
                )
            }
        }
        SettingsSection(Res.string.storage_group_pages) {
            row {
                SettingRow(
                    stringResource(Res.string.storage_page_cache),
                    leading = { SettingIcon(Icons.AutoMirrored.Outlined.MenuBook) },
                    subtitle = stringResource(
                        Res.string.storage_usage,
                        byteSizeText(pages),
                        byteSizeText(pageMb * 1024L * 1024L),
                    ),
                    trailing = {
                        IconButton({
                            PageCache.clear()
                            round++
                        }) { Icon(Icons.Outlined.DeleteOutline, stringResource(Res.string.storage_clear)) }
                    },
                )
            }
            padded {
                ChoiceSetting(Res.string.storage_page_memory_limit, PageSizes, pageMb, {
                    sizeLabel(it)
                }) { settings.onPageMemoryMb(it) }
            }
            padded {
                ChoiceSetting(Res.string.storage_page_keep, KeepTimes, keepMinutes, {
                    stringResource(Res.string.storage_minutes, it)
                }) { settings.onPageKeepMinutes(it) }
            }
            padded {
                ChoiceSetting(Res.string.storage_books_kept, BookCounts, booksKept, {
                    stringResource(Res.string.storage_books, it)
                }) { settings.onBooksKept(it) }
            }
        }
        SettingsSection(Res.string.storage_group_data) {
            row {
                SettingRow(
                    stringResource(Res.string.storage_library_data),
                    leading = { SettingIcon(Icons.Outlined.Storage) },
                    subtitle = "${byteSizeText(
                        data.databaseBytes,
                    )} · ${stringResource(Res.string.storage_library_data_hint, data.titles, data.chapters)}",
                )
            }
            row {
                SettingRow(
                    stringResource(Res.string.storage_clear_all),
                    leading = { SettingIcon(Icons.Outlined.DeleteSweep) },
                    onClick = {
                        clearImages()
                        PageCache.clear()
                        round++
                    },
                )
            }
        }
        SettingsSection(Res.string.storage_group_paths) {
            row { PathRow(Res.string.storage_path_database, database, Icons.Outlined.Description) }
            row { PathRow(Res.string.storage_path_data, dataFolder, Icons.Outlined.Folder) }
            row { PathRow(Res.string.storage_path_images, imageFolder, Icons.Outlined.PhotoLibrary) }
        }
    }
}

// The words for a size in megabytes, in gigabytes from one up.
@Composable
private fun sizeLabel(megabytes: Int): String = if (megabytes >=
    1024
) {
    stringResource(Res.string.storage_gigabytes, megabytes / 1024)
} else {
    stringResource(Res.string.storage_megabytes, megabytes)
}

// A place where the app keeps files, written out in full. Tapping the row copies it, and on a computer a button opens the folder.
@Composable
private fun PathRow(title: org.jetbrains.compose.resources.StringResource, path: String, icon: ImageVector) {
    if (path.isBlank()) return
    val copy = rememberCopyText()
    SettingRow(
        stringResource(title),
        subtitle = path,
        subtitleLines = 3,
        leading = { SettingIcon(icon) },
        trailing = {
            Row {
                IconButton({
                    copy(path)
                }) {
                    Icon(
                        Icons.Outlined.ContentCopy,
                        stringResource(Res.string.storage_copy_path),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                if (canOpenFolders()) {
                    IconButton({
                        openFolder(path)
                    }) {
                        Icon(
                            Icons.Outlined.FolderOpen,
                            stringResource(Res.string.storage_open_folder),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
        },
        onClick = { copy(path) },
    )
}
