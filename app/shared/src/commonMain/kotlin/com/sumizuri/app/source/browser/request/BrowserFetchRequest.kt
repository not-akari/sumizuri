package com.sumizuri.app.source.browser.request

import com.sumizuri.app.data.net.hostOf
import com.sumizuri.app.source.host.net.AddressGuard
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.time.Duration

class BrowserFetchRequest(
    val url: String,
    val method: String = "GET",
    val headers: Map<String, String> = emptyMap(),
    val body: String? = null,
    // Asks for the bytes of the answer, which come back as base64 text.
    val binary: Boolean = false,
    // A page of the site to make the request from. A bare page loads much faster than a busy front page.
    val page: String? = null,
    val timeout: Duration = DefaultRenderTimeout,
) {
    // The page the request is made from, either the one the source named or the site's front page.
    val pageUrl: String
        get() {
            val named = page?.trim().orEmpty()
            return if (isPublicWebUrl(named)) named else pageOrigin
        }

    // The site the request is made from.
    val pageOrigin: String
        get() {
            val origin = headers.entries
                .firstOrNull { it.key.equals("origin", ignoreCase = true) }
                ?.value
                ?.trim()
                .orEmpty()
            val base = if (isPublicWebUrl(origin)) origin else url
            return "${base.substringBefore("://")}://${authorityOf(base)}/"
        }

    private fun authorityOf(url: String) = url
        .substringAfter("://")
        .substringBefore('/')
        .substringBefore('?')
        .substringBefore('#')

    private fun isPublicWebUrl(text: String): Boolean {
        val scheme = text.substringBefore("://", "").lowercase()
        if (scheme != "http" && scheme != "https") return false
        val host = hostOf(text)
        return host.isNotEmpty() && !AddressGuard.isBlockedHost(host)
    }
}

class BrowserFetchResult(
    val statusCode: Int,
    val url: String,
    val body: String,
    val headers: Map<String, String>,
    // True when the body is base64 text for bytes and not a page.
    val binary: Boolean = false,
) {
    fun toJson(): JsonObject = buildJsonObject {
        put("statusCode", statusCode)
        put("url", url)
        put(if (binary) "bodyBase64" else "body", body)
        put("headers", JsonObject(headers.mapValues { JsonPrimitive(it.value) }))
    }
}
