package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.tracker.LibraryTitle
import com.sumizuri.app.data.model.Kind

// One title of the library found on a tracker by its AniList id, with its entry there when it has one.
internal class CrossFound(val title: LibraryTitle, val media: TrackerMedia, val entry: RemoteEntry?)

// Finds titles of the library that are linked to AniList on another tracker by their AniList ids, in a few requests and with no guessing by name. Their entries there are read in one go, so a title already on the list keeps how it stands. Gives nothing for AniList itself or a tracker that cannot look ids up.
internal suspend fun crossFind(
    db: AppDatabase,
    api: TrackerApi,
    tracker: TrackerId,
    account: TrackerAccount,
    titles: List<LibraryTitle>,
): List<CrossFound> {
    if (tracker == TrackerId.AniList || titles.isEmpty()) return emptyList()
    val onAniList = db
        .trackerLinks()
        .allOf(TrackerId.AniList.id)
        .filter { !it.gone }
        .associateBy { it.titleId }
    val pairs = titles.mapNotNull { title ->
        onAniList[title.id]?.let { link ->
            AniListRef(
                link.remoteId,
                Kind.fromCode(title.kind),
                link.remoteName,
                link.remoteCover,
                link.remoteTotal,
            ) to
                title
        }
    }
    if (pairs.isEmpty()) return emptyList()
    val found = api.fromAniList(account, pairs.map { it.first }).orEmpty()
    if (found.isEmpty()) return emptyList()
    val entries = api.entries(account, found.values.map { it.id }.distinct())
    return pairs.mapNotNull { (ref, title) -> found[ref.id]?.let { CrossFound(title, it, entries[it.id]) } }
}
