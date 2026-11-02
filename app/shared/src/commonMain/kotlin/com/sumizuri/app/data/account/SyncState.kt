package com.sumizuri.app.data.account

import com.sumizuri.app.data.backup.ImportedBackup
import kotlinx.serialization.Serializable

// What sync keeps of one chapter: the person's own marks on it, never its name or pictures.
@Serializable
data class ChapterMark(
    val read: Boolean = false,
    val readAt: Long? = null,
    val position: Double? = null,
    val bookmarked: Boolean = false,
) {
    val empty: Boolean get() = !read && position == null && !bookmarked
}

// What sync keeps of one title: whether it is in the library, a favorite, its shelves by name, and the chapters that hold a mark.
@Serializable
data class TitleMark(
    val inLibrary: Boolean = false,
    val favorite: Boolean = false,
    val shelves: Set<String> = emptySet(),
    val chapters: Map<String, ChapterMark> = emptyMap(),
)

// The whole library as sync sees it, by title key, with the settings and the versions of the sources when they sync. A title that is missing counts as one with no marks at all.
@Serializable
data class SyncState(
    val titles: Map<String, TitleMark> = emptyMap(),
    val settings: Map<String, String> = emptyMap(),
    val sources: Map<String, Int> = emptyMap(),
)

// A case where this device and the server both changed one value since they last agreed, by the name of the title, setting or source, and what kind of value it was.
@Serializable
data class SyncConflict(val name: String, val kind: String)

// Only the parts that sync, as the state both sides agreed on keeps them. A part that is off is left out, so turning it on later joins both sides rather than taking what one side lacks as removed.
fun SyncState.only(parts: SyncParts): SyncState = SyncState(
    titles = titles.mapValues { (_, title) ->
        title.copy(
            shelves = if (parts.shelves) title.shelves else emptySet(),
            chapters = if (parts.progress) title.chapters else emptyMap(),
        )
    },
    settings = if (parts.settings) settings else emptyMap(),
    sources = if (parts.sources) sources else emptyMap(),
)

// A title is the same on every device when its source and its address on the source are the same.
fun syncKey(sourceId: String, url: String): String = sourceId + "\n" + url

// The sync view of a backup of this app.
fun stateOf(backup: ImportedBackup): SyncState = SyncState(
    backup.titles
        .mapNotNull { title ->
            val source = title.sourceId ?: return@mapNotNull null
            syncKey(source, title.url) to TitleMark(
                inLibrary = title.inLibrary,
                favorite = title.favorite,
                shelves = title.shelves.toSet(),
                chapters = title.chapters
                    .mapNotNull { chapter ->
                        val mark =
                            ChapterMark(
                                chapter.read,
                                if (chapter.read) chapter.readAt else null,
                                if (chapter.read) null else chapter.position,
                                chapter.bookmarked,
                            )
                        if (mark.empty) null else chapter.url to mark
                    }.toMap(),
            )
        }.toMap(),
    // Only the settings that go across devices take part, so the look and the screen of each device stay its own.
    backup.extras
        ?.settings
        .orEmpty()
        .filterKeys(::syncsAcrossDevices),
    backup.extras
        ?.sources
        .orEmpty()
        .associate { it.id to it.version },
)
