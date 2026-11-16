package com.sumizuri.app.ui.kit.input

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.draganddrop.dragAndDropTarget
import androidx.compose.runtime.remember
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draganddrop.DragAndDropEvent
import androidx.compose.ui.draganddrop.DragAndDropTarget
import androidx.compose.ui.draganddrop.DragData
import androidx.compose.ui.draganddrop.dragData
import okio.Path
import okio.Path.Companion.toOkioPath
import java.io.File
import java.net.URI

@OptIn(ExperimentalFoundationApi::class, ExperimentalComposeUiApi::class)
actual fun Modifier.fileDrop(onHover: (Boolean) -> Unit, onFile: (Path) -> Unit): Modifier = composed {
    val target = remember(onHover, onFile) {
        object : DragAndDropTarget {
            override fun onEntered(event: DragAndDropEvent) = onHover(true)

            override fun onExited(event: DragAndDropEvent) = onHover(false)

            override fun onEnded(event: DragAndDropEvent) = onHover(false)

            override fun onDrop(event: DragAndDropEvent): Boolean {
                onHover(false)
                val files = event.dragData() as? DragData.FilesList ?: return false
                // Only the first file is taken, as the page shows one thing at a time.
                val first = files.readFiles().firstOrNull() ?: return false
                val path = runCatching { File(URI(first)).toOkioPath() }.getOrNull() ?: return false
                onFile(path)
                return true
            }
        }
    }
    dragAndDropTarget(shouldStartDragAndDrop = { it.dragData() is DragData.FilesList }, target = target)
}

actual fun canDropFiles(): Boolean = true
