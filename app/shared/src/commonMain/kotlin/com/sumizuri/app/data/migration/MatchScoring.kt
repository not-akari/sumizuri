package com.sumizuri.app.data.migration

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

// How much two titles look like one title, from their names, authors and chapter numbers. The words that only describe a release are left out of a name, accents are folded, and numbers in a name must agree.
object MatchScoring {
    private val noise =
        setOf("official", "uncensored", "colored", "colorized", "raw", "webtoon", "manga", "novel", "the")
    private val brackets = Regex("\\([^)]*\\)|\\[[^\\]]*\\]|\\{[^}]*\\}")
    private val symbols = Regex("[^\\p{L}\\p{N}\\s]")
    private val digits = Regex("\\d+")
    private val accents = mapOf(
        'à' to "a", 'á' to "a", 'â' to "a", 'ã' to "a", 'ä' to "a", 'å' to "a", 'ç' to "c", 'è' to "e", 'é' to "e",
        'ê' to "e", 'ë' to "e",
        'ì' to "i", 'í' to "i", 'î' to "i", 'ï' to "i", 'ñ' to "n", 'ò' to "o", 'ó' to "o", 'ô' to "o", 'õ' to "o",
        'ö' to "o", 'ø' to "o",
        'ù' to "u", 'ú' to "u", 'û' to "u", 'ü' to "u", 'ý' to "y", 'ÿ' to "y", 'ß' to "ss",
    )

    // A name with brackets, accents, punctuation and release words taken out.
    fun normalize(title: String): String {
        val plain = title
            .lowercase()
            .replace(brackets, " ")
            .map { accents[it] ?: it.toString() }
            .joinToString("")
            .replace(symbols, " ")
        return plain.split(Spaces).filter { it.isNotEmpty() && it !in noise }.joinToString(" ")
    }

    // From 0 to 1, how alike two strings are by the edits it takes to turn one into the other.
    fun editSimilarity(a: String, b: String): Double {
        if (a.isEmpty() && b.isEmpty()) return 1.0
        if (a.isEmpty() || b.isEmpty()) return 0.0
        var previous = IntArray(b.length + 1) { it }
        for (i in 1..a.length) {
            val current = IntArray(b.length + 1)
            current[0] = i
            for (j in 1..b.length) {
                val cost = if (a[i - 1] == b[j - 1]) 0 else 1
                current[j] = min(min(current[j - 1] + 1, previous[j] + 1), previous[j - 1] + cost)
            }
            previous = current
        }
        return 1.0 - previous[b.length].toDouble() / max(a.length, b.length)
    }

    private fun wordOverlap(a: String, b: String): Double {
        val x = a.split(' ').filter { it.isNotEmpty() }.toSet()
        val y = b.split(' ').filter { it.isNotEmpty() }.toSet()
        if (x.isEmpty() || y.isEmpty()) return 0.0
        return x.intersect(y).size.toDouble() / x.union(y).size
    }

    // How alike two names are, which is 1 for the same name. A name inside the other counts at least 0.8, and names whose numbers differ lose almost half.
    fun titleSimilarity(a: String, b: String): Double {
        val x = normalize(a)
        val y = normalize(b)
        if (x.isEmpty() || y.isEmpty()) return 0.0
        if (x == y) return 1.0
        var score = max(editSimilarity(x, y), wordOverlap(x, y))
        if (x.contains(y) || y.contains(x)) score = max(score, 0.8)
        val numbersX = digits.findAll(x).map { it.value }.toSet()
        val numbersY = digits.findAll(y).map { it.value }.toSet()
        if (numbersX.size != numbersY.size || !numbersX.containsAll(numbersY)) score *= 0.55
        return score.coerceIn(0.0, 1.0)
    }

    // How much of the chapters the title has are in the candidate, or null when either side has none to compare. A candidate that stops before the chapter the reader is at counts for less than half.
    fun chapterFit(subject: MigrationSubject, candidate: Set<Double>?): Double? {
        if (candidate.isNullOrEmpty() || subject.chapterNumbers.isEmpty()) return null
        fun has(n: Double) = candidate.any { abs(it - n) < 1e-6 }
        val shared = subject.chapterNumbers.count { has(it) }.toDouble() / subject.chapterNumbers.size
        val read = subject.lastRead
        if (read != null && read > 0 && !has(read) && candidate.max() < read) return shared * 0.4
        return shared
    }

    // The score of a candidate for a title: its name, with the author and the chapters counted in when both are known.
    fun score(subject: MigrationSubject, candidate: MigrationCandidate): MigrationScore {
        var title = titleSimilarity(subject.title, candidate.title)
        val a = subject.author?.trim()?.lowercase()
        val b = candidate.author?.trim()?.lowercase()
        // Two different named authors make a match doubtful, and agreeing authors help a little.
        if (!a.isNullOrEmpty() && !b.isNullOrEmpty()) title = if (a == b) min(1.0, title + 0.05) else title * 0.8
        val chapters = chapterFit(subject, candidate.chapterNumbers)
        val total = if (chapters == null) title else 0.6 * title + 0.4 * chapters
        return MigrationScore(total, title, chapters)
    }
}

// A run of spaces between words.
private val Spaces = Regex("\\s+")
