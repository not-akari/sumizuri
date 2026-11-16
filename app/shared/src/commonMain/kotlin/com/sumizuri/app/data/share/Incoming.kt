package com.sumizuri.app.data.share

import com.sumizuri.app.data.backup.BackupApp
import com.sumizuri.app.data.backup.HeadSize
import com.sumizuri.app.data.backup.isPackedBackup
import com.sumizuri.app.data.backup.sniffHead
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import okio.buffer
import okio.use

// The most a file that is not a backup may weigh, so a large file of something else is never read whole.
private const val SmallMost = 4L * 1024 * 1024

// What a file turned out to be: a backup for the backup page, which reads it itself, or a smaller thing read here.
sealed interface Identified {
    data class Backup(val path: Path) : Identified

    data class Small(val thing: SharedThing) : Identified
}

// A backup the import page found, held until the backup page takes it.
object Incoming {
    private val backupFile = MutableStateFlow<Path?>(null)
    val backup: StateFlow<Path?> = backupFile

    fun offerBackup(path: Path) {
        backupFile.value = path
    }

    fun backupTaken() {
        backupFile.value = null
    }
}

// Tells what a file holds from its first bytes, read once: a packed file, a backup of another app, or a file of the app that names itself a backup is a backup. Throws when it is none of the things the app reads.
suspend fun identify(path: Path): Identified = withContext(Dispatchers.IO) {
    val size = FileSystem.SYSTEM.metadataOrNull(path)?.size ?: 0L
    FileSystem.SYSTEM.source(path).buffer().use { source ->
        val head = source.peek().let { peek ->
            peek.request(HeadSize)
            peek.buffer.readByteArray(minOf(peek.buffer.size, HeadSize))
        }
        val app = sniffHead(head)
        val backup = isPackedBackup(head) || (app != null && app != BackupApp.Sumizuri) || namesBackup(head)
        when {
            backup -> Identified.Backup(path)

            size > SmallMost -> throw ShareUnreadable(ShareProblem.NotOurs)

            else -> {
                val thing = readShared(source.readUtf8())
                if (thing.kind == ShareKind.Backup) Identified.Backup(path) else Identified.Small(thing)
            }
        }
    }
}

// The file of the app of this kind at the path, or null when it is something else or cannot be read.
suspend fun readSharedFile(path: Path, kind: ShareKind): SharedThing? = withContext(Dispatchers.IO) {
    runCatching { readShared(FileSystem.SYSTEM.read(path) { readUtf8() }) }.getOrNull()?.takeIf { it.kind == kind }
}

// A file of the app names its kind before its content, so a backup says so in its first bytes.
private fun namesBackup(head: ByteArray): Boolean =
    head.decodeToString().contains("\"type\":\"${ShareKind.Backup.id}\"")
