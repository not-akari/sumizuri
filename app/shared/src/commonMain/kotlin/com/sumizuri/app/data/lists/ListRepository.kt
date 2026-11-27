package com.sumizuri.app.data.lists

import androidx.room3.withWriteTransaction
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.lists.ReadingListEntity
import com.sumizuri.app.data.db.lists.ReadingListItemEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

// The longest a name, a line about a list and a note may be, so a shared list stays small.
const val ListNameLimit = 80
const val ListAboutLimit = 300
const val ListNoteLimit = 300

// The most titles one list holds, and the most lists there are.
const val ListSizeLimit = 500
const val ListCountLimit = 500

// How many covers stand for a list.
const val FrontCount = 3

// Keys are sent to the database in parts, since a query takes only so many.
private const val Chunk = 500

// What became of a list that was asked for.
sealed interface MakeResult {
    data class Made(val id: Long) : MakeResult
    data object Empty : MakeResult
    data object Taken : MakeResult
    data object Full : MakeResult
}

// How many titles went on a list, and how many did not fit.
data class Added(val added: Int, val leftOut: Int)

// A shared list saved as a new one.
data class Imported(val id: Long, val name: String, val added: Int)

// The lists of titles: making, naming, ordering and deleting them, and putting titles on them with a note each. Every write waits for the one before, so two quick taps never put a title on twice.
class ListRepository(private val db: AppDatabase) {
    private val dao get() = db.lists()
    private val writing = Mutex()

    val lists: Flow<List<ReadingList>> = combine(dao.observeAll(), dao.observeCounts()) { rows, counts ->
        val sizes = counts.associate { it.listId to it.items }
        rows.map { it.toList(sizes[it.id] ?: 0) }
    }

    // How many of the titles each list holds, asked only about these titles.
    fun holding(keys: List<String>): Flow<Map<Long, Int>> {
        val wanted = keys.distinct()
        if (wanted.isEmpty()) return flowOf(emptyMap())
        val parts = wanted.chunked(Chunk).map { dao.observeHolding(it) }
        return combine(parts) { found ->
            found
                .asList()
                .flatten()
                .groupBy { it.listId }
                .mapValues { (_, rows) -> rows.distinctBy { it.matchKey }.size }
        }
    }

    fun list(id: Long): Flow<ReadingList?> =
        combine(dao.observe(id), dao.observeItems(id)) { row, items -> row?.toList(items.size) }

    fun items(id: Long): Flow<List<ListItem>> = dao.observeItems(id).map { rows -> rows.map { it.toItem() } }

    // The first titles of each list, whose covers stand for it on the page of the lists.
    val fronts: Flow<Map<Long, List<ListItem>>> =
        dao.observeFronts(FrontCount).map { rows -> rows.groupBy({ it.listId }, { it.toItem() }) }

    private fun ReadingListItemEntity.toItem() = ListItem(id, title, Kind.fromCode(kind), note, matchKey)

    // Makes a list at the end, unless the name is empty, another list has it, or there are as many lists as there can be.
    suspend fun create(name: String, about: String = ""): MakeResult = writing.withLock {
        val clean = cleanLine(name, ListNameLimit)
        val all = dao.all()
        when {
            clean.isEmpty() -> MakeResult.Empty

            all.any { it.name.equals(clean, ignoreCase = true) } -> MakeResult.Taken

            all.size >= ListCountLimit -> MakeResult.Full

            else -> {
                val now = nowMillis()
                val row = ReadingListEntity(
                    uid = newListUid(),
                    name = clean,
                    about = cleanNote(about, ListAboutLimit),
                    sortOrder = dao.lastOrder() + 1,
                    made = now,
                    changed = now,
                )
                MakeResult.Made(dao.insert(row))
            }
        }
    }

    // Gives a list a new name and line about it, and keeps the old name when the new one is empty or taken.
    suspend fun describe(id: Long, name: String, about: String) = writing.withLock {
        val clean = cleanLine(name, ListNameLimit)
        val all = dao.all()
        val current = all.firstOrNull { it.id == id } ?: return@withLock
        val taken = all.any { it.id != id && it.name.equals(clean, ignoreCase = true) }
        val kept = if (clean.isEmpty() || taken) current.name else clean
        dao.describe(id, kept, cleanNote(about, ListAboutLimit), nowMillis())
    }

    suspend fun delete(id: Long) = writing.withLock { dao.delete(id) }

    // Saves a shared list as a new one, under a free name, and gives its id, its name and how many titles went on. Null when there are as many lists as there can be.
    suspend fun import(shared: SharedList, fallbackName: String): Imported? = writing.withLock {
        val all = dao.all()
        if (all.size >= ListCountLimit) return@withLock null
        val name = freeName(shared.name.ifEmpty { cleanLine(fallbackName, ListNameLimit) }, all.map { it.name })
        val now = nowMillis()
        val id = dao.insert(
            ReadingListEntity(
                uid = newListUid(),
                name = name,
                about = shared.about,
                sortOrder = dao.lastOrder() + 1,
                made = now,
                changed = now,
            ),
        )
        val notes = shared.titles.associate { it.title.key to it.note }
        val added = addLocked(id, shared.titles.map { it.title }, notes)
        Imported(id, name, added.added)
    }

    suspend fun reorder(ids: List<Long>) = writing.withLock {
        val now = nowMillis()
        db.withWriteTransaction { ids.forEachIndexed { order, list -> dao.setOrder(list, order, now) } }
    }

    // Puts titles at the end of a list, leaving out the ones it holds already and the ones there is no room for.
    suspend fun add(listId: Long, titles: List<ListTitle>, notes: Map<String, String> = emptyMap()): Added =
        writing.withLock { addLocked(listId, titles, notes) }

    private suspend fun addLocked(listId: Long, titles: List<ListTitle>, notes: Map<String, String>): Added {
        val have = dao.keysOf(listId).toHashSet()
        val fresh = titles.filter { it.name.isNotEmpty() }.distinctBy { it.key }.filter { it.key !in have }
        val room = (ListSizeLimit - have.size).coerceAtLeast(0)
        val taken = fresh.take(room)
        if (taken.isEmpty()) return Added(0, fresh.size)
        val start = dao.lastPosition(listId) + 1
        val rows = taken.mapIndexed { index, title ->
            ReadingListItemEntity(
                listId = listId,
                title = title.name,
                kind = title.kind.code,
                note = cleanNote(notes[title.key].orEmpty(), ListNoteLimit),
                position = start + index,
                matchKey = title.key,
            )
        }
        db.withWriteTransaction {
            dao.insertItems(rows)
            dao.touch(listId, nowMillis())
        }
        return Added(taken.size, fresh.size - taken.size)
    }

    // Puts the titles on one list, or takes them all off it, and gives what went on.
    suspend fun toggle(listId: Long, titles: List<ListTitle>, on: Boolean): Added = writing.withLock {
        if (on) return@withLock addLocked(listId, titles, emptyMap())
        val keys = titles.map { it.key }.distinct()
        db.withWriteTransaction {
            for (part in keys.chunked(Chunk)) dao.deleteKeys(listId, part)
            dao.renumber(listId)
            dao.touch(listId, nowMillis())
        }
        Added(0, 0)
    }

    suspend fun removeItems(listId: Long, ids: List<Long>) = writing.withLock {
        db.withWriteTransaction {
            for (part in ids.chunked(Chunk)) dao.deleteItems(part)
            dao.renumber(listId)
            dao.touch(listId, nowMillis())
        }
    }

    // Puts the titles of a list in the order given.
    suspend fun moveItems(listId: Long, ids: List<Long>) = writing.withLock {
        db.withWriteTransaction {
            ids.forEachIndexed { position, item -> dao.setPosition(item, position) }
            dao.touch(listId, nowMillis())
        }
    }

    suspend fun setNote(listId: Long, itemId: Long, note: String) = writing.withLock {
        dao.setNote(itemId, cleanNote(note, ListNoteLimit))
        dao.touch(listId, nowMillis())
    }

    private fun ReadingListEntity.toList(size: Int) = ReadingList(id, name, about, size, changed)
}
