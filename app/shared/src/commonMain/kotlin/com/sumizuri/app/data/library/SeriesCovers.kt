package com.sumizuri.app.data.library

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.text.nowMillis
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.http.isSuccess
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import okio.FileSystem
import okio.Path

// What was found for a show out of the library is kept this long.
private const val RecentMs = 5 * 60 * 1000L

// How alike the name of a found show must be to the name asked for, as the share of words they have in common.
private const val Alike = 0.75

// A show found on TVmaze: its season posters by season number, its IMDb id when TVmaze knows it, and its big pictures, a background the size of a screen and its poster at full size.
class SeriesFound(
    val posters: Map<Int, String>,
    val imdb: String?,
    val background: String? = null,
    val poster: String? = null,
)

// The posters of the seasons of a show, found on TVmaze by the name of the show, which needs no key. TVmaze has movies and series of every kind, so it fills in what AniList does not have, such as live action shows. What is found for a show out of the library is kept five minutes, and for one in the library on disk until the cache is cleared.
class SeriesCovers(private val folder: Path) {
    private val http = HttpClient { install(HttpTimeout) { requestTimeoutMillis = 10_000 } }
    private val lock = Mutex()
    private val recent = HashMap<String, Pair<Long, SeriesFound?>>()
    private var kept: MutableMap<String, SeriesFound>? = null
    private val file: Path get() = folder / "tvmaze-season-covers.json"

    // The show found by that name, or null when nothing alike was found. Keep is for a show in the library.
    suspend fun find(show: String, keep: Boolean): SeriesFound? {
        val id = show.trim().lowercase()
        if (id.isEmpty()) return null
        lock.withLock {
            // One kept before the big pictures were asked for is asked again once.
            keptShows()[id]?.takeIf { it.poster != null || it.background != null }?.let { return it }
            recent[id]?.let { (at, found) -> if (nowMillis() - at < RecentMs) return found }
        }
        val found = runCatching { ask(show.trim()) }
            .onFailure { AppLog.warn(Tag, "season posters could not be looked up on TVmaze: ${it.message}") }
            .getOrElse { return null }
        lock.withLock {
            recent[id] = nowMillis() to found
            if (keep && found != null &&
                (found.posters.isNotEmpty() || found.background != null || found.poster != null)
            ) {
                val saved = keptShows()
                saved[id] = found
                save(saved)
            }
        }
        return found
    }

    // Forgets every show found, for when the person clears the cache of pictures.
    suspend fun clear() = lock.withLock {
        recent.clear()
        kept = HashMap()
        withContext(Dispatchers.IO) { runCatching { FileSystem.SYSTEM.delete(file) } }
    }

    private suspend fun ask(show: String): SeriesFound? {
        val answer = http.get("https://api.tvmaze.com/singlesearch/shows") {
            parameter("q", show)
            parameter("embed[]", "seasons")
            parameter("embed[]", "images")
        }
        // TVmaze answers that it found nothing as a missing page.
        if (answer.status == HttpStatusCode.NotFound) return null
        if (!answer.status.isSuccess()) throw IllegalStateException("TVmaze answered ${answer.status.value}")
        val found = Json.parseToJsonElement(answer.bodyAsText()) as? JsonObject ?: return null
        val name = (found["name"] as? JsonPrimitive)?.contentOrNull ?: return null
        if (likeness(show, listOf(name)) < Alike) {
            AppLog.info(Tag, "TVmaze gave $name for $show, which is not alike enough")
            return null
        }
        val seasons = ((found["_embedded"] as? JsonObject)?.get("seasons") as? JsonArray).orEmpty()
        val posters = seasons
            .mapNotNull { it as? JsonObject }
            .mapNotNull { season ->
                val number = (season["number"] as? JsonPrimitive)?.intOrNull ?: return@mapNotNull null
                val image = season["image"] as? JsonObject
                val url = (image?.get("original") as? JsonPrimitive)?.contentOrNull
                    ?: (image?.get("medium") as? JsonPrimitive)?.contentOrNull
                    ?: return@mapNotNull null
                number to url
            }.toMap()
        val imdb = ((found["externals"] as? JsonObject)?.get("imdb") as? JsonPrimitive)?.contentOrNull
        // The background marked main wins over the others, and the poster of the show comes at full size.
        val images = ((found["_embedded"] as? JsonObject)?.get("images") as? JsonArray).orEmpty().mapNotNull {
            it as? JsonObject
        }
        val backgrounds = images.filter { (it["type"] as? JsonPrimitive)?.contentOrNull == "background" }
        val background = (
            backgrounds.firstOrNull { (it["main"] as? JsonPrimitive)?.booleanOrNull == true }
                ?: backgrounds.firstOrNull()
            )?.let {
            (
                (
                    (it["resolutions"] as? JsonObject)?.get(
                        "original",
                    ) as? JsonObject
                    )?.get("url") as? JsonPrimitive
                )?.contentOrNull
        }
        val poster = ((found["image"] as? JsonObject)?.get("original") as? JsonPrimitive)?.contentOrNull
        return SeriesFound(posters, imdb, background, poster)
    }

    private suspend fun keptShows(): MutableMap<String, SeriesFound> {
        kept?.let { return it }
        val loaded = withContext(Dispatchers.IO) {
            runCatching {
                if (!FileSystem.SYSTEM.exists(file)) return@runCatching HashMap<String, SeriesFound>()
                val json = Json.parseToJsonElement(FileSystem.SYSTEM.read(file) { readUtf8() }).jsonObject
                json
                    .mapValues { (_, value) ->
                        val show = value.jsonObject
                        val posters = (show["posters"] as? JsonObject)
                            .orEmpty()
                            .mapNotNull { (number, url) ->
                                val at = number.toIntOrNull() ?: return@mapNotNull null
                                val link = (url as? JsonPrimitive)?.contentOrNull ?: return@mapNotNull null
                                at to link
                            }.toMap()
                        SeriesFound(
                            posters,
                            (show["imdb"] as? JsonPrimitive)?.contentOrNull,
                            (show["background"] as? JsonPrimitive)?.contentOrNull,
                            (show["poster"] as? JsonPrimitive)?.contentOrNull,
                        )
                    }.toMutableMap()
            }.getOrDefault(HashMap())
        }
        kept = loaded
        return loaded
    }

    private suspend fun save(shows: Map<String, SeriesFound>) = withContext(Dispatchers.IO) {
        runCatching {
            FileSystem.SYSTEM.createDirectories(folder)
            val json = JsonObject(
                shows.mapValues { (_, found) ->
                    JsonObject(
                        mapOf(
                            "posters" to
                                JsonObject(
                                    found.posters.entries.associate {
                                        it.key.toString() to
                                            JsonPrimitive(it.value)
                                    },
                                ),
                            "imdb" to JsonPrimitive(found.imdb),
                            "background" to JsonPrimitive(found.background),
                            "poster" to JsonPrimitive(found.poster),
                        ),
                    )
                },
            )
            FileSystem.SYSTEM.write(file) { writeUtf8(json.toString()) }
        }
    }

    private companion object {
        const val Tag = "covers"
    }
}
