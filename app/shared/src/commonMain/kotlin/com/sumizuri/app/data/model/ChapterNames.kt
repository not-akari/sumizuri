package com.sumizuri.app.data.model

// Reading the place of a chapter from its name, for names that hold more than one number: a season or a volume, the chapter, the piece of a split chapter, the end of a range, and whether it is an extra such as a special or a side story. "S2 Ep. 5", "Vol. 3 Ch. 12.5", "Chapter 10-11", "Chapter 40 (2/3)", "第12話" and "Chapter 50.5 Extra" are each read into their parts.

private const val Num = "(\\d+(?:[.,]\\d+)?)"
private val Options = setOf(RegexOption.IGNORE_CASE)

// A label is a word that does not run on from a letter before it, so "arc 3" is not chapter 3 and "res 2" is not season 2.
private val SeasonMark = Regex("(?<![\\p{L}])(?:season|saison|temporada|staffel|s)\\.?\\s*$Num", Options)
private val VolumeMark = Regex("(?<![\\p{L}])(?:volume|vol|tome|book|v)\\.?\\s*$Num", Options)
private val ChapterMark = Regex(
    "(?<![\\p{L}])(?:chapter|chap|ch|c|episode|ep|e|cap[ií]tulo|cap|chapitre|kapitel|глава|эпизод|#)\\.?\\s*$Num(?:\\s*[-–~]\\s*$Num)?(?:([a-d])(?![\\p{L}]))?",
    Options,
)
private val CjkChapter = Regex("第?\\s*$Num\\s*[話话章回]")
private val CjkVolume = Regex("第?\\s*$Num\\s*[巻卷]")
private val CjkSeason = Regex("(?:第\\s*$Num\\s*期|シーズン\\s*$Num)")
private val PieceMark =
    Regex("(?<![\\p{L}])(?:part|pt|parte|teil)\\.?\\s*$Num|\\(\\s*$Num\\s*/\\s*\\d+\\s*\\)|$Num\\s+of\\s+\\d+", Options)
private val ExtraMark =
    Regex(
        "(?<![\\p{L}])(?:extra|special|side\\s*story|omake|bonus|afterword|epilogue|gaiden)(?![\\p{L}])|番外|特別編|おまけ",
        Options,
    )
private val BareNumber = Regex("^\\s*$Num\\s*$")

// What a name says about where its chapter goes. A part the name does not give is null.
class ChapterName(
    val season: Double?,
    val volume: Double?,
    val chapter: Double?,
    val rangeEnd: Double?,
    val piece: Double?,
    val extra: Boolean,
)

private fun number(text: String?): Double? = text?.replace(',', '.')?.toDoubleOrNull()

// Full width digits, as Japanese and Chinese names often have, read as plain ones.
private fun plainDigits(text: String): String = buildString(text.length) {
    for (char in text) {
        append(
            if (char in
                '０'..'９'
            ) {
                '0' + (char - '０')
            } else {
                char
            },
        )
    }
}

fun readChapterName(name: String?): ChapterName {
    if (name.isNullOrBlank()) return ChapterName(null, null, null, null, null, extra = false)
    val text = plainDigits(name)
    val chapter = ChapterMark.find(text)
    val cjk = if (chapter == null) CjkChapter.find(text) else null
    val season = SeasonMark.find(text)?.groupValues?.get(1) ?: CjkSeason
        .find(text)
        ?.groupValues
        ?.drop(1)
        ?.firstOrNull { it.isNotEmpty() }
    val piece = PieceMark
        .find(text)
        ?.groupValues
        ?.drop(1)
        ?.firstOrNull { it.isNotEmpty() }
    return ChapterName(
        season = number(season),
        volume = number(VolumeMark.find(text)?.groupValues?.get(1) ?: CjkVolume.find(text)?.groupValues?.get(1)),
        chapter = number(
            chapter?.groupValues?.get(1) ?: cjk?.groupValues?.get(1) ?: BareNumber.find(text)?.groupValues?.get(1),
        ),
        rangeEnd = number(chapter?.groupValues?.get(2)?.ifEmpty { null }),
        // A letter after the number, as in 12b, is the second piece of chapter 12.
        piece = number(piece) ?: chapter
            ?.groupValues
            ?.get(3)
            ?.ifEmpty { null }
            ?.let { (it.lowercase()[0] - 'a' + 1).toDouble() },
        extra = ExtraMark.containsMatchIn(text),
    )
}

// The place of a chapter among the others of its title, compared part by part: the season, the volume, the chapter, an extra after every piece of the chapter it follows, the piece, the end of a range, and last the number the source gave.
class ChapterRank(
    private val season: Double,
    private val volume: Double,
    private val chapter: Double,
    private val piece: Double,
    private val extra: Boolean,
    private val rangeEnd: Double,
    private val number: Double,
) : Comparable<ChapterRank> {
    override fun compareTo(other: ChapterRank): Int = compareValuesBy(this, other, {
        it.season
    }, { it.volume }, { it.chapter }, { it.extra }, { it.piece }, { it.rangeEnd }, { it.number })
}

// The ranks of chapters from their names and the numbers their source gave, in the same order. A name with no chapter in it uses the number of the source. A chapter whose name leaves out the season or the volume that others give takes it from the chapter before it, as the newest chapters often go without the volume they will be in. When every season named is past the first, a chapter with none is in the first.
fun chapterRanks(chapters: List<Pair<String?, Double>>): List<ChapterRank> {
    val names = chapters.map { readChapterName(it.first) }
    val numbers = chapters.mapIndexed { index, (_, number) -> names[index].chapter ?: number }
    val seasons = filledIn(names.map { it.season }, chapters.map { it.second }, firstWhenAllLater = true)
    val volumes = filledIn(names.map { it.volume }, numbers, firstWhenAllLater = false)
    return chapters.indices.map { index ->
        val name = names[index]
        ChapterRank(
            season = seasons[index],
            volume = volumes[index],
            chapter = numbers[index],
            piece = name.piece ?: 0.0,
            extra = name.extra,
            rangeEnd = name.rangeEnd ?: numbers[index],
            number = chapters[index].second,
        )
    }
}

// Missing groups, such as seasons or volumes, taken from the nearest chapter at or before the same place that has one, and the first group for a chapter before every one that has a group. When every group named is past the first and that is asked for, a chapter with none is in the first, as a source often leaves the first season unnamed.
private fun filledIn(groups: List<Double?>, places: List<Double>, firstWhenAllLater: Boolean): List<Double> {
    val known = groups.indices.filter { groups[it] != null }.sortedBy { places[it] }
    if (known.isEmpty()) return groups.map { 0.0 }
    val lowest = groups.filterNotNull().min()
    if (firstWhenAllLater && lowest > 1.0) return groups.map { it ?: 1.0 }
    return groups.mapIndexed { index, group ->
        group ?: known.lastOrNull { places[it] <= places[index] }?.let { groups[it] } ?: lowest
    }
}
