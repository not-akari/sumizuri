package com.sumizuri.app.data.library

import com.sumizuri.app.data.local.localFileAddress
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath

// The covers the person chose, kept as files of their own, so a picture from a file or from another source never stops loading.
class CoverFiles(private val folder: Path, private val fs: FileSystem = FileSystem.SYSTEM) {
    // Keeps the picture as the cover file of a title and gives its address. The file has a new name each time, so a picture already shown is never taken for the new one.
    suspend fun save(titleId: Long, bytes: ByteArray): String = withContext(Dispatchers.IO) {
        fs.createDirectories(folder)
        forget(titleId)
        val file = folder / "$titleId-${nowMillis()}.${extensionOf(bytes)}"
        fs.write(file) { write(bytes) }
        localFileAddress(file.toString())
    }

    // Takes away the cover files of a title.
    suspend fun forget(titleId: Long) = withContext(Dispatchers.IO) {
        if (!fs.exists(folder)) return@withContext
        fs.list(folder).filter { it.name.startsWith("$titleId-") }.forEach { fs.delete(it) }
    }

    private fun extensionOf(bytes: ByteArray): String = when {
        bytes.size > 3 && bytes[0] == 0x89.toByte() && bytes[1] == 'P'.code.toByte() -> "png"
        bytes.size > 11 && bytes[8] == 'W'.code.toByte() && bytes[9] == 'E'.code.toByte() -> "webp"
        bytes.size > 3 && bytes[0] == 'G'.code.toByte() && bytes[1] == 'I'.code.toByte() -> "gif"
        else -> "jpg"
    }
}

// The folder of the chosen covers, beside the database of the profile, one for each profile.
fun coverFolder(databasePath: String): Path {
    if (databasePath.isBlank()) return FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-covers"
    val database = databasePath.toPath()
    val parent = database.parent ?: FileSystem.SYSTEM_TEMPORARY_DIRECTORY
    return parent / "covers" / database.name.substringBeforeLast('.')
}
