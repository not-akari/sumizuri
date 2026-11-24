package com.sumizuri.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.content.IntentCompat
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.share.Incoming
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okio.Path.Companion.toPath
import java.io.File

// The folder in the cache where a file opened with the app is copied, as another app only lends its file for a moment.
private const val OpenedFolder = "opened"

// The file another app opened or shared with this one, such as a .sumizuri file from a file manager or a chat, or null when the start brought none.
internal fun openedUriOf(intent: Intent): Uri? = when (intent.action) {
    Intent.ACTION_VIEW -> intent.data?.takeIf { it.scheme == "content" || it.scheme == "file" }
    Intent.ACTION_SEND -> IntentCompat.getParcelableExtra(intent, Intent.EXTRA_STREAM, Uri::class.java)
    else -> null
}

// Copies the file into the cache of the app and hands it to the import page, which tells what it holds.
internal suspend fun openFile(context: Context, uri: Uri) {
    val copied = withContext(Dispatchers.IO) {
        runCatching {
            val folder = File(context.cacheDir, OpenedFolder).apply { mkdirs() }
            val target = File(folder, nameOf(context, uri))
            context.contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return@runCatching null
            target
        }.onFailure { AppLog.warn("import", "could not copy the opened file, ${it.message}") }.getOrNull()
    }
    copied?.let { Incoming.open(it.absolutePath.toPath()) }
}

// The name the other app gives the file, kept to a plain file name, or a plain one when it gives none.
private fun nameOf(context: Context, uri: Uri): String {
    val shown = runCatching {
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { row ->
            if (row.moveToFirst()) row.getString(0) else null
        }
    }.getOrNull() ?: uri.lastPathSegment
    return shown?.substringAfterLast('/')?.takeIf { it.isNotBlank() } ?: "opened.sumizuri"
}
