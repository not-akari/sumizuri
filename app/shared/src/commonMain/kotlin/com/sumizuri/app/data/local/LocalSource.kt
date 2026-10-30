package com.sumizuri.app.data.local

import com.sumizuri.app.data.backup.chapterNumberFromName
import com.sumizuri.app.source.Source
import com.sumizuri.app.source.SourceError
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.model.CommentPage
import com.sumizuri.app.source.model.CommentSort
import com.sumizuri.app.source.model.FilterGroup
import com.sumizuri.app.source.model.SourceCatalog
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.model.SourceInfo
import com.sumizuri.app.source.model.SourcePage
import com.sumizuri.app.source.model.SourcePreference
import com.sumizuri.app.source.model.SourceVideo
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import okio.FileSystem
import okio.Path

private val Pictures = setOf("jpg", "jpeg", "png", "webp", "gif", "avif", "bmp", "heic")
private val CoverNames = setOf("cover.jpg", "cover.jpeg", "cover.png", "cover.webp")
private const val Details = "details.json"

private val Lenient = Json {
    ignoreUnknownKeys = true
    isLenient = true
}

private fun Path.ext(): String = name.substringAfterLast('.', "").lowercase()

// The files on the device as a source. Each folder in the source's folder is a title, and so is each CBZ, ZIP, EPUB or TXT file in it. Inside a title folder, each archive, book, text file or folder of pictures is a chapter, and pictures lying in the folder itself make one chapter. A cover file and a details file in the Mihon form give the cover and the facts. For novels an EPUB on its own is a book whose chapters are the documents of its reading order.
class LocalSource(
    name: String,
    private val novels: Boolean,
    private val folder: Path,
    private val fs: FileSystem = FileSystem.SYSTEM,
) : Source {
    override val info =
        SourceInfo(name, "local", null, null, hasDetails = true, hasFilters = false, hasCatalogs = false)

    override suspend fun popular(page: Int) = listed(page) { titles ->
        titles.sortedWith(
            compareBy(NaturalOrder) {
                it.name
            },
        )
    }

    override suspend fun latest(page: Int) = listed(page) { titles ->
        titles
            .associateWith { fs.metadataOrNull(it)?.lastModifiedAtMillis ?: 0L }
            .entries
            .sortedByDescending { it.value }
            .map { it.key }
    }

    override suspend fun search(query: String, page: Int, filters: Map<String, Any?>) = listed(page) { titles ->
        titles
            .filter {
                it.name.contains(query.trim(), ignoreCase = true)
            }.sortedWith(compareBy(NaturalOrder) { it.name })
    }

    override suspend fun details(entry: SourceEntry) = attempt { entryOf(titlePath(entry.url)) }

    override suspend fun chapters(entry: SourceEntry) = attempt { chaptersOf(titlePath(entry.url)) }

    override suspend fun pages(chapter: SourceChapter) = attempt { pagesOf(chapter.url) }

    override suspend fun videos(chapter: SourceChapter): SourceResult<List<SourceVideo>> =
        SourceResult.Err(SourceError.NotImplemented("videos"))
    override suspend fun filters(): SourceResult<List<FilterGroup>> = SourceResult.Ok(emptyList())
    override suspend fun catalogs(): SourceResult<List<SourceCatalog>> = SourceResult.Ok(emptyList())
    override suspend fun catalog(id: String, page: Int): SourceResult<List<SourceEntry>> = SourceResult.Ok(emptyList())
    override suspend fun comments(entry: SourceEntry, sort: CommentSort, page: Int): SourceResult<CommentPage> =
        SourceResult.Err(SourceError.NotImplemented("comments"))
    override suspend fun chapterComments(
        chapter: SourceChapter,
        sort: CommentSort,
        page: Int,
    ): SourceResult<CommentPage> = SourceResult.Err(SourceError.NotImplemented("comments"))
    override suspend fun commentReplies(commentId: String, page: Int): SourceResult<CommentPage> =
        SourceResult.Err(SourceError.NotImplemented("comments"))
    override suspend fun sourcePreferences(): SourceResult<List<SourcePreference>> = SourceResult.Ok(emptyList())
    override suspend fun preferences(): Map<String, Any?> = emptyMap()
    override suspend fun setPreference(key: String, value: Any?) = Unit
    override fun close() = Unit

    // Every call reads the files on a thread for them, and a file that cannot be read gives its reason as an error of the source.
    private suspend fun <T> attempt(block: () -> T): SourceResult<T> = withContext(Dispatchers.IO) {
        try {
            SourceResult.Ok(block())
        } catch (error: CancellationException) {
            throw error
        } catch (error: Throwable) {
            SourceResult.Err(SourceError.Script(error.message ?: "The file could not be read"))
        }
    }

    // The whole list comes on the first page, as the folder is read at once.
    private suspend fun listed(page: Int, order: (List<Path>) -> List<Path>) = attempt {
        if (page > 1) emptyList() else order(titles()).mapNotNull { runCatching { entryOf(it) }.getOrNull() }
    }

    private fun titles(): List<Path> {
        fs.createDirectories(folder)
        return fs.list(folder).filter { path -> if (isFolder(path)) !path.name.startsWith(".") else reads(path) }
    }

    // Whether this source reads a file, by the end of its name.
    private fun reads(path: Path): Boolean = path.ext() in LocalSources.readableFiles(novels)

    // The title a source address names, kept inside the folder of the source.
    private fun titlePath(key: String): Path {
        val name = key.substringBefore('/').substringBefore('#')
        require(name.isNotEmpty() && name != ".." && name != ".") { "No such title: $key" }
        val path = folder / name
        require(fs.exists(path)) { "The file of this title is gone: $name" }
        return path
    }

    private fun isFolder(path: Path) = fs.metadataOrNull(path)?.isDirectory == true

    private fun entryOf(path: Path): SourceEntry {
        val key = path.name
        if (!isFolder(path)) {
            val book = if (path.ext() == "epub") Epub(path.toString()) else null
            return SourceEntry(
                url = key,
                title = book?.title ?: key.substringBeforeLast('.'),
                coverUrl = book?.cover?.let { localEntryAddress(path.toString(), it) } ?: firstPictureOf(path),
                author = book?.author,
                description = book?.description,
            )
        }
        val details = (path / Details)
            .takeIf {
                fs.exists(it)
            }?.let { file ->
                runCatching {
                    Lenient.parseToJsonElement(
                        fs.read(file) { readUtf8() },
                    ) as? JsonObject
                }.getOrNull()
            }
        fun text(name: String) = (details?.get(name) as? JsonPrimitive)?.contentOrNull?.trim()?.ifEmpty { null }
        val genres = when (val genre = details?.get("genre")) {
            is JsonArray -> genre.mapNotNull { (it as? JsonPrimitive)?.contentOrNull?.trim() }

            is JsonPrimitive ->
                genre.contentOrNull
                    .orEmpty()
                    .split(',')
                    .map { it.trim() }

            else -> emptyList()
        }.filter { it.isNotEmpty() }
        val cover = fs
            .list(
                path,
            ).firstOrNull { it.name.lowercase() in CoverNames }
            ?.let { localFileAddress(it.toString()) }
        return SourceEntry(
            url = key,
            title = text("title") ?: key,
            coverUrl = cover ?: firstPictureOf(path),
            author = listOfNotNull(text("author"), text("artist")).distinct().joinToString(", ").ifEmpty { null },
            description = text("description"),
            status = text("status")?.let(::statusText),
            genres = genres,
        )
    }

    // The first page of the first chapter, as a cover for a title that has none of its own.
    private fun firstPictureOf(path: Path): String? = runCatching {
        if (isFolder(path)) {
            val chapters = chapterFiles(path)
            chapters.firstOrNull()?.let { first -> picturesOf(first).firstOrNull() }
        } else {
            picturesOf(path).firstOrNull()
        }
    }.getOrNull()

    // What in a title folder is a chapter: archives, books, text files and folders of pictures, with the pictures lying loose in it as one more.
    private fun chapterFiles(path: Path): List<Path> {
        val children = fs.list(path).filter {
            !it.name.startsWith(".") && it.name.lowercase() !in CoverNames &&
                it.name != Details
        }
        val chapters = children.filter { child ->
            if (isFolder(child)) {
                !novels &&
                    fs.list(child).any { it.ext() in Pictures }
            } else {
                reads(child)
            }
        }
        val loose = if (!novels && children.any { !isFolder(it) && it.ext() in Pictures }) listOf(path) else emptyList()
        return (loose + chapters.sortedWith(compareBy(NaturalOrder) { it.name }))
    }

    // The chapters of a title, the newest first as sources list them, numbered by what their names say or else by their place.
    private fun chaptersOf(path: Path): List<SourceChapter> {
        val key = path.name
        val found = if (isFolder(path)) {
            chapterFiles(path).map { file ->
                val name = if (file ==
                    path
                ) {
                    key
                } else {
                    file.name.substringBeforeLast('.').takeIf { !isFolder(file) } ?: file.name
                }
                val url = if (file == path) key else "$key/${file.name}"
                url to name
            }
        } else if (novels && path.ext() == "epub") {
            val book = Epub(path.toString())
            book.documents.mapIndexed { index, document ->
                "$key#$index" to
                    (book.names[document] ?: "Part ${index + 1}")
            }
        } else {
            listOf(key to key.substringBeforeLast('.'))
        }
        return found
            .mapIndexed { index, (url, name) ->
                SourceChapter(
                    url = url,
                    title = name,
                    number = chapterNumberFromName(name) ?: (index + 1).toDouble(),
                    uploadedAt = modifiedAt(url),
                )
            }.asReversed()
    }

    private fun modifiedAt(url: String): Long? {
        val relative = url.substringBefore('#')
        return fs.metadataOrNull(folder / relative)?.lastModifiedAtMillis
    }

    // The pages of a chapter: its pictures as addresses on the device, or its words.
    private fun pagesOf(url: String): List<SourcePage> {
        val relative = url.substringBefore('#')
        require(relative.split('/').none { it == ".." }) { "No such chapter: $url" }
        val path = folder / relative
        require(fs.exists(path)) { "The file of this chapter is gone: $relative" }
        val index = url.substringAfter('#', "").toIntOrNull()
        if (path.ext() == "epub" && novels) {
            val book = Epub(path.toString())
            val documents = if (index != null) listOfNotNull(book.documents.getOrNull(index)) else book.documents
            return documents.mapIndexed { i, document -> SourcePage(i, text = book.words(document)) }.filter {
                !it.text.isNullOrBlank()
            }
        }
        if (path.ext() == "txt") return listOf(SourcePage(0, text = fs.read(path) { readUtf8() }))
        if (path.ext() == "pdf") return listOf(SourcePage(0, text = pdfText(path.toString())))
        return picturesOf(path).mapIndexed { i, address -> SourcePage(i, imageUrl = address) }
    }

    // The pictures of a folder, an archive or a book of pictures, in order.
    private fun picturesOf(path: Path): List<String> = when {
        isFolder(path) ->
            fs
                .list(path)
                .filter { it.ext() in Pictures && it.name.lowercase() !in CoverNames }
                .sortedWith(compareBy(NaturalOrder) { it.name })
                .map { localFileAddress(it.toString()) }

        path.ext() == "epub" -> {
            val book = Epub(path.toString())
            val ordered = book.documents.flatMap { book.pictures(it) }.distinct()
            val pictures = ordered.ifEmpty {
                archiveEntries(path.toString())
                    .filter {
                        it.substringAfterLast('.').lowercase() in
                            Pictures
                    }.sortedWith(NaturalOrder)
            }
            pictures.map { localEntryAddress(path.toString(), it) }
        }

        else -> archiveEntries(path.toString())
            .filter {
                it.substringAfterLast('.').lowercase() in Pictures &&
                    !it.startsWith("__MACOSX")
            }.sortedWith(NaturalOrder)
            .map { localEntryAddress(path.toString(), it) }
    }
}

// The status a details file gives, by the number Mihon writes or as words.
private fun statusText(value: String): String = when (value) {
    "1" -> "Ongoing"
    "2" -> "Completed"
    "3" -> "Licensed"
    "4" -> "Completed"
    "5" -> "Cancelled"
    "6" -> "Hiatus"
    "0" -> "Unknown"
    else -> value
}
