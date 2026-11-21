package com.sumizuri.app.data.model.stats

import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.stats.ReadingStats.Companion.DayMs
import com.sumizuri.app.data.text.localOffsetMillis
import com.sumizuri.app.data.text.weekdayOf

private const val HourMs = 60 * 60 * 1000L

// Works out the statistics from the moments chapters were read, each with the title it belongs to, and from the titles of the library.
fun readingStatsOf(reads: List<Pair<Long, Long>>, library: List<Title>, now: Long): ReadingStats {
    val today = dayOf(now)
    val daily = HashMap<Long, Int>()
    val weekdays = IntArray(8)
    val times = IntArray(TimeOfDay.entries.size)
    val sittings = HashSet<Pair<Long, Long>>()
    var first: Long? = null
    // The offset of the time zone changes only a few times a year, so it is asked once for each hour that has reads and not once per read.
    val offsets = HashMap<Long, Long>()
    for ((titleId, at) in reads) {
        val local = at + offsets.getOrPut(at.floorDiv(HourMs)) { localOffsetMillis(at) }
        val day = local.floorDiv(DayMs)
        daily[day] = (daily[day] ?: 0) + 1
        weekdays[weekdayOf(day)]++
        times[timeOf((local.mod(DayMs) / HourMs).toInt()).ordinal]++
        sittings += titleId to day
        if (first == null || at < first) first = at
    }
    val active = daily.keys
    // A streak still counts when today has no reading yet but yesterday had.
    var streak = 0
    var cursor = if (today in active) {
        today
    } else if (today - 1 in active) {
        today - 1
    } else {
        null
    }
    while (cursor != null && cursor in active) {
        streak++
        cursor--
    }
    var longest = 0
    var run = 0
    var before = Long.MIN_VALUE
    for (day in active.sorted()) {
        run = if (day == before + 1) run + 1 else 1
        if (run > longest) longest = run
        before = day
    }
    return ReadingStats(
        libraryTitles = library.size,
        chaptersRead = reads.size,
        sittings = sittings.size,
        activeDays = active.size,
        currentStreak = streak,
        longestStreak = longest,
        chaptersToday = daily[today] ?: 0,
        chaptersThisWeek = (today - 6..today).sumOf { daily[it] ?: 0 },
        chaptersThisMonth = (today - 29..today).sumOf { daily[it] ?: 0 },
        kindCounts = library.groupingBy { it.kind }.eachCount(),
        favorites = library.count { it.favorite },
        daily = daily,
        firstReadAt = first,
        unreadChapters = library.sumOf { it.unread },
        busiestWeekday = (1..7).maxByOrNull { weekdays[it] }?.takeIf { weekdays[it] > 0 },
        busiestTime = TimeOfDay.entries.maxByOrNull { times[it.ordinal] }?.takeIf { times[it.ordinal] > 0 },
        today = today,
        nowAt = now,
    )
}

internal fun timeOf(hour: Int): TimeOfDay = when (hour) {
    in 5..11 -> TimeOfDay.Morning
    in 12..16 -> TimeOfDay.Afternoon
    in 17..20 -> TimeOfDay.Evening
    else -> TimeOfDay.Night
}
