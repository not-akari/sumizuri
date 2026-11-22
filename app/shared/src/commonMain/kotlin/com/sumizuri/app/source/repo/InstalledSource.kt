package com.sumizuri.app.source.repo

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.source.host.store.FilledHeaders
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

    // Headers the repo says the pictures of this source need, such as the fetch metadata a browser sends, for a CDN that answers anything else with a bot check. Headers filled from a setting are left out, they only go to the source's own server.
    fun imageHeaders(): Map<String, String> = allImageHeaders().filterValues { "{{" !in it }

    // Headers for pictures that name a setting, such as {{apiKey}}, which the app fills from the settings of the source.
    fun settingImageHeaders(): Map<String, String> = allImageHeaders().filterValues { "{{" in it }

    // The settings the repo marks secure, such as a password or an API key.
    fun secureSettingKeys(): Set<String> = ((json()?.get("settingsSchema") as? JsonArray).orEmpty())
        .mapNotNull { it as? JsonObject }
        .filter { (it["secure"] as? JsonPrimitive)?.content == "true" }
        .mapNotNull { (it["key"] as? JsonPrimitive)?.content }
        .toSet()

    private fun json(): JsonObject? = runCatching { Json.parseToJsonElement(extra) }.getOrNull() as? JsonObject

    private fun allImageHeaders(): Map<String, String> = (json()?.get("imageHeaders") as? JsonObject)
        ?.mapNotNull { (name, value) -> (value as? JsonPrimitive)?.content?.let { name to it } }
        ?.toMap()
        .orEmpty()
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

// The headers pictures of a source are loaded with, its site as the referrer. The reader and the saving of chapters both use them, so a saved page comes as the reader would have it. The headers filled from its settings are added when the picture is on the source's own server.
fun pictureHeaders(installed: InstalledSource, url: String? = null): Map<String, String> = buildMap {
    if (installed.baseUrl.isNotBlank()) put("Referer", installed.baseUrl.trimEnd('/') + "/")
    putAll(installed.imageHeaders())
    putAll(FilledHeaders.forUrl(installed.id, url))
}
