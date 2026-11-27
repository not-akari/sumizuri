package com.sumizuri.app.data.account

// What sync takes part in, from the switches of What syncs. The library itself always does.
data class SyncParts(
    val progress: Boolean,
    val shelves: Boolean,
    val settings: Boolean,
    val sources: Boolean = true,
    val lists: Boolean = true,
)

// The kinds of value a conflict can be about, as the details page names them.
object ConflictKind {
    const val Library = "library"
    const val Favorite = "favorite"
    const val Read = "read"
    const val Place = "place"
    const val Bookmark = "bookmark"
    const val Shelves = "shelves"
    const val Setting = "setting"
    const val Source = "source"
    const val List = "list"
}

// Joins this device and the server by what each changed since they last agreed. A side that left a value as it was takes the other side's change. When both changed one value, the merge keeps what is safer to keep: in the library, a favorite, read, bookmarked, the further place, the shelves of both, the newer version of a source, and this device's setting. Each such case is told to onConflict with the key it was found under.
object SyncMerge {
    fun merge(
        local: SyncState,
        server: SyncState,
        base: SyncState,
        parts: SyncParts,
        onConflict: (key: String, kind: String) -> Unit = { _, _ -> },
    ): SyncState {
        val merged = HashMap<String, TitleMark>()
        for (key in local.titles.keys + server.titles.keys + base.titles.keys) {
            val l = local.titles[key] ?: TitleMark()
            val s = server.titles[key] ?: TitleMark()
            val b = base.titles[key] ?: TitleMark()
            val told = { kind: String -> onConflict(key, kind) }
            val title = TitleMark(
                inLibrary = pick(
                    l.inLibrary,
                    s.inLibrary,
                    b.inLibrary,
                    { told(ConflictKind.Library) },
                ) { x, y -> x || y },
                favorite = pick(l.favorite, s.favorite, b.favorite, { told(ConflictKind.Favorite) }) { x, y -> x || y },
                // A part that does not sync stays as this device has it.
                shelves = if (parts.shelves) {
                    sets(
                        l.shelves,
                        s.shelves,
                        b.shelves,
                    ) { told(ConflictKind.Shelves) }
                } else {
                    l.shelves
                },
                chapters = if (parts.progress) chapters(l.chapters, s.chapters, b.chapters, told) else l.chapters,
            )
            if (title.inLibrary || title.favorite || title.shelves.isNotEmpty() ||
                title.chapters.isNotEmpty()
            ) {
                merged[key] = title
            }
        }
        val settings = if (parts.settings) {
            values(local.settings, server.settings, base.settings, {
                onConflict(it, ConflictKind.Setting)
            }) { mine, _ -> mine }
        } else {
            local.settings
        }
        val sources = if (parts.sources) {
            values(local.sources, server.sources, base.sources, {
                onConflict(it, ConflictKind.Source)
            }) { x, y -> maxOf(x ?: 0, y ?: 0) }
        } else {
            local.sources
        }
        // A list changed on both sides keeps the newer change, and one changed on one side and deleted on the other is kept.
        val lists = if (parts.lists) {
            values(local.lists, server.lists, base.lists, {
                onConflict(it, ConflictKind.List)
            }) { mine, theirs ->
                when {
                    mine == null -> theirs
                    theirs == null -> mine
                    else -> if (theirs.changed > mine.changed) theirs else mine
                }
            }
        } else {
            local.lists
        }
        return SyncState(merged, settings, sources, lists)
    }

    private fun chapters(
        local: Map<String, ChapterMark>,
        server: Map<String, ChapterMark>,
        base: Map<String, ChapterMark>,
        told: (String) -> Unit,
    ): Map<String, ChapterMark> {
        val out = HashMap<String, ChapterMark>()
        for (url in local.keys + server.keys + base.keys) {
            val l = local[url] ?: ChapterMark()
            val s = server[url] ?: ChapterMark()
            val b = base[url] ?: ChapterMark()
            val read = pick(l.read, s.read, b.read, { told(ConflictKind.Read) }) { x, y -> x || y }
            val readAt = if (read) {
                listOfNotNull(
                    l.readAt.takeIf { l.read },
                    s.readAt.takeIf { s.read },
                ).maxOrNull()
            } else {
                null
            }
            val position = if (read) {
                null
            } else {
                pick(
                    l.position,
                    s.position,
                    b.position,
                    { told(ConflictKind.Place) },
                ) { x, y -> maxOf(x ?: 0.0, y ?: 0.0) }
            }
            val mark =
                ChapterMark(
                    read,
                    readAt,
                    position,
                    pick(l.bookmarked, s.bookmarked, b.bookmarked, { told(ConflictKind.Bookmark) }) { x, y ->
                        x ||
                            y
                    },
                )
            if (!mark.empty) out[url] = mark
        }
        return out
    }

    // A map of values, each on its own, such as the settings or the versions of the sources. A value that is gone from a side is null there.
    private fun <T> values(
        local: Map<String, T>,
        server: Map<String, T>,
        base: Map<String, T>,
        told: (String) -> Unit,
        both: (T?, T?) -> T?,
    ): Map<String, T> {
        val out = HashMap<String, T>()
        for (key in local.keys + server.keys + base.keys) {
            pick(local[key], server[key], base[key], { told(key) }, both)?.let {
                out[key] =
                    it
            }
        }
        return out
    }

    // A value as this device and the server have it now and as they last agreed on it.
    private fun <T> pick(local: T, server: T, base: T, told: () -> Unit, both: (T, T) -> T): T = when {
        local == server -> local
        local == base -> server
        server == base -> local
        else -> both(local, server).also { told() }
    }

    // A name stays on a set when both sides have it, or when the side that does not has never had it since they last agreed.
    private fun sets(local: Set<String>, server: Set<String>, base: Set<String>, told: () -> Unit): Set<String> {
        if (local != base && server != base && local != server) told()
        return (local + server).filterTo(HashSet()) { name ->
            (name in local && name in server) ||
                (name in local && name !in base) ||
                (name in server && name !in base)
        }
    }
}
