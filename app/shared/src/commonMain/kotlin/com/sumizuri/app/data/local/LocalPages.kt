package com.sumizuri.app.data.local

import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

// The address the reader loads a picture on the device by: a file of its own, such as a saved page, or a file inside an archive, such as a page of a CBZ. The paths are written in a form that survives any letters a path can have, like the back slashes and the drive of Windows.
private const val Scheme = "sumizuri-local"

@OptIn(ExperimentalEncodingApi::class)
private val Coder = Base64.UrlSafe.withPadding(Base64.PaddingOption.ABSENT)

@OptIn(ExperimentalEncodingApi::class)
fun localFileAddress(path: String): String = "$Scheme://file/${Coder.encode(path.encodeToByteArray())}"

@OptIn(ExperimentalEncodingApi::class)
fun localEntryAddress(archive: String, entry: String): String =
    "$Scheme://zip/${Coder.encode(archive.encodeToByteArray())}/${Coder.encode(entry.encodeToByteArray())}"

@OptIn(ExperimentalEncodingApi::class)
fun localPdfPageAddress(pdf: String, index: Int): String =
    "$Scheme://pdf/${Coder.encode(pdf.encodeToByteArray())}/$index"

fun isLocalAddress(address: String): Boolean = address.startsWith("$Scheme://")

// Where a local address points: a file, or a file inside an archive. Null for any other address.
sealed interface LocalPicture {
    data class File(val path: String) : LocalPicture
    data class Entry(val archive: String, val entry: String) : LocalPicture
    data class PdfPage(val pdf: String, val index: Int) : LocalPicture
}

@OptIn(ExperimentalEncodingApi::class)
fun localPictureOf(address: String): LocalPicture? {
    if (!isLocalAddress(address)) return null
    val parts = address.removePrefix("$Scheme://").split('/')
    return runCatching {
        when (parts.firstOrNull()) {
            "file" -> LocalPicture.File(Coder.decode(parts[1]).decodeToString())

            "zip" -> LocalPicture.Entry(
                Coder.decode(parts[1]).decodeToString(),
                Coder.decode(parts[2]).decodeToString(),
            )

            "pdf" -> LocalPicture.PdfPage(Coder.decode(parts[1]).decodeToString(), parts[2].toInt())

            else -> null
        }
    }.getOrNull()
}
