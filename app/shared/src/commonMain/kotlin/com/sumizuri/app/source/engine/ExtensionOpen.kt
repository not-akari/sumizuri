package com.sumizuri.app.source.engine

import com.sumizuri.app.source.host.StandardHost
import com.sumizuri.app.source.host.store.FilledHeaders
import com.sumizuri.app.source.host.store.StorageHost
import com.sumizuri.app.source.host.store.ValueStore
import com.sumizuri.app.source.model.SourceInfo
import com.sumizuri.app.source.repo.InstalledSource
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject

// Loads an installed extension and reads what its repo entry and its Source say about it.
suspend fun ExtensionSource.Companion.open(
    installed: InstalledSource,
    scripts: EngineScripts,
    host: StandardHost,
    callTimeoutMs: Long = 90_000,
): ExtensionSource {
    val runtime = ExtensionRuntime.open(installed.id, installed.code, scripts, host.bridge)
    try {
        val extra = runCatching { Json.parseToJsonElement(installed.extra) }.getOrNull() as? JsonObject
        val schema = (extra?.get("settingsSchema") as? JsonArray)
            .orEmpty()
            .mapNotNull { it as? JsonObject }
            .filter { ResultParser.text(it, "type") != "section" && ResultParser.text(it, "key") != null }
        val methods = runtime.shape.methods
        val info = SourceInfo(
            name = installed.name,
            lang = installed.lang,
            iconUrl = installed.iconUrl.ifEmpty { null },
            baseUrl = installed.baseUrl.ifEmpty { null },
            hasDetails = true,
            hasFilters = "getSearchTags" in methods || "getSortOptions" in methods,
            hasCatalogs = runtime.shape.feeds.size > 2,
            hasPreferences = schema.isNotEmpty(),
        )
        return ExtensionSource(
            runtime,
            host,
            info,
            schema,
            callTimeoutMs,
            installed.id,
            installed.settingImageHeaders(),
        )
    } catch (error: Throwable) {
        runtime.close()
        throw error
    }
}

// Fills the picture headers of an installed source from its saved settings without starting it, so covers in the library load at once after a start.
suspend fun fillSettingHeaders(installed: InstalledSource, values: ValueStore) {
    val templates = installed.settingImageHeaders()
    if (templates.isEmpty()) return FilledHeaders.forget(installed.id)
    val extra = runCatching { Json.parseToJsonElement(installed.extra) }.getOrNull() as? JsonObject
    val settings = mutableMapOf<String, String>()
    for (field in (extra?.get("settingsSchema") as? JsonArray).orEmpty().mapNotNull { it as? JsonObject }) {
        val key = ResultParser.text(field, "key") ?: continue
        field["default"]?.let { settings[key] = settingText(it) }
    }
    StorageHost(installed.id, values, installed.secureSettingKeys()).preferenceMap().forEach { (key, value) ->
        settings[key] = settingText(value)
    }
    FilledHeaders.update(installed.id, templates, settings)
}
