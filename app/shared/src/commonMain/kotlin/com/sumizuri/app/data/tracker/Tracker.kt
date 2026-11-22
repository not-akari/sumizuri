package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.account.DeviceSecret
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.shareIn
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

// A site that keeps a list of what a person reads and watches. The id is what links and saved accounts say, so it never changes.
// The kinds of titles each tracker keeps. Some keep only manga and novels, which video titles are never offered to.
enum class TrackerId(
    val id: String,
    val label: String,
    val kinds: Set<Kind> = setOf(Kind.Anime, Kind.Manga, Kind.Novel),
) {
    AniList("anilist", "AniList"),
    Mal("mal", "MyAnimeList"),
    Kitsu("kitsu", "Kitsu"),
    MangaBaka("mangabaka", "MangaBaka", setOf(Kind.Manga, Kind.Novel)),
    ;

    companion object {
        fun of(id: String?): TrackerId? = entries.firstOrNull { it.id.equals(id, ignoreCase = true) }
    }
}

// The account a person signed in to on a tracker. The token is what the tracker takes instead of a password, and it ends at the time given, in epoch milliseconds, or never when that is 0.
@Serializable
data class TrackerAccount(
    val userId: Long,
    val name: String,
    val avatar: String? = null,
    // How the person scores on the tracker, as the tracker names it, such as POINT_10.
    val scoreFormat: String? = null,
    val token: String,
    val expiresAt: Long = 0,
    // What gets a new token when this one ends, for a tracker whose tokens last only weeks.
    val refreshToken: String? = null,
)

// Why a tracker could not be used, in a way the page explains in words of its own.
sealed class TrackerProblem(message: String) : Exception(message) {
    // The build was made without the key of the tracker.
    data object NoKey : TrackerProblem("no key")

    data object Offline : TrackerProblem("offline")

    // The tracker did not take the token, which is wrong or has ended.
    data object Refused : TrackerProblem("refused")

    // The tracker asked to wait before more is asked of it.
    data object Limited : TrackerProblem("limited")

    class Other(detail: String) : TrackerProblem(detail)

    companion object {
        // The problem an error stands for, which is the error itself when it is one already.
        fun from(error: Throwable): TrackerProblem = error as? TrackerProblem ?: Other(error.message.orEmpty())

        // The problem a log line kept, by the words it was kept with.
        fun of(message: String): TrackerProblem =
            listOf(NoKey, Offline, Refused, Limited).firstOrNull { it.message == message } ?: Other(message)
    }
}

// Under this name the accounts are left out of backups, of the settings file and of sync, as everything of sync that belongs to one device is.
private const val Prefix = "sync.tracker."

// How long a reading shared by pages stays after the last one stops watching, so going back and forth reads nothing again.
internal const val KeepMs = 5_000L

// How many opened accounts are kept.
private const val OpenedKept = 4

// When the person asked to sign in, which stays on this device.
private const val AskedPrefix = "memo.tracker.asked."

// A token that ends within this long is renewed before it is used.
private const val RenewBeforeMs = 24 * 60 * 60 * 1000L

// How a saved account begins: sealed with a key of the system, or plain where the system has none.
private const val Sealed = "s:"
private const val Plain = "p:"

// Keeps the tracker accounts of a profile with its settings, so they follow the profile when it is renamed and go with it when it is removed. Each is sealed with a key of the system where there is one, so the token is not plain text. They never leave the device in a backup, a settings file or sync, and only go to a TV of the same person when they choose to send them from their phone, locked on the way.
@OptIn(ExperimentalEncodingApi::class)
class TrackerAccounts(private val settings: SettingsRepository, scope: CoroutineScope) {
    private val json = Json { ignoreUnknownKeys = true }

    // The accounts opened before, by what is kept on disk, so a sealed account is opened once and not at each look.
    private var openedBefore: Map<String, TrackerAccount?> = emptyMap()

    val accounts: Flow<Map<TrackerId, TrackerAccount>> = settings
        .prefixed(Prefix)
        .map { saved ->
            saved
                .mapNotNull { (name, value) ->
                    val tracker = TrackerId.of(name.removePrefix(Prefix)) ?: return@mapNotNull null
                    opened(value)?.let { tracker to it }
                }.toMap()
        }.distinctUntilChanged()
        // Every page and the sync share one reading, kept while something watches it.
        .shareIn(scope, SharingStarted.WhileSubscribed(KeepMs), replay = 1)

    suspend fun of(tracker: TrackerId): TrackerAccount? = settings.textNow(Prefix + tracker.id)?.let(::opened)

    suspend fun save(tracker: TrackerId, account: TrackerAccount) {
        val plain = json.encodeToString(TrackerAccount.serializer(), account).encodeToByteArray()
        val sealed = DeviceSecret.seal(plain)
        val text = if (sealed != null) Sealed + Base64.encode(sealed) else Plain + Base64.encode(plain)
        settings.setText(Prefix + tracker.id, text)
    }

    suspend fun remove(tracker: TrackerId) = settings.resetNames(Prefix + tracker.id)

    // Notes that the person asked to sign in just now, with the check the site must send back. It is kept on disk, as a phone may close the app while the browser is open.
    suspend fun markAsked(tracker: TrackerId, check: String) =
        settings.setText(AskedPrefix + tracker.id, nowMillis().toString() + " " + check)

    // When the person asked to sign in, in epoch milliseconds, and the check, or null when they did not. Asking counts once.
    suspend fun takeAsked(tracker: TrackerId): Pair<Long, String>? {
        val saved = settings.textNow(AskedPrefix + tracker.id)
        settings.resetNames(AskedPrefix + tracker.id)
        val at = saved?.substringBefore(' ')?.toLongOrNull() ?: return null
        return at to saved.substringAfter(' ', "")
    }

    // Gets a new token for the tracker, as the client of the tracker does it.
    var renewer: (suspend (TrackerId, TrackerAccount) -> TrackerAccount?)? = null
    private val renewing = Mutex()

    // Renews a token that ends within a day, one at a time, since a tracker may take each refresh token only once.
    internal suspend fun renewIfDue(tracker: TrackerId, account: TrackerAccount): TrackerAccount {
        if (account.refreshToken == null || account.expiresAt !in 1..(nowMillis() + RenewBeforeMs)) return account
        return renewing.withLock {
            val now = of(tracker) ?: return@withLock account
            if (now.expiresAt > nowMillis() + RenewBeforeMs) return@withLock now
            val renewed = runCatching { renewer?.invoke(tracker, now) }.getOrNull() ?: return@withLock now
            save(tracker, renewed)
            renewed
        }
    }

    // A seal this system cannot open, such as after the keys of the system were reset, counts as signed out.
    private fun opened(value: String): TrackerAccount? {
        if (value in openedBefore) return openedBefore[value]
        val account = open(value)
        openedBefore =
            mapOf(value to account) + openedBefore.entries.take(OpenedKept - 1).associate { it.key to it.value }
        return account
    }

    private fun open(value: String): TrackerAccount? = runCatching {
        val bytes = when {
            value.startsWith(Sealed) -> DeviceSecret.open(Base64.decode(value.removePrefix(Sealed)))
            value.startsWith(Plain) -> Base64.decode(value.removePrefix(Plain))
            else -> null
        } ?: return null
        json.decodeFromString(TrackerAccount.serializer(), bytes.decodeToString())
    }.getOrNull()
}

// Where a title stands in the list of the person. The code is how AniList names it, which is also what links keep.
enum class TrackStatus(val code: String) {
    Current("CURRENT"),
    Planning("PLANNING"),
    Completed("COMPLETED"),
    Paused("PAUSED"),
    Dropped("DROPPED"),
    Repeating("REPEATING"),
    ;

    companion object {
        fun of(code: String?): TrackStatus = entries.firstOrNull { it.code == code } ?: Planning
    }
}

// The account of a tracker while its login still works, with its token renewed first when it ends soon.
internal suspend fun TrackerAccounts.signedIn(tracker: TrackerId): TrackerAccount {
    val account = renewIfDue(tracker, of(tracker) ?: throw TrackerProblem.Refused)
    if (account.expiresAt in 1..nowMillis()) throw TrackerProblem.Refused
    return account
}

// A title found on a tracker, for linking a title of the library to it.
data class TrackerMedia(
    val id: Long,
    val name: String,
    val cover: String? = null,
    val url: String? = null,
    val format: String? = null,
    val year: Int? = null,
    val total: Int? = null,
    // The names of the title in each language, and the other names it goes by, for finding the title of the library it is.
    val names: List<String> = emptyList(),
    val synonyms: List<String> = emptyList(),
    // How many people have it on their list, which tells a well known title from one that only shares its name.
    val popularity: Int = 0,
    // The entry of the person, when the answer said whether there is one.
    val listKnown: Boolean = false,
    val onList: RemoteEntry? = null,
    // The kind the tracker says the title is, when the client knows it for sure.
    val kind: Kind? = null,
)

// An entry in the list of the person on a tracker. The score is out of 100 and the time is in epoch milliseconds.
data class RemoteEntry(
    val entryId: Long,
    val mediaId: Long,
    val status: String,
    val progress: Int,
    val score: Int,
    val updatedAt: Long,
)
