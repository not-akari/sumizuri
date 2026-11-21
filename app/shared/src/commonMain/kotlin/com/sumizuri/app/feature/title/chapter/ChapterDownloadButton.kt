package com.sumizuri.app.feature.title.chapter

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DownloadDone
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.db.download.DownloadEntity
import com.sumizuri.app.data.db.download.DownloadState
import com.sumizuri.app.data.db.download.progress
import com.sumizuri.app.data.db.download.status
import com.sumizuri.app.feature.title.DownloadCalls
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.download_cancel
import com.sumizuri.app.shared.resources.download_chapter
import com.sumizuri.app.shared.resources.download_delete
import com.sumizuri.app.shared.resources.download_saved
import com.sumizuri.app.shared.resources.try_again
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import org.jetbrains.compose.resources.stringResource

// What a chapter row knows about saving its chapter: where its download is, if there is one, and what can be asked. A new download cannot start while the source is out of reach.
data class RowDownload(val entity: DownloadEntity?, val calls: DownloadCalls)

// The button at the end of a chapter row that saves the chapter to the device: an arrow to start, a ring that fills while it waits and saves, a tick once saved, and a mark when it failed. A tap on the ring stops it, a tap on the mark tries again, and the tick opens a menu to take it off the device.
@Composable
internal fun ChapterDownloadButton(chapterId: Long, download: RowDownload) {
    val colors = MaterialTheme.colorScheme
    val entity = download.entity
    val start = download.calls.onDownload
    when (val status = entity?.status) {
        null -> if (start != null) {
            IconButton({ start(chapterId) }, Modifier.size(RowButton)) {
                Icon(
                    Icons.Outlined.Download,
                    stringResource(Res.string.download_chapter),
                    Modifier.size(18.dp),
                    tint = colors.onSurfaceVariant,
                )
            }
        }

        DownloadState.Queued, DownloadState.Running -> IconButton({
            download.calls.onRemove(chapterId)
        }, Modifier.size(RowButton)) {
            Box(contentAlignment = Alignment.Center) {
                if (status == DownloadState.Running && entity.pages > 0) {
                    InkCircularProgressIndicator(progress = {
                        entity.progress
                    }, modifier = Modifier.size(18.dp), strokeWidth = 2.dp, trackColor = colors.surfaceContainerHighest)
                } else {
                    InkCircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = colors.outline)
                }
                Icon(
                    Icons.Outlined.Download,
                    stringResource(Res.string.download_cancel),
                    Modifier.size(11.dp),
                    tint = colors.onSurfaceVariant,
                )
            }
        }

        DownloadState.Done -> {
            var open by remember { mutableStateOf(false) }
            Box {
                IconButton({
                    open = true
                }, Modifier.size(RowButton)) {
                    Icon(
                        Icons.Filled.DownloadDone,
                        stringResource(Res.string.download_saved),
                        Modifier.size(18.dp),
                        tint = colors.primary,
                    )
                }
                AppMenu(open, { open = false }) {
                    AppMenuItem({ Text(stringResource(Res.string.download_delete)) }, {
                        open = false
                        download.calls.onRemove(chapterId)
                    })
                }
            }
        }

        DownloadState.Failed -> IconButton({
            if (start !=
                null
            ) {
                start(chapterId)
            } else {
                download.calls.onRemove(chapterId)
            }
        }, Modifier.size(RowButton)) {
            Icon(
                Icons.Outlined.ErrorOutline,
                stringResource(Res.string.try_again),
                Modifier.size(18.dp),
                tint = colors.error,
            )
        }
    }
}
