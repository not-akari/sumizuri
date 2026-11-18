package com.sumizuri.app.data.tracker

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
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import kotlin.math.roundToInt

private const val Api = "https://kitsu.app/api/edge"
private const val Token = "https://kitsu.app/api/oauth/token"
private const val JsonApi = "application/vnd.api+json"
private const val Page = 50
private const val Most = 500
private const val IdsAtOnce = 40

private const val AnimeFields = "canonicalTitle,titles,abbreviatedTitles,episodeCount,subtype,startDate,posterImage,userCount,slug"
private const val MangaFields = "canonicalTitle,titles,abbreviatedTitles,chapterCount,subtype,startDate,posterImage,userCount,slug"
private const val EntryFields = "status,progress,ratingTwenty,reconsuming,updatedAt,anime,manga"

// Talks to Kitsu. Kitsu has no sign in on its site for apps, so the person gives their email and password here, which go once to Kitsu only and are traded for a token that renews itself. The password is never kept. Anime and manga are numbered apart there, so manga ids are kept below zero here.
class KitsuClient : TrackerApi {
    private val http = TrackerHttp("Kitsu", gapMs = 250)

    override val hasKey: Boolean get() = true

    override val signInWay = SignInWay.Password

    override suspend fun accountFromPassword(name: String, password: String): TrackerAccount = token(
        Parameters.build {
            append("grant_type", "password")
            append("username", name.trim())
            append("password", password)
        },
    )

    override suspend fun refresh(account: TrackerAccount): TrackerAccount? {
        val refresh = account.refreshToken ?: return null
        return token(
            Parameters.build {
                append("grant_type", "refresh_token")
                append("refresh_token", refresh)
            },
        )
    }

    // Trades the login or a refresh token for a token, and reads who it belongs to.
    private suspend fun token(form: Parameters): TrackerAccount {
        val granted = http.grant(Token, form, "Kitsu")
        val token = granted.token
        val me = get(token, "$Api/users?filter%5Bself%5D=true&fields%5Busers%5D=name,avatar").obj()?.get("data").list().firstOrNull().obj()
        return TrackerAccount(
            userId = me.text("id")?.toLongOrNull() ?: throw TrackerProblem.Refused,
            name = me?.get("attributes").obj().text("name").orEmpty(),
            avatar = me?.get("attributes").obj()?.get("avatar").obj().let { it.text("small") ?: it.text("medium") },
            // Kitsu scores in halves from 1 to 10, which is 20 steps of the score out of 100.
            scoreFormat = "POINT_10_DECIMAL",
            token = token,
            expiresAt = nowMillis() + (granted.expiresIn ?: 2_592_000L) * 1000,
            refreshToken = granted.refresh,
        )
    }

    override suspend fun search(account: TrackerAccount, name: String, kind: Kind): List<TrackerMedia> {
        val words = name.trim()
        if (words.isEmpty()) return emptyList()
        val anime = kind == Kind.Anime
        val type = typeOf(anime)
        val fields = if (anime) AnimeFields else MangaFields
        val body = get(account.token, "$Api/$type?filter%5Btext%5D=${words.encodeURLParameter()}&page%5Blimit%5D=10&fields%5B$type%5D=$fields")
        return body.obj()?.get("data").list().mapNotNull { media(it.obj(), anime) }
    }

    override suspend fun entries(account: TrackerAccount, mediaIds: List<Long>): Map<Long, RemoteEntry> = buildMap {
        for (anime in listOf(true, false)) {
            val type = typeOf(anime)
            for (chunk in mediaIds.filter { isAnimeKey(it) == anime }.map(::rawId).chunked(IdsAtOnce)) {
                val url = "$Api/library-entries?filter%5BuserId%5D=${account.userId}&filter%5B${type}Id%5D=${chunk.joinToString(",")}" +
                    "&page%5Blimit%5D=$Most&fields%5BlibraryEntries%5D=$EntryFields&include=$type&fields%5B$type%5D=slug"
                // Kitsu names the title of an entry only when it is included, so the smallest part of it is.
                for ((entry, _) in rows(get(account.token, url), withMedia = false)) put(entry.mediaId, entry)
            }
        }
    }

    // Kitsu keeps which of its titles each AniList title is, and gives twenty of them to a request.
    override suspend fun fromAniList(account: TrackerAccount, refs: List<AniListRef>): Map<Long, TrackerMedia> = buildMap {
        for (anime in listOf(true, false)) {
            val type = typeOf(anime)
            val fields = if (anime) AnimeFields else MangaFields
            for (part in refs.filter { it.anime == anime }.chunked(20)) {
                val ids = part.joinToString(",") { it.id.toString() }
                val url = "$Api/mappings?filter%5BexternalSite%5D=anilist/$type&filter%5BexternalId%5D=$ids" +
                    "&include=item&page%5Blimit%5D=20&fields%5Bmappings%5D=externalId,item&fields%5B$type%5D=$fields"
                val body = get(account.token, url)
                val items = body.obj()?.get("included").list().mapNotNull { it.obj() }.associateBy { it.text("id") }
                for (mapping in body.obj()?.get("data").list().mapNotNull { it.obj() }) {
                    val aniList = mapping["attributes"].obj().text("externalId")?.toLongOrNull() ?: continue
                    val itemId = mapping["relationships"].obj()?.get("item").obj()?.get("data").obj().text("id")
                    media(items[itemId], anime)?.let { put(aniList, it) }
                }
            }
        }
    }

    // A known entry is changed in place. A new one is made, and when Kitsu says the person already has one, that one is found and changed.
    override suspend fun saveMany(account: TrackerAccount, saves: List<EntrySave>): Map<Long, RemoteEntry> = buildMap {
        // Entries this device does not know yet are looked up together, not one request for each.
        val missing = saves.filter { it.entryId == null }.map { it.mediaId }
        val found = if (missing.isEmpty()) emptyMap() else entries(account, missing)
        for (save in saves) {
            val known = save.entryId ?: found[save.mediaId]?.entryId
            val answer = if (known != null) {
                write(account, HttpMethod.Patch, "$Api/library-entries/$known", body(save, account, known))
            } else {
                write(account, HttpMethod.Post, "$Api/library-entries", body(save, account, null))
            }
            if (answer.status == HttpStatusCode.Unauthorized) throw TrackerProblem.Refused
            if (!answer.ok) continue
            entry(answer.json().obj()?.get("data").obj(), save.mediaId)?.let { put(save.mediaId, it) }
        }
    }

    override suspend fun recent(account: TrackerAccount, page: Int): Pair<List<Pair<RemoteEntry, TrackerMedia>>, Boolean> {
        val url = "$Api/library-entries?filter%5BuserId%5D=${account.userId}&sort=-updatedAt&include=anime,manga" +
            "&page%5Blimit%5D=$Page&page%5Boffset%5D=${(page - 1) * Page}" +
            "&fields%5BlibraryEntries%5D=$EntryFields&fields%5Banime%5D=$AnimeFields&fields%5Bmanga%5D=$MangaFields"
        val body = get(account.token, url)
        return rows(body, withMedia = true) to (body.obj()?.get("links").obj().text("next") != null)
    }

    override suspend fun collection(account: TrackerAccount, anime: Boolean): List<Pair<RemoteEntry, TrackerMedia>> {
        val type = typeOf(anime)
        val fields = if (anime) AnimeFields else MangaFields
        val all = mutableListOf<Pair<RemoteEntry, TrackerMedia>>()
        var url: String? = "$Api/library-entries?filter%5BuserId%5D=${account.userId}&filter%5Bkind%5D=$type&include=$type" +
            "&page%5Blimit%5D=$Most&fields%5BlibraryEntries%5D=$EntryFields&fields%5B$type%5D=$fields"
        while (url != null) {
            val body = get(account.token, url)
            all += rows(body, withMedia = true)
            url = body.obj()?.get("links").obj().text("next")
        }
        return all
    }

    override suspend fun delete(account: TrackerAccount, entryId: Long, mediaId: Long) {
        val answer = http.send(HttpMethod.Delete, "$Api/library-entries/$entryId") {
            header("Authorization", "Bearer ${account.token}")
            header("Accept", JsonApi)
        }
        // An entry that is already gone is as good as removed.
        if (answer.status != HttpStatusCode.NotFound) answer.orThrow("Kitsu")
    }

    // The entries of an answer, each with its title from what the answer included.
    private fun rows(body: JsonElement, withMedia: Boolean): List<Pair<RemoteEntry, TrackerMedia>> {
        val included = body.obj()?.get("included").list().mapNotNull { it.obj() }.associateBy { it.text("type") + ":" + it.text("id") }
        return body.obj()?.get("data").list().mapNotNull { row ->
            val data = row.obj()
            val links = data?.get("relationships").obj()
            val anime = links?.get("anime").obj()?.get("data").obj()
            val manga = links?.get("manga").obj()?.get("data").obj()
            val isAnime = anime != null
            val id = (anime ?: manga).text("id")?.toLongOrNull() ?: return@mapNotNull null
            val key = mediaKey(id, isAnime)
            val entry = entry(data, key) ?: return@mapNotNull null
            val media = if (withMedia) {
                media(included[(if (isAnime) "anime" else "manga") + ":" + id], isAnime) ?: return@mapNotNull null
            } else {
                TrackerMedia(id = key, name = "")
            }
            entry to media
        }
    }

    private fun media(data: JsonObject?, anime: Boolean): TrackerMedia? {
        val id = data.text("id")?.toLongOrNull() ?: return null
        val about = data?.get("attributes").obj()
        val titles = about?.get("titles").obj()
        val type = typeOf(anime)
        return TrackerMedia(
            id = mediaKey(id, anime),
            name = about.text("canonicalTitle").orEmpty(),
            cover = about?.get("posterImage").obj().let { it.text("medium") ?: it.text("small") ?: it.text("original") },
            url = "https://kitsu.app/$type/${about.text("slug") ?: id}",
            format = about.text("subtype"),
            year = yearOf(about.text("startDate")),
            total = (if (anime) about.long("episodeCount") else about.long("chapterCount"))?.toInt()?.takeIf { it > 0 },
            names = listOfNotNull(about.text("canonicalTitle")) + titles?.values.orEmpty().mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p !is JsonNull }?.content },
            synonyms = about?.get("abbreviatedTitles").list().mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p !is JsonNull }?.content },
            popularity = about.long("userCount")?.toInt() ?: 0,
        )
    }

    private fun entry(data: JsonObject?, key: Long): RemoteEntry? {
        val about = data?.get("attributes").obj() ?: return null
        val status = about.text("status") ?: return null
        return RemoteEntry(
            entryId = data.text("id")?.toLongOrNull() ?: return null,
            mediaId = key,
            status = when (status) {
                "current" -> if (about.flag("reconsuming")) TrackStatus.Repeating else TrackStatus.Current
                "completed" -> if (about.flag("reconsuming")) TrackStatus.Repeating else TrackStatus.Completed
                "on_hold" -> TrackStatus.Paused
                "dropped" -> TrackStatus.Dropped
                else -> TrackStatus.Planning
            }.code,
            progress = about.long("progress")?.toInt() ?: 0,
            score = ((about.long("ratingTwenty") ?: 0) * 5).toInt(),
            updatedAt = timeOf(about.text("updatedAt")),
        )
    }

    // The entry as Kitsu takes it. A title read again is current with the again mark on.
    private fun body(save: EntrySave, account: TrackerAccount, entryId: Long?): String {
        val status = TrackStatus.of(save.status)
        val anime = isAnimeKey(save.mediaId)
        return buildJsonObject {
            putJsonObject("data") {
                entryId?.let { put("id", it.toString()) }
                put("type", "libraryEntries")
                putJsonObject("attributes") {
                    put(
                        "status",
                        when (status) {
                            TrackStatus.Current, TrackStatus.Repeating -> "current"
                            TrackStatus.Planning -> "planned"
                            TrackStatus.Completed -> "completed"
                            TrackStatus.Paused -> "on_hold"
                            TrackStatus.Dropped -> "dropped"
                        },
                    )
                    put("progress", save.progress)
                    put("reconsuming", status == TrackStatus.Repeating)
                    val rating = (save.score / 5.0).roundToInt()
                    if (rating >= 2) put("ratingTwenty", rating.coerceAtMost(20)) else put("ratingTwenty", JsonNull)
                }
                if (entryId == null) {
                    putJsonObject("relationships") {
                        putJsonObject("user") { putJsonObject("data") { put("type", "users"); put("id", account.userId.toString()) } }
                        putJsonObject(typeOf(anime)) {
                            putJsonObject("data") {
                                put("type", typeOf(anime))
                                put("id", rawId(save.mediaId).toString())
                            }
                        }
                    }
                }
            }
        }.toString()
    }

    private suspend fun write(account: TrackerAccount, method: HttpMethod, url: String, json: String) = http.send(method, url) {
        header("Authorization", "Bearer ${account.token}")
        header("Accept", JsonApi)
        contentType(ContentType.parse(JsonApi))
        setBody(json)
    }

    private suspend fun get(token: String, url: String) = http.send(HttpMethod.Get, url) {
        header("Authorization", "Bearer $token")
        header("Accept", JsonApi)
    }.orThrow("Kitsu").json()
}
