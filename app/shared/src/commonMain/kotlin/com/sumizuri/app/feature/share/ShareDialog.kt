package com.sumizuri.app.feature.share

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.SaveAlt
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.shareFileName
import com.sumizuri.app.data.share.shareText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.close
import com.sumizuri.app.shared.resources.share_file
import com.sumizuri.app.shared.resources.share_hint
import com.sumizuri.app.shared.resources.share_save
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.input.canShareFiles
import com.sumizuri.app.ui.kit.input.rememberFileSaver
import com.sumizuri.app.ui.kit.input.rememberFileSharer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonElement
import okio.FileSystem
import okio.Path
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The one way to share anything of the app: a .sumizuri file, sent to another app or saved, as big buttons side by side.
@Composable
fun ShareDialog(title: String, name: String, kind: ShareKind, data: JsonElement, onDismiss: () -> Unit) {
    val fileName = remember(name) { shareFileName(name) }
    val save = rememberFileSaver { if (it) onDismiss() }
    val send = rememberFileSharer()
    val scope = rememberCoroutineScope()
    // The file is written once, away from the screen, to the temporary folder the saver and the sharer copy from.
    var written by remember(kind, data, fileName) { mutableStateOf<Path?>(null) }

    fun withFile(use: (Path) -> Unit) {
        scope.launch {
            val path = written ?: withContext(Dispatchers.IO) {
                (FileSystem.SYSTEM_TEMPORARY_DIRECTORY / fileName).also {
                    FileSystem.SYSTEM.write(it) { writeUtf8(shareText(kind, data)) }
                }
            }.also { written = it }
            use(path)
        }
    }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    stringResource(Res.string.share_hint),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (canShareFiles()) {
                        ShareTile(
                            Icons.Outlined.Share,
                            Res.string.share_file,
                        ) { withFile { send(fileName, it) } }
                    }
                    ShareTile(Icons.Outlined.SaveAlt, Res.string.share_save) { withFile { save(fileName, it) } }
                }
            }
        },
        confirmButton = { InkOutlinedButton(onDismiss) { Text(stringResource(Res.string.close)) } },
    )
}

// One big button of the share window: an icon over its name.
@Composable
private fun RowScope.ShareTile(icon: ImageVector, label: StringResource, onClick: () -> Unit) {
    AppCard(Modifier.weight(1f), onClick = onClick) {
        Column(
            Modifier.fillMaxWidth().padding(vertical = 16.dp, horizontal = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(icon, null, Modifier.size(26.dp), tint = MaterialTheme.colorScheme.primary)
            Text(
                stringResource(label),
                style = MaterialTheme.typography.labelLarge,
                textAlign = TextAlign.Center,
                maxLines = 2,
            )
        }
    }
}
