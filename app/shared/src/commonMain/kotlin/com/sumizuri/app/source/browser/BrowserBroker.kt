package com.sumizuri.app.source.browser

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.briefTrace
import com.sumizuri.app.core.log.withoutQuery
import com.sumizuri.app.data.net.hostOf
import com.sumizuri.app.source.browser.page.PageFetcher
import com.sumizuri.app.source.browser.page.PageLoadException
import com.sumizuri.app.source.browser.page.PageLoader
import com.sumizuri.app.source.browser.page.PageRenderer
import com.sumizuri.app.source.browser.page.RenderPage
import com.sumizuri.app.source.browser.page.RenderPageFactory
import com.sumizuri.app.source.browser.request.BrowserFetchRequest
import com.sumizuri.app.source.browser.request.BrowserFetchResult
import com.sumizuri.app.source.browser.request.RenderRequest
import com.sumizuri.app.source.browser.request.RenderResult
import com.sumizuri.app.source.host.BlockedException
import com.sumizuri.app.source.host.BridgeException
import com.sumizuri.app.source.host.net.AddressGuard
import com.sumizuri.app.source.host.net.ChallengeCheck
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

// How long a site that could not be found is not tried again in a page of its own.
private val UnreachableQuiet = 15.seconds

// The words of a page that could not be loaded because the site could not be found or there was no connection at all.
private val UnreachableWords =
    listOf(
        "ERR_NAME_NOT_RESOLVED",
        "ERR_INTERNET_DISCONNECTED",
        "ERR_ADDRESS_UNREACHABLE",
        "ERR_NETWORK_CHANGED",
        "Unable to resolve host",
    )

// Runs the hidden browser pages that extensions ask for, a one off render or a request made inside a site's own page.
class BrowserBroker(
    private val factory: RenderPageFactory,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default),
    maxPages: Int = 3,
    private val sessionIdle: Duration = 90.seconds,
) {
    private class Session(val page: RenderPage) {
        var idle: Job? = null
    }

    // Work for one site runs in order, and different sites run side by side a few at a time.
    private val slots = Semaphore(maxPages)
    private val stateLock = Mutex()
    private val lanes = HashMap<String, Mutex>()
    private val sessions = HashMap<String, Session>()

    // The sites whose page could not even be found lately, with when and why.
    private val unreachable = HashMap<String, Pair<TimeSource.Monotonic.ValueTimeMark, String>>()

    // How many site pages are kept open now.
    suspend fun openPages(): Int = stateLock.withLock { sessions.size }

    private suspend fun <T> inLane(site: String, work: suspend () -> T): T {
        val lane = stateLock.withLock { lanes.getOrPut(site) { Mutex() } }
        return lane.withLock { slots.withPermit { work() } }
    }

    suspend fun render(request: RenderRequest): RenderResult = inLane(siteOf(request.url)) {
        val result = try {
            open(request.userAgent, request.timeout) { PageRenderer.render(it, request) }
        } catch (error: ChallengeStillShowing) {
            // A made up user agent contradicts the browser's own hints, and a bot check never passes it.
            if (request.userAgent == null) throw error
            open(null, request.timeout) { PageRenderer.render(it, request) }
        }
        refuseInternalRedirect(result.url)
        result
    }

    suspend fun browserFetch(request: BrowserFetchRequest): BrowserFetchResult {
        val site = siteOf(request.pageUrl)
        return inLane(site) {
            var attempt = 0
            while (true) {
                val session = session(site, request)
                val result = try {
                    withTimeout(request.timeout + 5.seconds) { PageFetcher.fetch(session.page, request) }
                } catch (error: Throwable) {
                    AppLog.warn(TAG, "request in the page of $site failed: ${error.briefTrace()}")
                    closeSession(site)
                    if (error is TimeoutCancellationException) {
                        throw BridgeException(
                            "The page did not answer the request",
                        )
                    }
                    throw error
                }
                val headers = JsonObject(result.headers.mapValues { JsonPrimitive(it.value) })
                // Bytes as base64 text hold nothing to read, so only the headers say whether it was a bot check.
                val challenge = ChallengeCheck.reason(
                    result.statusCode,
                    headers,
                    if (request.binary) "" else result.body,
                )
                AppLog.debug(
                    TAG,
                    "request in the page of $site answered ${result.statusCode}, bot check: ${challenge ?: "none"}",
                )
                if (challenge == null) {
                    refuseInternalRedirect(result.url)
                    keep(site, session)
                    return@inLane result
                }
                // The clearance ran out or the kept page lost it, so a new page is warmed once.
                closeSession(site)
                AppLog.warn(TAG, "the page of $site still shows a bot check, attempt ${attempt + 1} of 2")
                if (attempt++ >= 1) throw ChallengeStillShowing(request.url)
            }
            @Suppress("UNREACHABLE_CODE")
            error("unreachable")
        }
    }

    // Closes the kept pages so the next request opens a fresh one.
    suspend fun resetSessions() {
        val sites = stateLock.withLock { sessions.keys + lanes.keys }
        sites.forEach { site -> inLane(site) { closeSession(site) } }
    }

    suspend fun close() {
        resetSessions()
        scope.cancel()
    }

    private suspend fun session(site: String, request: BrowserFetchRequest): Session {
        stateLock.withLock { sessions[site] }?.let { kept ->
            kept.idle?.cancel()
            return kept
        }
        // A site that could not be reached a moment ago fails at once, since opening a page is heavy and would only fail the same way.
        stateLock.withLock { unreachable[site] }?.let { (since, message) ->
            if (since.elapsedNow() < UnreachableQuiet) throw PageLoadException(message)
        }
        // Never a made up user agent, because the clearance belongs to the one that earned it.
        AppLog.info(TAG, "opening a hidden page for $site")
        val started = TimeSource.Monotonic.markNow()
        val page = try {
            factory.open(null)
        } catch (error: Throwable) {
            AppLog.error(TAG, "the hidden page for $site could not be opened", error)
            throw error
        }
        try {
            try {
                withTimeout(request.timeout) { PageLoader.loadWithRetry(page, request.pageUrl) }
                AppLog.info(
                    TAG,
                    "loaded ${request.pageUrl.withoutQuery()} in ${started.elapsedNow().inWholeMilliseconds} ms",
                )
            } catch (error: TimeoutCancellationException) {
                AppLog.warn(TAG, "${request.pageUrl.withoutQuery()} did not finish loading in time")
                throw PageLoadException(
                    "The site did not finish loading, waited ${request.timeout.inWholeSeconds} seconds",
                )
            }
            ChallengeWaiter.settle(page)
            AppLog.info(TAG, "the page for $site is ready after ${started.elapsedNow().inWholeMilliseconds} ms")
        } catch (error: Throwable) {
            AppLog.warn(TAG, "the page for $site was closed: ${error.briefTrace()}")
            closeQuietly(page)
            val message = error.message.orEmpty()
            if (UnreachableWords.any { message.contains(it) }) {
                stateLock.withLock {
                    unreachable[site] =
                        TimeSource.Monotonic.markNow() to message
                }
            }
            throw error
        }
        return Session(page).also { created ->
            stateLock.withLock {
                unreachable.remove(site)
                sessions[site] = created
            }
        }
    }

    private fun keep(site: String, session: Session) {
        session.idle?.cancel()
        session.idle = scope.launch {
            delay(sessionIdle)
            inLane(site) {
                val current = stateLock.withLock { sessions[site] }
                if (current === session) closeSession(site)
            }
        }
    }

    private suspend fun closeSession(site: String) {
        val session = stateLock.withLock { sessions.remove(site) } ?: return
        // The idle job must not cancel itself half way through.
        if (kotlin.coroutines.coroutineContext[Job] != session.idle) session.idle?.cancel()
        closeQuietly(session.page)
    }

    private suspend fun closeQuietly(page: RenderPage) {
        withContext(NonCancellable) {
            try {
                page.close()
            } catch (_: Exception) {
            }
        }
    }

    // Opens a page, runs the body on it under a timeout, and always closes it.
    private suspend fun <T> open(userAgent: String?, timeout: Duration, body: suspend (RenderPage) -> T): T {
        val page = factory.open(userAgent)
        try {
            return withTimeout(timeout + ChallengeSettleBudget + 15.seconds) { body(page) }
        } catch (error: TimeoutCancellationException) {
            throw PageLoadException("The page timed out, waited ${timeout.inWholeSeconds} seconds")
        } finally {
            closeQuietly(page)
        }
    }

    // A redirect must not lead somewhere the request itself would have been refused.
    private fun refuseInternalRedirect(url: String) {
        val host = hostOf(url)
        if (host.isNotEmpty() && AddressGuard.isBlockedHost(host)) {
            throw BlockedException("The page redirected to a private or internal address: \"$host\"")
        }
    }

    private companion object {
        const val TAG = "browser"
    }

    private fun siteOf(url: String): String {
        val scheme = url.substringBefore("://", "")
        return if (scheme.isEmpty()) {
            url
        } else {
            "$scheme://${url.substringAfter(
                "://",
            ).substringBefore('/').substringBefore('?').substringBefore('#')}"
        }
    }
}
