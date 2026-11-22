package com.sumizuri.app.data.backup

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.category.CategoryEntity
import com.sumizuri.app.data.db.chapter.ChapterEntity
import com.sumizuri.app.data.db.progress.ProgressEntity
import com.sumizuri.app.data.db.title.TitleEntity
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.data.tracker.ImportedTrack
import com.sumizuri.app.data.tracker.carried
import com.sumizuri.app.source.host.store.SealMark
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.first
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import okio.BufferedSink
import kotlin.time.Instant

// The version of the backups this app writes. Version 3 is version 2 of the Flutter app with the titles in full, seasons, shelves with their rules, and the sources, settings and sign ins of this app.
const val SumizuriBackupVersion = 3

// The parts a backup can hold besides the library, which is always in it.
enum class BackupPart { Sources, SourceSettings, Settings, Logins }

// How many of each thing a backup holds, to tell the person when it is made.
data class BackupSummary(val titles: Int, val chapters: Int, val shelves: Int, val sources: Int)

// Settings that only make sense on the device that has them: where the app was left and when it last checked for news. The sync settings of a device, under sync, stay on it too.
private val LocalSettings = setOf("session.place", "lastUpdateCheck", "lastSourceCheck", "backup.autoLast")

// Writes a Sumizuri backup of the open profile as JSON, title by title, so a big library is never held in memory whole.
class BackupWriter(private val db: AppDatabase) {
    suspend fun write(
        out: BufferedSink,
        parts: Set<BackupPart>,
        onProgress: (done: Int, total: Int) -> Unit,
        isCancelled: () -> Boolean,
    ): BackupSummary {
        val shelves = db.categories().all()
        val shelfNames = shelves.associate { it.id to it.name }
        val titles = db.titles().everything()
        val onShelves = db.categories().memberships().groupBy({ it.titleId }, { it.categoryId })
        val sources = db.sources().observeAll().first()
        val links = db.trackerLinks().everything().groupBy { it.titleId }
        val head = buildJsonObject {
            put("backupVersion", SumizuriBackupVersion)
            put("createdAt", Instant.fromEpochMilliseconds(nowMillis()).toString())
            put(
                "contents",
                buildJsonArray {
                    add(JsonPrimitive("library"))
                    parts.forEach { add(JsonPrimitive(it.name.replaceFirstChar(Char::lowercase))) }
                },
            )
            put("categories", JsonArray(shelves.map(::shelfJson)))
            if (BackupPart.Sources in parts) {
                put(
                    "sources",
                    JsonArray(
                        sources.map { source ->
                            buildJsonObject {
                                put("id", source.id)
                                put("repoUrl", source.repoUrl)
                                put("name", source.name)
                                put("lang", source.lang)
                                put("mediaType", Kind.fromCode(source.kind).name.lowercase())
                                put("engineKind", source.engineKind)
                                put("version", source.version)
                                put("iconUrl", source.iconUrl)
                                put("baseUrl", source.baseUrl)
                                put("code", source.code)
                                put("extra", source.extra)
                                put("enabled", source.enabled)
                            }
                        },
                    ),
                )
                put(
                    "repos",
                    JsonArray(
                        db.repos().observeAll().first().map {
                            buildJsonObject {
                                put("url", it.url)
                                put("name", it.name)
                                put("addedAt", it.addedAt)
                            }
                        },
                    ),
                )
            }
            if (BackupPart.SourceSettings in parts) {
                put(
                    "sourceValues",
                    JsonArray(
                        // A value locked with the key of this device opens nowhere else, so it stays here.
                        db.values().everything().filterNot { it.value.startsWith(SealMark) }.map {
                            buildJsonObject {
                                put("scope", it.scope)
                                put("area", it.area)
                                put("key", it.key)
                                put("value", it.value)
                            }
                        },
                    ),
                )
            }
            if (BackupPart.Settings in parts) {
                put(
                    "settings",
                    buildJsonObject {
                        db
                            .settings()
                            .everything()
                            .filter { it.name !in LocalSettings && !it.name.startsWith("sync.") }
                            .forEach { put(it.name, it.value) }
                    },
                )
            }
            if (BackupPart.Logins in parts) {
                put(
                    "cookies",
                    JsonArray(
                        db.cookies().everything().map {
                            buildJsonObject {
                                put("scope", it.scope)
                                put("domain", it.domain)
                                put("path", it.path)
                                put("name", it.name)
                                put("value", it.value)
                                put("expiresAt", it.expiresAt)
                                put("secure", it.secure)
                                put("httpOnly", it.httpOnly)
                            }
                        },
                    ),
                )
            }
        }.toString()
        // Everything but the closing brace, then the titles one by one, then the brace.
        out.writeUtf8(head.dropLast(1)).writeUtf8(",\"libraryEntries\":[")
        val sourceById = sources.associateBy { it.id }
        var chapters = 0
        onProgress(0, titles.size)
        for ((index, title) in titles.withIndex()) {
            if (isCancelled()) throw CancellationException("the backup was stopped")
            val rows = db.chapters().allOf(title.id)
            val marks = db.progress().allOf(title.id).associateBy { it.chapterId }
            chapters += rows.size
            val source = sourceById[title.sourceId]
            val entry = titleJson(
                title,
                rows,
                marks,
                onShelves[title.id].orEmpty().mapNotNull { shelfNames[it] },
                source?.name ?: ImportedSources.nameOf(title.sourceId),
                source?.baseUrl,
                links[title.id].orEmpty(),
            )
            if (index > 0) out.writeUtf8(",")
            out.writeUtf8(entry.toString())
            onProgress(index + 1, titles.size)
        }
        out.writeUtf8("]}")
        return BackupSummary(titles.size, chapters, shelves.size, if (BackupPart.Sources in parts) sources.size else 0)
    }

    private fun shelfJson(shelf: CategoryEntity) = buildJsonObject {
        put("name", shelf.name)
        put("sortOrder", shelf.sortOrder)
        put("excludeFromUpdate", shelf.excludeFromUpdate)
        put("mediaType", if (shelf.kind < 0) null else Kind.fromCode(shelf.kind).name.lowercase())
        put("sort", shelf.sortField)
        put("sortAscending", shelf.sortAscending)
        put("then", shelf.thenField)
        put("thenAscending", shelf.thenAscending)
        put("status", shelf.statusFilter)
        put("conditions", shelf.conditions)
        put("matchAll", shelf.matchAll)
    }

    // A title with its chapters, using the field names of the Flutter backups where they mean the same, so either app can read the common part.
    private fun titleJson(
        title: TitleEntity,
        chapters: List<ChapterEntity>,
        marks: Map<Long, ProgressEntity>,
        shelves: List<String>,
        sourceName: String?,
        sourceUrl: String?,
        links: List<TrackerLinkEntity>,
    ): JsonObject = buildJsonObject {
        put("title", title.name)
        put("externalId", title.externalId)
        put("coverUrl", title.coverUrl)
        put("mediaType", Kind.fromCode(title.kind).name.lowercase())
        put("favorite", title.favorite)
        put("sourceId", title.sourceId)
        put("sourceName", sourceName.orEmpty())
        put("sourceBaseUrl", sourceUrl.orEmpty())
        put("categoryNames", JsonArray(shelves.map(::JsonPrimitive)))
        put("inLibrary", title.inLibrary)
        put("addedAt", title.addedAt)
        put("status", Status.fromCode(title.status).name.lowercase())
        put("summary", title.summary)
        put("author", title.author)
        put(
            "genres",
            JsonArray(
                title.genres
                    .split("\n")
                    .filter { it.isNotBlank() }
                    .map(::JsonPrimitive),
            ),
        )
        put("rating", title.rating)
        put("webUrl", title.webUrl)
        if (links.isNotEmpty()) {
            put(
                "trackers",
                JsonArray(
                    links.map {
                        Json.encodeToJsonElement(ImportedTrack.serializer(), it.carried())
                    },
                ),
            )
        }
        put(
            "chapters",
            JsonArray(
                chapters.map { chapter ->
                    val mark = marks[chapter.id]
                    buildJsonObject {
                        put("url", chapter.url)
                        put("number", chapter.number)
                        put("title", chapter.name)
                        if (chapter.publishedAt >
                            0
                        ) {
                            put("dateUploaded", Instant.fromEpochMilliseconds(chapter.publishedAt).toString())
                        }
                        put("consumed", mark?.read == true)
                        mark?.readAt?.let { put("consumedAt", Instant.fromEpochMilliseconds(it).toString()) }
                        mark?.position?.takeIf { mark.read.not() }?.let { put("progressPosition", it) }
                        put("bookmarked", chapter.bookmarked)
                        chapter.season?.let { put("season", it) }
                        chapter.seasonName?.let { put("seasonName", it) }
                        chapter.seasonCoverUrl?.let { put("seasonCoverUrl", it) }
                    }
                },
            ),
        )
    }
}
