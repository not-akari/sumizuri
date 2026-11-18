package com.sumizuri.app.data.backup

import com.sumizuri.app.data.tracker.linkOf
import androidx.room3.withWriteTransaction
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.chapter.ChapterEntity
import com.sumizuri.app.data.db.progress.ProgressEntity
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.db.title.TitleEntity
import com.sumizuri.app.data.library.CategoryRepository
import com.sumizuri.app.data.library.ChapterCarry
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.library.SortRule
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.first

// Puts what a backup holds into the library: its shelves, and each title with its marks, bookmarks and shelves. A backup of this app first brings back its sources, repos, source settings, sign ins and, when asked, the settings. A title from a Sumizuri backup whose source is installed stays with that source. Any other title gets an id that says where it came from, so the person can move it to a source they have. Of the chapters only the ones that hold something of the person's are put in: a read mark, a place or a bookmark. They are marked as brought, so the chapters the source lists take their place the first time they are read, and the list of chapters is always the source's own and never an old copy from the backup.
class BackupRestorer(
    private val db: AppDatabase,
    private val shelves: CategoryRepository,
    private val sources: SourceRepository,
    private val carry: ChapterCarry,
) {
    suspend fun restore(backup: ImportedBackup, onProgress: (done: Int, total: Int) -> Unit, isCancelled: () -> Boolean, withSettings: Boolean = true): RestoreResult {
        backup.extras?.let { restoreExtras(it, withSettings) }
        val shelfIds = shelfIdsOf(backup)
        val installed = sources.installed.first().filter { it.enabled }
        var added = 0
        var skipped = 0
        var failed = 0
        var cancelled = false
        val candidates = ArrayList<SourceCandidate>()
        onProgress(0, backup.titles.size)
        for ((index, title) in backup.titles.withIndex()) {
            if (isCancelled()) {
                cancelled = true
                break
            }
            try {
                if (title.name.isBlank() || title.url.isBlank()) {
                    failed++
                } else {
                    // A backup of this app names the source by its id, and an older one by its name.
                    val own = if (backup.app == BackupApp.Sumizuri) {
                        title.sourceId?.takeIf { id -> installed.any { it.id == id } } ?: installed.firstOrNull { it.name.equals(title.sourceName, ignoreCase = true) }?.id
                    } else {
                        null
                    }
                    val sourceId = own ?: title.sourceId?.takeIf { ImportedSources.isImported(it) } ?: ImportedSources.idOf(backup.app, title.sourceName)
                    val existing = db.titles().findId(sourceId, title.url)
                    // A title from another app that is there already was imported before, so it is left as it is.
                    if (existing != null && backup.app != BackupApp.Sumizuri) {
                        skipped++
                    } else {
                        // One title is written at once, which is much quicker than a write for each row and leaves no title half put in.
                        val id = db.withWriteTransaction {
                            val id = existing ?: insert(title, sourceId)
                            fill(id, title, shelfIds)
                            id
                        }
                        if (existing == null) added++ else skipped++
                        if (existing == null && own == null) candidates += SourceCandidate(id, title.kind, title.url, title.sourceName)
                    }
                }
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                failed++
                AppLog.warn("backup", "could not restore ${title.name}, ${error.message}")
            }
            onProgress(index + 1, backup.titles.size)
        }
        AppLog.info("backup", "${backup.app.name} backup: $added added, $skipped already there, $failed failed")
        return RestoreResult(added, skipped, failed, candidates, cancelled)
    }

    // Sources, repos, source values and sign ins are added where this device has none, so nothing it has is changed. The settings of the backup replace the ones here when asked.
    internal suspend fun restoreExtras(extras: BackupExtras, withSettings: Boolean) {
        for (source in extras.sources) if (db.sources().get(source.id) == null) db.sources().put(source)
        val repos = db
            .repos()
            .observeAll()
            .first()
            .map { it.url }
            .toSet()
        for (repo in extras.repos) if (repo.url !in repos) db.repos().put(repo)
        for (value in extras.values) if (db.values().get(value.scope, value.area, value.key) == null) db.values().put(value)
        for (cookie in extras.cookies) db.cookies().put(cookie)
        if (withSettings) for ((name, value) in extras.settings) db.settings().put(SettingEntity(name, value))
        AppLog.info("backup", "restored ${extras.sources.size} sources, ${extras.repos.size} repos, ${extras.values.size} source values, ${extras.cookies.size} sign ins, ${if (withSettings) extras.settings.size else 0} settings")
    }

    internal suspend fun insert(title: ImportedTitle, sourceId: String): Long {
        val now = nowMillis()
        return db.titles().insert(
            TitleEntity(
                sourceId = sourceId,
                externalId = title.url,
                name = title.name,
                kind = title.kind.code,
                coverUrl = title.coverUrl,
                status = (title.status ?: Status.Unknown).code,
                summary = title.summary,
                author = title.author,
                genres = title.genres.joinToString("\n"),
                inLibrary = title.inLibrary,
                addedAt = title.addedAt ?: now,
                updatedAt = now,
                rating = title.rating,
                webUrl = title.webUrl,
                favorite = title.favorite,
            ),
        )
    }

    // Adds the chapters of the backup that hold something of the person's and that the title does not have, with their seasons, the read marks it does not have, the bookmarks, and the shelves.
    private suspend fun fill(id: Long, title: ImportedTitle, shelfIds: Map<String, Long>) {
        val kept = title.chapters.filter { it.read || it.position != null || it.bookmarked }
        if (kept.isNotEmpty()) {
            db.chapters().insertAll(
                kept.map {
                    ChapterEntity(titleId = id, url = it.url, number = it.number, name = it.name, publishedAt = it.uploadedAt, bookmarked = false, season = it.season, seasonName = it.seasonName, seasonCoverUrl = it.seasonCoverUrl)
                },
            )
            carry.mark(id)
        }
        // Chapters that were there already take the season the backup knows.
        for (chapter in kept) if (chapter.season != null) db.chapters().setSeason(id, chapter.url, chapter.season, chapter.seasonName, chapter.seasonCoverUrl)
        val idByUrl = db.chapters().allOf(id).associate { it.url to it.id }
        val marked = db
            .progress()
            .allOf(id)
            .filter { it.read }
            .map { it.chapterId }
            .toSet()
        db.progress().putAll(
            kept.mapNotNull { chapter ->
                val chapterId = idByUrl[chapter.url] ?: return@mapNotNull null
                if (chapterId in marked || !(chapter.read || chapter.position != null)) return@mapNotNull null
                ProgressEntity(chapterId, id, chapter.read, if (chapter.read) chapter.readAt else null, if (chapter.read) null else chapter.position)
            },
        )
        val bookmarked = kept.filter { it.bookmarked }.mapNotNull { idByUrl[it.url] }
        if (bookmarked.isNotEmpty()) db.chapters().setBookmarkedMany(bookmarked, true)
        val on = title.shelves.mapNotNull { name -> shelfIds[key(name, title.kind.code)] ?: shelfIds[key(name, -1)] }.toSet()
        if (on.isNotEmpty()) shelves.change(listOf(id), on, emptySet())
        // The trackers of the title, where it has no link to them yet.
        for (track in title.trackers) {
            if (db.trackerLinks().get(id, track.tracker) == null) db.trackerLinks().put(track.linkOf(id, title.kind.code))
        }
    }

    private fun key(name: String, kind: Int) = name.trim().lowercase() + "|" + kind

    // The id of a shelf for each name and kind in the backup, keyed by the lower case name and the code of the kind, or -1 for a shelf of every kind. A whole shelf of this app is made as it was, rules and all. A shelf from another app is made for each kind of title that uses it, so shelves stay apart by kind. A shelf that is there already for the kind, or for every kind, is used.
    private suspend fun shelfIdsOf(backup: ImportedBackup): Map<String, Long> {
        val existing = shelves.categories.first()
        val ids = mutableMapOf<String, Long>()
        for (shelf in backup.shelves) {
            val stored = shelf.stored ?: continue
            val kind = stored.kind.takeIf { it >= 0 }?.let { Kind.fromCode(it) }
            val have = existing.firstOrNull { it.name.trim().equals(stored.name, ignoreCase = true) && it.kind == kind }
            ids[key(stored.name, stored.kind)] = have?.id ?: db.categories().insert(stored.copy(id = 0, sortOrder = db.categories().lastOrder() + 1))
        }
        val kindsOf = backup.titles
            .flatMap { title -> title.shelves.map { it.trim().lowercase() to title.kind } }
            .groupBy({ it.first }, { it.second })
            .mapValues { it.value.toSet() }
        val wanted = (backup.shelves.filter { it.stored == null } + backup.titles.flatMap { it.shelves }.map { ImportedShelf(it) }).distinctBy { it.name.trim().lowercase() }
        for (shelf in wanted) {
            val name = shelf.name.trim()
            if (name.isEmpty()) continue
            // A shelf no title uses has no kind to take, so it is for every kind.
            val kinds: List<Kind?> = kindsOf[name.lowercase()]?.toList() ?: listOf(null)
            for (kind in kinds) {
                if (key(name, kind?.code ?: -1) in ids || key(name, -1) in ids) continue
                val have = existing.firstOrNull { it.name.trim().equals(name, ignoreCase = true) && (it.kind == kind || it.kind == null) }
                if (have != null) {
                    ids[key(name, kind?.code ?: -1)] = have.id
                    continue
                }
                val id = shelves.add(name, kind) ?: continue
                ids[key(name, kind?.code ?: -1)] = id
                if (shelf.excludeFromUpdate) shelves.setExcluded(id, true)
                if (shelf.sort != null || shelf.status != null) shelves.setRule(id, shelf.sort?.let { SortRule(it, shelf.ascending) }, shelf.status)
            }
        }
        return ids
    }
}
