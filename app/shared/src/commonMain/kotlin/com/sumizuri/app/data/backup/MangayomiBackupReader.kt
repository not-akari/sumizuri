package com.sumizuri.app.data.backup

import com.sumizuri.app.data.json.flag
import com.sumizuri.app.data.json.int
import com.sumizuri.app.data.json.list
import com.sumizuri.app.data.json.text
import com.sumizuri.app.data.model.Kind
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.longOrNull
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath
import okio.openZip

// Reads a Mangayomi backup, a zip with one JSON file in it. The titles that are favourites come with their shelves, chapters and reading history.
fun readMangayomiBackup(file: Path, system: FileSystem = FileSystem.SYSTEM): ImportedBackup {
    val root = try {
        val zip = system.openZip(file)
        val entry =
            zip.listRecursively("/".toPath()).firstOrNull { it.name.endsWith(".db") && zip.metadata(it).isRegularFile }
                ?: throw BackupUnreadable(BackupProblem.NotBackup)
        Json.parseToJsonElement(zip.read(entry) { readUtf8() }).jsonObject
    } catch (error: BackupUnreadable) {
        throw error
    } catch (error: Throwable) {
        throw BackupUnreadable(BackupProblem.NotBackup, error)
    }
    try {
        val categories = root.list("categories").map {
            Category(it.int("id") ?: 0, it.text("name").trim(), it.int("forItemType"))
        }
        val shelfNames = categories.associate { it.id to it.name }
        val chapters = root.list("chapters")
        val byTitle = chapters.groupBy { it.int("mangaId") }
        val chapterUrls = chapters.associate { it.int("id") to it.text("url") }
        val historyByTitle = root.list("history").groupBy { it.int("mangaId") }
        val titles = root.list("manga").filter { it.flag("favorite") }.map { manga ->
            val id = manga.int("id")
            // The last time each chapter was read, from the history.
            val readAt = buildMap {
                for (entry in historyByTitle[id].orEmpty()) {
                    chapterUrls[entry.int("chapterId")]?.let { url ->
                        time(entry["date"])?.let {
                            put(
                                url,
                                maxOf(
                                    it,
                                    this[url] ?: 0L,
                                ),
                            )
                        }
                    }
                }
            }
            val rows = byTitle[id].orEmpty()
            ImportedTitle(
                name = manga.text("name").trim(),
                url = manga.text("link"),
                coverUrl = manga.text("imageUrl").ifEmpty { null },
                kind = kindOf(manga.int("itemType")),
                favorite = true,
                sourceName = manga.text("source").ifEmpty { null },
                sourceUrl = null,
                shelves = (manga["categories"] as? JsonArray)
                    .orEmpty()
                    .mapNotNull {
                        shelfNames[(it as? JsonPrimitive)?.intOrNull]
                    }.filter { it.isNotEmpty() },
                chapters = rows.mapIndexed { index, chapter ->
                    val name = chapter.text("name").trim()
                    val url = chapter.text("url")
                    val read = chapter.flag("isRead")
                    ImportedChapter(
                        url = url,
                        number = chapterNumberFromName(name) ?: (rows.size - index).toDouble(),
                        name = name.ifEmpty { null },
                        uploadedAt = time(chapter["dateUpload"]) ?: 0L,
                        read = read,
                        readAt = if (read) readAt[url] else null,
                        position = if (read) {
                            null
                        } else {
                            (chapter["lastPageRead"] as? JsonPrimitive)
                                ?.contentOrNull
                                ?.toDoubleOrNull()
                                ?.takeIf { it > 0 }
                                ?.coerceAtMost(1.0)
                        },
                        bookmarked = chapter.flag("isBookmarked"),
                    )
                },
            )
        }
        return ImportedBackup(
            BackupApp.Mangayomi,
            titles,
            categories
                .filter {
                    it.name.isNotEmpty()
                }.map { ImportedShelf(it.name) },
        )
    } catch (error: Throwable) {
        throw BackupUnreadable(BackupProblem.Damaged, error)
    }
}

private class Category(val id: Int, val name: String, val itemType: Int?)

private fun kindOf(itemType: Int?): Kind = when (itemType) {
    1 -> Kind.Anime
    2 -> Kind.Novel
    else -> Kind.Manga
}

// A time written as a number or as text of one, in milliseconds, or null when it is missing or not after the start.
private fun time(value: Any?): Long? = (value as? JsonPrimitive)
    ?.let {
        it.longOrNull
            ?: it.contentOrNull?.toLongOrNull()
    }?.takeIf { it > 0 }
