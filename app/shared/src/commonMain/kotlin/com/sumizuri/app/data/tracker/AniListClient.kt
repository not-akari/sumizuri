package com.sumizuri.app.data.tracker

import com.sumizuri.app.BuildInfo
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.json.long
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.nowMillis
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put

private const val Api = "https://graphql.anilist.co"

// What a write to the list of the person changes for one title, with the score out of 100.
data class EntrySave(
    val mediaId: Long,
    val status: String,
    val progress: Int,
    val score: Int,
    // The entry when the tracker has one already, which a tracker that changes entries by their own id needs.
    val entryId: Long? = null,
)

// Talks to AniList. Signing in is the way AniList has for apps: the person allows the app on the site of AniList, which then opens the app again with a token. Only the id of the app is used for it, as an app cannot keep a secret. AniList takes only so many requests a minute, so searches and writes go many to a request, and the requests go one at a time at the pace AniList says.
class AniListClient {
    private val http = HttpClient { install(HttpTimeout) { requestTimeoutMillis = 30_000 } }
    private val gate = Mutex()

    // How many requests AniList said are left this minute.
    private var left = Int.MAX_VALUE

    // Whether this build has the id AniList gave the app, without which nobody can sign in.
    val hasKey: Boolean get() = BuildInfo.AniListClientId.isNotEmpty()

    // The page of AniList where the person allows the app.
    val signInAddress: String
        get() = "https://anilist.co/api/v2/oauth/authorize?client_id=${BuildInfo.AniListClientId}&response_type=token"

    // The account a token belongs to, which also proves the token works. The token lasts for the seconds AniList said, or a year when it said nothing.
    suspend fun account(token: String, lastsSeconds: Long?): TrackerAccount {
        val viewer =
            ask(
                token,
                "query { Viewer { id name avatar { medium } mediaListOptions { scoreFormat } } }",
            )["Viewer"] as? JsonObject
                ?: throw TrackerProblem.Refused
        val id = viewer.long("id") ?: throw TrackerProblem.Refused
        return TrackerAccount(
            userId = id,
            name = (viewer["name"] as? JsonPrimitive)?.content.orEmpty(),
            avatar = ((viewer["avatar"] as? JsonObject)?.get("medium") as? JsonPrimitive)?.content,
            scoreFormat = ((viewer["mediaListOptions"] as? JsonObject)?.get("scoreFormat") as? JsonPrimitive)?.content,
            token = token,
            expiresAt = nowMillis() + (lastsSeconds ?: YearSeconds) * 1000,
        )
    }

    // The titles of AniList that match a name, of the kind of the title, each with the entry of the person when there is one.
    suspend fun search(token: String, name: String, kind: Kind): List<TrackerMedia> =
        searchMany(token, listOf(name to kind)).first()

    // Many searches, up to twenty to a request, each giving what one search gives, in the same order.
    suspend fun searchMany(token: String, names: List<Pair<String, Kind>>): List<List<TrackerMedia>> =
        names.chunked(SearchBatch).flatMap { chunk ->
            val fields = chunk.indices.joinToString(", ") { "\$q$it: String, \$t$it: MediaType" }
            val body = chunk.indices.joinToString(" ") {
                "s$it: Page(perPage: 10) { media(search: \$q$it, type: \$t$it) { $SearchFields } }"
            }
            val data = ask(
                token,
                "query($fields) { $body }",
                buildJsonObject {
                    chunk.forEachIndexed { index, (name, kind) ->
                        put("q$index", name)
                        put("t$index", if (kind == Kind.Anime) "ANIME" else "MANGA")
                    }
                },
            )
            chunk.mapIndexed { index, (_, kind) ->
                val found = ((data["s$index"] as? JsonObject)?.get("media") as? JsonArray).orEmpty().mapNotNull {
                    (it as? JsonObject)?.let(::media)
                }
                // A novel is listed as a book on AniList, so books come first for one.
                if (kind == Kind.Novel) found.sortedByDescending { it.format == "NOVEL" } else found
            }
        }

    // The entries the person has on AniList for these titles, by the id of the title. A title missing from the answer has no entry.
    suspend fun entries(token: String, userId: Long, mediaIds: List<Long>): Map<Long, RemoteEntry> = buildMap {
        for (chunk in mediaIds.distinct().chunked(PageSize)) {
            val data = ask(
                token,
                EntriesQuery,
                buildJsonObject {
                    put("user", userId)
                    put("ids", JsonArray(chunk.map { JsonPrimitive(it) }))
                },
            )
            ((data["Page"] as? JsonObject)?.get("mediaList") as? JsonArray).orEmpty().forEach { item ->
                (item as? JsonObject)?.let(::entry)?.let { put(it.mediaId, it) }
            }
        }
    }

    // Writes entries, ten to a request, making each one when there is none yet, and gives them as AniList keeps them now by the id of the title. One AniList did not keep is missing from the answer, and is sent again at the next sync.
    suspend fun saveMany(token: String, saves: List<EntrySave>): Map<Long, RemoteEntry> = buildMap {
        for (chunk in saves.chunked(SaveBatch)) {
            val fields = chunk.indices.joinToString(
                ", ",
            ) { "\$m$it: Int, \$s$it: MediaListStatus, \$p$it: Int, \$r$it: Int" }
            val body = chunk.indices.joinToString(" ") {
                "e$it: SaveMediaListEntry(mediaId: \$m$it, status: \$s$it, progress: \$p$it, scoreRaw: \$r$it) { $EntryFields }"
            }
            val data = ask(
                token,
                "mutation($fields) { $body }",
                buildJsonObject {
                    chunk.forEachIndexed { index, save ->
                        put("m$index", save.mediaId)
                        put("s$index", save.status)
                        put("p$index", save.progress)
                        put("r$index", save.score)
                    }
                },
                partial = true,
            )
            chunk.indices.forEach { index ->
                (data["e$index"] as? JsonObject)
                    ?.let(
                        ::entry,
                    )?.let { put(it.mediaId, it) }
            }
        }
    }

    // One page of the entries of the person, the last changed first, each with its title, and whether more pages follow.
    suspend fun recent(token: String, userId: Long, page: Int): Pair<List<Pair<RemoteEntry, TrackerMedia>>, Boolean> {
        val data = ask(
            token,
            RecentQuery,
            buildJsonObject {
                put("user", userId)
                put("page", page)
            },
        )
        val found = data["Page"] as? JsonObject
        val rows = (found?.get("mediaList") as? JsonArray).orEmpty().mapNotNull { item ->
            val row = item as? JsonObject ?: return@mapNotNull null
            val media = (row["media"] as? JsonObject)?.let(::media) ?: return@mapNotNull null
            entry(row)?.let { it to media }
        }
        val more = ((found?.get("pageInfo") as? JsonObject)?.get("hasNextPage") as? JsonPrimitive)?.content == "true"
        return rows to more
    }

    // The whole list of the person of one kind, each entry with its title.
    suspend fun collection(token: String, userId: Long, anime: Boolean): List<Pair<RemoteEntry, TrackerMedia>> {
        val data = ask(
            token,
            CollectionQuery,
            buildJsonObject {
                put("user", userId)
                put("type", if (anime) "ANIME" else "MANGA")
            },
        )
        val lists = ((data["MediaListCollection"] as? JsonObject)?.get("lists") as? JsonArray).orEmpty()
        return lists
            .flatMap { list ->
                (
                    (list as? JsonObject)?.get(
                        "entries",
                    ) as? JsonArray
                    ).orEmpty()
            }.mapNotNull { item ->
                val row = item as? JsonObject ?: return@mapNotNull null
                val media = (row["media"] as? JsonObject)?.let(::media) ?: return@mapNotNull null
                entry(row)?.let { it to media }
            }.distinctBy { it.first.mediaId }
    }

    suspend fun delete(token: String, entryId: Long) {
        ask(token, DeleteQuery, buildJsonObject { put("id", entryId) })
    }

    private fun media(item: JsonObject): TrackerMedia? {
        val id = item.long("id") ?: return null
        return TrackerMedia(
            id = id,
            name = ((item["title"] as? JsonObject)?.get("userPreferred") as? JsonPrimitive)?.content.orEmpty(),
            names = (item["title"] as? JsonObject).orEmpty().values.mapNotNull {
                (it as? JsonPrimitive)?.contentOrNull
            },
            synonyms = (item["synonyms"] as? JsonArray).orEmpty().mapNotNull { (it as? JsonPrimitive)?.contentOrNull },
            popularity = item.long("popularity")?.toInt() ?: 0,
            cover = ((item["coverImage"] as? JsonObject)?.get("medium") as? JsonPrimitive)?.content,
            url = (item["siteUrl"] as? JsonPrimitive)?.content,
            format = (item["format"] as? JsonPrimitive)?.content,
            year = ((item["startDate"] as? JsonObject)?.long("year"))?.toInt(),
            total = (item.long("chapters") ?: item.long("episodes"))?.toInt(),
            // A search says whether the person has the title on their list, which saves asking for it again.
            listKnown = "mediaListEntry" in item,
            onList = (item["mediaListEntry"] as? JsonObject)?.let(::entry),
        )
    }

    private fun entry(item: JsonObject): RemoteEntry? = RemoteEntry(
        entryId = item.long("id") ?: return null,
        mediaId = item.long("mediaId") ?: return null,
        status = (item["status"] as? JsonPrimitive)?.content ?: TrackStatus.Planning.code,
        progress = item.long("progress")?.toInt() ?: 0,
        score = ((item["score"] as? JsonPrimitive)?.doubleOrNull ?: 0.0).toInt(),
        updatedAt = (item.long("updatedAt") ?: 0) * 1000,
    )

    // Asks AniList one question as the person the token belongs to, and gives the data of the answer. A request of many writes that came back with some of them refused still gives the ones that were kept, when partial.
    private suspend fun ask(
        token: String,
        query: String,
        variables: JsonObject = JsonObject(emptyMap()),
        partial: Boolean = false,
    ): JsonObject = withContext(Dispatchers.IO) {
        val answer = paced { send(token, query, variables) }
        val body = runCatching { Json.parseToJsonElement(answer.bodyAsText()).jsonObject }.getOrNull()
        // AniList says why in its own words, such as Invalid token for a token that ended.
        val said = ((body?.get("errors") as? JsonArray)?.firstOrNull() as? JsonObject)?.get("message")?.let {
            (it as? JsonPrimitive)?.content
        }
        val data = body?.get("data") as? JsonObject
        when {
            answer.status == HttpStatusCode.Unauthorized || said == "Invalid token" -> throw TrackerProblem.Refused

            answer.status == HttpStatusCode.TooManyRequests -> throw TrackerProblem.Limited

            !answer.status.isSuccess() && !(partial && data != null) ->
                throw TrackerProblem.Other(
                    "AniList answered ${answer.status.value}" + (said?.let { ", $it" } ?: ""),
                )
        }
        data ?: throw TrackerProblem.Other("AniList gave an answer that could not be read")
    }

    // Sends requests one at a time. When AniList says only a few are left this minute, the next one waits for the minute to pass. One AniList turns away waits as long as AniList asks, and is sent once more.
    private suspend fun paced(request: suspend () -> HttpResponse): HttpResponse = gate.withLock {
        if (left <= Spare) {
            AppLog.info("tracker", "AniList has few requests left this minute, waiting for the next one")
            delay(MinuteMs)
        }
        var answer = request()
        if (answer.status == HttpStatusCode.TooManyRequests) {
            val wait = answer.headers["Retry-After"]?.toLongOrNull()?.times(1000) ?: MinuteMs
            AppLog.info("tracker", "AniList asked to wait ${wait / 1000} seconds")
            delay(wait.coerceIn(1_000, 2 * MinuteMs))
            answer = request()
        }
        left = answer.headers["X-RateLimit-Remaining"]?.toIntOrNull() ?: Int.MAX_VALUE
        answer
    }

    private suspend fun send(token: String, query: String, variables: JsonObject): HttpResponse = try {
        http.post(Api) {
            contentType(ContentType.Application.Json)
            header("Accept", "application/json")
            header("Authorization", "Bearer $token")
            setBody(
                buildJsonObject {
                    put("query", query)
                    put("variables", variables)
                }.toString(),
            )
        }
    } catch (error: CancellationException) {
        throw error
    } catch (error: Exception) {
        throw TrackerProblem.Offline
    }

    private companion object {
        const val YearSeconds = 365L * 24 * 60 * 60
        const val MinuteMs = 60_000L

        // Requests kept back each minute, for what the person does by hand.
        const val Spare = 2

        // How many go to one request. AniList takes a request up to a size, and twenty searches stay well under it.
        const val SearchBatch = 20
        const val SaveBatch = 10
        const val PageSize = 50
        const val EntryFields = "id mediaId status progress score(format: POINT_100) updatedAt"
        const val MediaFields = "id format siteUrl chapters episodes popularity startDate { year } synonyms " +
            "title { userPreferred romaji english native } coverImage { medium }"
        const val SearchFields = "$MediaFields mediaListEntry { $EntryFields }"
        const val EntriesQuery = "query(\$user: Int, \$ids: [Int]) { Page(perPage: 50) { " +
            "mediaList(userId: \$user, mediaId_in: \$ids) { $EntryFields } } }"
        const val CollectionQuery =
            "query(\$user: Int, \$type: MediaType) { MediaListCollection(userId: \$user, type: \$type) { " +
                "lists { entries { $EntryFields media { $MediaFields } } } } }"
        const val RecentQuery =
            "query(\$user: Int, \$page: Int) { Page(page: \$page, perPage: 50) { pageInfo { hasNextPage } " +
                "mediaList(userId: \$user, sort: UPDATED_TIME_DESC) { $EntryFields media { $MediaFields } } } }"
        const val DeleteQuery = "mutation(\$id: Int) { DeleteMediaListEntry(id: \$id) { deleted } }"
    }
}
