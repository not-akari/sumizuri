package com.sumizuri.app.data.library

// The words a note in brackets may be made of when it only tells the sound, the subtitles or the cut, such as (English Dub) or [Sub]. A note with any other word is part of the name and is kept.
private val NoteWords = setOf(
    "dub", "dubbed", "sub", "subs", "subbed", "english", "eng", "japanese", "jp", "jpn", "audio", "dual", "multi",
    "uncensored", "censored", "uncut", "raw", "hd", "sd", "1080p", "720p", "480p", "version", "ver", "tv", "and",
)

// A note in round or square brackets.
private val Bracketed = Regex("[(\\[]([^)\\]]*)[)\\]]")

// A dub or a language named at the very end of a name without brackets, such as Attack on Titan English Dub. A bare Sub is left alone, as a name may end in it.
private val TrailingNote =
    Regex("(?i)[\\s:-]+(?:(?:english|eng|japanese)\\s+)?(?:dubbed|subbed|dub)$|[\\s:-]+(?:english|eng)\\s+sub$")

// A part or a cour with its number at the very end, such as Season 1 Part 2 or Cour 2. A name such as Part of Us has no number after the word and is left alone.
private val TrailingPart =
    Regex("(?i)[\\s:-]+(?:part|cour)\\s*\\d+(?:\\s*of\\s*\\d+)?$|[\\s:-]+\\d+(?:st|nd|rd|th)\\s+(?:part|cour)$")

// The first season named at the very end, such as Black Clover Season 1, which is listed under the name of the show alone.
private val TrailingFirstSeason = Regex("(?i)[\\s:-]+(?:season\\s*0*1|1st\\s+season)$")

// The short names of a video sold apart from the show, which AniList lists as OVA.
private val Extra = Regex("(?i)\\b(?:oads?|oavs?|ovas)\\b")

// The names to look a season up by, the surest first: the name as it is, without notes on the sound, with OAD read as OVA, without a part number at the end, and for a first season the show alone. Each is only tried when the ones before it found nothing alike, so a real name is never cut when it is found as it is.
internal fun seasonQueries(name: String): List<String> {
    val plain = name.trim()
    val noNotes = Bracketed
        .replace(plain) { match -> if (isNote(match.groupValues[1])) "" else match.value }
        .replace(TrailingNote, "")
        .tidy()
    val asOva = noNotes.replace(Extra, "OVA")
    val noPart = asOva.replace(TrailingPart, "").tidy()
    val show = noPart.replace(TrailingFirstSeason, "").tidy()
    return listOf(plain, noNotes, asOva, noPart, show).filter { it.isNotBlank() }.distinct()
}

// Whether the words in brackets only tell the sound, the subtitles or the cut.
private fun isNote(inside: String): Boolean {
    val words = inside.lowercase().split(NotWord).filter { it.isNotEmpty() }
    return words.isNotEmpty() && words.all { it in NoteWords }
}

// Spaces made single and marks left at the ends taken off.
private fun String.tidy(): String = replace(Spaces, " ").trim().trimEnd(':', '-', ',').trim()

// The season a part belongs to, such as Season 1 for Season 1 Part 2, or null when the name does not end in a part with its number.
internal fun partOf(name: String): String? {
    val base = name.replace(TrailingPart, "").tidy()
    return base.takeIf { it.isNotEmpty() && it != name.trim() }
}

// Words left out when names are compared, and the ordinals read as plain numbers.
private val Filler = setOf("the", "season", "part", "cour")
private val Ordinal = Regex("^(\\d+)(st|nd|rd|th)$")

// The best share of words a found title has in common with the name, over all its titles.
internal fun likeness(name: String, titles: List<String>): Double {
    val wanted = words(name)
    if (wanted.isEmpty()) return 0.0
    return titles.maxOfOrNull { title ->
        val have = words(title)
        if (have.isEmpty()) 0.0 else (wanted intersect have).size.toDouble() / (wanted union have).size
    } ?: 0.0
}

// The words of a name that tell seasons apart. Words like season and part say nothing on their own, 2nd counts as 2, so Season 2 and 2nd Season are alike.
private fun words(text: String): Set<String> = text
    .lowercase()
    .split(NotWord)
    .map { it.replace(Ordinal, "$1") }
    // A plural counts as its one, so OADs and OAD are alike.
    .map { if (it.length > 3 && it.endsWith("s") && !it.endsWith("ss")) it.dropLast(1) else it }
    // AniList calls every video sold apart from the show an OVA, whatever the source calls it.
    .map { if (it == "oad" || it == "oav") "ova" else it }
    .filter { it.isNotEmpty() && it !in Filler }
    .toSet()

// A season named by its number in one of the usual languages, such as Season 2, Staffel 2, Saison 2, Temporada 2 or S2.
private val NumberedSeason = Regex(
    "(?i)\\b(?:season|staffel|saison|temporada|stagione|seizoen|sezon|series)\\s*0*(\\d+)\\b|\\bs0*(\\d+)\\b|\\b(\\d+)(?:st|nd|rd|th)\\s+season\\b",
)

// The number of a season, from its name when the name gives one, or from its key when it has no name. A season with a name and no number, such as OVA, has none.
internal fun seasonNumber(key: String?, name: String?): Int? {
    if (!name.isNullOrBlank()) {
        val groups = NumberedSeason.find(name)?.groupValues ?: return null
        return groups.drop(1).firstOrNull { it.isNotEmpty() }?.toIntOrNull()
    }
    return key?.toDoubleOrNull()?.takeIf { it > 0 && it % 1.0 == 0.0 }?.toInt()
}

// What lies between words, and a run of spaces.
private val NotWord = Regex("[^\\p{L}\\p{N}]+")
private val Spaces = Regex("\\s+")
