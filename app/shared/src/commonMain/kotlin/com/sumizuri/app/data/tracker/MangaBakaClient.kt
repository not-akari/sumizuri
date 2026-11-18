package com.sumizuri.app.data.tracker

import com.sumizuri.app.BuildInfo
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.nowMillis
import io.ktor.client.request.HttpRequestBuilder
import io.ktor.client.request.header
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.Parameters
import io.ktor.http.contentType
import io.ktor.http.encodeURLParameter
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import okio.ByteString.Companion.encodeUtf8
import kotlin.math.roundToInt
import kotlin.time.Instant

private const val Api = "https://api.mangabaka.org"
private const val Auth = "https://mangabaka.org/auth/oauth2"
private const val Back = "sumizuri://track/mangabaka"

// What the app asks for: who the person is, a token that renews, and reading and writing the library.
private const val Scopes = "openid profile offline_access library.read library.write"
private const val Page = 100
private const val IdsAtOnce = 100

// Changes this many or more since the last sync are read with the whole list instead.
private const val Many = 400

// Talks to MangaBaka. A build with the id of the app signs in on the site, the way MangaBaka has for apps that cannot keep a secret: the person allows the app there, and the code it sends back is traded for a token with a check only this sign in knows. A build without the id signs in with a personal access token the person makes on the site. Either token is kept sealed on the device. MangaBaka has manga and novels only.
class MangaBakaClient : TrackerApi {
    private val http = TrackerHttp("MangaBaka", gapMs = 600)

    override val hasKey: Boolean get() = true

    private val withApp: Boolean get() = BuildInfo.MangaBakaClientId.isNotEmpty()

    override val signInWay get() = if (withApp) SignInWay.Browser else SignInWay.Token

    // The check is the code verifier, and MangaBaka takes only its SHA-256, in base64 for addresses. Its start comes back as the state.
    override fun signInAddress(check: String): String = "$Auth/authorize?response_type=code" +
        "&client_id=${BuildInfo.MangaBakaClientId.encodeURLParameter()}&redirect_uri=${Back.encodeURLParameter()}" +
        "&scope=${Scopes.encodeURLParameter()}&state=${check.take(16)}" +
        "&code_challenge=${check.encodeUtf8().sha256().base64Url().trimEnd('=')}&code_challenge_method=S256"

    override suspend fun accountFromLink(answer: Map<String, String>, check: String): TrackerAccount {
        val code = codeFrom(answer, check, "MangaBaka")
        return token(
            Parameters.build {
                append("grant_type", "authorization_code")
                append("code", code)
                append("redirect_uri", Back)
                append("client_id", BuildInfo.MangaBakaClientId)
                append("code_verifier", check)
            },
        )
    }

    // MangaBaka takes each refresh token once, which the accounts make sure of by renewing one at a time.
    override suspend fun refresh(account: TrackerAccount): TrackerAccount? {
        val refresh = account.refreshToken ?: return null
        return token(
            Parameters.build {
                append("grant_type", "refresh_token")
                append("refresh_token", refresh)
                append("client_id", BuildInfo.MangaBakaClientId)
            },
        )
    }

    private suspend fun token(form: Parameters): TrackerAccount {
        val granted = http.grant("$Auth/token", form, "MangaBaka")
        return accountFromToken(granted.token).copy(
            expiresAt = nowMillis() + (granted.expiresIn ?: 604_800L) * 1000,
            refreshToken = granted.refresh,
        )
    }

    override val tokenPage = "https://mangabaka.org/my/settings"

    override val changesByTime = true

    override suspend fun accountFromToken(token: String): TrackerAccount {
        val clean = token.trim()
        if (clean.isEmpty()) throw TrackerProblem.Refused
        val me = get(clean, "$Api/v1/my/profile").obj()?.get("data").obj() ?: throw TrackerProblem.Refused
        val id = me.text("id") ?: throw TrackerProblem.Refused
        return TrackerAccount(
            // The id there is text, so a number made from it stands for it here.
            userId = id.hashCode().toLong() and 0xFFFFFFFFL,
            name = me.text("preferred_username") ?: me.text("nickname").orEmpty(),
            avatar = me.text("picture"),
            scoreFormat = "POINT_100",
            token = clean,
        )
    }

    override suspend fun search(account: TrackerAccount, name: String, kind: Kind): List<TrackerMedia> {
        val words = name.trim()
        if (words.isEmpty() || kind == Kind.Anime) return emptyList()
        val type = if (kind == Kind.Novel) "&type=novel" else ""
        val body = get(account.token, "$Api/v2/series/search?q=${words.encodeURLParameter()}&limit=10$type")
        return body
            .obj()
            ?.get("data")
            .list()
            .mapNotNull { media(it.obj()) }
    }

    // MangaBaka finds its title for an AniList title by its id, one to a request but exact, with no guess by name. It has no anime.
    override suspend fun fromAniList(account: TrackerAccount, refs: List<AniListRef>): Map<Long, TrackerMedia> =
        buildMap {
            for (ref in refs.filter { !it.anime }) {
                val answer = http.send(
                    HttpMethod.Get,
                    "$Api/v1/source/anilist/${ref.id}",
                ) { header("Accept", "application/json") }
                if (!answer.ok) continue
                val series = answer
                    .json()
                    .obj()
                    ?.get("data")
                    .obj()
                    ?.get("series")
                    .list()
                    .firstOrNull()
                    .obj() ?: continue
                val id = series.long("id") ?: continue
                put(
                    ref.id,
                    TrackerMedia(
                        id,
                        ref.name,
                        ref.cover,
                        series.text("canonical_url"),
                        total = ref.total,
                        kind = ref.kind,
                    ),
                )
            }
        }

    override suspend fun entries(account: TrackerAccount, mediaIds: List<Long>): Map<Long, RemoteEntry> = buildMap {
        for (chunk in mediaIds.filter { it > 0 }.chunked(IdsAtOnce)) {
            val body = get(account.token, "$Api/v1/my/library/batch?" + chunk.joinToString("&") { "series_id=$it" })
            for (row in body.obj()?.get("data").list()) entry(row.obj())?.let { put(it.mediaId, it) }
        }
    }

    // A title not on the list yet is added, one that is is changed, as MangaBaka has a call for each.
    override suspend fun saveMany(account: TrackerAccount, saves: List<EntrySave>): Map<Long, RemoteEntry> {
        val known = entries(account, saves.filter { it.entryId == null }.map { it.mediaId }).keys
        val sent = mutableListOf<Long>()
        for (save in saves) {
            val method = if (save.entryId != null || save.mediaId in known) HttpMethod.Patch else HttpMethod.Post
            val answer = http.send(method, "$Api/v1/my/library/${save.mediaId}") {
                auth(account.token)
                header("Accept", "application/json")
                contentType(ContentType.Application.Json)
                setBody(body(save))
            }
            if (answer.status == HttpStatusCode.Unauthorized) throw TrackerProblem.Refused
            if (answer.ok) sent += save.mediaId
        }
        // The answer of a write says only that it worked, so the entries are read again as MangaBaka keeps them.
        return entries(account, sent)
    }

    // MangaBaka sorts the list by when entries changed only through a filter, so the changes are asked for by their time.
    override suspend fun changedSince(account: TrackerAccount, since: Long): List<Pair<RemoteEntry, TrackerMedia>>? {
        val after = Instant.fromEpochMilliseconds(since).toString().encodeURLParameter()
        val all = mutableListOf<Pair<RemoteEntry, TrackerMedia>>()
        var page = 1
        while (true) {
            val (rows, more) = libraryPage(account, page, "&updated_after=$after")
            all += rows
            // So many changes at once, such as an import on the site, are read faster whole.
            if (all.size >= Many) return null
            if (!more || rows.isEmpty()) return all
            page++
        }
    }

    override suspend fun recent(
        account: TrackerAccount,
        page: Int,
    ): Pair<List<Pair<RemoteEntry, TrackerMedia>>, Boolean> = emptyList<Pair<RemoteEntry, TrackerMedia>>() to false

    override suspend fun collection(account: TrackerAccount, anime: Boolean): List<Pair<RemoteEntry, TrackerMedia>> {
        if (anime) return emptyList()
        val all = mutableListOf<Pair<RemoteEntry, TrackerMedia>>()
        var page = 1
        while (true) {
            val (rows, more) = libraryPage(account, page, "")
            all += rows
            if (!more || rows.isEmpty()) return all
            page++
        }
    }

    override suspend fun delete(account: TrackerAccount, entryId: Long, mediaId: Long) {
        val answer = http.send(HttpMethod.Delete, "$Api/v1/my/library/$mediaId") {
            auth(account.token)
            header("Accept", "application/json")
        }
        // An entry that is already gone is as good as removed.
        if (answer.status != HttpStatusCode.NotFound) answer.orThrow("MangaBaka")
    }

    private suspend fun libraryPage(
        account: TrackerAccount,
        page: Int,
        filter: String,
    ): Pair<List<Pair<RemoteEntry, TrackerMedia>>, Boolean> {
        val body = get(account.token, "$Api/v2/my/library?page=$page&limit=$Page$filter").obj()
        val rows = body?.get("data").list().mapNotNull { row ->
            val entry = entry(row.obj()?.get("entry").obj()) ?: return@mapNotNull null
            val media = media(row.obj()?.get("series").obj()) ?: return@mapNotNull null
            entry to media
        }
        return rows to (body?.get("pagination").obj().text("next") != null)
    }

    private fun media(series: JsonObject?): TrackerMedia? {
        val id = series.long("id") ?: return null
        val titles = series?.get("titles").list().mapNotNull { it.obj() }
        val primary = titles.filter { it.flag("is_primary") }
        // The English name first, then the name in Latin letters, then any main name, as people know a title best by those.
        val name =
            (
                primary.firstOrNull { it.text("language") == "en" }
                    ?: primary.firstOrNull { it.text("language")?.endsWith("-Latn") == true }
                    ?: primary.firstOrNull() ?: titles.firstOrNull()
                ).text("title")
                ?: series.text("title").orEmpty()
        val rank = series
            ?.get("popularity")
            .obj()
            ?.get("global")
            .obj()
            .long("current") ?: 0
        return TrackerMedia(
            id = id,
            name = name,
            cover = series?.get("cover").obj().let { it.text("x350") ?: it.text("x250") ?: it.text("raw") },
            url = series.text("canonical_url") ?: "https://mangabaka.org/manga/$id",
            format = series.text("type"),
            year = yearOf(series?.get("published").obj().text("start_date")),
            total = series.long("total_chapters")?.toInt()?.takeIf { it > 0 },
            names = primary.mapNotNull { it.text("title") }.ifEmpty { listOf(name) },
            synonyms = titles.filter { !it.flag("is_primary") }.mapNotNull { it.text("title") },
            // MangaBaka gives a rank, where 1 is the most read, so a rank is turned into a number that grows with readers.
            popularity = if (rank > 0) (1_000_000 / rank).toInt() else 0,
        )
    }

    private fun entry(data: JsonObject?): RemoteEntry? {
        val series = data.long("series_id") ?: return null
        val state = data.text("state") ?: return null
        return RemoteEntry(
            entryId = data.long("id") ?: series,
            mediaId = series,
            status = when (state) {
                "reading" -> TrackStatus.Current
                "rereading" -> TrackStatus.Repeating
                "completed" -> TrackStatus.Completed
                "paused" -> TrackStatus.Paused
                "dropped" -> TrackStatus.Dropped
                else -> TrackStatus.Planning
            }.code,
            progress = data.number("progress_chapter")?.toInt() ?: 0,
            score = data.number("rating")?.roundToInt()?.coerceIn(0, 100) ?: 0,
            updatedAt = timeOf(data.text("updated_at")),
        )
    }

    private fun body(save: EntrySave): String = buildJsonObject {
        put(
            "state",
            when (TrackStatus.of(save.status)) {
                TrackStatus.Current -> "reading"
                TrackStatus.Repeating -> "rereading"
                TrackStatus.Completed -> "completed"
                TrackStatus.Paused -> "paused"
                TrackStatus.Dropped -> "dropped"
                TrackStatus.Planning -> "plan_to_read"
            },
        )
        put("progress_chapter", save.progress)
        if (save.score > 0) put("rating", save.score) else put("rating", JsonNull)
    }.toString()

    // A personal access token goes in its own header, and a token from signing in on the site goes as a bearer token.
    private fun HttpRequestBuilder.auth(token: String) {
        if (token.startsWith("mb-")) header("x-api-key", token) else header("Authorization", "Bearer $token")
    }

    private suspend fun get(token: String, url: String): JsonElement = http
        .send(HttpMethod.Get, url) {
            auth(token)
            header("Accept", "application/json")
        }.let { answer ->
            if (answer.status == HttpStatusCode.Forbidden) throw TrackerProblem.Refused
            answer.orThrow("MangaBaka").json()
        }
}
