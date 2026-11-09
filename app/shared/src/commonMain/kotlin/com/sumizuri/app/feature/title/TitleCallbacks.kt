package com.sumizuri.app.feature.title

import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.Facet
import com.sumizuri.app.feature.comments.CommentsTarget

// The titles whose page last showed their volumes, so the page opens on them again while the app runs.
internal object VolumeViews {
    private val shown = HashSet<Long>()

    fun remember(titleId: Long, volumes: Boolean) {
        if (volumes) shown += titleId else shown -= titleId
    }

    fun showing(titleId: Long): Boolean = titleId in shown
}

// What one chapter row can ask for.
data class ChapterCallbacks(
    val onOpen: (Long) -> Unit,
    val onToggleRead: (Long, Boolean) -> Unit,
    val onToggleBookmark: (Long, Boolean) -> Unit,
    // A tap picks or drops the chapter while others are picked, and a long press starts the picking.
    val onSelect: (Long) -> Unit,
)

// What the bar over a selection can ask for.
class SelectionCallbacks(
    val onClose: () -> Unit,
    val onSelectAll: () -> Unit,
    val onInvert: () -> Unit,
    val onMarkRead: (Boolean) -> Unit,
    val onBookmark: (Boolean) -> Unit,
    val onMarkBelowRead: () -> Unit,
)

// Everything the title page can ask for, so the page is given a few things and not thirty.
data class TitleCallbacks(
    val onBack: () -> Unit,
    val onRefresh: () -> Unit,
    val onSolve: () -> Unit,
    val onMigrate: () -> Unit,
    val onEnableSource: () -> Unit,
    val onToggleSort: () -> Unit,
    val onToggleGrid: () -> Unit,
    val onToggleGridPictures: () -> Unit,
    val onToggleDuplicates: () -> Unit,
    val onSort: (ChapterSort) -> Unit,
    // Which chapters show by their marks, for every title, and the groups, languages and labels whose chapters this title hides.
    val onFilter: (ChapterFilter) -> Unit = {},
    val onHideFacets: (Set<Facet>) -> Unit = {},
    // Turns the page between the title by chapter and the same title by volume.
    val onSwitchVolumes: () -> Unit = {},
    val onToggleLibrary: () -> Unit,
    val onToggleFavorite: () -> Unit,
    val onMarkAll: (Boolean) -> Unit,
    val onComments: (CommentsTarget) -> Unit,
    val onContinue: (Long) -> Unit,
    val onSetFocus: (Float, Float) -> Unit,
    val onClearFocus: () -> Unit,
    val chapters: ChapterCallbacks,
    val selection: SelectionCallbacks,
    // Saving chapters to the device. A title whose chapters cannot be saved, such as a preview, has none.
    val downloads: DownloadCalls? = null,
)

// What the page can ask of the saving of chapters: one chapter, the picked ones, or all or the unread ones of the title, and taking them off the device again. The ones that start a download are null while the source cannot be reached.
data class DownloadCalls(
    val onDownload: ((Long) -> Unit)?,
    val onRemove: (Long) -> Unit,
    val onDownloadSelected: (() -> Unit)?,
    val onRemoveSelected: () -> Unit,
    val onDownloadAll: ((unreadOnly: Boolean) -> Unit)?,
    val onRemoveAll: () -> Unit,
)

// The calls that fit the page as it is. A title whose chapters cannot be saved has no downloads. A title whose source cannot be reached loses the calls that need the source: only its saved chapters open, and saved ones can still be taken off the device.
fun TitleCallbacks.fitting(state: TitleState): TitleCallbacks {
    val saving = downloads?.takeIf { state.canDownload }
    if (state.readable) return copy(downloads = saving)
    val saved = state.savedIds
    return copy(
        onRefresh = {},
        onSolve = {},
        onContinue = { id -> if (id in saved) onContinue(id) },
        chapters = chapters.copy(onOpen = { id -> if (id in saved) chapters.onOpen(id) }),
        downloads = saving?.copy(onDownload = null, onDownloadSelected = null, onDownloadAll = null),
    )
}
