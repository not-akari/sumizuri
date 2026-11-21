package com.sumizuri.app.feature.title.layout

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Deselect
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.FlipToBack
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.RemoveDone
import androidx.compose.material.icons.outlined.SelectAll
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.title.DownloadCalls
import com.sumizuri.app.feature.title.SelectionCallbacks
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_menu_more
import com.sumizuri.app.shared.resources.download_delete_selected
import com.sumizuri.app.shared.resources.download_selected
import com.sumizuri.app.shared.resources.selection_all
import com.sumizuri.app.shared.resources.selection_bookmark
import com.sumizuri.app.shared.resources.selection_close
import com.sumizuri.app.shared.resources.selection_count
import com.sumizuri.app.shared.resources.selection_invert
import com.sumizuri.app.shared.resources.selection_mark_below
import com.sumizuri.app.shared.resources.selection_mark_read
import com.sumizuri.app.shared.resources.selection_mark_unread
import com.sumizuri.app.shared.resources.selection_unbookmark
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The bar that takes the place of the top bar while chapters are picked, with what can be done to them.
@Composable
internal fun SelectionBar(
    count: Int,
    total: Int,
    calls: SelectionCallbacks,
    modifier: Modifier = Modifier,
    downloads: DownloadCalls? = null,
) {
    var open by remember { mutableStateOf(false) }
    Surface(modifier.fillMaxWidth(), color = MaterialTheme.colorScheme.surfaceContainerHigh) {
        Row(
            Modifier
                .windowInsetsPadding(
                    WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal),
                ).padding(horizontal = 4.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(calls.onClose) { Icon(Icons.Outlined.Close, stringResource(Res.string.selection_close)) }
            Text(
                pluralStringResource(Res.plurals.selection_count, count, count),
                Modifier.weight(1f),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
            )
            IconButton(calls.onSelectAll) {
                Icon(
                    if (count ==
                        total
                    ) {
                        Icons.Outlined.Deselect
                    } else {
                        Icons.Outlined.SelectAll
                    },
                    stringResource(Res.string.selection_all),
                )
            }
            IconButton(calls.onInvert) { Icon(Icons.Outlined.FlipToBack, stringResource(Res.string.selection_invert)) }
            IconButton(
                { calls.onMarkRead(true) },
            ) { Icon(Icons.Outlined.DoneAll, stringResource(Res.string.selection_mark_read)) }
            IconButton({
                calls.onMarkRead(false)
            }) { Icon(Icons.Outlined.RemoveDone, stringResource(Res.string.selection_mark_unread)) }
            // The menu opens under the button, so the two are together in one box.
            Box {
                IconButton(
                    { open = true },
                ) { Icon(Icons.Outlined.MoreVert, stringResource(Res.string.chapter_menu_more)) }
                AppMenu(open, { open = false }) {
                    AppMenuItem({ Text(stringResource(Res.string.selection_bookmark)) }, {
                        open = false
                        calls.onBookmark(true)
                    })
                    AppMenuItem({ Text(stringResource(Res.string.selection_unbookmark)) }, {
                        open = false
                        calls.onBookmark(false)
                    })
                    AppMenuItem({ Text(stringResource(Res.string.selection_mark_below)) }, {
                        open = false
                        calls.onMarkBelowRead()
                    })
                    if (downloads != null) {
                        downloads.onDownloadSelected?.let { start ->
                            AppMenuItem({ Text(stringResource(Res.string.download_selected)) }, {
                                open = false
                                start()
                            })
                        }
                        AppMenuItem({ Text(stringResource(Res.string.download_delete_selected)) }, {
                            open = false
                            downloads.onRemoveSelected()
                        })
                    }
                }
            }
        }
    }
}
