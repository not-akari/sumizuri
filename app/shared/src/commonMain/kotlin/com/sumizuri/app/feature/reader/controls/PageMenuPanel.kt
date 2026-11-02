package com.sumizuri.app.feature.reader.controls

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.close
import com.sumizuri.app.shared.resources.reader_open_browser
import com.sumizuri.app.shared.resources.reader_page_copy_link
import com.sumizuri.app.shared.resources.reader_page_menu_title
import com.sumizuri.app.shared.resources.reader_page_save
import com.sumizuri.app.shared.resources.reader_page_set_cover
import com.sumizuri.app.shared.resources.reader_page_share
import com.sumizuri.app.ui.kit.dock.DockAction
import com.sumizuri.app.ui.kit.dock.LocalDockLabels
import com.sumizuri.app.ui.kit.dock.PanelHead
import com.sumizuri.app.ui.kit.image.PageImages
import com.sumizuri.app.ui.kit.image.buildImageRequest
import com.sumizuri.app.ui.kit.input.canShareFiles
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.kit.input.rememberFileSaver
import com.sumizuri.app.ui.kit.input.rememberFileSharer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import okio.buffer
import okio.use
import org.jetbrains.compose.resources.stringResource

// The extensions a saved picture can have, and the one used when the address does not say.
private val Extensions = setOf("jpg", "jpeg", "png", "webp", "gif", "avif")
private const val UsualExtension = "jpg"

// How tall the picture of the page is at the head of the panel, and the size of its card at the side of the wide panel.
private val BannerHeight = 88.dp
private val CardWidth = 96.dp
private val CardHeight = 128.dp

// What a long press on a page offers, as a panel the dock grows to hold: saving or sharing the picture as a file, making it the cover of the title, and copying its address. The picture is taken from the copy the reader already holds, so a page that is not kept on the device cannot be saved or shared. The cover is not offered when it is null, as for a page that is shuffled.
@Composable
fun PageMenuPanel(
    number: Int,
    address: String,
    onSetCover: (() -> Unit)?,
    onOpenBrowser: (() -> Unit)?,
    onDismiss: () -> Unit,
) {
    val context = LocalPlatformContext.current
    val scope = rememberCoroutineScope()
    val copy = rememberCopyText()
    val share = rememberFileSharer()
    val made = remember { mutableStateOf<Path?>(null) }
    val saveFile = rememberFileSaver { _ ->
        made.value?.let { runCatching { FileSystem.SYSTEM.delete(it) } }
        onDismiss()
    }
    val saveable by produceState(false, address) {
        value = withContext(Dispatchers.IO) {
            val snapshot = PageImages.get(context).diskCache?.openSnapshot(address)
            snapshot?.close()
            snapshot != null
        }
    }
    val actions = buildList {
        if (saveable) {
            add(
                PageAction(Icons.Outlined.Download, stringResource(Res.string.reader_page_save)) {
                    scope.launch {
                        val name = "page-$number.${extensionOf(address)}"
                        val file = withContext(Dispatchers.IO) { copyOut(context, address, name) }
                        if (file == null) {
                            onDismiss()
                        } else {
                            made.value = file
                            saveFile(name, file)
                        }
                    }
                },
            )
        }
        if (saveable && canShareFiles()) {
            add(
                PageAction(Icons.Outlined.Share, stringResource(Res.string.reader_page_share)) {
                    scope.launch {
                        val name = "page-$number.${extensionOf(address)}"
                        val file = withContext(Dispatchers.IO) { copyOut(context, address, name) }
                        if (file != null) share(name, file)
                        onDismiss()
                    }
                },
            )
        }
        if (onSetCover != null) {
            add(
                PageAction(Icons.Outlined.Image, stringResource(Res.string.reader_page_set_cover)) {
                    onSetCover()
                    onDismiss()
                },
            )
        }
        add(
            PageAction(Icons.Outlined.Link, stringResource(Res.string.reader_page_copy_link)) {
                copy(address)
                onDismiss()
            },
        )
        if (onOpenBrowser != null) {
            add(
                PageAction(Icons.AutoMirrored.Outlined.OpenInNew, stringResource(Res.string.reader_open_browser)) {
                    onOpenBrowser()
                    onDismiss()
                },
            )
        }
    }
    val title = stringResource(Res.string.reader_page_menu_title, number)
    // A wide dock gives its track to this panel, which then puts the picture at the side with the actions and the track beside it.
    val track = LocalDockTrack.current
    if (track != null) {
        Column {
            PanelHead(title, onDismiss)
            Row(
                Modifier.fillMaxWidth().height(IntrinsicSize.Min).padding(start = 10.dp, bottom = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (saveable) {
                    PageCard(address)
                    VerticalDivider(
                        Modifier.padding(horizontal = 14.dp).fillMaxHeight(0.8f),
                        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f),
                    )
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        for (action in actions) ActionButton(action, Modifier.weight(1f))
                    }
                    track()
                }
            }
        }
        return
    }
    Column(Modifier.verticalScroll(rememberScrollState())) {
        // The page kept on the device heads the panel as a wide picture with its number and the close button on it, and the actions sit under it. A page that is not kept has the plain head.
        if (saveable) PageBanner(address, title, onDismiss) else PanelHead(title, onDismiss)
        // The actions in one row, drawn as the buttons of the dock with their names, so the panel stays low over the page.
        CompositionLocalProvider(LocalDockLabels provides true) {
            Row(Modifier.fillMaxWidth().padding(bottom = 4.dp)) {
                for (action in actions) DockAction(action.icon, action.label, false, action.onClick)
            }
        }
    }
}

// One action of the panel: its picture, its name and what it does.
private class PageAction(val icon: ImageVector, val label: String, val onClick: () -> Unit)

// The page as a wide picture across the panel, its middle shown, darkened at the bottom where its number sits, with the close button in a corner.
@Composable
private fun PageBanner(address: String, title: String, onClose: () -> Unit) {
    val context = LocalPlatformContext.current
    val request = remember(address) { buildImageRequest(context, address) }
    Box(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 4.dp)
            .height(BannerHeight)
            .clip(MaterialTheme.shapes.large),
    ) {
        AsyncImage(request, null, PageImages.get(context), Modifier.matchParentSize(), contentScale = ContentScale.Crop)
        Box(
            Modifier.matchParentSize().background(
                Brush.verticalGradient(
                    0.4f to Color.Transparent,
                    1f to Color.Black.copy(alpha = 0.7f),
                ),
            ),
        )
        Text(
            title,
            Modifier.align(Alignment.BottomStart).padding(start = 14.dp, bottom = 10.dp),
            style = MaterialTheme.typography.titleMedium,
            color = Color.White,
        )
        IconButton(
            onClose,
            Modifier.align(Alignment.TopEnd).padding(6.dp),
            colors = IconButtonDefaults.iconButtonColors(
                containerColor = Color.Black.copy(alpha = 0.45f),
                contentColor = Color.White,
            ),
        ) { Icon(Icons.Outlined.Close, stringResource(Res.string.close)) }
    }
}

// The page as a card of its top at the side of the wide panel.
@Composable
private fun PageCard(address: String) {
    val context = LocalPlatformContext.current
    val request = remember(address) { buildImageRequest(context, address) }
    AsyncImage(
        request,
        null,
        PageImages.get(context),
        Modifier.size(CardWidth, CardHeight).clip(MaterialTheme.shapes.medium),
        alignment = Alignment.TopCenter,
        contentScale = ContentScale.Crop,
    )
}

// One action as a button of the wide panel, its icon in the accent beside its name.
@Composable
private fun ActionButton(action: PageAction, modifier: Modifier = Modifier) {
    Surface(
        action.onClick,
        modifier.heightIn(min = 48.dp),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.surfaceContainerHighest.copy(alpha = 0.6f),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)),
    ) {
        Row(
            Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp, Alignment.CenterHorizontally),
        ) {
            Icon(action.icon, null, Modifier.size(20.dp), tint = MaterialTheme.colorScheme.primary)
            Text(
                action.label,
                style = MaterialTheme.typography.labelLarge,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

private fun extensionOf(address: String): String {
    val name = address.substringBefore('?').substringBefore('#').substringAfterLast('/')
    val extension = name.substringAfterLast('.', "").lowercase()
    return if (extension in Extensions) extension else UsualExtension
}

// Copies the kept file of a picture to a file of its own in the temporary folder, or gives null when it is not kept.
private fun copyOut(context: coil3.PlatformContext, address: String, name: String): Path? {
    val cache = PageImages.get(context).diskCache ?: return null
    val snapshot = cache.openSnapshot(address) ?: return null
    return try {
        val target = FileSystem.SYSTEM_TEMPORARY_DIRECTORY
            .resolve("sumizuri_save")
            .also { FileSystem.SYSTEM.createDirectories(it) }
            .resolve(name)
        FileSystem.SYSTEM
            .source(snapshot.data)
            .buffer()
            .use { from ->
                FileSystem.SYSTEM
                    .sink(target)
                    .buffer()
                    .use { to -> to.writeAll(from) }
            }
        target
    } catch (_: Exception) {
        null
    } finally {
        snapshot.close()
    }
}
