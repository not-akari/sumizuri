package com.sumizuri.app.data.local

import com.sumizuri.app.source.model.SourcePage
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.header
import io.ktor.client.request.prepareGet
import io.ktor.client.statement.bodyAsChannel
import io.ktor.http.isSuccess
import io.ktor.utils.io.readAvailable
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath
import okio.buffer

private val Spaces = Regex("[ \\t\\u00A0]+")
private val BlankLines = Regex("\\n{3,}")

// The client books are fetched with. A book may take minutes, so only a stalled connection gives up.
private val http = lazy { HttpClient { install(HttpTimeout) { socketTimeoutMillis = 60_000 } } }

// The words a PDF gave, with the spaces of its layout taken out of each line.
internal fun tidiedPdfText(text: String): String = text
    .lines()
    .joinToString("\n") { it.replace(Spaces, " ").trim() }
    .replace(BlankLines, "\n\n")
    .trim()

// The pages of a book at an address. It is kept among the temporary files, so opening a chapter again does not fetch it again.
internal suspend fun bookPages(url: String, headers: Map<String, String>): List<SourcePage> = withContext(Dispatchers.IO) {
    val fs = FileSystem.SYSTEM
    val folder = FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-books"
    fs.createDirectories(folder)
    val file = folder / url.hashCode().toUInt().toString()
    if (!fs.exists(file)) fetchBook(url, headers, file)
    val start = fs.read(file) { readUtf8(minOf(4L, fs.metadata(file).size ?: 0L)) }
    val pages = when {
        start == "%PDF" -> listOf(SourcePage(0, text = pdfText(file.toString())))
        start.startsWith("PK") -> Epub(file.toString()).let { book ->
            book.documents.mapIndexed { index, document -> SourcePage(index, text = book.words(document)) }
        }
        else -> emptyList()
    }.filter { !it.text.isNullOrBlank() }
    if (pages.isEmpty()) {
        fs.delete(file)
        error("This book has no words to show. It may be a PDF of scanned pictures, or the file could not be read")
    }
    pages
}

// Writes the file as it arrives, into a name of its own first so a cut one is never taken for the book.
private suspend fun fetchBook(url: String, headers: Map<String, String>, file: Path) {
    val part = "$file.part".toPath()
    http.value.prepareGet(url) { headers.forEach { (name, value) -> header(name, value) } }.execute { response ->
        if (!response.status.isSuccess()) error("The book answered ${response.status.value}")
        val channel = response.bodyAsChannel()
        val buffer = ByteArray(64 * 1024)
        FileSystem.SYSTEM.sink(part).buffer().use { sink ->
            while (true) {
                val read = channel.readAvailable(buffer, 0, buffer.size)
                if (read == -1) break
                if (read > 0) sink.write(buffer, 0, read)
            }
        }
    }
    FileSystem.SYSTEM.atomicMove(part, file)
}
