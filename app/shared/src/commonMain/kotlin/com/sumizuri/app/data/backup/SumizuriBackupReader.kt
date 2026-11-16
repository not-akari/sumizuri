package com.sumizuri.app.data.backup

import com.sumizuri.app.data.db.category.CategoryEntity
import com.sumizuri.app.data.db.cookie.CookieEntity
import com.sumizuri.app.data.db.repo.RepoEntity
import com.sumizuri.app.data.db.source.SourceEntity
import com.sumizuri.app.data.db.value.SourceValueEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.library.LibrarySortField
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.ShareProblem
import com.sumizuri.app.data.share.ShareUnreadable
import com.sumizuri.app.data.share.readShared
import com.sumizuri.app.data.text.localOffsetMillis
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.longOrNull
import kotlin.time.Instant

// Reads the titles and shelves of a Sumizuri backup. A backup of the Flutter app is version 2, and its sources, themes and fonts are for that app and are not used here. A backup of this app is version 3 and also brings its sources, settings and sign ins.
fun readSumizuriBackup(text: String): ImportedBackup {
    val root = try {
        Json.parseToJsonElement(text).jsonObject
    } catch (error: Exception) {
        throw BackupUnreadable(BackupProblem.NotBackup, error)
    }
    return readSumizuriBackup(root)
}

// Reads a backup file, which is a file of the app that holds a backup.
fun readBackupFile(text: String): ImportedBackup {
    val shared = try {
        readShared(text)
    } catch (error: ShareUnreadable) {
        throw BackupUnreadable(
            if (error.problem ==
                ShareProblem.Newer
            ) {
                BackupProblem.NewerVersion
            } else {
                BackupProblem.NotBackup
            },
            error,
        )
    }
    if (shared.kind != ShareKind.Backup) throw BackupUnreadable(BackupProblem.NotBackup)
    return readSumizuriBackup(shared.data as? JsonObject ?: throw BackupUnreadable(BackupProblem.Damaged))
}

fun readSumizuriBackup(root: JsonObject): ImportedBackup {
    val version =
        (root["backupVersion"] as? JsonPrimitive)?.intOrNull ?: throw BackupUnreadable(BackupProblem.NotBackup)
    if (version > SumizuriBackupVersion) throw BackupUnreadable(BackupProblem.NewerVersion)
    val ours = version >= 3
    try {
        val shelves = root.list("categories").map { shelf -> if (ours) ourShelf(shelf) else flutterShelf(shelf) }
        val titles = root.list("libraryEntries").map { entry ->
            // When each chapter was last read: the time it was marked, or else the newest sitting that names it.
            val sittings = buildMap {
                for (session in entry.list("sessions")) {
                    timeOf(session.text("readAt"))?.let {
                        put(
                            session.text("url"),
                            maxOf(
                                it,
                                this[session.text("url")] ?: 0L,
                            ),
                        )
                    }
                }
            }
            ImportedTitle(
                name = entry.text("title"),
                url = entry.text("externalId"),
                coverUrl = entry.text("coverUrl").ifEmpty { null },
                kind = kindOf(entry.text("mediaType")) ?: Kind.Manga,
                favorite = entry.bool("favorite"),
                sourceName = entry.text("sourceName").ifEmpty { null },
                sourceUrl = entry.text("sourceBaseUrl").ifEmpty { null },
                shelves = entry.strings("categoryNames"),
                chapters = entry.list("chapters").map { chapter ->
                    val url = chapter.text("url")
                    val read = chapter.bool("consumed")
                    ImportedChapter(
                        url = url,
                        number = (chapter["number"] as? JsonPrimitive)?.doubleOrNull ?: 0.0,
                        name = chapter.text("title").ifEmpty { null },
                        uploadedAt = timeOf(chapter.text("dateUploaded")) ?: 0L,
                        read = read,
                        readAt = if (read) timeOf(chapter.text("consumedAt")) ?: sittings[url] else null,
                        position = if (read) {
                            null
                        } else {
                            (chapter["progressPosition"] as? JsonPrimitive)
                                ?.doubleOrNull
                                ?.takeIf {
                                    it >
                                        0
                                }?.coerceAtMost(1.0)
                        },
                        bookmarked = chapter.bool("bookmarked"),
                        season = chapter.text("season").ifEmpty { null },
                        seasonName = chapter.text("seasonName").ifEmpty { null },
                        seasonCoverUrl = chapter.text("seasonCoverUrl").ifEmpty { null },
                    )
                },
                sourceId = if (ours) entry.text("sourceId").ifEmpty { null } else null,
                inLibrary = (entry["inLibrary"] as? JsonPrimitive)?.booleanOrNull ?: true,
                addedAt = (entry["addedAt"] as? JsonPrimitive)?.longOrNull,
                status = Status.entries.firstOrNull { it.name.equals(entry.text("status"), ignoreCase = true) },
                summary = entry.text("summary"),
                author = entry.text("author"),
                genres = entry.strings("genres"),
                rating = (entry["rating"] as? JsonPrimitive)?.doubleOrNull,
                webUrl = entry.text("webUrl").ifEmpty { null },
            )
        }
        return ImportedBackup(
            BackupApp.Sumizuri,
            titles,
            shelves.filter {
                it.name.isNotEmpty()
            },
            if (ours) extrasOf(root) else null,
        )
    } catch (error: Exception) {
        throw BackupUnreadable(BackupProblem.Damaged, error)
    }
}

private fun flutterShelf(shelf: JsonObject): ImportedShelf {
    val smart = shelf.bool("useSmartRule")
    return ImportedShelf(
        name = shelf.text("name").trim(),
        excludeFromUpdate = shelf.bool("excludeFromUpdate"),
        sort = if (smart) sortOf(shelf.text("sortField")) else null,
        ascending = shelf["sortAscending"].let { (it as? JsonPrimitive)?.booleanOrNull } ?: true,
        status = if (smart) statusOf(shelf.text("statusFilter")) else null,
    )
}

// A shelf of this app, kept whole with its rules, its kind and its conditions.
private fun ourShelf(shelf: JsonObject): ImportedShelf {
    val name = shelf.text("name").trim()
    val stored = CategoryEntity(
        name = name,
        sortOrder = shelf.int("sortOrder") ?: 0,
        excludeFromUpdate = shelf.bool("excludeFromUpdate"),
        sortField = shelf.int("sort"),
        sortAscending = (shelf["sortAscending"] as? JsonPrimitive)?.booleanOrNull ?: true,
        statusFilter = shelf.int("status") ?: 0,
        kind = kindOf(shelf.text("mediaType"))?.code ?: -1,
        thenField = shelf.int("then"),
        thenAscending = (shelf["thenAscending"] as? JsonPrimitive)?.booleanOrNull ?: true,
        conditions = shelf.text("conditions"),
        matchAll = (shelf["matchAll"] as? JsonPrimitive)?.booleanOrNull ?: true,
    )
    return ImportedShelf(name = name, excludeFromUpdate = stored.excludeFromUpdate, stored = stored)
}

private fun extrasOf(root: JsonObject) = BackupExtras(
    sources = root
        .list("sources")
        .map {
            SourceEntity(
                id = it.text(
                    "id",
                ),
                repoUrl = it.text("repoUrl").ifEmpty { null }, name = it.text("name"), lang = it.text("lang"),
                kind = (kindOf(it.text("mediaType")) ?: Kind.Manga).code, engineKind = it.text("engineKind"),
                version =
                it.int("version") ?: 0,
                iconUrl = it.text(
                    "iconUrl",
                ),
                baseUrl = it.text("baseUrl"), code = it.text("code"), extra = it.text("extra"),
                enabled = (it["enabled"] as? JsonPrimitive)?.booleanOrNull ?: true,
            )
        }.filter { it.id.isNotEmpty() && it.code.isNotEmpty() },
    repos = root
        .list("repos")
        .map {
            RepoEntity(
                it.text("url"),
                it.text("name"),
                (it["addedAt"] as? JsonPrimitive)?.longOrNull ?: 0L,
            )
        }.filter { it.url.isNotEmpty() },
    values = root.list("sourceValues").map {
        SourceValueEntity(it.text("scope"), it.int("area") ?: 0, it.text("key"), it.text("value"))
    },
    settings = (root["settings"] as? JsonObject)
        ?.mapNotNull { (key, value) ->
            (value as? JsonPrimitive)?.contentOrNull?.let {
                key to
                    it
            }
        }?.toMap()
        .orEmpty(),
    cookies = root.list("cookies").map {
        CookieEntity(
            it.text("scope"),
            it.text("domain"),
            it.text("path"),
            it.text("name"),
            it.text("value"),
            (it["expiresAt"] as? JsonPrimitive)?.longOrNull,
            it.bool("secure"),
            it.bool("httpOnly"),
        )
    },
)

private fun kindOf(name: String): Kind? = Kind.entries.firstOrNull { it.name.equals(name, ignoreCase = true) }

private fun sortOf(name: String): LibrarySortField = when (name) {
    "unreadCount" -> LibrarySortField.Unread
    "addedAt" -> LibrarySortField.Added
    "lastUpdatedAt" -> LibrarySortField.LatestChapter
    else -> LibrarySortField.Title
}

private fun statusOf(name: String): Status? = when (name) {
    "ongoing" -> Status.Ongoing
    "completed" -> Status.Completed
    "hiatus" -> Status.Hiatus
    else -> null
}

// A time the Flutter app wrote as text. It leaves the zone off, which means the clock of the device that made it, so the clock of this device is the best guess.
private fun timeOf(text: String): Long? {
    if (text.isEmpty()) return null
    val zoned = text.endsWith("Z") || text.lastIndexOf('+') > 10 || text.lastIndexOf('-') > 10
    return try {
        if (zoned) {
            Instant.parse(text).toEpochMilliseconds()
        } else {
            val guess = Instant.parse(text + "Z").toEpochMilliseconds()
            guess - localOffsetMillis(guess)
        }
    } catch (error: Exception) {
        null
    }
}

private fun JsonObject.strings(key: String): List<String> = (this[key] as? JsonArray).orEmpty().mapNotNull {
    (it as? JsonPrimitive)?.contentOrNull
}
