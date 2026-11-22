package com.sumizuri.app.source.host.store

import com.sumizuri.app.data.account.DeviceSecret
import com.sumizuri.app.source.host.BridgeException
import com.sumizuri.app.source.host.string
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// A small key and value store for one source, and the source's preference values. Both are kept in the value store. Settings the source marks secure are locked with the key of this device, and so is what a source with such settings saves for itself, since that is often a sign in token.
class StorageHost(
    private val scope: String,
    private val store: ValueStore,
    private val secureKeys: Set<String> = emptySet(),
) {

    suspend fun get(arguments: JsonObject): JsonElement = buildJsonObject {
        put("value", read(ValueArea.Storage, key(arguments)))
    }

    suspend fun set(arguments: JsonObject): JsonElement {
        write(ValueArea.Storage, key(arguments), arguments["value"] ?: JsonNull)
        return ok()
    }

    suspend fun delete(arguments: JsonObject): JsonElement {
        store.delete(scope, ValueArea.Storage, key(arguments))
        return ok()
    }

    suspend fun clear(): JsonElement {
        store.clear(scope, ValueArea.Storage)
        return ok()
    }

    suspend fun all(): JsonElement = buildJsonObject { put("values", JsonObject(readAll(ValueArea.Storage))) }

    suspend fun preference(arguments: JsonObject): JsonElement = buildJsonObject {
        put("value", read(ValueArea.Preference, key(arguments)))
    }

    suspend fun setPreference(arguments: JsonObject): JsonElement {
        write(ValueArea.Preference, key(arguments), arguments["value"] ?: JsonNull)
        return ok()
    }

    suspend fun preferences(): JsonElement =
        buildJsonObject { put("values", JsonObject(readAll(ValueArea.Preference))) }

    // The preference values, as JSON.
    suspend fun preferenceMap(): Map<String, JsonElement> = readAll(ValueArea.Preference)

    suspend fun putPreference(key: String, value: JsonElement) = write(ValueArea.Preference, key, value)

    private suspend fun read(area: ValueArea, key: String): JsonElement =
        store.get(scope, area, key)?.let(::parsed) ?: JsonNull

    // A value locked on another device cannot be opened here, so it is left out as if it was never set.
    private suspend fun readAll(area: ValueArea): Map<String, JsonElement> = store
        .all(scope, area)
        .mapNotNull { (key, text) -> parsed(text)?.let { key to it } }
        .toMap()

    private fun parsed(stored: String): JsonElement? =
        openText(stored)?.let { runCatching { Json.parseToJsonElement(it) }.getOrNull() }

    private suspend fun write(area: ValueArea, key: String, value: JsonElement) {
        val text = value.toString()
        store.set(scope, area, key, if (sealed(area, key) && value != JsonNull) sealText(text) else text)
    }

    // Locks the values that were saved as plain text before this source's secure settings were locked.
    suspend fun sealOld() {
        if (secureKeys.isEmpty() || !DeviceSecret.canSeal) return
        for (area in listOf(ValueArea.Preference, ValueArea.Storage)) {
            for ((key, text) in store.all(scope, area)) {
                if (sealed(area, key) && !text.startsWith(SealMark)) store.set(scope, area, key, sealText(text))
            }
        }
    }

    private fun sealed(area: ValueArea, key: String): Boolean = when (area) {
        ValueArea.Preference -> key in secureKeys
        ValueArea.Storage -> secureKeys.isNotEmpty()
        ValueArea.Flag -> false
    }

    private fun ok(): JsonElement = buildJsonObject { put("ok", true) }

    private fun key(arguments: JsonObject): String =
        arguments.string("key") ?: throw BridgeException("This call needs a key")
}
