package com.sumizuri.app.data.account

import com.sumizuri.app.data.backup.ImportedBackup
import com.sumizuri.app.data.backup.SumizuriBackupVersion
import com.sumizuri.app.data.backup.readSumizuriBackup
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.time.Instant

// The kinds of row a library is split into.
internal object RowKind {
    const val Title = "t"
    const val Chapter = "c"
    const val Setting = "s"
    const val Source = "x"
    const val Extras = "e"
}

// What one row holds once unlocked. A title row has its flags and shelves, a chapter row its marks, a setting its value and a source its version, each null when it was removed. Titles, chapters and sources also carry the piece of a backup that lets a device that lacks them put them in. The names are kept to one letter, since a big library has a row for each read chapter.
@Serializable
internal data class RowBody(
    @SerialName("k") val kind: String,
    @SerialName("t") val titleKey: String? = null,
    @SerialName("u") val url: String? = null,
    @SerialName("n") val name: String? = null,
    @SerialName("f") val fields: TitleFields? = null,
    @SerialName("m") val mark: ChapterMark? = null,
    @SerialName("v") val value: String? = null,
    @SerialName("r") val version: Int? = null,
    @SerialName("e") val entry: JsonObject? = null,
    @SerialName("x") val extras: JsonObject? = null,
) {
    // The key of the row, the same on every device, which the id the server sees is made from.
    val key: String
        get() = when (kind) {
            RowKind.Title -> "t\n$titleKey"
            RowKind.Chapter -> "c\n$titleKey\n$url"
            RowKind.Setting -> "s\n$name"
            RowKind.Source -> "x\n$name"
            else -> "e"
        }
}

@Serializable
internal data class TitleFields(
    @SerialName("l") val inLibrary: Boolean = false,
    @SerialName("f") val favorite: Boolean = false,
    @SerialName("s") val shelves: Set<String> = emptySet(),
)

// The pieces of this device's own backup that rows carry: each title without its chapters and history, each chapter, each source, and the repos and source values together.
internal class LocalEntries(
    val titles: Map<String, JsonObject>,
    val chapters: Map<String, Map<String, JsonObject>>,
    val sources: Map<String, JsonObject>,
    val extras: JsonObject,
)

internal object SyncRowCodec {
    private val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
    }

    fun encode(body: RowBody): ByteArray = json.encodeToString(RowBody.serializer(), body).encodeToByteArray()

    fun decode(bytes: ByteArray): RowBody? = runCatching {
        json.decodeFromString(RowBody.serializer(), bytes.decodeToString())
    }.getOrNull()

    // Reads the pieces rows carry out of a backup of this app.
    fun entriesOf(backupText: String): LocalEntries {
        val root = json.parseToJsonElement(backupText).jsonObject
        val titles = HashMap<String, JsonObject>()
        val chapters = HashMap<String, Map<String, JsonObject>>()
        for (element in root["libraryEntries"] as? JsonArray ?: JsonArray(emptyList())) {
            val title = element as? JsonObject ?: continue
            val source = (title["sourceId"] as? JsonPrimitive)?.content ?: continue
            if (source == "null") continue
            val key = syncKey(source, title["externalId"]?.jsonPrimitive?.content.orEmpty())
            titles[key] = JsonObject(title - "chapters" - "sessions")
            chapters[key] =
                (title["chapters"] as? JsonArray).orEmpty().mapNotNull { it as? JsonObject }.associate { chapter ->
                    chapter["url"]?.jsonPrimitive?.content.orEmpty() to
                        lean(chapter)
                }
        }
        val sources = (root["sources"] as? JsonArray)
            .orEmpty()
            .mapNotNull {
                it as? JsonObject
            }.associateBy { it["id"]?.jsonPrimitive?.content.orEmpty() }
        val extras =
            JsonObject(
                listOfNotNull(
                    root["repos"]?.let { "repos" to it },
                    root["sourceValues"]?.let {
                        "sourceValues" to
                            it
                    },
                ).toMap(),
            )
        return LocalEntries(titles, chapters, sources, extras)
    }

    // The parts of a chapter a device needs to put it in: its name, number, date and season. Its address and marks are in the row already, and empty parts are left out.
    private fun lean(chapter: JsonObject): JsonObject = JsonObject(
        chapter.filterKeys { it in ChapterParts }.filterValues { value ->
            value !is JsonNull &&
                !(value is JsonPrimitive && value.isString && value.content.isEmpty())
        },
    )

    private val ChapterParts = setOf("title", "number", "dateUploaded", "season", "seasonName", "seasonCoverUrl")

    // The server's state: the state both sides last agreed on, with the rows that changed since laid over it.
    fun overlay(base: SyncState, rows: Collection<RowBody>): SyncState {
        val titles = base.titles.toMutableMap()
        val settings = base.settings.toMutableMap()
        val sources = base.sources.toMutableMap()
        for (row in rows) {
            when (row.kind) {
                RowKind.Title -> {
                    val key = row.titleKey ?: continue
                    val fields = row.fields ?: TitleFields()
                    titles[key] =
                        (titles[key] ?: TitleMark()).copy(
                            inLibrary = fields.inLibrary,
                            favorite = fields.favorite,
                            shelves = fields.shelves,
                        )
                }

                RowKind.Chapter -> {
                    val key = row.titleKey ?: continue
                    val url = row.url ?: continue
                    val title = titles[key] ?: TitleMark()
                    val mark = row.mark ?: ChapterMark()
                    titles[key] =
                        title.copy(chapters = if (mark.empty) title.chapters - url else title.chapters + (url to mark))
                }

                RowKind.Setting -> row.name?.let { name ->
                    row.value?.let { settings[name] = it }
                        ?: settings.remove(name)
                }

                RowKind.Source -> row.name?.let { id -> row.version?.let { sources[id] = it } ?: sources.remove(id) }
            }
        }
        // Settings of a device that an older version sent are left out, so they never reach this one.
        return SyncState(titles, settings.filterKeys(::syncsAcrossDevices), sources)
    }

    // The rows to send so the server holds what this device wants: the ones that differ, in the parts that sync. A part that does not sync is never sent, and a title row then keeps the shelves the server has.
    fun changed(
        want: SyncState,
        server: SyncState,
        parts: SyncParts,
        entries: LocalEntries,
        serverExtras: JsonObject?,
    ): List<RowBody> {
        val out = ArrayList<RowBody>()
        for (key in want.titles.keys + server.titles.keys) {
            val w = want.titles[key] ?: TitleMark()
            val s = server.titles[key] ?: TitleMark()
            val wanted = TitleFields(w.inLibrary, w.favorite, if (parts.shelves) w.shelves else s.shelves)
            if (wanted !=
                TitleFields(s.inLibrary, s.favorite, s.shelves)
            ) {
                out +=
                    RowBody(RowKind.Title, titleKey = key, fields = wanted, entry = entries.titles[key])
            }
            if (!parts.progress) continue
            val known = entries.chapters[key].orEmpty()
            for (url in w.chapters.keys + s.chapters.keys) {
                val mark = w.chapters[url] ?: ChapterMark()
                if (mark !=
                    (s.chapters[url] ?: ChapterMark())
                ) {
                    out +=
                        RowBody(RowKind.Chapter, titleKey = key, url = url, mark = mark, entry = known[url])
                }
            }
        }
        if (parts.settings) {
            for (name in want.settings.keys + server.settings.keys) {
                if (want.settings[name] !=
                    server.settings[name]
                ) {
                    out += RowBody(RowKind.Setting, name = name, value = want.settings[name])
                }
            }
        }
        if (parts.sources) {
            for (id in want.sources.keys + server.sources.keys) {
                if (want.sources[id] !=
                    server.sources[id]
                ) {
                    out +=
                        RowBody(RowKind.Source, name = id, version = want.sources[id], entry = entries.sources[id])
                }
            }
            // The repos and source values are sent only when this device has one the server lacks, and then with all the server has, in a set order. A value both have is left as each device has it, as a restore never changes one, so two devices never send the same row back and forth.
            val joined = joinExtras(serverExtras, entries.extras)
            if (joined.isNotEmpty() && joined != serverExtras?.let { joinExtras(it, JsonObject(emptyMap())) }) {
                out += RowBody(RowKind.Extras, extras = joined)
            }
        }
        return out
    }

    // The repos of the server with the ones only this device has, and the same for the source values, each sorted by what names them.
    private fun joinExtras(server: JsonObject?, local: JsonObject): JsonObject {
        fun join(part: String, key: (JsonObject) -> String): JsonArray? {
            val all = ((server?.get(part) as? JsonArray).orEmpty() + (local[part] as? JsonArray).orEmpty()).mapNotNull {
                it as? JsonObject
            }
            if (all.isEmpty()) return null
            return JsonArray(all.distinctBy(key).sortedBy(key))
        }
        val text = { item: JsonObject, name: String -> item[name]?.jsonPrimitive?.content.orEmpty() }
        return JsonObject(
            listOfNotNull(
                join("repos") { text(it, "url") }?.let { "repos" to it },
                join(
                    "sourceValues",
                ) { listOf("scope", "area", "key").joinToString("\u0000") { name -> text(it, name) } }?.let {
                    "sourceValues" to
                        it
                },
            ).toMap(),
        )
    }

    // The rows that came from the server as a backup, so the titles, chapters and sources this device lacks can be put in the way a restore does.
    fun backupOf(rows: Collection<RowBody>): ImportedBackup? {
        val chapters = rows.filter { it.kind == RowKind.Chapter && it.entry != null }.groupBy { it.titleKey }
        val titles = rows.filter { it.kind == RowKind.Title && it.entry != null }.map { row ->
            JsonObject(
                row.entry!! +
                    (
                        "chapters" to
                            JsonArray(
                                chapters[row.titleKey].orEmpty().map {
                                    JsonObject(it.entry!! + ("url" to JsonPrimitive(it.url)) + markFields(it.mark))
                                },
                            )
                        ),
            )
        }
        val sources = rows
            .filter {
                it.kind == RowKind.Source && it.entry != null && it.version != null
            }.map { it.entry!! }
        val extras = rows.lastOrNull { it.kind == RowKind.Extras }?.extras
        if (titles.isEmpty() && sources.isEmpty() && extras == null) return null
        val root = JsonObject(
            buildMap {
                put("backupVersion", JsonPrimitive(SumizuriBackupVersion))
                put("libraryEntries", JsonArray(titles))
                put("sources", JsonArray(sources))
                extras?.let { putAll(it) }
            },
        )
        return readSumizuriBackup(root.toString())
    }

    // The read state of a chapter, kept in its mark and not in its entry, in the words of a backup, so the copy shows what was read.
    private fun markFields(mark: ChapterMark?): Map<String, JsonElement> {
        if (mark == null) return emptyMap()
        return buildMap {
            put("consumed", JsonPrimitive(mark.read))
            mark.readAt?.let { put("consumedAt", JsonPrimitive(Instant.fromEpochMilliseconds(it).toString())) }
            mark.position?.takeIf { !mark.read }?.let { put("progressPosition", JsonPrimitive(it)) }
            put("bookmarked", JsonPrimitive(mark.bookmarked))
        }
    }
}
