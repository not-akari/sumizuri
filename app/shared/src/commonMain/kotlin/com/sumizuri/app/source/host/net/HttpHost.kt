package com.sumizuri.app.source.host.net

import io.ktor.client.plugins.HttpTimeoutConfig
import io.ktor.client.plugins.timeout
import io.ktor.client.request.prepareGet
import io.ktor.client.statement.bodyAsChannel
import io.ktor.http.isSuccess
import io.ktor.utils.io.readAvailable
import okio.FileSystem
import okio.Path
import okio.buffer
import okio.use
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.briefTrace
import com.sumizuri.app.core.log.withoutQuery
import com.sumizuri.app.core.perf.Perf
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.net.SiteKinds
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.source.browser.BrowserBroker
import com.sumizuri.app.source.browser.ChallengeStillShowing
import com.sumizuri.app.source.browser.request.BrowserFetchRequest
import com.sumizuri.app.source.host.BlockedException
import com.sumizuri.app.source.host.BridgeException
import com.sumizuri.app.source.host.ChallengeException
import com.sumizuri.app.source.host.bool
import com.sumizuri.app.source.host.int
import com.sumizuri.app.source.host.store.BrowserFirstFlag
import com.sumizuri.app.source.host.store.CookieStore
import com.sumizuri.app.source.host.store.InMemoryBrowserFirstFlag
import com.sumizuri.app.source.host.string
import io.ktor.client.HttpClient
import io.ktor.client.HttpClientConfig
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.cookies.AcceptAllCookiesStorage
import io.ktor.client.plugins.cookies.CookiesStorage
import io.ktor.client.plugins.cookies.HttpCookies
import io.ktor.client.request.header
import io.ktor.client.request.request
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsBytes
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.concurrent.Volatile
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeSource

// How long the requests of a source skip a hidden browser that failed on its own.
private const val BrowserPauseMs = 60_000L

// Makes the requests an extension asks for, and follows redirects itself so every hop is checked.
@OptIn(ExperimentalEncodingApi::class)
class HttpHost(
    engine: HttpClientEngine? = null,
    private val defaultUserAgent: String? = null,
    private val resolver: HostResolver = SystemResolver,
    private val timeoutMs: Long = 30_000,
    // For a developer's own test setup, and an extension cannot set it.
    private val allowPrivateAddresses: Boolean = false,
    // The hidden browser for sites that put a bot check in the way. Without one a bot check is only reported.
    private val browser: BrowserBroker? = null,
    private val browserFirst: BrowserFirstFlag = InMemoryBrowserFirstFlag(),
    // The name the source goes by in the log.
    private val label: String = "http",
    // Where cookies are kept between runs, under the scope. Without a store they last until the app closes.
    cookieStore: CookieStore? = null,
    cookieScope: String = label,
    // The hosts the source may reach, each one a name or a name with a star in front for the hosts under it. Without a list every public host is fine.
    private val allowedHosts: List<String>? = null,
    // The kind of titles the source has.
    private val kind: Kind? = null,
    // The source the requests are for, for the routes set for single sources.
    private val sourceId: String? = null,
) {
    val cookies: CookiesStorage =
        if (cookieStore == null) AcceptAllCookiesStorage() else PersistentCookiesStorage(cookieScope, cookieStore)

    private val client: HttpClient = createClient(engine)

    // Requests run side by side, so the map of lookups is only touched with this lock held.
    private val lookupLock = Mutex()
    private val lookups = HashMap<String, Pair<Boolean, TimeSource.Monotonic.ValueTimeMark>>()

    private fun createClient(engine: HttpClientEngine?): HttpClient {
        val configure: HttpClientConfig<*>.() -> Unit = {
            followRedirects = false
            expectSuccess = false
            install(HttpCookies) { storage = cookies }
            install(HttpTimeout) {
                requestTimeoutMillis = timeoutMs
                connectTimeoutMillis = timeoutMs
                socketTimeoutMillis = timeoutMs
            }
        }
        return if (engine == null) HttpClient(configure) else HttpClient(engine, configure)
    }

    // When the hidden browser last failed on its own, as epoch milliseconds, or 0 when it has not.
    @Volatile
    private var browserFailedAt = 0L

    private fun browserRecentlyFailed(): Boolean =
        browserFailedAt != 0L && nowMillis() - browserFailedAt < BrowserPauseMs

    // Each request is counted while it runs, for the performance overlay.
    suspend fun fetch(arguments: JsonObject): JsonElement {
        Perf.requestStarted()
        try {
            return fetchNow(arguments)
        } finally {
            Perf.requestEnded()
        }
    }

    private suspend fun fetchNow(arguments: JsonObject): JsonElement {
        val url = arguments.string("url") ?: throw BridgeException("fetch needs a url")
        val options = arguments["options"] as? JsonObject ?: JsonObject(emptyMap())
        val method = options.string("method")?.uppercase() ?: "GET"
        val binary = options.bool("binary") ?: false
        val headers = (options["headers"] as? JsonObject)
            ?.mapNotNull { (name, value) ->
                (value as? JsonPrimitive)?.content?.let { name to it }
            }.orEmpty()
        val body = options.string("body")
        val request = Request(url, method, headers, body, binary, options.string("browserPage"))
        AppLog.debug(label, "$method ${url.withoutQuery()}${if (binary) " binary" else ""}")

        val broker = browser ?: return fetchPlain(request)
        if (browserFirst.isSet() && !browserRecentlyFailed()) {
            AppLog.debug(label, "this source goes through the hidden browser first")
            return try {
                fetchViaBrowser(broker, request).also { browserFailedAt = 0L }
            } catch (error: ChallengeStillShowing) {
                AppLog.warn(
                    label,
                    "the hidden browser could not get past the bot check at ${request.url.withoutQuery()}",
                )
                throw ChallengeException(request.url.trim(), "the hidden browser could not get past it")
            } catch (error: ChallengeException) {
                throw error
            } catch (error: kotlinx.coroutines.CancellationException) {
                throw error
            } catch (error: Exception) {
                // The browser itself failed, not the check: the plain request may still get through. The next requests skip the browser for a while, so each one does not open a hidden page that is bound to fail too.
                browserFailedAt = nowMillis()
                AppLog.warn(
                    label,
                    "the hidden browser failed, trying a plain request, and the next requests skip it for a minute: ${error.briefTrace()}",
                )
                fetchPlain(request)
            }
        }
        return try {
            fetchPlain(request)
        } catch (plain: ChallengeException) {
            AppLog.info(
                label,
                "bot check on ${request.url.withoutQuery()}, ${plain.message}, trying the hidden browser",
            )
            val started = TimeSource.Monotonic.markNow()
            // The hidden browser passes most checks by itself, and a person is needed only when it cannot.
            val result = try {
                fetchViaBrowser(broker, request)
            } catch (error: ChallengeStillShowing) {
                AppLog.warn(
                    label,
                    "the hidden browser could not get past the bot check after ${started.elapsedNow().inWholeMilliseconds} ms",
                )
                throw ChallengeException(plain.url, "${plain.message}; the hidden browser could not get past it")
            } catch (error: ChallengeException) {
                throw error
            } catch (error: kotlinx.coroutines.CancellationException) {
                throw error
            } catch (error: Exception) {
                AppLog.error(
                    label,
                    "the hidden browser failed after ${started.elapsedNow().inWholeMilliseconds} ms",
                    error,
                )
                throw ChallengeException(plain.url, "the hidden browser failed: ${error.message}")
            }
            AppLog.info(
                label,
                "the hidden browser got through in ${started.elapsedNow().inWholeMilliseconds} ms, it will be used first from now on",
            )
            browserFirst.set()
            result
        }
    }

    class Page(val statusCode: Int, val url: String, val body: String)

    // A plain get for the app's own use, such as a repo's index, through the same address checks. No browser, no script.
    suspend fun get(url: String): Page {
        val answer = fetchPlain(
            Request(url, "GET", emptyList(), null, binary = false, browserPage = null),
        ) as JsonObject
        return Page(
            statusCode = answer.int("statusCode") ?: 0,
            url = answer.string("url") ?: url,
            body = answer.string("body").orEmpty(),
        )
    }

    private class Request(
        val url: String,
        val method: String,
        val headers: List<Pair<String, String>>,
        val body: String?,
        val binary: Boolean,
        val browserPage: String?,
    )

    private suspend fun fetchViaBrowser(broker: BrowserBroker, request: Request): JsonElement {
        val result = broker.browserFetch(
            BrowserFetchRequest(
                url = checked(request.url),
                method = request.method,
                headers = request.headers.toMap(),
                body = request.body,
                binary = request.binary,
                page = request.browserPage,
                timeout = timeoutMs.milliseconds,
            ),
        )
        return result.toJson()
    }

    private suspend fun fetchPlain(request: Request): JsonElement {
        var url = request.url
        var method = request.method
        var body = request.body
        val binary = request.binary
        val headers = request.headers

        var response: HttpResponse? = null
        for (hop in 0..MAX_REDIRECTS) {
            url = checked(url)
            response = send(url, method, headers, body)
            val location = response.headers[HttpHeaders.Location]
            val redirect = response.status.value in REDIRECTS && location != null
            if (!redirect) break
            if (hop == MAX_REDIRECTS) throw BridgeException("Too many redirects from ${AddressGuard.hostOf(url)}")
            AppLog.debug(
                label,
                "redirect ${response.status.value} from ${url.withoutQuery()} to ${location.withoutQuery()}",
            )
            url = resolveLocation(url, location)
            // A form post answered with a redirect is read again with a plain get, as browsers do.
            val status = response.status.value
            if (status == 303 || ((status == 301 || status == 302) && method == "POST")) {
                method = "GET"
                body = null
            }
        }
        val last = response!!
        val status = last.status.value
        val replyHeaders = buildJsonObject {
            last.headers.names().forEach { name ->
                put(
                    name,
                    last.headers
                        .getAll(name)
                        .orEmpty()
                        .joinToString(", "),
                )
            }
        }
        val replyBody = if (binary) null else last.bodyAsText()
        AppLog.debug(label, "answer $status from ${url.withoutQuery()}, ${replyBody?.length ?: 0} characters")
        // A picture has no page to read, so the headers alone say that a bot check answered.
        ChallengeCheck.throwIfChallenge(url, status, replyHeaders, replyBody ?: "")
        return buildJsonObject {
            put("statusCode", status)
            put("url", url)
            if (binary) put("bodyBase64", Base64.encode(last.bodyAsBytes())) else put("body", replyBody.orEmpty())
            put("headers", replyHeaders)
        }
    }

    private suspend fun send(
        url: String,
        method: String,
        headers: List<Pair<String, String>>,
        body: String?,
    ): HttpResponse = try {
        // The router learns the kind of each site this source asks, so it can give the site the way of that kind.
        kind?.let { SiteKinds.mark(url, it, sourceId) }
        client.request(url) {
            this.method = HttpMethod.parse(method)
            headers.forEach { (name, value) -> header(name, value) }
            val hasAgent = headers.any { it.first.equals(HttpHeaders.UserAgent, ignoreCase = true) }
            if (!hasAgent && defaultUserAgent != null) header(HttpHeaders.UserAgent, defaultUserAgent)
            if (body != null) setBody(body)
        }
    } catch (error: Exception) {
        if (error is kotlinx.coroutines.CancellationException) throw error
        throw BridgeException(
            "Could not reach ${AddressGuard.hostOf(url)}: ${error.message ?: error::class.simpleName}",
        )
    }

    // The address, once it is known to be a public web address as written and as the name resolves.
    private suspend fun checked(url: String): String {
        allowedHosts?.let { allowed ->
            val host = AddressGuard.hostOf(url.trim())
            if (allowed.none {
                    hostMatches(it, host)
                }
            ) {
                throw BlockedException("This source may not reach \"$host\", it is not in the hosts its repo gave.")
            }
        }
        if (allowPrivateAddresses) return url.trim()
        val clean = AddressGuard.check(url)
        val host = AddressGuard.hostOf(clean)
        // A literal address was fully checked above.
        if (AddressGuard.isLiteralAddress(host)) return clean
        val known = lookupLock.withLock { lookups[host] }
        if (known != null && known.second.elapsedNow().inWholeMinutes < LOOKUP_MINUTES) {
            if (known.first) throw BlockedException("Refusing to fetch a private or internal address: \"$host\"")
            return clean
        }
        val blocked = resolver.resolve(host).any { AddressGuard.isBlockedHost(it) }
        lookupLock.withLock { lookups[host] = blocked to TimeSource.Monotonic.markNow() }
        if (blocked) throw BlockedException("Refusing to fetch a private or internal address: \"$host\"")
        return clean
    }

    // Writes a big file a source points at, such as a book, as it arrives. It goes through the same checks, cookies, agent and way as every other call of the source, with no time limit on the whole, since a book may take minutes.
    suspend fun download(url: String, headers: Map<String, String>, target: Path) {
        var address = url
        repeat(MAX_REDIRECTS + 1) {
            address = checked(address)
            kind?.let { SiteKinds.mark(address, it, sourceId) }
            val next = client.prepareGet(address) {
                timeout { requestTimeoutMillis = HttpTimeoutConfig.INFINITE_TIMEOUT_MS }
                headers.forEach { (name, value) -> header(name, value) }
                val hasAgent = headers.keys.any { it.equals(HttpHeaders.UserAgent, ignoreCase = true) }
                if (!hasAgent && defaultUserAgent != null) header(HttpHeaders.UserAgent, defaultUserAgent)
            }.execute { response ->
                val location = response.headers[HttpHeaders.Location]
                if (response.status.value in REDIRECTS && location != null) return@execute resolveLocation(address, location)
                if (!response.status.isSuccess()) throw BridgeException("The file answered ${response.status.value}")
                val channel = response.bodyAsChannel()
                val buffer = ByteArray(64 * 1024)
                FileSystem.SYSTEM.sink(target).buffer().use { sink ->
                    while (true) {
                        val read = channel.readAvailable(buffer, 0, buffer.size)
                        if (read == -1) break
                        if (read > 0) sink.write(buffer, 0, read)
                    }
                }
                null
            } ?: return
            address = next
        }
        throw BridgeException("Too many redirects from ${AddressGuard.hostOf(url)}")
    }

    fun close() = client.close()

    private companion object {
        const val MAX_REDIRECTS = 10
        const val LOOKUP_MINUTES = 10
        val REDIRECTS = setOf(301, 302, 303, 307, 308)
    }
}
