package com.sumizuri.app.ui.kit.input

import androidx.compose.ui.Modifier
import okio.Path

actual fun Modifier.fileDrop(onHover: (Boolean) -> Unit, onFile: (Path) -> Unit): Modifier = this

actual fun canDropFiles(): Boolean = false
