package com.sumizuri.app.feature.settings.data

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.font.FontWeight
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.storage.DatabaseTables
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_percent
import com.sumizuri.app.shared.resources.storage_anilist_season_covers
import com.sumizuri.app.shared.resources.storage_anilist_season_covers_hint
import com.sumizuri.app.shared.resources.storage_books
import com.sumizuri.app.shared.resources.storage_books_kept
import com.sumizuri.app.shared.resources.storage_clear
import com.sumizuri.app.shared.resources.storage_data_chapters
import com.sumizuri.app.shared.resources.storage_data_hint
import com.sumizuri.app.shared.resources.storage_data_library
import com.sumizuri.app.shared.resources.storage_data_logs
import com.sumizuri.app.shared.resources.storage_data_marks
import com.sumizuri.app.shared.resources.storage_data_size
import com.sumizuri.app.shared.resources.storage_data_sources
import com.sumizuri.app.shared.resources.storage_data_titles
import com.sumizuri.app.shared.resources.storage_image_cache
import com.sumizuri.app.shared.resources.storage_image_disk_limit
import com.sumizuri.app.shared.resources.storage_image_memory_limit
import com.sumizuri.app.shared.resources.storage_images_hint
import com.sumizuri.app.shared.resources.storage_library_data
import com.sumizuri.app.shared.resources.storage_minutes
import com.sumizuri.app.shared.resources.storage_page_cache
import com.sumizuri.app.shared.resources.storage_page_keep
import com.sumizuri.app.shared.resources.storage_page_memory_limit
import com.sumizuri.app.shared.resources.storage_part_images
import com.sumizuri.app.shared.resources.storage_part_reader
import com.sumizuri.app.shared.resources.storage_reader_hint
import com.sumizuri.app.shared.resources.storage_usage
import com.sumizuri.app.ui.kit.image.PageCache
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The choices for each limit of the caches.
private val DiskSizes = listOf(64, 128, 256, 512, 1024, 2048)
private val MemoryShares = listOf(10, 15, 25, 35, 50)
private val PageSizes = listOf(32, 64, 128, 256, 512)
private val KeepTimes = listOf(1, 5, 15, 30, 60, 180)
private val BookCounts = listOf(3, 5, 10, 20)

// The picture cache: how much it holds with a button to clear it, its limits, and the season posters.
@Composable
internal fun StorageImagesRoute(onBack: () -> Unit) {
    val context = LocalPlatformContext.current
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val diskMb by settings.imageDiskMb.collectAsStateWithLifecycle()
    val memoryPercent by settings.imageMemoryPercent.collectAsStateWithLifecycle()
    val aniListCovers by settings.aniListSeasonCovers.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    var round by remember { mutableIntStateOf(0) }
    val images = rememberImageBytes(round, diskMb)
    SettingsPageFrame(Res.string.storage_part_images, onBack, subtitle = Res.string.storage_images_hint, onReset = {
        container.settings.resetNames(
            SettingKey.ImageDiskMb,
            SettingKey.ImageMemoryPercent,
            SettingKey.AniListSeasonCovers,
        )
    }) {
        SettingsSection {
            row {
                UsageRow(Res.string.storage_image_cache, images, diskMb) {
                    clearImageCaches(context)
                    scope.launch { container.seasonCovers.clear() }
                    round++
                }
            }
            padded {
                ChoiceSetting(Res.string.storage_image_disk_limit, DiskSizes, diskMb, { sizeLabel(it) }) {
                    settings.onImageDiskMb(it)
                }
            }
            padded {
                ChoiceSetting(Res.string.storage_image_memory_limit, MemoryShares, memoryPercent, {
                    stringResource(Res.string.display_percent, it)
                }) { settings.onImageMemoryPercent(it) }
            }
        }
        SettingsSection {
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
    }
}

// The pages the reader keeps in memory: how much it holds with a button to clear it, and how much and how long it keeps.
@Composable
internal fun StorageReaderRoute(onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val pageMb by settings.pageMemoryMb.collectAsStateWithLifecycle()
    val keepMinutes by settings.pageKeepMinutes.collectAsStateWithLifecycle()
    val booksKept by settings.booksKept.collectAsStateWithLifecycle()
    var round by remember { mutableIntStateOf(0) }
    val pages = remember(round) { PageCache.bytes() }
    SettingsPageFrame(Res.string.storage_part_reader, onBack, subtitle = Res.string.storage_reader_hint, onReset = {
        container.settings.resetNames(SettingKey.PageMemoryMb, SettingKey.PageKeepMinutes, SettingKey.BooksKept)
    }) {
        SettingsSection {
            row {
                UsageRow(Res.string.storage_page_cache, pages, pageMb, Icons.AutoMirrored.Outlined.MenuBook) {
                    PageCache.clear()
                    round++
                }
            }
            padded {
                ChoiceSetting(Res.string.storage_page_memory_limit, PageSizes, pageMb, { sizeLabel(it) }) {
                    settings.onPageMemoryMb(it)
                }
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
    }
}

// What the database of this profile holds, counted when the page opens.
@Composable
internal fun StorageDataRoute(onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val tables by produceState<DatabaseTables?>(null) { value = container.storage.tables() }
    SettingsPageFrame(Res.string.storage_library_data, onBack, subtitle = Res.string.storage_data_hint) {
        val shown = tables ?: return@SettingsPageFrame
        SettingsSection {
            row { CountRow(Res.string.storage_data_size, byteSizeText(shown.bytes)) }
            row { CountRow(Res.string.storage_data_library, shown.inLibrary.toString()) }
            row { CountRow(Res.string.storage_data_titles, shown.titles.toString()) }
            row { CountRow(Res.string.storage_data_chapters, shown.chapters.toString()) }
            row { CountRow(Res.string.storage_data_marks, shown.marks.toString()) }
            row { CountRow(Res.string.storage_data_sources, shown.sources.toString()) }
            row { CountRow(Res.string.storage_data_logs, shown.logs.toString()) }
        }
    }
}

// A cache with how much it holds of its limit and a button that clears it.
@Composable
private fun UsageRow(
    title: StringResource,
    bytes: Long,
    limitMb: Int,
    icon: androidx.compose.ui.graphics.vector.ImageVector = Icons.Outlined.Image,
    onClear: () -> Unit,
) {
    SettingRow(
        stringResource(title),
        leading = { SettingIcon(icon) },
        subtitle = stringResource(Res.string.storage_usage, byteSizeText(bytes), byteSizeText(limitMb * 1024L * 1024L)),
        trailing = {
            IconButton(onClear) { Icon(Icons.Outlined.DeleteOutline, stringResource(Res.string.storage_clear)) }
        },
    )
}

// A name with a number at the end.
@Composable
private fun CountRow(title: StringResource, value: String) {
    SettingRow(
        stringResource(title),
        trailing = {
            Text(
                value,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary,
            )
        },
    )
}
