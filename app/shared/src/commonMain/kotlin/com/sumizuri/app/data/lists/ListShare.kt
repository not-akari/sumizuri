package com.sumizuri.app.data.lists

import com.sumizuri.app.data.model.Kind
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.addJsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray

// A title of a shared list with its note.
class SharedListTitle(val title: ListTitle, val note: String)

// A list as a file holds it. Extra is how many more titles the file had than a list can hold.
class SharedList(val name: String, val about: String, val titles: List<SharedListTitle>, val extra: Int)

// A list with its titles in order, as the content of a file of the app. A title keeps its name, its kind and its note, and never a source.
fun listData(list: ReadingList, items: List<ListItem>): JsonElement = buildJsonObject {
    put("name", list.name)
    if (list.about.isNotEmpty()) put("about", list.about)
    putJsonArray("titles") {
        for (item in items) {
            addJsonObject {
                put("name", item.title)
                put("kind", item.kind.code)
                if (item.note.isNotEmpty()) put("note", item.note)
            }
        }
    }
}

// Reads a shared list without trusting it: names and notes are cleaned and cut like typed ones, titles of a kind this app does not know or with no name are left out, the same title is kept once, and no more than a list holds is kept.
fun sharedListOf(data: JsonElement): SharedList? {
    val root = data as? JsonObject ?: return null
    val rows = root["titles"] as? JsonArray ?: return null
    val seen = HashSet<String>()
    val titles = ArrayList<SharedListTitle>()
    var extra = 0
    for (row in rows) {
        val item = row as? JsonObject ?: continue
        val code = (item["kind"] as? JsonPrimitive)?.intOrNull ?: continue
        val kind = Kind.entries.firstOrNull { it.code == code } ?: continue
        val title = ListTitle(textOf(item["name"]), kind)
        if (title.name.isEmpty() || !seen.add(title.key)) continue
        if (titles.size >= ListSizeLimit) {
            extra++
            continue
        }
        titles += SharedListTitle(title, cleanNote(textOf(item["note"]), ListNoteLimit))
    }
    return SharedList(
        cleanLine(textOf(root["name"]), ListNameLimit),
        cleanNote(textOf(root["about"]), ListAboutLimit),
        titles,
        extra,
    )
}

// The text of a value, or nothing when it is not plain text.
private fun textOf(value: JsonElement?): String = (value as? JsonPrimitive)?.takeIf { it.isString }?.content.orEmpty()

// A name no list has yet: the name itself, or with a number after it, cut so the number still fits.
internal fun freeName(base: String, taken: Collection<String>): String {
    val used = taken.mapTo(HashSet()) { it.lowercase() }
    if (base.lowercase() !in used) return base
    var number = 2
    while (true) {
        val end = " ($number)"
        val name = base.take(ListNameLimit - end.length).trimEnd() + end
        if (name.lowercase() !in used) return name
        number++
    }
}
