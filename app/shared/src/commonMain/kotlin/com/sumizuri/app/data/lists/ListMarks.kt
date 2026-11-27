package com.sumizuri.app.data.lists

import androidx.room3.withWriteTransaction
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.lists.ReadingListEntity
import com.sumizuri.app.data.db.lists.ReadingListItemEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.nowMillis
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.addJsonObject
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import kotlin.random.Random

// A title of a list as backups and sync keep it: its name, kind and note.
@Serializable
data class ListMarkItem(val title: String, val kind: Int, val note: String = "")

// A list as backups and sync keep it: its name, the line about it, its place among the lists, when it last changed, and its titles in order.
@Serializable
data class ListMark(
    val name: String,
    val about: String = "",
    val order: Int = 0,
    val changed: Long = 0,
    val items: List<ListMarkItem> = emptyList(),
)

// A new id for a list, the same on every device it reaches.
fun newListUid(): String = Random.nextBytes(12).joinToString("") { (it.toInt() and 0xff).toString(16).padStart(2, '0') }

// Gives each list that has no id yet one, such as the lists made before ids came.
suspend fun ensureListUids(db: AppDatabase) {
    for (list in db.lists().all()) if (list.uid.isEmpty()) db.lists().setUid(list.id, newListUid())
}

// Every list of the profile by its id.
suspend fun listMarksOf(db: AppDatabase): Map<String, ListMark> {
    ensureListUids(db)
    val items = db.lists().allItems().groupBy { it.listId }
    return db.lists().all().associate { list ->
        list.uid to ListMark(
            list.name,
            list.about,
            list.sortOrder,
            list.changed,
            items[list.id].orEmpty().map { ListMarkItem(it.title, it.kind, it.note) },
        )
    }
}

// Makes the lists of the profile what is wanted, writing only the ones that differ from what it has. A list that is no longer wanted is deleted, and one with a name another list here has gets a free name.
suspend fun applyListMarks(db: AppDatabase, want: Map<String, ListMark>, have: Map<String, ListMark>): Int {
    var changed = 0
    for (uid in want.keys + have.keys) {
        val wanted = want[uid]
        if (wanted == have[uid]) continue
        db.withWriteTransaction {
            val current = db.lists().byUid(uid)
            if (wanted == null) {
                current?.let { db.lists().delete(it.id) }
                return@withWriteTransaction
            }
            val taken = db
                .lists()
                .all()
                .filter { it.uid != uid }
                .map { it.name }
            val name = freeName(cleanLine(wanted.name, ListNameLimit).ifEmpty { "List" }, taken)
            val about = cleanNote(wanted.about, ListAboutLimit)
            val id = if (current == null) {
                db.lists().insert(
                    ReadingListEntity(
                        uid = uid,
                        name = name,
                        about = about,
                        sortOrder = wanted.order,
                        made = nowMillis(),
                        changed = wanted.changed,
                    ),
                )
            } else {
                db.lists().replace(current.id, name, about, wanted.order, wanted.changed)
                db.lists().clearItems(current.id)
                current.id
            }
            val seen = HashSet<String>()
            val rows = wanted.items
                .mapNotNull { item ->
                    val kind = Kind.entries.firstOrNull { it.code == item.kind } ?: return@mapNotNull null
                    val title = ListTitle(item.title, kind)
                    if (title.name.isEmpty() || !seen.add(title.key)) return@mapNotNull null
                    title to cleanNote(item.note, ListNoteLimit)
                }.take(ListSizeLimit)
                .mapIndexed { index, (title, note) ->
                    ReadingListItemEntity(
                        listId = id,
                        title = title.name,
                        kind = title.kind.code,
                        note = note,
                        position = index,
                        matchKey = title.key,
                    )
                }
            if (rows.isNotEmpty()) db.lists().insertItems(rows)
        }
        changed++
    }
    return changed
}

// The lists of a profile as the part of a backup that holds them.
fun listsJson(marks: Map<String, ListMark>): JsonElement = buildJsonArray {
    for ((uid, list) in marks) {
        addJsonObject {
            put("id", uid)
            put("name", list.name)
            if (list.about.isNotEmpty()) put("about", list.about)
            put("order", list.order)
            put("changed", list.changed)
            putJsonArray("titles") {
                for (item in list.items) {
                    addJsonObject {
                        put("name", item.title)
                        put("kind", item.kind)
                        if (item.note.isNotEmpty()) put("note", item.note)
                    }
                }
            }
        }
    }
}

// The lists of a backup, read without trusting them: an id and a name are needed, text is cleaned and cut like typed text, and no more lists or titles are kept than the app holds.
fun listsOf(element: JsonElement?): Map<String, ListMark> {
    val rows = element as? JsonArray ?: return emptyMap()
    val out = LinkedHashMap<String, ListMark>()
    for (row in rows) {
        if (out.size >= ListCountLimit) break
        val list = row as? JsonObject ?: continue
        val uid = text(list["id"]).filter { it.isLetterOrDigit() }.take(64)
        val name = cleanLine(text(list["name"]), ListNameLimit)
        if (uid.isEmpty() || name.isEmpty() || uid in out) continue
        val items = (list["titles"] as? JsonArray)
            .orEmpty()
            .mapNotNull { element ->
                val item = element as? JsonObject ?: return@mapNotNull null
                val kind = (item["kind"] as? JsonPrimitive)?.intOrNull ?: return@mapNotNull null
                ListMarkItem(
                    cleanLine(text(item["name"]), TitleNameLimit),
                    kind,
                    cleanNote(text(item["note"]), ListNoteLimit),
                )
            }.filter { it.title.isNotEmpty() }
            .take(ListSizeLimit)
        out[uid] = ListMark(
            name,
            cleanNote(text(list["about"]), ListAboutLimit),
            (list["order"] as? JsonPrimitive)?.intOrNull ?: out.size,
            (list["changed"] as? JsonPrimitive)?.longOrNull ?: 0,
            items,
        )
    }
    return out
}

private fun text(value: JsonElement?): String = (value as? JsonPrimitive)?.takeIf { it.isString }?.content.orEmpty()
