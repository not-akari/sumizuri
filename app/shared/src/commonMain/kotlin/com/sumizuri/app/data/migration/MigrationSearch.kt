package com.sumizuri.app.data.migration

import com.sumizuri.app.source.Source
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.source.valueOrNull
import kotlinx.coroutines.delay

// Results of one source whose chapters are read to be compared, and the most results looked at by name before that.
private const val MostResults = 8
private const val WorthALook = 0.4

// Looks for a title on one open source. The address the title has now is tried first when the source is of the same site, then the name is searched, and when that finds nothing a shorter name is searched. The results are ranked by their names, and when the rules ask for it the chapters of the likeliest are read and counted in too, which costs a request for each.
class MigrationSearch(
    private val installed: InstalledSource,
    private val source: Source,
    private val rules: MigrationRules,
    private val stopped: () -> Boolean,
) {
    suspend fun find(subject: MigrationSubject, address: String): MigrationFound {
        if (rules.tryAddress && address.isNotBlank() &&
            sameSite(address, installed.baseUrl)
        ) {
            byAddress(subject, address)?.let { return it }
        }
        var failure: String? = null
        var ruledOut = 0
        for (query in queriesFor(subject.title)) {
            if (stopped()) break
            when (val answer = source.search(query, 1)) {
                is SourceResult.Err -> {
                    failure = answer.error.message
                    break
                }

                is SourceResult.Ok -> {
                    failure = null
                    pause()
                    val ranked = rank(subject, answer.value)
                    ruledOut = ranked.ruledOut
                    if (ranked.verdict != MigrationVerdict.NotFound) return ranked
                }
            }
        }
        return MigrationFound(MigrationVerdict.NotFound, emptyList(), ruledOut, failure)
    }

    // The entry at the address the title has now, when the source can show it. Without reading chapters, the details the source gives are enough to know the address works.
    private suspend fun byAddress(subject: MigrationSubject, address: String): MigrationFound? {
        val shown = source.details(SourceEntry(url = address, title = "")).valueOrNull() ?: return null
        val entry = shown.copy(url = address, title = shown.title.ifBlank { subject.title })
        if (!rules.readChapters) {
            return MigrationFound(
                MigrationVerdict.Found,
                listOf(MigrationOption(installed, entry, MigrationScore(1.0, 1.0, null), null)),
                0,
                null,
            )
        }
        pause()
        val chapters = source.chapters(entry).valueOrNull()?.takeIf { it.isNotEmpty() } ?: return null
        return MigrationFound(
            MigrationVerdict.Found,
            listOf(MigrationOption(installed, entry, MigrationScore(1.0, 1.0, null), chapters.size, chapters)),
            0,
            null,
        )
    }

    private suspend fun rank(subject: MigrationSubject, results: List<SourceEntry>): MigrationFound {
        val byName = results
            .take(MostResults)
            .map {
                it to MatchScoring.titleSimilarity(subject.title, it.title)
            }.sortedByDescending { it.second }
        if (!rules.readChapters) return rankByName(subject, byName.filter { it.second >= WorthALook }.map { it.first })
        val close = byName.filter { it.second >= WorthALook }.map { it.first }.take(
            rules.looksAt.coerceIn(1, MostResults),
        )
        val lists = mutableListOf<List<SourceChapter>>()
        for (entry in close) {
            if (stopped()) break
            lists += source.chapters(entry).valueOrNull().orEmpty()
            pause()
        }
        val looked = close.take(lists.size)
        val candidates = looked.mapIndexed { index, entry ->
            MigrationCandidate(
                entry.title,
                entry.author,
                lists[index]
                    .mapNotNull {
                        it.number
                    }.toSet(),
            )
        }
        val ranking = MigrationRanker.rank(subject, candidates, rules)
        // Only the best match keeps its chapters.
        val options = ranking.ranked.mapIndexed { place, (index, score) ->
            MigrationOption(
                installed,
                looked[index],
                score,
                lists[index].size,
                if (place ==
                    0
                ) {
                    lists[index]
                } else {
                    null
                },
            )
        }
        return MigrationFound(ranking.verdict, options, ranking.excluded, null)
    }

    // The results ranked by name and author alone, with no request more, so the rules about chapters have nothing to go on and let every result through.
    private fun rankByName(subject: MigrationSubject, close: List<SourceEntry>): MigrationFound {
        val ranking = MigrationRanker.rank(subject, close.map { MigrationCandidate(it.title, it.author, null) }, rules)
        val options = ranking.ranked.map { (index, score) -> MigrationOption(installed, close[index], score, null) }
        return MigrationFound(ranking.verdict, options, ranking.excluded, null)
    }

    private suspend fun pause() {
        if (rules.delayMs > 0) delay(rules.delayMs.toLong())
    }

    // The whole name, then what stands before a colon or a dash, then the first words.
    private fun queriesFor(title: String): List<String> {
        if (!rules.tryShorterName) return listOf(title)
        val before = title.split(NameBreak).first().trim()
        val words = title.trim().split(Spaces)
        val first = if (words.size >= 5) words.take(4).joinToString(" ") else ""
        return listOf(title, before, first).filter { it.length >= 3 }.distinct()
    }

    private fun sameSite(address: String, baseUrl: String): Boolean {
        val a = hostOf(address)
        return a != null && a == hostOf(baseUrl)
    }

    private fun hostOf(url: String): String? = HostPart
        .find(url)
        ?.groupValues
        ?.get(1)
        ?.lowercase()
        ?.removePrefix("www.")
}

// Where a name breaks into a shorter one, a run of spaces, and the host of an address.
private val NameBreak = Regex("\\s[-\u2013|]\\s|:")
private val Spaces = Regex("\\s+")
private val HostPart = Regex("^[a-zA-Z][a-zA-Z0-9+.-]*://([^/:?#]+)")
