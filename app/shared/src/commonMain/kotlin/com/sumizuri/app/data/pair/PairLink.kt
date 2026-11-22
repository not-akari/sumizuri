@file:OptIn(ExperimentalEncodingApi::class)

package com.sumizuri.app.data.pair

import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.sync.core.SyncCrypto
import io.ktor.http.Url
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

// What a TV shows in its QR code: where on the home network it listens, the one-time path a phone must post to, and the key that locks what the phone sends.
class PairLink(val address: String, val token: String, val key: ByteArray) {
    // The link the QR code holds, which the camera of a phone opens in the Sumizuri app.
    val text: String get() = "sumizuri://pair?a=$address&t=$token&k=${Base64.UrlSafe.encode(key).trimEnd('=')}"

    companion object {
        // A new link for a TV that listens at the address given, with a fresh path and key.
        fun make(address: String): PairLink = PairLink(
            address,
            Base64.UrlSafe.encode(SyncCrypto.randomBytes(12)).trimEnd('='),
            SyncCrypto.randomBytes(32),
        )

        // Reads a link of a TV, or null when it is not one.
        fun read(url: Url): PairLink? {
            val address = url.parameters["a"]?.takeIf { it.isNotBlank() } ?: return null
            val token = url.parameters["t"]?.takeIf { it.isNotBlank() } ?: return null
            val key =
                url.parameters["k"]?.let {
                    runCatching {
                        Base64.UrlSafe
                            .withPadding(
                                Base64.PaddingOption.ABSENT_OPTIONAL,
                            ).decode(it)
                    }.getOrNull()
                }
                    ?: return null
            return if (key.size == 32) PairLink(address, token, key) else null
        }
    }
}

// What a phone sends a TV: the repos to add, the sources to install from them, how to sign in to sync, and the trackers it is signed in to.
@Serializable
data class PairPackage(
    val repos: List<String> = emptyList(),
    val sources: List<PairSource> = emptyList(),
    val sync: PairSync? = null,
    // The tracker accounts of the phone, by the id of each tracker.
    val trackers: Map<String, TrackerAccount> = emptyMap(),
)

// A source by the repo it is from and the id that repo gives it.
@Serializable
data class PairSource(val repoUrl: String, val id: String)

// The sign in to sync: the server, who signs in, the password and the code of two-step sign in when there is one, and the profile on the server the phone syncs with.
@Serializable
data class PairSync(
    val server: String,
    val username: String,
    val password: String,
    val code: String? = null,
    val libraryId: Long? = null,
)

private const val Purpose = "sumizuri-pair"
private val PairJson = Json { ignoreUnknownKeys = true }

// Locks a package with the key of the TV, so only that TV can read it on its way across the network.
fun PairPackage.sealFor(link: PairLink): ByteArray =
    SyncCrypto.lock(link.key, PairJson.encodeToString(PairPackage.serializer(), this).encodeToByteArray(), Purpose)

// Opens what a phone sent, or null when it was not locked with this key.
fun openPackage(link: PairLink, sealed: ByteArray): PairPackage? {
    val plain = SyncCrypto.unlock(link.key, sealed, Purpose) ?: return null
    return runCatching { PairJson.decodeFromString(PairPackage.serializer(), plain.decodeToString()) }.getOrNull()
}
