package com.sumizuri.app.data.local

import com.sumizuri.app.source.host.net.HttpHost
import com.sumizuri.app.source.model.SourcePage
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okio.ByteString.Companion.encodeUtf8
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath

// How many fetched books are kept, the ones opened last, so the temporary folder does not grow without end.
private const val KeptBooks = 5

// One book is fetched at a time, so two asks for the same book never write the same file.
private val Fetching = Mutex()

// The pages of a book at an address. It is kept among the temporary files, so opening a chapter again does not fetch it again.
internal suspend fun bookPages(url: String, headers: Map<String, String>, http: HttpHost): List<SourcePage> =
    withContext(Dispatchers.IO) {
        val fs = FileSystem.SYSTEM
        val folder = FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-books"
        fs.createDirectories(folder)
        val file = folder / url.encodeUtf8().sha256().hex()
        if (!fs.exists(file)) {
            Fetching.withLock {
                if (!fs.exists(file)) {
                    val part = "$file.part".toPath()
                    try {
                        http.download(url, headers, part)
                        fs.atomicMove(part, file)
                    } catch (problem: Throwable) {
                        fs.delete(part)
                        throw problem
                    }
                    forgetOldBooks(fs, folder)
                }
            }
        }
        // The mark of when the book was last opened, which decides the books that stay.
        fs.write(usedMark(file)) {}
        // A file that cannot be read is not kept, so the next try fetches it again.
        val pages = try {
            readBook(fs, file)
        } catch (problem: Throwable) {
            if (problem !is CancellationException) forget(fs, file)
            throw problem
        }
        if (pages.isEmpty()) {
            forget(fs, file)
            error("This book has no pages to show, or the file could not be read")
        }
        pages
    }

private fun readBook(fs: FileSystem, file: Path): List<SourcePage> {
    val start = fs.read(file) { readUtf8(minOf(4L, fs.metadata(file).size ?: 0L)) }
    return when {
        start == "%PDF" -> List(pdfPageCount(file.toString())) {
            SourcePage(it, imageUrl = localPdfPageAddress(file.toString(), it))
        }

        start.startsWith("PK") -> Epub(file.toString()).let { book ->
            book.documents.mapIndexed { index, document -> SourcePage(index, text = book.words(document)) }
        }

        else -> emptyList()
    }.filter { it.imageUrl != null || !it.text.isNullOrBlank() }
}

private fun usedMark(file: Path): Path = "$file.used".toPath()

private fun forget(fs: FileSystem, file: Path) {
    fs.delete(file)
    fs.delete(usedMark(file))
}

// Only the books opened last stay. It runs while no book is being fetched, so a part file here was left by a fetch that stopped, and goes too.
private fun forgetOldBooks(fs: FileSystem, folder: Path) {
    val names = fs.list(folder)
    names.filter { it.name.endsWith(".part") }.forEach { fs.delete(it) }
    val books = names.filter { !it.name.endsWith(".part") && !it.name.endsWith(".used") }
    fun opened(book: Path): Long = fs.metadataOrNull(usedMark(book))?.lastModifiedAtMillis
        ?: fs.metadataOrNull(book)?.lastModifiedAtMillis
        ?: 0L
    books.sortedByDescending(::opened).drop(KeptBooks).forEach { forget(fs, it) }
    // A mark whose book is gone is dropped as well.
    names
        .filter {
            it.name.endsWith(".used") && !fs.exists(folder / it.name.removeSuffix(".used"))
        }.forEach { fs.delete(it) }
}
