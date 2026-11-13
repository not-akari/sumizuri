package com.sumizuri.app.feature.share

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.SaveAlt
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.shareFileName
import com.sumizuri.app.data.share.shareLink
import com.sumizuri.app.data.share.shareText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.close
import com.sumizuri.app.shared.resources.share_copied
import com.sumizuri.app.shared.resources.share_copy_link
import com.sumizuri.app.shared.resources.share_copy_text
import com.sumizuri.app.shared.resources.share_file
import com.sumizuri.app.shared.resources.share_hint
import com.sumizuri.app.shared.resources.share_save
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.input.canShareFiles
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.kit.input.rememberFileSaver
import com.sumizuri.app.ui.kit.input.rememberFileSharer
import kotlinx.serialization.json.JsonElement
import okio.FileSystem
import org.jetbrains.compose.resources.stringResource

// A link longer than this is left out, as chats cut long links.
private const val LinkMost = 8000

// The one way to share anything of the app: as a .sumizuri file to save or to send, as a link, or as text to paste. All of them import the same way.
@Composable
fun ShareDialog(title: String, name: String, kind: ShareKind, data: JsonElement, onDismiss: () -> Unit) {
    val text = remember(kind, data) { shareText(kind, data) }
    val link = remember(text) { shareLink(text).takeIf { it.length <= LinkMost } }
    val fileName = remember(name) { shareFileName(name) }
    var copied by remember { mutableStateOf(false) }
    val copy = rememberCopyText()
    val save = rememberFileSaver { if (it) onDismiss() }
    val send = rememberFileSharer()

    // The file is written to the temporary folder first, which the saver and the sharer copy from.
    fun file() = (FileSystem.SYSTEM_TEMPORARY_DIRECTORY / fileName).also { path ->
        FileSystem.SYSTEM.write(path) {
            writeUtf8(text)
        }
    }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    stringResource(Res.string.share_hint),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                AppListRow(stringResource(Res.string.share_save), leading = {
                    Icon(Icons.Outlined.SaveAlt, null)
                }, onClick = { save(fileName, file()) })
                if (canShareFiles()) {
                    AppListRow(stringResource(Res.string.share_file), leading = {
                        Icon(Icons.Outlined.Share, null)
                    }, onClick = { send(fileName, file()) })
                }
                if (link != null) {
                    AppListRow(
                        stringResource(
                            Res.string.share_copy_link,
                        ),
                        leading = { Icon(Icons.Outlined.Link, null) },
                        onClick = {
                            copy(link)
                            copied = true
                        },
                    )
                }
                AppListRow(
                    stringResource(
                        Res.string.share_copy_text,
                    ),
                    leading = { Icon(Icons.Outlined.ContentCopy, null) },
                    onClick = {
                        copy(text)
                        copied = true
                    },
                )
                if (copied) {
                    Text(
                        stringResource(Res.string.share_copied),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                    )
                }
            }
        },
        confirmButton = { TextButton(onDismiss) { Text(stringResource(Res.string.close)) } },
    )
}
