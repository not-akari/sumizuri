package com.sumizuri.app.data.tracker

import com.sumizuri.app.BuildInfo
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.nowMillis
import io.ktor.client.request.header
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.Parameters
import io.ktor.http.contentType
import io.ktor.http.encodeURLParameter
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.math.roundToInt

private const val Api = "https://api.myanimelist.net/v2"
private const val Auth = "https://myanimelist.net/v1/oauth2"
private const val Back = "sumizuri://track/mal"
private const val Page = 100
private const val Few = 5

private const val AnimeFields =
    "id,title,main_picture,alternative_titles,media_type,start_season,num_episodes,num_list_users,my_list_status"
private const val MangaFields =
    "id,title,main_picture,alternative_titles,media_type,start_date,num_chapters,num_list_users,my_list_status"

// Talks to MyAnimeList. Signing in is the way MyAnimeList has for apps: the person allows the app on the site, which opens the app again with a code the app trades for a token. Only the id of the app is used, as an app cannot keep a secret. Anime and manga are numbered apart there, so manga ids are kept below zero here.
class MalClient : TrackerApi {
    private val http = TrackerHttp("MyAnimeList", gapMs = 400)

    override val hasKey: Boolean get() = BuildInfo.MalClientId.isNotEmpty()

    override val signInWay = SignInWay.Browser

    // The check is also the code verifier, sent plain as MyAnimeList takes it, and its start comes back as the state.
    override fun signInAddress(check: String): String = "$Auth/authorize?response_type=code" +
        "&client_id=${BuildInfo.MalClientId}&code_challenge=$check&code_challenge_method=plain" +
        "&state=${check.take(16)}&redirect_uri=${Back.encodeURLParameter()}"

    override suspend fun accountFromLink(answer: Map<String, String>, check: String): TrackerAccount {
        val code = codeFrom(answer, check, "MyAnimeList")
        return token(
            Parameters.build {
                append("client_id", BuildInfo.MalClientId)
                append("grant_type", "authorization_code")
                append("code", code)
                append("code_verifier", check)
                append("redirect_uri", Back)
            },
        )
    }

    override suspend fun refresh(account: TrackerAccount): TrackerAccount? {
        val refresh = account.refreshToken ?: return null
        return token(
            Parameters.build {
                append("client_id", BuildInfo.MalClientId)
                append("grant_type", "refresh_token")
                append("refresh_token", refresh)
            },
        )
    }

    // Trades a code or a refresh token for a token, and reads who it belongs to.
    private suspend fun token(form: Parameters): TrackerAccount {
        val granted = http.grant("$Auth/token", form, "MyAnimeList")
        val token = granted.token
        val me = try {
            get(token, "$Api/users/@me?fields=picture").obj()
        } catch (problem: TrackerProblem) {
            AppLog.warn("tracker", "MyAnimeList gave a token that its own api did not take, ${problem.message}")
            throw problem
        }
        return TrackerAccount(
            userId = me.long("id") ?: throw TrackerProblem.Refused,
            name = me.text("name").orEmpty(),
            avatar = me.text("picture"),
            scoreFormat = "POINT_10",
            token = token,
            expiresAt = nowMillis() + (granted.expiresIn ?: 2_592_000L) * 1000,
            refreshToken = granted.refresh,
        )
    }

    override suspend fun search(account: TrackerAccount, name: String, kind: Kind): List<TrackerMedia> {
        // MyAnimeList answers nothing for fewer than three letters, and at most 64.
        val words = name.trim().take(64)
        if (words.length < 3) return emptyList()
        val anime = kind == Kind.Anime
        val path = typeOf(anime)
        val fields = if (anime) AnimeFields else MangaFields
        val answer = get(account.token, "$Api/$path?q=${words.encodeURLParameter()}&limit=10&nsfw=true&fields=$fields")
        return answer
            .obj()
            ?.get(
                "data",
            ).list()
            .mapNotNull { media(it.obj()?.get("node").obj(), anime, listKnown = true) }
    }

    override suspend fun entries(account: TrackerAccount, mediaIds: List<Long>): Map<Long, RemoteEntry> = buildMap {
        for (anime in listOf(true, false)) {
            val wanted = mediaIds.filter { isAnimeKey(it) == anime }
            if (wanted.isEmpty()) continue
            // A few titles are asked one by one, and more are found in the whole list, which takes fewer requests.
            if (wanted.size <= Few) {
                for (key in wanted) {
                    val path = typeOf(anime)
                    val node = get(account.token, "$Api/$path/${rawId(key)}?fields=my_list_status").obj()
                    entry(node.obj()?.get("my_list_status").obj(), key, anime)?.let { put(key, it) }
                }
            } else {
                val keys = wanted.toSet()
                for ((entry, _) in collection(account, anime)) if (entry.mediaId in keys) put(entry.mediaId, entry)
            }
        }
    }

    // AniList keeps the MyAnimeList id of each of its titles, so up to fifty are turned into MyAnimeList ids with one question to AniList, which needs no sign in.
    override suspend fun fromAniList(account: TrackerAccount, refs: List<AniListRef>): Map<Long, TrackerMedia> =
        buildMap {
            for (part in refs.chunked(50)) {
                val ids = part.joinToString(",") { it.id.toString() }
                val query = "query { Page(perPage: 50) { media(id_in: [$ids]) { id idMal } } }"
                val answer = http
                    .send(HttpMethod.Post, "https://graphql.anilist.co") {
                        contentType(ContentType.Application.Json)
                        header("Accept", "application/json")
                        setBody(buildJsonObject { put("query", query) }.toString())
                    }.orThrow("AniList")
                val malOf = answer
                    .json()
                    .obj()
                    ?.get("data")
                    .obj()
                    ?.get("Page")
                    .obj()
                    ?.get("media")
                    .list()
                    .mapNotNull { it.obj() }
                    .mapNotNull { media -> media.long("idMal")?.let { mal -> media.long("id")?.let { it to mal } } }
                    .toMap()
                for (ref in part) {
                    val mal = malOf[ref.id] ?: continue
                    val type = if (ref.anime) "anime" else "manga"
                    put(
                        ref.id,
                        TrackerMedia(
                            mediaKey(mal, ref.anime),
                            ref.name,
                            ref.cover,
                            "https://myanimelist.net/$type/$mal",
                            kind = ref.kind,
                            total = ref.total,
                        ),
                    )
                }
            }
        }

    override suspend fun saveMany(account: TrackerAccount, saves: List<EntrySave>): Map<Long, RemoteEntry> = buildMap {
        for (save in saves) {
            val anime = isAnimeKey(save.mediaId)
            val status = TrackStatus.of(save.status)
            val form = Parameters.build {
                append("status", statusName(status, anime))
                append(if (anime) "num_watched_episodes" else "num_chapters_read", save.progress.toString())
                append("score", (save.score / 10.0).roundToInt().coerceIn(0, 10).toString())
                append(if (anime) "is_rewatching" else "is_rereading", (status == TrackStatus.Repeating).toString())
            }
            val path = typeOf(anime)
            val answer = http.send(HttpMethod.Patch, "$Api/$path/${rawId(save.mediaId)}/my_list_status") {
                header("Authorization", "Bearer ${account.token}")
                formBody(form)
            }
            if (answer.status == HttpStatusCode.Unauthorized) throw TrackerProblem.Refused
            if (!answer.ok) continue
            entry(answer.json().obj(), save.mediaId, anime)?.let { put(save.mediaId, it) }
        }
    }

    // The newest changes of the anime list and of the manga list together. The last row is the newer of the two oldest, so a sync only stops once both lists are read back to where it was.
    override suspend fun recent(
        account: TrackerAccount,
        page: Int,
    ): Pair<List<Pair<RemoteEntry, TrackerMedia>>, Boolean> {
        val parts = listOf(true, false).map { anime -> listPage(account, anime, (page - 1) * Page, "list_updated_at") }
        val rows = parts.flatMap { it.first }.sortedByDescending { it.first.updatedAt }.toMutableList()
        val last = parts
            .mapNotNull { part ->
                part.first.minByOrNull { it.first.updatedAt }
            }.maxByOrNull { it.first.updatedAt }
        if (last != null && rows.remove(last)) rows += last
        return rows to parts.any { it.second }
    }

    override suspend fun collection(account: TrackerAccount, anime: Boolean): List<Pair<RemoteEntry, TrackerMedia>> {
        val all = mutableListOf<Pair<RemoteEntry, TrackerMedia>>()
        var offset = 0
        while (true) {
            val (rows, more) = listPage(account, anime, offset, null, limit = 1000)
            all += rows
            if (!more || rows.isEmpty()) return all
            offset += rows.size
        }
    }

    override suspend fun delete(account: TrackerAccount, entryId: Long, mediaId: Long) {
        val path = if (isAnimeKey(mediaId)) "anime" else "manga"
        val answer = http.send(HttpMethod.Delete, "$Api/$path/${rawId(mediaId)}/my_list_status") {
            header("Authorization", "Bearer ${account.token}")
        }
        // An entry that is already gone is as good as removed.
        if (answer.status != HttpStatusCode.NotFound) answer.orThrow("MyAnimeList")
    }

    private suspend fun listPage(
        account: TrackerAccount,
        anime: Boolean,
        offset: Int,
        sort: String?,
        limit: Int = Page,
    ): Pair<List<Pair<RemoteEntry, TrackerMedia>>, Boolean> {
        val path = if (anime) "animelist" else "mangalist"
        val fields = (if (anime) AnimeFields else MangaFields).replace("my_list_status", "list_status")
        val url =
            "$Api/users/@me/$path?limit=$limit&offset=$offset&nsfw=true&fields=$fields" +
                (sort?.let { "&sort=$it" } ?: "")
        val body = get(account.token, url).obj()
        val rows = body?.get("data").list().mapNotNull { row ->
            val node = row.obj()?.get("node").obj()
            val media = media(node, anime, listKnown = false) ?: return@mapNotNull null
            val entry = entry(row.obj()?.get("list_status").obj(), media.id, anime) ?: return@mapNotNull null
            entry to media
        }
        return rows to (body?.get("paging").obj().text("next") != null)
    }

    // A search asks for the entry of the person with each title, so a title without one is known not to be on the list.
    private fun media(node: JsonObject?, anime: Boolean, listKnown: Boolean): TrackerMedia? {
        val id = node.long("id") ?: return null
        val other = node?.get("alternative_titles").obj()
        val listed = node?.get("my_list_status").obj()
        val key = mediaKey(id, anime)
        return TrackerMedia(
            id = key,
            name = node.text("title").orEmpty(),
            cover = node?.get("main_picture").obj().let { it.text("large") ?: it.text("medium") },
            url = "https://myanimelist.net/${typeOf(anime)}/$id",
            format = node.text("media_type"),
            year = node
                ?.get("start_season")
                .obj()
                .long("year")
                ?.toInt() ?: yearOf(node.text("start_date")),
            total = (if (anime) node.long("num_episodes") else node.long("num_chapters"))?.toInt()?.takeIf { it > 0 },
            names = listOfNotNull(node.text("title"), other.text("en"), other.text("ja")),
            synonyms = other?.get("synonyms").list().mapNotNull { (it as? JsonPrimitive)?.content },
            popularity = node.long("num_list_users")?.toInt() ?: 0,
            listKnown = listKnown,
            onList = entry(listed, key, anime),
        )
    }

    private fun entry(status: JsonObject?, key: Long, anime: Boolean): RemoteEntry? {
        val name = status.text("status") ?: return null
        val again = status.flag(if (anime) "is_rewatching" else "is_rereading")
        return RemoteEntry(
            entryId = key,
            mediaId = key,
            status = statusOf(name, again).code,
            progress =
            (if (anime) status.long("num_episodes_watched") else status.long("num_chapters_read"))?.toInt() ?: 0,
            score = ((status.long("score") ?: 0) * 10).toInt(),
            updatedAt = timeOf(status.text("updated_at")),
        )
    }

    private fun statusOf(name: String, again: Boolean): TrackStatus = when (name) {
        "watching", "reading" -> if (again) TrackStatus.Repeating else TrackStatus.Current
        "completed" -> if (again) TrackStatus.Repeating else TrackStatus.Completed
        "on_hold" -> TrackStatus.Paused
        "dropped" -> TrackStatus.Dropped
        else -> TrackStatus.Planning
    }

    // MyAnimeList keeps a title watched again as completed with the again mark on.
    private fun statusName(status: TrackStatus, anime: Boolean): String = when (status) {
        TrackStatus.Current -> if (anime) "watching" else "reading"
        TrackStatus.Completed, TrackStatus.Repeating -> "completed"
        TrackStatus.Paused -> "on_hold"
        TrackStatus.Dropped -> "dropped"
        TrackStatus.Planning -> if (anime) "plan_to_watch" else "plan_to_read"
    }

    private suspend fun get(token: String, url: String) = http
        .send(HttpMethod.Get, url) {
            header("Authorization", "Bearer $token")
        }.orThrow("MyAnimeList")
        .json()
}
