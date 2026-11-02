package com.sumizuri.app.feature.sync.data

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CloudUpload
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.backup.ImportedChapter
import com.sumizuri.app.feature.sync.Note
import com.sumizuri.app.feature.sync.SideBySide
import com.sumizuri.app.feature.sync.home.SyncHome
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_chapter_line
import com.sumizuri.app.shared.resources.sync_chapter_number
import com.sumizuri.app.shared.resources.sync_copy_line
import com.sumizuri.app.shared.resources.sync_copy_no_library
import com.sumizuri.app.shared.resources.sync_copy_none
import com.sumizuri.app.shared.resources.sync_copy_packing
import com.sumizuri.app.shared.resources.sync_copy_refresh
import com.sumizuri.app.shared.resources.sync_copy_section
import com.sumizuri.app.shared.resources.sync_copy_upload
import com.sumizuri.app.shared.resources.sync_history_none
import com.sumizuri.app.shared.resources.sync_library_more
import com.sumizuri.app.shared.resources.sync_library_title_line
import com.sumizuri.app.shared.resources.sync_tab_history
import com.sumizuri.app.shared.resources.sync_tab_library
import com.sumizuri.app.shared.resources.sync_tab_updates
import com.sumizuri.app.shared.resources.sync_updates_none
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.agoText
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The most titles the library list shows at once, so a big library stays quick to draw.
private const val TitleLimit = 300

// What the server holds of this profile's library and when it came, with the buttons to send it again or fetch it again.
@Composable
private fun CopyHeader(home: SyncHome, onUpload: () -> Unit, onRefresh: () -> Unit) {
    // The tab above already says this is the server, so the card has no heading of its own.
    SettingsSection {
        val linked = home.libraries != null
        val copy = home.copy
        row {
            val line = when {
                home.packing != null -> stringResource(
                    Res.string.sync_copy_packing,
                    home.packing.first,
                    home.packing.second,
                )

                copy != null -> stringResource(Res.string.sync_copy_line, copy.library.size, agoText(copy.at))

                linked && home.copyChecked -> stringResource(Res.string.sync_copy_none)

                else -> ""
            }
            SettingRow(stringResource(Res.string.sync_copy_section), subtitle = line, leading = {
                SettingIcon(Icons.Outlined.CloudUpload)
            })
        }
        padded {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                InkButton(onUpload, enabled = !home.busy) { Text(stringResource(Res.string.sync_copy_upload)) }
                InkOutlinedButton(
                    onRefresh,
                    enabled = !home.busy,
                ) { Text(stringResource(Res.string.sync_copy_refresh)) }
            }
        }
    }
}

// The titles of the server's copy with their covers, how far each is read, and whether this device has it.
@Composable
internal fun LibraryData(home: SyncHome, linked: Boolean, wide: Boolean, onUpload: () -> Unit, onRefresh: () -> Unit) {
    if (!linked) return NoLibrary()
    SideBySide(wide, { CopyHeader(home, onUpload, onRefresh) }) { home.copy?.let { LibraryList(it) } }
}

@Composable
private fun LibraryList(copy: ServerCopy) {
    val found = copy.library
    val device by rememberOnDevice(found)
    SettingsSection(Res.string.sync_tab_library) {
        for (title in found.take(TitleLimit)) {
            row {
                val read = title.chapters.count { it.read }
                CopyTitleRow(
                    title,
                    stringResource(
                        Res.string.sync_library_title_line,
                        title.sourceName ?: title.sourceId.orEmpty(),
                        read,
                        title.chapters.size,
                    ),
                    device,
                )
            }
        }
        if (found.size >
            TitleLimit
        ) {
            padded { Note(stringResource(Res.string.sync_library_more, TitleLimit, found.size)) }
        }
    }
}

// The unread new chapters of the server's copy, newest first.
@Composable
internal fun UpdatesData(home: SyncHome, linked: Boolean, wide: Boolean, onUpload: () -> Unit, onRefresh: () -> Unit) {
    if (!linked) return NoLibrary()
    SideBySide(wide, {
        CopyHeader(home, onUpload, onRefresh)
    }) { home.copy?.let { ChapterList(Res.string.sync_tab_updates, it.updates, Res.string.sync_updates_none) } }
}

// The chapters read in the server's copy, newest first.
@Composable
internal fun HistoryData(home: SyncHome, linked: Boolean, wide: Boolean, onUpload: () -> Unit, onRefresh: () -> Unit) {
    if (!linked) return NoLibrary()
    SideBySide(wide, {
        CopyHeader(home, onUpload, onRefresh)
    }) { home.copy?.let { ChapterList(Res.string.sync_tab_history, it.history, Res.string.sync_history_none) } }
}

@Composable
private fun ChapterList(title: StringResource, chapters: List<CopyChapter>, empty: StringResource) {
    val device by rememberOnDevice(chapters.map { it.title }.distinct())
    SettingsSection(title) {
        if (chapters.isEmpty()) padded { Note(stringResource(empty)) }
        for (item in chapters) {
            row {
                CopyTitleRow(
                    item.title,
                    stringResource(Res.string.sync_chapter_line, chapterLabel(item.chapter), agoText(item.at)),
                    device,
                )
            }
        }
    }
}

@Composable
private fun NoLibrary() {
    SettingsSection(Res.string.sync_copy_section) { padded { Note(stringResource(Res.string.sync_copy_no_library)) } }
}

// A chapter's own name, or its number when it has none.
@Composable
private fun chapterLabel(chapter: ImportedChapter): String {
    chapter.name?.takeIf { it.isNotBlank() }?.let { return it }
    val number = chapter.number
    val text = if (number == number.toLong().toDouble()) number.toLong().toString() else number.toString()
    return stringResource(Res.string.sync_chapter_number, text)
}
