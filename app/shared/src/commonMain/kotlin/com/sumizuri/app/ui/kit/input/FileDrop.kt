package com.sumizuri.app.ui.kit.input

import androidx.compose.ui.Modifier
import okio.Path

// Lets a file be dropped on this part of a desktop window. The hover callback says when a file is held over it. On a phone it does nothing.
expect fun Modifier.fileDrop(onHover: (Boolean) -> Unit, onFile: (Path) -> Unit): Modifier

// Whether files can be dropped on the window, which only a desktop has.
expect fun canDropFiles(): Boolean
