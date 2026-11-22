package com.sumizuri.app.data.backup

import com.sumizuri.app.data.db.category.CategoryEntity
import com.sumizuri.app.data.db.cookie.CookieEntity
import com.sumizuri.app.data.db.repo.RepoEntity
import com.sumizuri.app.data.db.source.SourceEntity
import com.sumizuri.app.data.db.value.SourceValueEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.library.LibrarySortField
import com.sumizuri.app.data.tracker.ImportedTrack

// The apps a backup can come from.
enum class BackupApp { Sumizuri, Mihon, Mangayomi, Boundless }

// A chapter of a title in a backup, with what the reader did with it. The times are epoch milliseconds, and 0 means unknown.
data class ImportedChapter(
    val url: String,
    val number: Double,
    val name: String?,
    val uploadedAt: Long,
    val read: Boolean,
    val readAt: Long?,
    // How far through the chapter the reader got, from 0 to 1, or null when the backup does not say.
    val position: Double?,
    val bookmarked: Boolean,
    // The season of the chapter, from backups of this app.
    val season: String? = null,
    val seasonName: String? = null,
    val seasonCoverUrl: String? = null,
)

// A title of a backup, with the name of the source it came from and the shelves it was on.
data class ImportedTitle(
    val name: String,
    val url: String,
    val coverUrl: String?,
    val kind: Kind,
    val favorite: Boolean,
    val sourceName: String?,
    // The site of the source, when the backup knows it. It helps to find the source among the installed ones.
    val sourceUrl: String?,
    val shelves: List<String>,
    val chapters: List<ImportedChapter>,
    // What backups of this app add: the source it is from, whether it is in the library, and its details.
    val sourceId: String? = null,
    val inLibrary: Boolean = true,
    val addedAt: Long? = null,
    val status: Status? = null,
    val summary: String = "",
    val author: String = "",
    val genres: List<String> = emptyList(),
    val rating: Double? = null,
    val webUrl: String? = null,
    // The trackers the title is linked to, from backups of this app.
    val trackers: List<ImportedTrack> = emptyList(),
)

// A shelf of a backup. A rule is only there when the backup had one switched on.
data class ImportedShelf(
    val name: String,
    val excludeFromUpdate: Boolean = false,
    val sort: LibrarySortField? = null,
    val ascending: Boolean = true,
    val status: Status? = null,
    // The whole shelf as this app keeps it, rules and kind included, from backups of this app.
    val stored: CategoryEntity? = null,
)

// Everything a backup holds that this app can use.
class ImportedBackup(
    val app: BackupApp,
    val titles: List<ImportedTitle>,
    val shelves: List<ImportedShelf>,
    val extras: BackupExtras? = null,
)

// What a backup of this app holds beyond the titles and shelves, each part empty when the backup left it out.
class BackupExtras(
    val sources: List<SourceEntity> = emptyList(),
    val repos: List<RepoEntity> = emptyList(),
    val values: List<SourceValueEntity> = emptyList(),
    val settings: Map<String, String> = emptyMap(),
    val cookies: List<CookieEntity> = emptyList(),
)
