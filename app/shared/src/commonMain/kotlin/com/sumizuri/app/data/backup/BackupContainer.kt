package com.sumizuri.app.data.backup

import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.shareHead
import dev.whyoleg.cryptography.random.CryptographyRandom
import okio.Buffer
import okio.BufferedSink
import okio.Deflater
import okio.DeflaterSink
import okio.FileSystem
import okio.Inflater
import okio.InflaterSource
import okio.Path
import okio.Sink
import okio.Source
import okio.buffer
import okio.use

// The first bytes of a backup that is compressed or has a password. A backup with neither stays plain JSON text, the way the Flutter app wrote it.
private val Magic = "SUMIZURI".encodeToByteArray()
private const val ContainerVersion = 1
private const val SaltSize = 16
private const val NonceSize = 12

// How much a backup is squeezed. None keeps it readable, Fast is quick to make, Small takes the least room.
enum class BackupCompression(val code: Int, val level: Int) {
    None(0, 0),
    Fast(1, 1),
    Small(1, 9),
}

// How a backup file is packed: how much it is squeezed, and the password it is shut with, if any.
data class BackupPacking(val compression: BackupCompression = BackupCompression.Fast, val password: String? = null)

// True when the bytes are the start of a packed backup of this app.
fun isPackedBackup(head: ByteArray): Boolean = head.size >= Magic.size && head.copyOf(Magic.size).contentEquals(Magic)

// For a packed backup of this app, whether it is shut with a password. Null for any other file, such as plain JSON text.
fun packedNeedsPassword(file: Path, system: FileSystem = FileSystem.SYSTEM): Boolean? {
    val head = system.source(file).buffer().use { source ->
        source.request(Magic.size + 3L)
        source.buffer.readByteArray(minOf(source.buffer.size, Magic.size + 3L))
    }
    if (!isPackedBackup(head) || head.size < Magic.size + 3) return null
    return head[Magic.size + 2].toInt() != 0
}

// Writes the backup into the file, squeezed and shut as the packing says. The body writes the JSON as it goes, so nothing has to be held in memory whole.
suspend fun writePackedBackup(
    file: Path,
    packing: BackupPacking,
    system: FileSystem = FileSystem.SYSTEM,
    body: suspend (BufferedSink) -> Unit,
) {
    val compressed = packing.compression != BackupCompression.None
    val password = packing.password?.takeIf { it.isNotEmpty() }
    if (!compressed && password == null) {
        system.sink(file).buffer().use { wrapped(it, body) }
        return
    }
    val header = Buffer()
        .write(Magic)
        .writeByte(ContainerVersion)
        .writeByte(packing.compression.code)
        .writeByte(if (password != null) 1 else 0)
    var salt = ByteArray(0)
    var nonce = ByteArray(0)
    if (password != null) {
        salt = CryptographyRandom.nextBytes(SaltSize)
        nonce = CryptographyRandom.nextBytes(NonceSize)
        header
            .writeInt(KeyIterations)
            .writeByte(salt.size)
            .write(salt)
            .writeByte(nonce.size)
            .write(nonce)
    }
    val headerBytes = header.readByteArray()
    val raw = system.sink(file)
    raw.write(Buffer().write(headerBytes), headerBytes.size.toLong())
    var sink: Sink = raw
    if (password != null) sink = SealingSink(sink, backupCipher(password, salt, KeyIterations), nonce, headerBytes)
    if (compressed) sink = DeflaterSink(sink, Deflater(packing.compression.level, false))
    sink.buffer().use { wrapped(it, body) }
}

// A backup file is a file of the app that holds the backup, so the backup is written inside its shape.
private suspend fun wrapped(out: BufferedSink, body: suspend (BufferedSink) -> Unit) {
    out.writeUtf8(shareHead(ShareKind.Backup))
    body(out)
    out.writeUtf8("}")
}

// Unpacks a packed backup into a plain JSON file, opening it with the password when it has one.
suspend fun unpackBackup(file: Path, target: Path, password: String?, system: FileSystem = FileSystem.SYSTEM) {
    val input = system.source(file).buffer()
    try {
        val header = Buffer()
        val magic = input.readByteArray(Magic.size.toLong())
        if (!magic.contentEquals(Magic)) throw BackupUnreadable(BackupProblem.NotBackup)
        header.write(magic)
        val version = input.readByte().toInt()
        if (version > ContainerVersion) throw BackupUnreadable(BackupProblem.NewerVersion)
        val compression = input.readByte().toInt()
        val encryption = input.readByte().toInt()
        header.writeByte(version).writeByte(compression).writeByte(encryption)
        var source: Source = input
        if (encryption != 0) {
            if (encryption != 1) throw BackupUnreadable(BackupProblem.NewerVersion)
            if (password.isNullOrEmpty()) throw BackupUnreadable(BackupProblem.WrongPassword)
            val iterations = input.readInt()
            val salt = input.readByteArray(input.readByte().toLong() and 0xFF)
            val nonce = input.readByteArray(input.readByte().toLong() and 0xFF)
            header
                .writeInt(iterations)
                .writeByte(salt.size)
                .write(salt)
                .writeByte(nonce.size)
                .write(nonce)
            source = OpeningSource(input, backupCipher(password, salt, iterations), nonce, header.readByteArray())
        }
        if (compression == 1) {
            source = InflaterSource(source.buffer(), Inflater(false))
        } else if (compression != 0) {
            throw BackupUnreadable(BackupProblem.NewerVersion)
        }
        system.sink(target).buffer().use { out -> source.buffer().use { out.writeAll(it) } }
    } catch (error: BackupUnreadable) {
        throw error
    } catch (error: Exception) {
        if (error is kotlinx.coroutines.CancellationException) throw error
        throw BackupUnreadable(BackupProblem.Damaged, error)
    } finally {
        runCatching { input.close() }
    }
}
