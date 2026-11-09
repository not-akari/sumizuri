package com.sumizuri.app.feature.title

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import com.sumizuri.app.data.db.download.DownloadEntity
import com.sumizuri.app.data.db.download.DownloadState
import com.sumizuri.app.data.db.download.status
import com.sumizuri.app.data.download.canBeSaved
import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.Facet
import com.sumizuri.app.data.model.SourceState
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.facetsOf
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.feature.title.chapter.ChapterWork
import com.sumizuri.app.feature.title.chapter.ContinueTarget
import com.sumizuri.app.feature.title.chapter.watchOrder
import com.sumizuri.app.feature.title.chapter.withoutDuplicates
import com.sumizuri.app.ui.kit.cover.focus.CoverFocus
import com.sumizuri.app.ui.kit.cover.focus.rememberCoverFocus

data class TitleState(
    val title: Title? = null,
    val sourceName: String? = null,
    val chapters: List<ChapterItem> = emptyList(),
    // True while the source is being asked, and an error says why it failed.
    val loading: Boolean = false,
    val error: String? = null,
    // The address of the site when a bot check stopped the page, so a person can be sent there to pass it.
    val challengeUrl: String? = null,
    // A preview is not saved yet, so it has no read marks and no continue.
    val preview: Boolean = false,
    // True when the chapter list starts with the oldest. The choice is kept for every title.
    val oldestFirst: Boolean = false,
    // The chapters as a grid of cells, and a chapter listed twice shown once. Both are kept for every title.
    val grid: Boolean = false,
    // A page from inside each chapter in its cell of the grid, kept for every title.
    val gridPictures: Boolean = false,
    val hideDuplicates: Boolean = false,
    // What the chapters are put in order by, which is kept for every title.
    val sort: ChapterSort = ChapterSort.Source,
    // Which chapters show by their marks, kept for every title, and the groups, languages and other labels whose chapters this title hides.
    val filter: ChapterFilter = ChapterFilter(),
    val hidden: Set<Facet> = emptySet(),
    // The chapters picked for a bulk action, which makes the page a selection page while there are any.
    val selected: Set<Long> = emptySet(),
    // What the continue button opens, or null when there is nothing to open.
    val target: ContinueTarget? = null,
    // The spot a person picked on the cover for the backdrop, or null to let the page find the face.
    val focus: Pair<Float, Float>? = null,
    // Whether the person lets titles be favorites, which shows the star tile.
    val favoritesEnabled: Boolean = false,
    // The comments of the title, when its source has them, which shows the comments tile.
    val comments: CommentsTarget? = null,
    // The chapters that are saved to the device, waiting to be or being saved, or failed, by chapter.
    val downloads: Map<Long, DownloadEntity> = emptyMap(),
    // Whether the page shows the chapters or the volumes of a title whose source offers both, or null when it offers only one list.
    val volumeSwitch: Boolean? = null,
    // The posters found for the seasons of an anime, by the key of the season.
    val seasonCovers: Map<String, String> = emptyMap(),
) {
    val selecting: Boolean get() = selected.isNotEmpty()

    // Whether the chapters can be saved to the device: those of a saved title, but not episodes, and not files that are on the device already.
    val canDownload: Boolean get() = !preview && title != null && canBeSaved(title.kind, title.sourceId)

    // The chapters that are on the device and open with no source.
    val savedIds: Set<Long> by lazy {
        downloads.values.filter { it.status == DownloadState.Done }.mapTo(HashSet()) { it.chapterId }
    }

    // Whether the chapters can be opened. A saved title whose source is not installed or is off only shows what is saved, and a preview is read from its source.
    val readable: Boolean get() = preview || title?.sourceState == SourceState.Ready

    // The chapters of the groups, languages and labels this title shows. The others are as good as not there: they are not counted, not continued to and not read next. This and the lists below are kept by ChapterWork for the very list of chapters, so a new state for the same chapters does not work them out again, and the page model works them out ahead, away from the thread that draws.
    val visible: List<ChapterItem> by lazy {
        if (hidden.isEmpty()) {
            chapters
        } else {
            ChapterWork.of(
                chapters,
                "visible" to hidden,
            ) { chapters.filter { it.facets().none(hidden::contains) } }
        }
    }

    // The chapters that count, once each when repeats are hidden, for the numbers the page shows such as how many there are and how many are read.
    val counted: List<ChapterItem> by lazy {
        if (hideDuplicates) ChapterWork.of(chapters, "counted" to hidden) { withoutDuplicates(visible) } else visible
    }

    // The ways the chapters differ that are worth choosing between: the groups, the languages and each other label, when there is more than one of it. A list by volume has none, as its group line only says how many chapters a volume holds.
    val facets: List<FacetGroup> by lazy {
        if (volumeSwitch ==
            true
        ) {
            emptyList()
        } else {
            ChapterWork.of(chapters, "facets") { facetGroups(chapters) }
        }
    }

    // The counted chapters in the order they are read, from the first.
    val reading: List<ChapterItem> by lazy {
        ChapterWork.of(chapters, Triple(sort, hidden, hideDuplicates)) { watchOrder(counted, sort) }
    }

    // Every chapter in the order they are read, hidden or not, and the furthest one read, season by season, so a later season counts as further than a higher number in an earlier one.
    val ordered: List<ChapterItem> by lazy {
        ChapterWork.of(
            chapters,
            "ordered" to sort,
        ) { watchOrder(chapters, sort) }
    }
    val furthestRead: ChapterItem? by lazy { ordered.lastOrNull { it.read } }

    // A preview has no marks and nothing saved, so only the groups, languages and labels filter it.
    private val applied: ChapterFilter get() = if (preview) ChapterFilter() else filter

    // Whether a filter hides some chapters, which tints its button.
    val filtering: Boolean get() = applied.active || hidden.isNotEmpty()

    // The chapters in the order and with the duplicates the person chose, the latest first unless the oldest are asked for first, less the ones the filters hide.
    val shown: List<ChapterItem> by lazy {
        val ordered = if (oldestFirst) reading else reading.asReversed()
        if (!applied.active) ordered else ordered.filter { passes(it) }
    }

    private fun passes(chapter: ChapterItem): Boolean =
        applied.unread.keeps(!chapter.read) && applied.downloaded.keeps(chapter.id in savedIds) &&
            applied.bookmarked.keeps(chapter.bookmarked)
}

// One way the chapters of a title differ, with the values it has, such as the languages they come in.
data class FacetGroup(val kind: String, val values: List<String>)

fun ChapterItem.facets(): List<Facet> = facetsOf(scanlator, language, tags)

// The groups first, then the languages, then the other labels by name, each only when the chapters have more than one value of it.
private fun facetGroups(chapters: List<ChapterItem>): List<FacetGroup> {
    val values = LinkedHashMap<String, MutableSet<String>>()
    for (chapter in chapters) for (facet in chapter.facets()) values.getOrPut(facet.kind) { HashSet() } += facet.value
    val order = compareBy<String>({
        if (it == Facet.Group) {
            0
        } else if (it == Facet.Language) {
            1
        } else {
            2
        }
    }, { it })
    return values
        .filterValues { it.size > 1 }
        .keys
        .sortedWith(order)
        .map { kind -> FacetGroup(kind, values.getValue(kind).sorted()) }
}

// The shape of a cover when nothing is known about it.
private const val UsualAspect = 2f / 3f

// The spot the backdrop centres on. A spot the person picked wins over the face the page found, and the page falls back to the top when it has neither.
@Composable
internal fun rememberTitleFocus(url: String?, picked: Pair<Float, Float>?): CoverFocus? {
    val found by rememberCoverFocus(url)
    return remember(found, picked) { picked?.let { (x, y) -> CoverFocus(x, y, found?.aspect ?: UsualAspect) } ?: found }
}
