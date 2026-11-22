package com.sumizuri.app.source.engine

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.source.model.FilterOption
import com.sumizuri.app.source.model.PreferenceOption
import com.sumizuri.app.source.model.PreferenceType
import com.sumizuri.app.source.model.SourcePreference
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull

internal class Feed(val id: JsonElement, val name: String) {
    fun reads(vararg words: String): Boolean {
        val text = "${(id as? JsonPrimitive)?.content.orEmpty()} $name".lowercase()
        return words.any { it in text }
    }
}

internal fun settingText(value: JsonElement): String = when (value) {
    is JsonArray -> value.mapNotNull { (it as? JsonPrimitive)?.content }.joinToString(",")
    is JsonPrimitive -> value.content
    else -> value.toString()
}

internal fun sections(given: JsonArray): List<Section> {
    val sections = mutableListOf<Section>()
    val loose = mutableListOf<FilterOption>()
    given.forEachIndexed { index, item ->
        val obj = item as? JsonObject ?: return@forEachIndexed
        val tags = obj["tags"] as? JsonArray
        if (tags != null) {
            val id = ResultParser.text(obj, "id") ?: index.toString()
            sections +=
                Section(
                    id,
                    ResultParser.text(obj, "title") ?: ResultParser.text(obj, "label") ?: id,
                    (obj["single"] as? JsonPrimitive)?.booleanOrNull == true,
                    distinctOptions(tags.mapNotNull { option(it) }),
                )
        } else {
            option(obj)?.let { loose += it }
        }
    }
    if (loose.isNotEmpty()) sections.add(0, Section("genres", "Genres", false, distinctOptions(loose)))
    return sections
}

internal fun option(element: JsonElement): FilterOption? {
    val item = element as? JsonObject ?: return null
    val id = ResultParser.text(item, "id") ?: (item["id"] as? JsonPrimitive)?.content ?: return null
    val label = ResultParser.text(item, "label") ?: ResultParser.text(item, "title") ?: id
    // A label read from a page may hold line breaks and runs of spaces, which would draw a tall box with its words scattered, so it is made one line.
    return FilterOption(label.replace(Spaces, " ").trim().ifEmpty { id }, id)
}

// Line breaks, tabs and runs of spaces in a label.
private val Spaces = Regex("\\s+")

// The options with a name shown once. Options with the same name cannot be told apart, such as a link a source read from every card of a page, so only the first is kept.
private fun distinctOptions(options: List<FilterOption>): List<FilterOption> {
    val kept = options.distinctBy { it.label.lowercase() }
    if (kept.size <
        options.size
    ) {
        AppLog.warn("sources", "${options.size - kept.size} filter options repeat a name and are shown once")
    }
    return kept
}

// A filter value as a list of texts, whether it came as one value or as many.
internal fun many(value: Any?): List<String> = when (value) {
    null -> emptyList()
    is Collection<*> -> value.mapNotNull { it?.toString()?.takeIf(String::isNotEmpty) }
    else -> listOfNotNull(value.toString().takeIf(String::isNotEmpty))
}

// Whether metadata asks for another page, as JavaScript reads it: nothing, false, zero and an empty text mean the list ended.
internal fun truthy(value: JsonElement?): Boolean = when (value) {
    null, JsonNull -> false

    is JsonPrimitive -> when {
        value.isString -> value.content.isNotEmpty()
        value.booleanOrNull != null -> value.booleanOrNull == true
        else -> (value.doubleOrNull ?: 0.0) != 0.0
    }

    else -> true
}

internal fun splitChapterUrl(url: String): Pair<String, String> {
    val at = url.indexOf(PackedChapterMark)
    return if (at < 0) "" to url else url.substring(0, at) to url.substring(at + PackedChapterMark.length)
}

internal class Section(val id: String, val title: String, val single: Boolean, val options: List<FilterOption>)

// The settings of the repo entry's settingsSchema as the settings page of the source shows them.
internal fun preferencesOf(schema: List<JsonObject>): List<SourcePreference> = schema.map { field ->
    val type = when (ResultParser.text(field, "type")) {
        "toggle" -> PreferenceType.Switch
        "select" -> PreferenceType.List
        "multiSelect" -> PreferenceType.MultiSelectList
        else -> PreferenceType.EditText
    }
    val fallback = field["default"]?.let(::primitiveValue)
    SourcePreference(
        key = ResultParser.text(field, "key").orEmpty(),
        title = ResultParser.text(field, "label") ?: ResultParser.text(field, "key").orEmpty(),
        type = type,
        summary = ResultParser.text(field, "placeholder"),
        defaultValue = if (type == PreferenceType.Switch) fallback?.toString() == "true" else fallback,
        secure = field["secure"]?.let(::primitiveValue)?.toString() == "true",
        options = (field["options"] as? JsonArray).orEmpty().mapNotNull { option ->
            val item = option as? JsonObject ?: return@mapNotNull null
            val value = ResultParser.text(item, "value") ?: return@mapNotNull null
            PreferenceOption(ResultParser.text(item, "label") ?: value, value)
        },
    )
}
