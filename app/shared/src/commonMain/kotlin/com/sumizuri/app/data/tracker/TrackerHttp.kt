package com.sumizuri.app.data.tracker

import com.sumizuri.app.core.log.AppLog
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.HttpRequestBuilder
import io.ktor.client.request.header
import io.ktor.client.request.request
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.Parameters
import io.ktor.http.contentType
import io.ktor.http.formUrlEncode
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
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull
import kotlin.time.Instant
import kotlin.time.TimeMark
import kotlin.time.TimeSource

// An answer of a tracker: its status and its text.
internal class TrackerAnswer(val status: HttpStatusCode, val text: String) {
    val ok: Boolean get() = status.isSuccess()

    fun json(): JsonElement = runCatching { Json.parseToJsonElement(text) }.getOrNull() ?: JsonNull
}

// Sends the requests of one tracker one at a time with a short gap between them, which keeps under limits the tracker does not tell. One the tracker turns away waits as long as it asks, and is sent once more.
internal class TrackerHttp(private val name: String, private val gapMs: Long) {
    // Made at the first request, so a tracker nobody uses costs nothing at start.
    private val http by lazy { HttpClient { install(HttpTimeout) { requestTimeoutMillis = 30_000 } } }
    private val gate = Mutex()

    // When the last request ended, which the next one waits a gap after.
    private var last: TimeMark? = null

    suspend fun send(method: HttpMethod, url: String, setup: HttpRequestBuilder.() -> Unit = {}): TrackerAnswer =
        withContext(Dispatchers.IO) {
            gate.withLock {
                var answer = once(method, url, setup)
                if (answer.status == HttpStatusCode.TooManyRequests) {
                    val wait = answer.headers["Retry-After"]?.toLongOrNull()?.times(1000) ?: 30_000L
                    AppLog.info("tracker", "$name asked to wait ${wait / 1000} seconds")
                    delay(wait.coerceIn(1_000, 120_000))
                    answer = once(method, url, setup)
                }
                val text = answer.bodyAsText()
                when (answer.status) {
                    HttpStatusCode.TooManyRequests -> throw TrackerProblem.Limited
                    else -> TrackerAnswer(answer.status, text)
                }
            }
        }

    // The settings of the request are named setup, as a call named build inside it would reach the build of the request builder itself and leave them out.
    private suspend fun once(method: HttpMethod, url: String, setup: HttpRequestBuilder.() -> Unit): HttpResponse {
        last?.let { mark ->
            val wait = gapMs - mark.elapsedNow().inWholeMilliseconds
            if (wait > 0) delay(wait)
        }
        return try {
            http.request(url) {
                this.method = method
                header("User-Agent", "Sumizuri")
                setup()
            }
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            throw TrackerProblem.Offline
        } finally {
            last = TimeSource.Monotonic.markNow()
        }
    }
}

// Sends a form as its encoded text with the type of a form, the way the sites that sign in apps read it. A form object of the client library went out with no body at all.
internal fun HttpRequestBuilder.formBody(values: Parameters) {
    contentType(ContentType.Application.FormUrlEncoded)
    setBody(values.formUrlEncode())
}

// The word the trackers use for the kind of a title in their addresses.
internal fun typeOf(anime: Boolean): String = if (anime) "anime" else "manga"

// The code a tracker sent back to the app after a sign in in the browser, once its state shows it answers this sign in.
internal fun codeFrom(answer: Map<String, String>, check: String, tracker: String): String {
    val code = answer["code"]?.takeIf { it.isNotBlank() } ?: throw TrackerProblem.Refused
    if (answer["state"] != check.take(16)) {
        AppLog.warn("tracker", "the $tracker answer did not carry the check of this sign in")
        throw TrackerProblem.Refused
    }
    return code
}

// A token a tracker gave, with when it ends in seconds from now and the token that renews it.
internal class GrantedToken(val token: String, val expiresIn: Long?, val refresh: String?)

// Trades a form, such as a code, a login or a refresh token, for a token. A refusal is logged with what the tracker said, which tells why.
internal suspend fun TrackerHttp.grant(url: String, form: Parameters, tracker: String): GrantedToken {
    val answer = send(HttpMethod.Post, url) { formBody(form) }
    if (answer.status == HttpStatusCode.BadRequest || answer.status == HttpStatusCode.Unauthorized) {
        AppLog.warn("tracker", "$tracker refused the token request, ${answer.status.value} ${answer.text.take(300)}")
        throw TrackerProblem.Refused
    }
    val body = answer.orThrow(tracker).json().obj()
    val token = body.text("access_token") ?: throw TrackerProblem.Refused
    return GrantedToken(token, body.long("expires_in"), body.text("refresh_token"))
}

// What a refused or failed answer means, for a tracker that says nothing better.
internal fun TrackerAnswer.orThrow(tracker: String): TrackerAnswer {
    if (ok) return this
    throw when (status) {
        HttpStatusCode.Unauthorized -> TrackerProblem.Refused
        else -> TrackerProblem.Other("$tracker answered ${status.value}")
    }
}

internal fun JsonElement?.obj(): JsonObject? = this as? JsonObject

internal fun JsonElement?.list(): List<JsonElement> = (this as? JsonArray).orEmpty()

internal fun JsonObject?.text(name: String): String? =
    (this?.get(name) as? JsonPrimitive)?.takeIf { it !is JsonNull }?.content?.takeIf { it.isNotBlank() }

internal fun JsonObject?.long(name: String): Long? = (this?.get(name) as? JsonPrimitive)?.let {
    it.longOrNull ?: it.content.toLongOrNull()
}

internal fun JsonObject?.number(name: String): Double? = (this?.get(name) as? JsonPrimitive)?.doubleOrNull

internal fun JsonObject?.flag(name: String): Boolean = (this?.get(name) as? JsonPrimitive)?.booleanOrNull == true

// A time a tracker writes like 2024-05-01T10:00:00+00:00, in epoch milliseconds, or 0 when it gave none.
internal fun timeOf(text: String?): Long =
    text?.let { runCatching { Instant.parse(it).toEpochMilliseconds() }.getOrNull() } ?: 0

// The year a date such as 2024-05-01 starts with.
internal fun yearOf(text: String?): Int? = text?.take(4)?.toIntOrNull()

// The id a tracker that numbers anime and manga apart is known by here, below zero for manga.
internal fun mediaKey(id: Long, anime: Boolean): Long = if (anime) id else -id

internal fun isAnimeKey(key: Long): Boolean = key > 0

internal fun rawId(key: Long): Long = kotlin.math.abs(key)
