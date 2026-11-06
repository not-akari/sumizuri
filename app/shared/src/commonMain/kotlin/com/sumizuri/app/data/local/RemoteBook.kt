package com.sumizuri.app.data.local

import com.sumizuri.app.source.host.net.HttpHost
import com.sumizuri.app.source.model.SourcePage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import okio.ByteString.Companion.encodeUtf8
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath

// How many fetched books are kept, the ones fetched last, so the temporary folder does not grow without end.
private const val KeptBooks = 5

// The pages of a book at an address. It is kept among the temporary files, so opening a chapter again does not fetch it again.
internal suspend fun bookPages(url: String, headers: Map<String, String>, http: HttpHost): List<SourcePage> =
    withContext(Dispatchers.IO) {
        val fs = FileSystem.SYSTEM
        val folder = FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-books"
        fs.createDirectories(folder)
        val file = folder / url.encodeUtf8().sha256().hex()
        if (!fs.exists(file)) {
            val part = "$file.part".toPath()
            http.download(url, headers, part)
            fs.atomicMove(part, file)
            forgetOldBooks(fs, folder)
        }
        val start = fs.read(file) { readUtf8(minOf(4L, fs.metadata(file).size ?: 0L)) }
        val pages = when {
            start == "%PDF" -> List(pdfPageCount(file.toString())) {
                SourcePage(it, imageUrl = localPdfPageAddress(file.toString(), it))
            }

            start.startsWith("PK") -> Epub(file.toString()).let { book ->
                book.documents.mapIndexed { index, document -> SourcePage(index, text = book.words(document)) }
            }

            else -> emptyList()
        }.filter { it.imageUrl != null || !it.text.isNullOrBlank() }
        if (pages.isEmpty()) {
            fs.delete(file)
            error("This book has no pages to show, or the file could not be read")
        }
        pages
    }

// Only the books fetched last stay. A file still being fetched is left alone.
private fun forgetOldBooks(fs: FileSystem, folder: Path) {
    val books = fs.list(folder).filter { !it.name.endsWith(".part") }.sortedByDescending {
        fs.metadata(it).lastModifiedAtMillis
            ?: 0L
    }
    books.drop(KeptBooks).forEach { fs.delete(it) }
}
