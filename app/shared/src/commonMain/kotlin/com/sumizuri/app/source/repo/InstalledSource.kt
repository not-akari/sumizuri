package com.sumizuri.app.source.repo

import com.sumizuri.app.data.model.Kind
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

// A source that is installed, together with the code it was installed with.
data class InstalledSource(
    val id: String,
    // The repo it came from, or null when it was added by hand.
    val repoUrl: String?,
    val name: String,
    val lang: String,
    val kind: Kind,
    val engineKind: EngineKind,
    val version: Int,
    val iconUrl: String,
    val baseUrl: String,
    val code: String,
    // What the repo said about the source that the engine needs, as JSON text. An extension source keeps its allowed hosts and its settings here.
    val extra: String = "",
    val enabled: Boolean = true,
    // When the source was last opened, epoch milliseconds, or 0 when it never was.
    val lastUsedAt: Long = 0,
) {
    // The hosts the source may reach, or null when it did not say and every public host is fine.
    fun allowedHosts(): List<String>? = (
        (
            runCatching {
                Json.parseToJsonElement(extra)
            }.getOrNull() as? JsonObject
            )?.get("hosts") as? JsonArray
        )?.mapNotNull { (it as? JsonPrimitive)?.content }
        ?.takeIf { it.isNotEmpty() }
}

// The format of a source. Only the current one runs, and a source kept from the old engine stays listed until it is installed again.
enum class EngineKind(val key: String) {
    Current("boundless"),
    Old("old"),
    ;

    companion object {
        fun fromKey(key: String?): EngineKind = if (key?.lowercase() == Current.key) Current else Old
    }
}

// What a browser says about a picture it asks for. A few sites, and the CDN in front of them, answer a picture
// asked for without it with a bot check instead of the picture.
val BrowserPictureHeaders = mapOf(
    "Sec-Fetch-Dest" to "image",
    "Sec-Fetch-Mode" to "no-cors",
)

// The headers pictures of a source are loaded with, its site as the referrer. The reader and the saving of chapters both use them, so a saved page comes as the reader would have it.
fun pictureHeaders(installed: InstalledSource): Map<String, String> = buildMap {
    putAll(BrowserPictureHeaders)
    if (installed.baseUrl.isNotBlank()) put("Referer", installed.baseUrl.trimEnd('/') + "/")
}
