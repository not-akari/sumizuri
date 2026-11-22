package com.sumizuri.app.data.library

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.text.nowMillis
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.put

// What was found is kept this long, so going back to a title does not ask again.
private const val KeepMs = 30 * 60 * 1000L

// How alike a found title must be to the name it was asked by, as the share of words they have in common.
private const val Alike = 0.75

// The number of an episode in a name such as Episode 12 - The Storm.
private val EpisodeNumber = Regex("(?i)\\bep(?:isode)?\\.?\\s*(\\d+(?:\\.\\d+)?)")

// A picture of one episode, with its number and its name as the site gives them, so it can be matched to an episode by name where the numbers of the site run on across seasons. Own season is for a number counted inside its season, as TVmaze counts them.
class EpisodeStill(val number: Double?, val name: String?, val url: String, val ownSeason: Boolean = false)

// The pictures of the episodes of an anime or a show, for cards that look different from one another. AniList is asked by the name of each season, as it lists the thumbnail of every episode of many anime, and TVmaze by the number of each season still without them, as it has stills of shows of every kind. Nothing here comes from the sources.
class EpisodeStills {
    private val http = HttpClient { install(HttpTimeout) { requestTimeoutMillis = 10_000 } }
    private val lock = Mutex()
    private val recent = HashMap<String, Pair<Long, List<*>>>()

    // The picture of each episode by the key of its season, and in it by the number of the episode. A title with no seasons uses the empty key and its own name. Names are the names to look each season up by, and numbers the number of each season.
    suspend fun stills(
        show: String,
        names: Map<String, String>,
        numbers: Map<String, Int>,
    ): Map<String, List<EpisodeStill>> {
        val asked = names.ifEmpty { mapOf("" to show) }
        val found = HashMap<String, List<EpisodeStill>>()
        // TVmaze is asked too, since AniList may list only part of a show, or number it on across seasons.
        val tv = remembered("tvmaze:$show") { tvMaze(show) }
        for ((key, name) in asked) {
            val season = numbers[key] ?: if (key.isEmpty()) 1 else null
            val fromTv = season?.let { wanted -> tv.filter { it.first == wanted }.map { it.second } }.orEmpty()
            val all = remembered("anilist:$name") { aniList(name) } + fromTv
            if (all.isNotEmpty()) found[key] = all
        }
        return found
    }

    private suspend fun <T> remembered(name: String, ask: suspend () -> List<T>): List<T> {
        val now = nowMillis()
        lock.withLock {
            @Suppress("UNCHECKED_CAST")
            recent[name]?.takeIf { now - it.first < KeepMs }?.let { return it.second as List<T> }
        }
        val got = runCatching { ask() }.getOrElse {
            AppLog.info(Tag, "Episode pictures for $name could not be read: ${it.message}")
            emptyList()
        }
        lock.withLock { recent[name] = now to got }
        return got
    }

    // The thumbnails AniList lists for the episodes of the anime of this name, by the number in the name of each.
    private suspend fun aniList(name: String): List<EpisodeStill> {
        val body = buildJsonObject {
            put(
                "query",
                "query(\$s: String) { Media(search: \$s, type: ANIME) { title { romaji english native } synonyms streamingEpisodes { title thumbnail } } }",
            )
            put("variables", buildJsonObject { put("s", name) })
        }
        val answer = http.post("https://graphql.anilist.co") {
            contentType(ContentType.Application.Json)
            setBody(body.toString())
        }
        if (answer.status == HttpStatusCode.NotFound) return emptyList()
        if (!answer.status.isSuccess()) throw IllegalStateException("AniList answered ${answer.status.value}")
        val media =
            (
                (
                    Json.parseToJsonElement(
                        answer.bodyAsText(),
                    ) as? JsonObject
                    )?.get("data") as? JsonObject
                )?.get("Media") as? JsonObject
                ?: return emptyList()
        val titles = buildList {
            (media["title"] as? JsonObject)?.values?.forEach { (it as? JsonPrimitive)?.contentOrNull?.let(::add) }
            (media["synonyms"] as? JsonArray)?.forEach { (it as? JsonPrimitive)?.contentOrNull?.let(::add) }
        }
        if (likeness(name, titles) < Alike) return emptyList()
        return (media["streamingEpisodes"] as? JsonArray).orEmpty().mapNotNull { item ->
            val episode = item as? JsonObject ?: return@mapNotNull null
            val title = (episode["title"] as? JsonPrimitive)?.contentOrNull ?: return@mapNotNull null
            val thumbnail = (episode["thumbnail"] as? JsonPrimitive)?.contentOrNull ?: return@mapNotNull null
            val match = EpisodeNumber.find(title)
            // A title such as Episode 25 - The Busy Life gives its number and the name after it.
            val rest = match?.let { title.substring(it.range.last + 1).trimStart(' ', '-', ':', '–') } ?: title
            EpisodeStill(match?.groupValues?.get(1)?.toDoubleOrNull(), rest.ifBlank { null }, thumbnail)
        }
    }

    // The stills TVmaze has of the episodes of the show of this name, by season and number.
    private suspend fun tvMaze(show: String): List<Pair<Int, EpisodeStill>> {
        val answer = http.get("https://api.tvmaze.com/singlesearch/shows") {
            parameter("q", show)
            parameter("embed", "episodes")
        }
        if (answer.status == HttpStatusCode.NotFound) return emptyList()
        if (!answer.status.isSuccess()) throw IllegalStateException("TVmaze answered ${answer.status.value}")
        val found = Json.parseToJsonElement(answer.bodyAsText()) as? JsonObject ?: return emptyList()
        val name = (found["name"] as? JsonPrimitive)?.contentOrNull ?: return emptyList()
        if (likeness(show, listOf(name)) < Alike) return emptyList()
        return ((found["_embedded"] as? JsonObject)?.get("episodes") as? JsonArray).orEmpty().mapNotNull { item ->
            val episode = item as? JsonObject ?: return@mapNotNull null
            val season = (episode["season"] as? JsonPrimitive)?.intOrNull ?: return@mapNotNull null
            val number = (episode["number"] as? JsonPrimitive)?.doubleOrNull?.toInt() ?: return@mapNotNull null
            val image = episode["image"] as? JsonObject
            val url =
                (image?.get("original") as? JsonPrimitive)?.contentOrNull
                    ?: (image?.get("medium") as? JsonPrimitive)?.contentOrNull
                    ?: return@mapNotNull null
            season to
                EpisodeStill(
                    number.toDouble(),
                    (episode["name"] as? JsonPrimitive)?.contentOrNull,
                    url,
                    ownSeason = true,
                )
        }
    }

    private companion object {
        const val Tag = "covers"
    }
}
