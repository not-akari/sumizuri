package com.sumizuri.app.data.json

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.longOrNull

// Reading the fields of JSON from files and services, where a missing or odd field reads as empty rather than failing the whole read.

internal fun JsonObject.list(key: String): List<JsonObject> = (this[key] as? JsonArray).orEmpty().mapNotNull {
    it as? JsonObject
}

internal fun JsonObject.textOrNull(key: String): String? = (this[key] as? JsonPrimitive)?.contentOrNull

internal fun JsonObject.text(key: String): String = textOrNull(key).orEmpty()

internal fun JsonObject.int(key: String): Int? = (this[key] as? JsonPrimitive)?.intOrNull

internal fun JsonObject.long(key: String): Long? = (this[key] as? JsonPrimitive)?.longOrNull

internal fun JsonObject.flag(key: String): Boolean = (this[key] as? JsonPrimitive)?.booleanOrNull == true

internal fun JsonObject.strings(key: String): List<String> = (this[key] as? JsonArray).orEmpty().mapNotNull {
    (it as? JsonPrimitive)?.contentOrNull
}
