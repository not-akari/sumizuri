package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.model.Kind
import dev.whyoleg.cryptography.random.CryptographyRandom

// How a person signs in to a tracker: on its site in the browser, with their email and password in a form of the app for a tracker that has no other way, or with a token they make on the site of the tracker.
enum class SignInWay { Browser, Password, Token }

// What every tracker does for the sync, the linking and the pages. Ids of titles are the tracker's own. A tracker that numbers anime and manga apart gives the ids of manga below zero, so one number never stands for two titles.
interface TrackerApi {
    // Whether this build can sign in to the tracker at all.
    val hasKey: Boolean

    val signInWay: SignInWay

    // The page where the person allows the app, made with the check the site must send back.
    fun signInAddress(check: String): String = ""

    // The account from what the site of the tracker opened the app again with.
    suspend fun accountFromLink(answer: Map<String, String>, check: String): TrackerAccount =
        throw TrackerProblem.Refused

    // The page of the tracker where the person makes a token, for a tracker that signs in with one.
    val tokenPage: String? get() = null

    // The account from a token the person made on the site of the tracker.
    suspend fun accountFromToken(token: String): TrackerAccount = throw TrackerProblem.Refused

    // The account from an email and a password, which go only to the tracker and are not kept.
    suspend fun accountFromPassword(name: String, password: String): TrackerAccount = throw TrackerProblem.Refused

    // A new token for an account whose token ends soon, or null when the tracker gives none.
    suspend fun refresh(account: TrackerAccount): TrackerAccount? = null

    suspend fun search(account: TrackerAccount, name: String, kind: Kind): List<TrackerMedia>

    // Many searches, each giving what one search gives, in the same order.
    suspend fun searchMany(account: TrackerAccount, names: List<Pair<String, Kind>>): List<List<TrackerMedia>> =
        names.map { (name, kind) -> search(account, name, kind) }

    // The entries of the person for these titles, by the id of each title. A title with no entry is left out.
    suspend fun entries(account: TrackerAccount, mediaIds: List<Long>): Map<Long, RemoteEntry>

    // Writes the entries, and gives each as the tracker kept it, by the id of its title.
    suspend fun saveMany(account: TrackerAccount, saves: List<EntrySave>): Map<Long, RemoteEntry>

    // One page of the entries the person changed last, newest first, and whether there are more.
    suspend fun recent(account: TrackerAccount, page: Int): Pair<List<Pair<RemoteEntry, TrackerMedia>>, Boolean>

    // The titles of this tracker for titles of AniList, by AniList id, found in a few requests and without guessing by name. Null for a tracker that cannot.
    suspend fun fromAniList(account: TrackerAccount, refs: List<AniListRef>): Map<Long, TrackerMedia>? = null

    // Whether the tracker asks for its changes by their time instead of reading its newest changes page by page.
    val changesByTime: Boolean get() = false

    // The entries changed since a time, or null when they are so many that reading the whole list is faster.
    suspend fun changedSince(account: TrackerAccount, since: Long): List<Pair<RemoteEntry, TrackerMedia>>? = null

    // Every entry of the list of the person, of anime or of the rest.
    suspend fun collection(account: TrackerAccount, anime: Boolean): List<Pair<RemoteEntry, TrackerMedia>>

    suspend fun delete(account: TrackerAccount, entryId: Long, mediaId: Long)
}

// A title already linked to AniList, which other trackers can find by its AniList id, with what the link knows of it.
class AniListRef(val id: Long, val kind: Kind, val name: String, val cover: String?, val total: Int?) {
    val anime: Boolean get() = kind == Kind.Anime
}

// The formats of shows and of novels as AniList, MyAnimeList, Kitsu and MangaBaka name them, in small letters.
private val ShowFormats = setOf("tv", "tv_short", "tv_special", "movie", "special", "ova", "ona", "music", "cm", "pv")
private val NovelFormats = setOf("novel", "light_novel")

// A title of the tracker that is a novel, by how the tracker names its format.
internal val TrackerMedia.isNovel: Boolean
    get() = format?.lowercase()?.replace('-', '_') in NovelFormats

// The kind of a title of the tracker: what its client said, or else what its format says. A novel and a manga of the same name are never taken for each other.
internal val TrackerMedia.kindHere: Kind
    get() = kind ?: when (format?.lowercase()?.replace('-', '_')) {
        in ShowFormats -> Kind.Anime
        in NovelFormats -> Kind.Novel
        else -> Kind.Manga
    }

// Random text for the check a sign in brings back, made from the random source of the system.
internal fun randomCheck(): String {
    val letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    return CryptographyRandom
        .nextBytes(
            64,
        ).joinToString("") { letters[(it.toInt() and 0xFF) % letters.length].toString() }
}

// AniList through the same doors as every tracker.
class AniListApi(private val client: AniListClient) : TrackerApi {
    override val hasKey: Boolean get() = client.hasKey

    override val signInWay = SignInWay.Browser

    override fun signInAddress(check: String): String = client.signInAddress

    override suspend fun accountFromLink(answer: Map<String, String>, check: String): TrackerAccount {
        val token = answer["access_token"]?.takeIf { it.isNotBlank() } ?: throw TrackerProblem.Refused
        return client.account(token, answer["expires_in"]?.toLongOrNull())
    }

    override suspend fun search(account: TrackerAccount, name: String, kind: Kind) =
        client.search(account.token, name, kind)

    override suspend fun searchMany(account: TrackerAccount, names: List<Pair<String, Kind>>) =
        client.searchMany(account.token, names)

    override suspend fun entries(account: TrackerAccount, mediaIds: List<Long>) =
        client.entries(account.token, account.userId, mediaIds)

    override suspend fun saveMany(account: TrackerAccount, saves: List<EntrySave>) =
        client.saveMany(account.token, saves)

    override suspend fun recent(account: TrackerAccount, page: Int) = client.recent(account.token, account.userId, page)

    override suspend fun collection(account: TrackerAccount, anime: Boolean) =
        client.collection(account.token, account.userId, anime)

    override suspend fun delete(account: TrackerAccount, entryId: Long, mediaId: Long) =
        client.delete(account.token, entryId)
}

// The client of each tracker, made once for the profile.
class TrackerApis(aniList: AniListClient) {
    private val all: Map<TrackerId, TrackerApi> = mapOf(
        TrackerId.AniList to AniListApi(aniList),
        TrackerId.Mal to MalClient(),
        TrackerId.Kitsu to KitsuClient(),
        TrackerId.MangaBaka to MangaBakaClient(),
    )

    fun of(tracker: TrackerId): TrackerApi = all.getValue(tracker)
}
