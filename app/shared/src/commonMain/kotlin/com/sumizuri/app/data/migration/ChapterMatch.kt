package com.sumizuri.app.data.migration

import com.sumizuri.app.data.db.chapter.ChapterEntity
import com.sumizuri.app.data.model.readChapterName
import com.sumizuri.app.source.model.SourceChapter
import kotlin.math.roundToLong

// The number of each chapter as it is saved. Many sources give 0 or a number below zero when they have none, so a number above zero is taken as it is, and else the number in the name, such as 16 in Chapter 16. A chapter whose name has none keeps a 0 its source gave, and with nothing at all it takes its place in the list, counted from the end.
fun chapterNumbers(chapters: List<SourceChapter>): List<Double> = chapters.mapIndexed { index, chapter ->
    chapter.number?.takeIf { it > 0 }
        ?: readChapterName(chapter.title).chapter
        ?: chapter.number?.takeIf { it == 0.0 }
        ?: (chapters.size - index).toDouble()
}

// Two chapters are the same one when their numbers agree to the third decimal.
internal fun numberKey(number: Double): Long = (number * 1000).roundToLong()

private val NotWord = Regex("[^\\p{L}\\p{N}]+")

// What tells one chapter from another, from the surest to the loosest: the number with the season, the number, the name, and the place the name gives, with the volume and without. A key a chapter does not have is null.
private class ChapterKeys(chapter: ChapterEntity) {
    val number = numberKey(chapter.number)
    val seasoned = chapter.season?.let { it to number }

    // Case, spaces and marks are left out, so "Chapter 12: The Fall" and "chapter 12 the fall" are the same.
    var name = chapter.name
        ?.lowercase()
        ?.replace(NotWord, " ")
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
    val place: List<Long?>?
    val placeInVolume: List<Long?>?

    init {
        val read = readChapterName(chapter.name)
        place =
            read.chapter?.let {
                listOf(
                    read.season,
                    it,
                    read.piece,
                    if (read.extra) 1.0 else null,
                ).map { part -> part?.let(::numberKey) }
            }
        placeInVolume = read.volume?.let { volume -> place?.let { listOf(numberKey(volume)) + it } }
    }
}

private val Lookups: List<(ChapterKeys) -> Any?> =
    listOf({ it.seasoned }, { it.number }, { it.name }, { it.placeInVolume }, { it.place })

// Pairs each old chapter with the chapter of the new list that is the same one, as old id to new id. The number decides first, with the season when the old chapter has one. A chapter whose number finds none is paired by its name, and then by the place its name gives, for two lists that number their chapters in different ways, such as one going on across seasons where the other starts each season again. A name that more than one new chapter has pairs nothing, as a source that calls every chapter the same says nothing by it.
fun matchChapters(old: List<ChapterEntity>, new: List<ChapterEntity>): Map<Long, Long> {
    val newKeys = new.map { it.id to ChapterKeys(it) }
    val shared = newKeys
        .mapNotNull { it.second.name }
        .groupingBy { it }
        .eachCount()
        .filterValues { it > 1 }
        .keys
    for ((_, keys) in newKeys) if (keys.name in shared) keys.name = null
    val indexes = Lookups.map { lookup ->
        lookup to
            buildMap { for ((id, keys) in newKeys) lookup(keys)?.let { key -> if (key !in this) put(key, id) } }
    }
    return buildMap {
        for (chapter in old) {
            val keys = ChapterKeys(chapter)
            indexes
                .firstNotNullOfOrNull { (lookup, index) ->
                    lookup(
                        keys,
                    )?.let(index::get)
                }?.let { put(chapter.id, it) }
        }
    }
}
