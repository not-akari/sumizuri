package com.sumizuri.app.feature.title.chapter

import com.sumizuri.app.data.text.weekdayOf
// A pattern needs this many dates, and the top weekday needs this share of them.
private const val FewestDates = 4
private const val ClearShare = 0.4
private const val DayMs = 24L * 60 * 60 * 1000

// The weekday of a time, with Monday as 0. The day is counted in UTC.
private fun weekdayAt(time: Long): Int = weekdayOf(time.floorDiv(DayMs)) - 1

// The weekday a title most likely comes out on, with Monday as 0, guessed from the dates of its chapters. It is null when there is no clear pattern.
fun guessReleaseDay(times: List<Long>): Int? {
    val dates = times.filter { it > 0 }
    if (dates.size < FewestDates) return null
    val top = dates.groupingBy(::weekdayAt).eachCount().maxByOrNull { it.value } ?: return null
    return if (top.value < dates.size * ClearShare) null else top.key
}
