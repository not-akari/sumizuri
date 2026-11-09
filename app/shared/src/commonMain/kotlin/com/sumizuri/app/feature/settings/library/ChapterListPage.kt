package com.sumizuri.app.feature.settings.library

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.TriFilter
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.feature.title.chapter.sortLabel
import com.sumizuri.app.feature.title.chapter.triLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_filter_bookmarked
import com.sumizuri.app.shared.resources.chapter_filter_downloaded
import com.sumizuri.app.shared.resources.chapter_filter_settings_hint
import com.sumizuri.app.shared.resources.chapter_filter_title
import com.sumizuri.app.shared.resources.chapter_filter_unread
import com.sumizuri.app.shared.resources.chapter_group_display
import com.sumizuri.app.shared.resources.chapter_group_sorting
import com.sumizuri.app.shared.resources.chapter_list_duplicates
import com.sumizuri.app.shared.resources.chapter_list_duplicates_hint
import com.sumizuri.app.shared.resources.chapter_list_grid
import com.sumizuri.app.shared.resources.chapter_list_grid_hint
import com.sumizuri.app.shared.resources.chapter_list_oldest
import com.sumizuri.app.shared.resources.chapter_list_oldest_hint
import com.sumizuri.app.shared.resources.chapter_list_pictures
import com.sumizuri.app.shared.resources.chapter_list_pictures_hint
import com.sumizuri.app.shared.resources.chapter_settings_hint
import com.sumizuri.app.shared.resources.chapter_settings_title
import com.sumizuri.app.shared.resources.chapter_sort_hint
import com.sumizuri.app.shared.resources.chapter_sort_title
import com.sumizuri.app.shared.resources.reader_skip_filtered
import com.sumizuri.app.shared.resources.reader_skip_filtered_hint
import com.sumizuri.app.shared.resources.reader_skip_read
import com.sumizuri.app.shared.resources.reader_skip_read_hint
import com.sumizuri.app.shared.resources.reading_group_chapters
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The page for the list of chapters of every title: its order, how it looks, the chapters it hides, and where the next and the one before lead. A title page changes the same choices from its chapter options.
@Composable
fun ChapterListRoute(onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val chapters = viewModel { ChapterListViewModel(container.session) }
    val choices by chapters.state.collectAsStateWithLifecycle()
    val prefs = container.settings
    val scope = rememberCoroutineScope()
    val skipRead by remember(prefs) { prefs.flag(SettingKey.ReaderSkipRead, false) }.collectAsStateWithLifecycle(false)
    val skipFiltered by remember(prefs) {
        prefs.flag(SettingKey.ReaderSkipFiltered, false)
    }.collectAsStateWithLifecycle(false)
    SettingsPageFrame(
        Res.string.chapter_settings_title,
        onBack,
        subtitle = Res.string.chapter_settings_hint,
        onReset = {
            container.session.resetChapterLook()
            prefs.resetNames(SettingKey.ReaderSkipRead, SettingKey.ReaderSkipFiltered)
        },
    ) {
        SettingsSection(Res.string.chapter_group_sorting) {
            padded {
                ChoiceSetting(Res.string.chapter_sort_title, ChapterSort.entries, choices.sort, {
                    stringResource(sortLabel(it))
                }, hint = Res.string.chapter_sort_hint, onSelect = chapters::onSort)
            }
            padded {
                SwitchSetting(
                    Res.string.chapter_list_oldest,
                    choices.oldestFirst,
                    chapters::onOldestFirst,
                    Res.string.chapter_list_oldest_hint,
                )
            }
        }
        SettingsSection(Res.string.chapter_group_display) {
            padded {
                SwitchSetting(
                    Res.string.chapter_list_grid,
                    choices.grid,
                    chapters::onGrid,
                    Res.string.chapter_list_grid_hint,
                )
            }
            if (choices.grid) {
                padded {
                    SwitchSetting(
                        Res.string.chapter_list_pictures,
                        choices.pictures,
                        chapters::onPictures,
                        Res.string.chapter_list_pictures_hint,
                    )
                }
            }
            padded {
                SwitchSetting(
                    Res.string.chapter_list_duplicates,
                    choices.hideDuplicates,
                    chapters::onHideDuplicates,
                    Res.string.chapter_list_duplicates_hint,
                )
            }
        }
        // The same filters as the chapter options of a title. The groups, languages and labels are left out, as each title has its own.
        val filter = choices.filter
        SettingsSection(Res.string.chapter_filter_title, hint = Res.string.chapter_filter_settings_hint) {
            padded {
                ChoiceSetting(Res.string.chapter_filter_unread, TriFilter.entries, filter.unread, {
                    triLabel(it)
                }) { chapters.onFilter(filter.copy(unread = it)) }
            }
            padded {
                ChoiceSetting(Res.string.chapter_filter_downloaded, TriFilter.entries, filter.downloaded, {
                    triLabel(it)
                }) { chapters.onFilter(filter.copy(downloaded = it)) }
            }
            padded {
                ChoiceSetting(Res.string.chapter_filter_bookmarked, TriFilter.entries, filter.bookmarked, {
                    triLabel(it)
                }) { chapters.onFilter(filter.copy(bookmarked = it)) }
            }
        }
        // Where the next and the one before lead, in the reader and on the title page.
        SettingsSection(Res.string.reading_group_chapters) {
            padded {
                SwitchSetting(Res.string.reader_skip_read, skipRead, { on ->
                    scope.launch {
                        prefs.setFlag(SettingKey.ReaderSkipRead, on)
                    }
                }, Res.string.reader_skip_read_hint)
            }
            padded {
                SwitchSetting(Res.string.reader_skip_filtered, skipFiltered, { on ->
                    scope.launch {
                        prefs.setFlag(SettingKey.ReaderSkipFiltered, on)
                    }
                }, Res.string.reader_skip_filtered_hint)
            }
        }
    }
}
