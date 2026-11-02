package com.sumizuri.app.data.library

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.chapter.ChapterRef
import com.sumizuri.app.data.db.chapter.ChapterSlot
import com.sumizuri.app.data.migration.numberKey
import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.OrderKey
import com.sumizuri.app.data.model.TriFilter
import com.sumizuri.app.data.model.chapterTags
import com.sumizuri.app.data.model.facetsFrom
import com.sumizuri.app.data.model.facetsOf
import com.sumizuri.app.data.model.readingOrder
import com.sumizuri.app.data.settings.FilterBookmarkedKey
import com.sumizuri.app.data.settings.FilterDownloadedKey
import com.sumizuri.app.data.settings.FilterUnreadKey
import com.sumizuri.app.data.settings.HiddenFacetsPrefix
import com.sumizuri.app.data.settings.SettingKey
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

// Finds a chapter with its title, the place the reader left it, and the chapters before and after it in the order the title page lists them.
internal class ChapterPlaces(private val db: AppDatabase) {
    // A chapter with its title, its neighbours and the place the reader left it, or null when it is gone.
    suspend fun of(chapterId: Long): ChapterPlace? {
        val ref = db.chapters().find(chapterId) ?: return null
        val origin = db.titles().origin(ref.titleId) ?: return null
        val title = db.titles().observe(ref.titleId).first() ?: return null
        val (previousId, nextId) = neighbours(ref)
        return ChapterPlace(
            id = ref.id,
            titleId = ref.titleId,
            url = ref.url,
            number = ref.number,
            name = ref.name,
            titleName = title.name,
            kind = Kind.fromCode(title.kind),
            sourceId = origin.sourceId,
            coverUrl = title.coverUrl,
            previousId = previousId,
            nextId = nextId,
            position = db.progress().position(ref.id),
        )
    }

    // The chapters before and after this one, in the order the title page lists them: the order of the site, the numbers or the dates, season by season, so the last episode of a season leads to the first of the next. With repeats hidden, a number that is listed twice is passed through once, as the list shows it.
    private suspend fun neighbours(ref: ChapterRef): Pair<Long?, Long?> {
        val hiding = db.settings().get(HideRepeatsKey) == "true"
        val sort = ChapterSort.of(db.settings().get(ChapterSortKey))
        // The groups, languages and labels the title hides are as good as not there, so they go before a copy of each number is picked.
        val hidden = facetsFrom(db.settings().get(HiddenFacetsPrefix + ref.titleId))
        val slots = db.chapters().slotsOf(ref.titleId).let { all ->
            if (hidden.isEmpty()) {
                all
            } else {
                all.filter {
                    it.id == ref.id ||
                        facetsOf(it.scanlator, it.language, chapterTags(it.tags)).none(hidden::contains)
                }
            }
        }
        val kept = (
            if (hiding) {
                oneOfEach(
                    slots,
                    ref.id,
                    db.chapters().touchedIds(ref.titleId).toHashSet(),
                )
            } else {
                slots
            }
            ).let { all ->
            skipping(ref)?.let(all::filter)
                ?: all
        }
        val shown =
            readingOrder(kept, sort) { OrderKey(it.id, it.number, it.sourceOrder, it.publishedAt, it.season, it.name) }
        val at = shown.indexOfFirst { it.id == ref.id }
        if (at < 0) return null to null
        return shown.getOrNull(at - 1)?.id to shown.getOrNull(at + 1)?.id
    }

    // Which chapters the reader may land on when the person chose to pass over the read ones or the ones the filters of the chapter list hide, or null when it lands on every one. The chapter being read always counts.
    private suspend fun skipping(ref: ChapterRef): ((ChapterSlot) -> Boolean)? {
        val settings = db.settings()
        val skipRead = settings.get(SettingKey.ReaderSkipRead) == "true"
        val skipFiltered = settings.get(SettingKey.ReaderSkipFiltered) == "true"
        if (!skipRead && !skipFiltered) return null
        val read = db
            .progress()
            .allOf(ref.titleId)
            .filter { it.read }
            .mapTo(HashSet()) { it.chapterId }
        val filter = if (!skipFiltered) {
            ChapterFilter()
        } else {
            ChapterFilter(
                TriFilter.of(settings.get(FilterUnreadKey)),
                TriFilter.of(settings.get(FilterDownloadedKey)),
                TriFilter.of(settings.get(FilterBookmarkedKey)),
            )
        }
        val saved = if (filter.downloaded == TriFilter.Any) emptySet() else db.downloads().doneIds().toHashSet()
        return { slot ->
            slot.id == ref.id || (
                !(skipRead && slot.id in read) &&
                    filter.unread.keeps(slot.id !in read) && filter.downloaded.keeps(slot.id in saved) &&
                    filter.bookmarked.keeps(slot.bookmarked)
                )
        }
    }

    // One chapter of each number of a season: the one being read, or else the copy the title page keeps, which is one that was read, bookmarked or begun, or else the newest.
    private fun oneOfEach(slots: List<ChapterSlot>, current: Long, touched: Set<Long>): List<ChapterSlot> = slots
        .groupBy {
            it.season to
                numberKey(it.number)
        }.values
        .map { copies ->
            copies.firstOrNull { it.id == current }
                ?: copies.sortedByDescending { it.id }.let { newest ->
                    newest.firstOrNull { it.id in touched }
                        ?: newest.first()
                }
        }
}
