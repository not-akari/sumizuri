package com.sumizuri.app.data.library

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.text.nowMillis
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put
import okio.FileSystem
import okio.Path

// Names asked of AniList in one request. Each is asked by up to five names it may be found by.
private const val PerRequest = 5

// What was found for a title out of the library is kept this long.
private const val RecentMs = 5 * 60 * 1000L

// How alike a found title must be to the name of the season, as the share of words they have in common.
private const val Alike = 0.75

// The covers of the seasons of an anime, found on AniList by the names of the seasons. What is found for a title out of the library is kept five minutes, and for a title in the library on disk until the cache is cleared.
class SeasonCovers(private val folder: Path) {
    private val http = HttpClient { install(HttpTimeout) { requestTimeoutMillis = 10_000 } }
    private val lock = Mutex()
    private val recent = HashMap<String, Pair<Long, String?>>()
    private var kept: MutableMap<String, String>? = null
    private val file: Path get() = folder / "anilist-season-covers.json"
    private val series = SeriesCovers(folder)

    // The posters of the seasons by their keys. AniList is asked by the names of the seasons first, as it has the best posters of anime, and TVmaze by the number of each season still without one, as it has shows of every kind, live action too.
    suspend fun posters(
        show: String,
        names: Map<String, String>,
        numbers: Map<String, Int>,
        keep: Boolean,
    ): Map<String, String> {
        val found = covers(names.values, keep)
        val posters = HashMap<String, String>()
        names.forEach { (key, name) -> found[name]?.let { posters[key] = it } }
        val missing = numbers.filterKeys { it !in posters }
        if (missing.isEmpty()) return posters
        val tv = series.find(show, keep) ?: return posters
        missing.forEach { (key, number) -> tv.posters[number]?.let { posters[key] = it } }
        return posters
    }

    // The cover found for each name, leaving out the names nothing alike was found for. Keep is for a title in the library.
    suspend fun covers(names: Collection<String>, keep: Boolean): Map<String, String> {
        val wanted = names.map { it.trim() }.filter { it.isNotEmpty() }.distinct()
        if (wanted.isEmpty()) return emptyMap()
        val found = HashMap<String, String>()
        val missing = ArrayList<String>()
        lock.withLock {
            val saved = keptCovers()
            val now = nowMillis()
            for (name in wanted) {
                val id = name.lowercase()
                saved[id]?.let {
                    found[name] = it
                    continue
                }
                val hit = recent[id]
                if (hit != null && now - hit.first < RecentMs) hit.second?.let { found[name] = it } else missing += name
            }
        }
        for (batch in missing.chunked(PerRequest)) {
            val answers =
                runCatching {
                    ask(batch)
                }.onFailure {
                    // A screen that closed stops the lookup, which is not a problem to report.
                    if (it is CancellationException) throw it
                    AppLog.warn(Tag, "season covers could not be looked up: ${it.message}")
                }.getOrNull()
                    ?: break
            lock.withLock {
                val now = nowMillis()
                for (name in batch) {
                    val url = answers[name]
                    recent[name.lowercase()] = now to url
                    if (url != null) found[name] = url
                }
            }
        }
        // A title in the library keeps what was found for it on disk, also what was found while it was still out of the library.
        if (keep) {
            lock.withLock {
                val saved = keptCovers()
                val fresh = found.filterKeys { saved[it.lowercase()] == null }
                if (fresh.isNotEmpty()) {
                    fresh.forEach { (name, url) -> saved[name.lowercase()] = url }
                    save(saved)
                }
            }
        }
        return found
    }

    // Forgets every cover found, kept or recent, for when the person clears the cache of pictures.
    suspend fun clear() {
        series.clear()
        clearOwn()
    }

    private suspend fun clearOwn() = lock.withLock {
        recent.clear()
        kept = HashMap()
        withContext(Dispatchers.IO) { runCatching { FileSystem.SYSTEM.delete(file) } }
    }

    // Each name is asked by all the names it may be found by, in one request, and the surest of them that finds something alike wins.
    private suspend fun ask(names: List<String>): Map<String, String> {
        val queries = names.associateWith(::seasonQueries)
        val asked = queries.values.flatten().distinct()
        val fields = asked.indices.joinToString(" ") {
            "a$it: Page(perPage: 3) { media(search: \$s$it, type: ANIME) { title { romaji english native } synonyms coverImage { extraLarge large } } }"
        }
        val params = asked.indices.joinToString(", ") { "\$s$it: String" }
        val body = buildJsonObject {
            put("query", "query($params) { $fields }")
            put("variables", buildJsonObject { asked.forEachIndexed { index, query -> put("s$index", query) } })
        }
        val answer = http.post("https://graphql.anilist.co") {
            contentType(ContentType.Application.Json)
            setBody(body.toString())
        }
        if (!answer.status.isSuccess()) throw IllegalStateException("AniList answered ${answer.status.value}")
        val data = Json.parseToJsonElement(answer.bodyAsText()).jsonObject["data"] as? JsonObject ?: return emptyMap()
        val out = HashMap<String, String>()
        for ((name, tries) in queries) {
            val hit = tries.firstNotNullOfOrNull { query ->
                coverFor(query, data["a${asked.indexOf(query)}"])?.let { query to it }
            } ?: continue
            if (hit.first != tries.first()) AppLog.info(Tag, "the season $name was found as ${hit.first}")
            out[name] = hit.second
        }
        return out
    }

    // The cover of the found title most alike to what was asked, when one is alike enough.
    private fun coverFor(query: String, answer: Any?): String? {
        val media = ((answer as? JsonObject)?.get("media") as? JsonArray).orEmpty().mapNotNull { it as? JsonObject }
        val best = media
            .map { it to likeness(query, titlesOf(it)) }
            .filter { it.second >= Alike }
            .maxByOrNull { it.second }
            ?.first ?: return null
        val cover = best["coverImage"] as? JsonObject
        return (cover?.get("extraLarge") as? JsonPrimitive)?.contentOrNull
            ?: (cover?.get("large") as? JsonPrimitive)?.contentOrNull
    }

    private fun titlesOf(media: JsonObject): List<String> {
        val title = media["title"] as? JsonObject
        val names = listOf(
            "romaji",
            "english",
            "native",
        ).mapNotNull { (title?.get(it) as? JsonPrimitive)?.contentOrNull }
        val synonyms = (media["synonyms"] as? JsonArray).orEmpty().mapNotNull { (it as? JsonPrimitive)?.contentOrNull }
        return names + synonyms
    }

    private suspend fun keptCovers(): MutableMap<String, String> {
        kept?.let { return it }
        val loaded = withContext(Dispatchers.IO) {
            runCatching {
                if (!FileSystem.SYSTEM.exists(file)) return@runCatching HashMap<String, String>()
                val json = Json.parseToJsonElement(FileSystem.SYSTEM.read(file) { readUtf8() }).jsonObject
                json
                    .mapValues { (it.value as? JsonPrimitive)?.contentOrNull.orEmpty() }
                    .filterValues { it.isNotEmpty() }
                    .toMutableMap()
            }.getOrDefault(HashMap())
        }
        kept = loaded
        return loaded
    }

    private suspend fun save(covers: Map<String, String>) = withContext(Dispatchers.IO) {
        runCatching {
            FileSystem.SYSTEM.createDirectories(folder)
            FileSystem.SYSTEM.write(
                file,
            ) { writeUtf8(JsonObject(covers.mapValues { JsonPrimitive(it.value) }).toString()) }
        }
    }

    private companion object {
        const val Tag = "covers"
    }
}
