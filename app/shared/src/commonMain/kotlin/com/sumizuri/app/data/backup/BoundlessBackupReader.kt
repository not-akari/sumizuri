package com.sumizuri.app.data.backup

import com.sumizuri.app.data.db.repo.RepoEntity
import com.sumizuri.app.data.json.flag
import com.sumizuri.app.data.json.int
import com.sumizuri.app.data.json.list
import com.sumizuri.app.data.json.strings
import com.sumizuri.app.data.json.text
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import dev.whyoleg.cryptography.BinarySize.Companion.bits
import dev.whyoleg.cryptography.CryptographyProvider
import dev.whyoleg.cryptography.DelicateCryptographyApi
import dev.whyoleg.cryptography.algorithms.AES
import dev.whyoleg.cryptography.algorithms.PBKDF2
import dev.whyoleg.cryptography.algorithms.SHA256
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import okio.Buffer
import okio.FileSystem
import okio.GzipSource
import okio.Path
import okio.buffer
import okio.use

// The first byte of a Boundless backup that is shut with a password, then 16 bytes of salt, 12 of nonce, and the sealed gzip with its tag.
private const val SealedMark = 0xE1.toByte()
private const val SaltSize = 16
private const val NonceSize = 12
private const val SealedIterations = 100_000
private const val KeyBits = 256
private const val TagBits = 128

// A chapter that was read to its end, in the history of Boundless, which keeps the share of a chapter that was read.
private const val Finished = 1.0

// True when the bytes start a Boundless backup that is shut with a password.
fun isBoundlessSealed(head: ByteArray): Boolean = head.isNotEmpty() && head[0] == SealedMark

// True when the first bytes are the plain JSON of a Boundless backup, which names its version and the time it was made before anything else and has none of the names a Sumizuri backup has.
fun isBoundlessText(head: ByteArray): Boolean {
    val text = head.decodeToString()
    return text.contains("\"exportedAt\"") && !text.contains("\"backupVersion\"") &&
        !text.contains("\"type\":\"backup\"")
}

// True when what the gzip holds starts as JSON text, which is Boundless, where Mihon holds protobuf. A file that was cut short still gives its first bytes.
fun isBoundlessGzip(head: ByteArray): Boolean = try {
    val first = GzipSource(Buffer().write(head)).buffer().use { it.readByte() }
    first == '{'.code.toByte()
} catch (error: Exception) {
    false
}

// For a Boundless backup, whether it is shut with a password.
fun boundlessNeedsPassword(file: Path, system: FileSystem = FileSystem.SYSTEM): Boolean = try {
    system.source(file).buffer().use { it.readByte() == SealedMark }
} catch (error: Exception) {
    false
}

// Reads a backup of Boundless Reader, a JSON file that is squeezed with gzip, and shut with a password when the person chose one. The library comes with its shelves, the chapters read, and the saved repos.
suspend fun readBoundlessBackup(
    file: Path,
    password: String? = null,
    system: FileSystem = FileSystem.SYSTEM,
): ImportedBackup {
    val root = try {
        Json.parseToJsonElement(boundlessText(system.read(file) { readByteArray() }, password)).jsonObject
    } catch (error: CancellationException) {
        throw error
    } catch (error: BackupUnreadable) {
        throw error
    } catch (error: Throwable) {
        throw BackupUnreadable(BackupProblem.NotBackup, error)
    }
    val version = (root["version"] as? JsonPrimitive)?.intOrNull ?: throw BackupUnreadable(BackupProblem.NotBackup)
    if (version > 1) throw BackupUnreadable(BackupProblem.NewerVersion)
    if (version < 1) throw BackupUnreadable(BackupProblem.NotBackup)
    try {
        return boundlessBackupOf(root)
    } catch (error: Throwable) {
        throw BackupUnreadable(BackupProblem.Damaged, error)
    }
}

// The text of the backup: opened with the password when it is shut, then inflated when it is squeezed.
private suspend fun boundlessText(bytes: ByteArray, password: String?): String {
    val packed = if (isBoundlessSealed(bytes)) open(bytes, password) else bytes
    val squeezed = packed.size >= 2 && packed[0] == 0x1f.toByte() && packed[1] == 0x8b.toByte()
    return if (squeezed) {
        GzipSource(Buffer().write(packed)).buffer().use { it.readUtf8() }
    } else {
        packed.decodeToString()
    }.removePrefix("")
}

// Opens the sealed backup with the password. A wrong password and a damaged file both fail the cipher the same way.
@OptIn(DelicateCryptographyApi::class)
private suspend fun open(bytes: ByteArray, password: String?): ByteArray {
    if (password == null || bytes.size < 1 + SaltSize + NonceSize) throw BackupUnreadable(BackupProblem.WrongPassword)
    try {
        val salt = bytes.copyOfRange(1, 1 + SaltSize)
        val nonce = bytes.copyOfRange(1 + SaltSize, 1 + SaltSize + NonceSize)
        val sealed = bytes.copyOfRange(1 + SaltSize + NonceSize, bytes.size)
        val provider = CryptographyProvider.Default
        val key = provider
            .get(PBKDF2)
            .secretDerivation(SHA256, SealedIterations, KeyBits.bits, salt)
            .deriveSecretToByteArray(password.encodeToByteArray())
        return provider
            .get(AES.GCM)
            .keyDecoder()
            .decodeFromByteArray(AES.Key.Format.RAW, key)
            .cipher(TagBits.bits)
            .decryptWithIv(nonce, sealed)
    } catch (error: Exception) {
        if (error is CancellationException) throw error
        throw BackupUnreadable(BackupProblem.WrongPassword, error)
    }
}

private fun boundlessBackupOf(root: JsonObject): ImportedBackup {
    val categories = root
        .list("categories")
        .filter { !it.flag("deleted") && it.text("name").isNotBlank() }
        .sortedBy { it.int("sortOrder") ?: 0 }
    val shelfNames = categories.associate { it.text("id") to it.text("name").trim() }
    val history = root.list("history").groupBy { key(it) }
    val readIds = (root["readChapters"] as? JsonObject).orEmpty()
    val readNumbers = (root["readNumbers"] as? JsonObject).orEmpty()
    val titles = root
        .list("library")
        .filter { it.text("mangaId").isNotEmpty() && it.text("title").isNotBlank() }
        .map { entry ->
            val key = key(entry)
            val rows = history[key].orEmpty()
            ImportedTitle(
                name = entry.text("title").trim(),
                url = entry.text("mangaId"),
                coverUrl = entry.text("coverUrl").ifEmpty { null },
                // Boundless has no kind of its own for a title, and a title that was read as a novel says so in its history.
                kind = if (rows.any { it.flag("isNovel") }) Kind.Novel else Kind.Manga,
                favorite = true,
                sourceName = entry.text("sourceLabel").ifEmpty { null },
                sourceUrl = null,
                shelves = entry.strings("categoryIds").mapNotNull { shelfNames[it] },
                chapters = chaptersOf(rows, ids(readIds[key]), numbers(readNumbers[key])),
                addedAt = timeOf(entry.text("addedAt")),
                status = statusOf(entry.text("status")),
                genres = entry.strings("genres"),
            )
        }
    val repos = root
        .list("repos")
        .filter { it.text("url").startsWith("https://") || it.text("url").startsWith("http://") }
        .map { RepoEntity(it.text("url"), it.text("name"), 0L) }
    return ImportedBackup(
        BackupApp.Boundless,
        titles,
        categories.map { ImportedShelf(it.text("name").trim(), excludeFromUpdate = it.noUpdates()) },
        BackupExtras(repos = repos).takeIf { repos.isNotEmpty() },
    )
}

// The chapters of one title: the ones the backup lists as read, and the ones its history holds, which come with how far the reader got. A chapter in both is read, and has the time of the history.
private fun chaptersOf(rows: List<JsonObject>, read: List<String>, numbers: List<Double>): List<ImportedChapter> {
    val byId = LinkedHashMap<String, ImportedChapter>()
    read.forEachIndexed { index, id ->
        byId[id] = ImportedChapter(
            url = id,
            number =
            numbers.takeIf { it.size == read.size }?.get(index) ?: chapterNumberFromName(id)
                ?: (index + 1).toDouble(),
            name = null,
            uploadedAt = 0L,
            read = true,
            readAt = null,
            position = null,
            bookmarked = false,
        )
    }
    for (row in rows) {
        val id = row.text("chapterId").ifEmpty { continue }
        val progress = (row["progressFraction"] as? JsonPrimitive)?.doubleOrNull ?: 0.0
        val before = byId[id]
        val done = progress >= Finished || before != null
        byId[id] = ImportedChapter(
            url = id,
            number = before?.number
                ?: (row["chapterNumber"] as? JsonPrimitive)?.doubleOrNull
                ?: chapterNumberFromName(id)
                ?: ((row.int("chapterIndex") ?: 0) + 1).toDouble(),
            name = null,
            uploadedAt = 0L,
            read = done,
            readAt = if (done) timeOf(row.text("timestamp")) else null,
            position = if (done) null else progress.takeIf { it > 0 },
            bookmarked = false,
        )
    }
    return byId.values.toList()
}

// A title and a chapter are found by the source and the title together, written as the source, a bar, and the title.
private fun key(row: JsonObject) = "${row.text("extensionId")}|${row.text("mangaId")}"

private fun ids(value: Any?): List<String> = (value as? JsonArray).orEmpty().mapNotNull {
    (it as? JsonPrimitive)?.contentOrNull
}

// A chapter number of a foreign import is written in thousandths.
private fun numbers(value: Any?): List<Double> =
    (value as? JsonArray).orEmpty().mapNotNull { (it as? JsonPrimitive)?.doubleOrNull?.div(1000.0) }

// A shelf that is left out of the check for new chapters says so. One that does not say is checked, as Boundless does.
private fun JsonObject.noUpdates(): Boolean = (this["trackUpdates"] as? JsonPrimitive)?.booleanOrNull == false

private fun statusOf(name: String): Status? = when (name.lowercase()) {
    "ongoing" -> Status.Ongoing
    "completed" -> Status.Completed
    "hiatus" -> Status.Hiatus
    "cancelled", "canceled" -> Status.Cancelled
    else -> null
}
