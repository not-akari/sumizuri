package com.sumizuri.app.data.account

import androidx.room3.withWriteTransaction
import com.sumizuri.app.data.backup.BackupRestorer
import com.sumizuri.app.data.backup.ImportedBackup
import com.sumizuri.app.data.backup.ImportedChapter
import com.sumizuri.app.data.backup.ImportedTitle
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.chapter.ChapterEntity
import com.sumizuri.app.data.db.progress.ProgressEntity
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.library.CategoryRepository
import com.sumizuri.app.data.library.ChapterCarry
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.flow.MutableStateFlow

// Writes what a merge settled into the library of this device: titles it does not have yet, whether each is in the library or a favorite, its shelves, and the marks on its chapters. Only what differs from this device is written, and the count of titles that changed comes back.
class SyncApply(
    private val db: AppDatabase,
    private val shelves: CategoryRepository,
    private val carry: ChapterCarry,
    private val restorer: BackupRestorer,
) {
    // The title read furthest on another device in the last sync, as its id and when, for offering to go on reading it here. Taken back once offered.
    val handoff = MutableStateFlow<Long?>(null)
    private var furthest: Pair<Long, Long>? = null

    suspend fun apply(merged: SyncState, local: SyncState, server: ImportedBackup?): Int {
        furthest = null
        val fromServer = server
            ?.titles
            .orEmpty()
            .filter { it.sourceId != null }
            .associateBy { syncKey(it.sourceId!!, it.url) }
        val shelfIds = db
            .categories()
            .all()
            .associate { it.name to it.id }
            .toMutableMap()
        var changed = 0
        for (key in merged.titles.keys + local.titles.keys) {
            val want = merged.titles[key] ?: TitleMark()
            val have = local.titles[key] ?: TitleMark()
            if (want == have) continue
            val (sourceId, url) = key.split("\n", limit = 2).let { it[0] to it.getOrElse(1) { "" } }
            val title = fromServer[key]
            // Each title is written in one transaction, which is many times quicker than a write for each mark on a big library.
            val wrote = db.withWriteTransaction {
                val id =
                    db.titles().findId(sourceId, url) ?: title?.let { restorer.insert(it, sourceId) }
                        ?: return@withWriteTransaction false
                write(id, want, have, title, shelfIds)
                true
            }
            if (!wrote) continue
            changed++
        }
        // A source removed on another device goes here too, and a newer version from another device comes with its code from the server's copy.
        val serverSources = server
            ?.extras
            ?.sources
            .orEmpty()
            .associateBy { it.id }
        for (id in merged.sources.keys + local.sources.keys) {
            val want = merged.sources[id]
            if (want == local.sources[id]) continue
            if (want ==
                null
            ) {
                db.sources().delete(id)
            } else {
                serverSources[id]?.takeIf { it.version == want }?.let { db.sources().put(it) }
            }
        }
        for (key in merged.settings.keys + local.settings.keys) {
            // A setting of this device is never changed by a sync.
            if (!syncsAcrossDevices(key)) continue
            val want = merged.settings[key]
            if (want == local.settings[key]) continue
            if (want == null) db.settings().delete(key) else db.settings().put(SettingEntity(key, want))
        }
        furthest?.let { (id, _) -> handoff.value = id }
        return changed
    }

    private suspend fun write(
        id: Long,
        want: TitleMark,
        have: TitleMark,
        title: ImportedTitle?,
        shelfIds: MutableMap<String, Long>,
    ) {
        if (want.inLibrary != have.inLibrary) db.titles().setInLibrary(id, want.inLibrary, nowMillis())
        if (want.favorite != have.favorite) db.titles().setFavoriteMany(listOf(id), want.favorite)
        if (want.shelves != have.shelves) {
            val add = (want.shelves - have.shelves)
                .mapNotNull { name ->
                    shelfIds[name]
                        ?: shelves.add(name)?.also { shelfIds[name] = it }
                }.toSet()
            val remove = (have.shelves - want.shelves).mapNotNull { shelfIds[it] }.toSet()
            shelves.change(listOf(id), add, remove)
        }
        if (want.chapters !=
            have.chapters
        ) {
            chapters(id, want.chapters, have.chapters, title?.chapters.orEmpty().associateBy { it.url })
        }
    }

    // The marks of the chapters that differ. A chapter this device has not listed yet is put in from what the server knows of it, marked as brought, so the source's own list takes its place later.
    private suspend fun chapters(
        id: Long,
        want: Map<String, ChapterMark>,
        have: Map<String, ChapterMark>,
        known: Map<String, ImportedChapter>,
    ) {
        val ids = db
            .chapters()
            .allOf(id)
            .associate { it.url to it.id }
            .toMutableMap()
        val missing = (want.keys - ids.keys).filter { want[it]?.empty == false }
        if (missing.isNotEmpty()) {
            val added = db.chapters().insertAll(
                missing.map { url ->
                    val chapter = known[url]
                    ChapterEntity(
                        titleId = id, url = url, number = chapter?.number ?: 0.0, name = chapter?.name,
                        publishedAt =
                        chapter?.uploadedAt ?: 0,
                        bookmarked = false,
                        season = chapter?.season, seasonName = chapter?.seasonName,
                        seasonCoverUrl = chapter
                            ?.seasonCoverUrl,
                    )
                },
            )
            missing.zip(added).forEach { (url, rowId) -> if (rowId != -1L) ids[url] = rowId }
            carry.mark(id)
        }
        for (url in want.keys + have.keys) {
            val w = want[url] ?: ChapterMark()
            val h = have[url] ?: ChapterMark()
            if (w == h) continue
            val chapterId = ids[url] ?: continue
            // Reading that went further elsewhere: a chapter finished there, or a page further on in one.
            val further = (w.read && !h.read) || (!w.read && (w.position ?: 0.0) > (h.position ?: 0.0))
            if (further) {
                val at = w.readAt ?: nowMillis()
                if (at > (furthest?.second ?: 0L)) furthest = id to at
            }
            when {
                w.read -> db.progress().put(ProgressEntity(chapterId, id, true, w.readAt ?: nowMillis(), null))
                w.position != null -> db.progress().put(ProgressEntity(chapterId, id, false, null, w.position))
                else -> db.progress().clear(chapterId)
            }
            if (w.bookmarked != h.bookmarked) db.chapters().setBookmarkedMany(listOf(chapterId), w.bookmarked)
        }
    }
}
