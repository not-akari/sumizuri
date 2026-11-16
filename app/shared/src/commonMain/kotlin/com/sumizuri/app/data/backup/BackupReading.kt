package com.sumizuri.app.data.backup

import com.sumizuri.app.data.model.readChapterName
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.backup_problem_damaged
import com.sumizuri.app.shared.resources.backup_problem_not_backup
import com.sumizuri.app.shared.resources.backup_problem_password
import com.sumizuri.app.shared.resources.backup_problem_version
import okio.FileSystem
import okio.Path
import okio.buffer
import okio.use
import org.jetbrains.compose.resources.StringResource

// How many bytes at the start of a file are enough to tell what it is.
const val HeadSize = 512L

// Tells which app a backup file came from by its first bytes: a packed backup of this app starts with its name, gzip is Mihon, zip is Mangayomi, and text that begins with a brace is Sumizuri. Null when it is none of them.
fun sniffBackup(file: Path, system: FileSystem = FileSystem.SYSTEM): BackupApp? {
    val head = try {
        system.source(file).buffer().use { source ->
            source.request(HeadSize)
            source.buffer.readByteArray(minOf(source.buffer.size, HeadSize))
        }
    } catch (error: Exception) {
        return null
    }
    return sniffHead(head)
}

// The same, from the first bytes of a file already read.
fun sniffHead(head: ByteArray): BackupApp? {
    if (isPackedBackup(head)) return BackupApp.Sumizuri
    if (head.size >= 2 && head[0] == 0x1f.toByte() && head[1] == 0x8b.toByte()) return BackupApp.Mihon
    if (head.size >= 2 && head[0] == 'P'.code.toByte() && head[1] == 'K'.code.toByte()) return BackupApp.Mangayomi
    val text = head.decodeToString().removePrefix("").trimStart()
    return if (text.startsWith("{")) BackupApp.Sumizuri else null
}

// Reads the text of a file, which is a Sumizuri backup or the envelope of one that has a password.
fun readBackupText(file: Path, system: FileSystem = FileSystem.SYSTEM): String = try {
    system.read(file) { readUtf8() }.removePrefix("")
} catch (error: Exception) {
    throw BackupUnreadable(BackupProblem.NotBackup, error)
}

// Why a backup file could not be read.
enum class BackupProblem(val text: StringResource) {
    NotBackup(Res.string.backup_problem_not_backup),

    // The backup was made by a newer version of the app.
    NewerVersion(Res.string.backup_problem_version),
    WrongPassword(Res.string.backup_problem_password),
    Damaged(Res.string.backup_problem_damaged),
}

class BackupUnreadable(val problem: BackupProblem, cause: Throwable? = null) : Exception(problem.name, cause)

private val AnyNumber = Regex("\\d+(?:\\.\\d+)?")

// The number a chapter has in its name, such as 12.5 in Chapter 12.5: The Fall. The number the name gives the chapter comes first, read past a volume, a season or a piece, and else the first number there is. Null when the name has none.
fun chapterNumberFromName(name: String): Double? =
    readChapterName(name).chapter ?: AnyNumber.find(name)?.value?.toDoubleOrNull()
