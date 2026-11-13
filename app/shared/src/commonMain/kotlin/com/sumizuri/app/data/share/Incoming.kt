package com.sumizuri.app.data.share

import com.sumizuri.app.data.backup.BackupApp
import com.sumizuri.app.data.backup.isPackedBackup
import com.sumizuri.app.data.backup.sniffBackup
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import okio.buffer
import okio.use

// The most text of a file that is read to see what it holds, short of a backup, which is read by the backup page.
private const val SmallMost = 4L * 1024 * 1024

// Something to import: a file on the device, or a text or link the person pasted or tapped.
sealed interface ImportSource {
    data class File(val path: Path) : ImportSource

    data class Text(val text: String) : ImportSource
}

// What an import turned out to be: a backup for the backup page, which reads it itself, or a smaller thing read here.
sealed interface Identified {
    data class Backup(val path: Path) : Identified

    data class Small(val thing: SharedThing) : Identified
}

// What waits to be imported, set by a link, a file the system opened the app with, or a file picked in the app, and taken by the page that shows it.
object Incoming {
    private val waiting = MutableStateFlow<ImportSource?>(null)
    val source: StateFlow<ImportSource?> = waiting

    private val backupFile = MutableStateFlow<Path?>(null)

    // A backup the import page found, for the backup page to read.
    val backup: StateFlow<Path?> = backupFile

    fun offer(source: ImportSource) {
        waiting.value = source
    }

    fun taken() {
        waiting.value = null
    }

    fun offerBackup(path: Path) {
        backupFile.value = path
    }

    fun backupTaken() {
        backupFile.value = null
    }
}

// Tells what an import holds. A packed file, a backup of another app, or a file of the app that holds a backup is a backup. Throws when it is none of the things the app reads.
suspend fun identify(source: ImportSource): Identified = withContext(Dispatchers.IO) {
    when (source) {
        is ImportSource.Text -> Identified.Small(readShared(textOfLink(source.text) ?: source.text))

        is ImportSource.File -> {
            if (sniffBackup(source.path).let {
                    it == BackupApp.Mihon || it == BackupApp.Mangayomi
                }
            ) {
                return@withContext Identified.Backup(source.path)
            }
            val head = FileSystem.SYSTEM.source(source.path).buffer().use {
                it.peek().readByteArray(minOf(16L, sizeOf(source.path)))
            }
            if (isPackedBackup(head)) return@withContext Identified.Backup(source.path)
            if (sizeOf(source.path) > SmallMost) return@withContext Identified.Backup(source.path)
            val thing = readShared(FileSystem.SYSTEM.read(source.path) { readUtf8() })
            if (thing.kind == ShareKind.Backup) Identified.Backup(source.path) else Identified.Small(thing)
        }
    }
}

private fun sizeOf(path: Path): Long = FileSystem.SYSTEM.metadataOrNull(path)?.size ?: 0L
