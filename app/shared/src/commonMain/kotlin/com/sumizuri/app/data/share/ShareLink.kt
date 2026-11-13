package com.sumizuri.app.data.share

import com.sumizuri.app.navigation.AppLinks
import okio.Buffer
import okio.Deflater
import okio.DeflaterSink
import okio.Inflater
import okio.InflaterSource
import okio.buffer
import okio.use
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

// The letters of a link, with no padding at the end, which links do not like.
@OptIn(ExperimentalEncodingApi::class)
private val LinkLetters = Base64.UrlSafe.withPadding(Base64.PaddingOption.ABSENT_OPTIONAL)

// A link that carries a whole small file, squeezed, for a chat. Opening it in the app imports the file.
@OptIn(ExperimentalEncodingApi::class)
fun shareLink(text: String): String {
    val squeezed = Buffer()
    DeflaterSink(squeezed, Deflater(9, true)).buffer().use { it.writeUtf8(text) }
    return "${AppLinks.Scheme}://import?d=" + LinkLetters.encode(squeezed.readByteArray())
}

// The text of the file a link carries, or null when the text is no such link.
@OptIn(ExperimentalEncodingApi::class)
fun textOfLink(link: String): String? {
    val trimmed = link.trim()
    if (!trimmed.startsWith("${AppLinks.Scheme}://import?", ignoreCase = true)) return null
    val data = trimmed.substringAfter("d=", "").substringBefore('&').takeIf { it.isNotEmpty() } ?: return null
    return runCatching {
        val squeezed = Buffer().write(LinkLetters.decode(data))
        InflaterSource(squeezed, Inflater(true)).buffer().use { it.readUtf8() }
    }.getOrNull()
}
