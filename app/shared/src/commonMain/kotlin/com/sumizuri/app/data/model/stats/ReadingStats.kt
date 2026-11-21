package com.sumizuri.app.data.model.stats

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.stats.ReadingStats.Companion.DayMs
import com.sumizuri.app.data.text.localOffsetMillis
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.stats_time_afternoon
import com.sumizuri.app.shared.resources.stats_time_evening
import com.sumizuri.app.shared.resources.stats_time_morning
import com.sumizuri.app.shared.resources.stats_time_night
import org.jetbrains.compose.resources.StringResource

// The part of the day a reader reads most in.
enum class TimeOfDay(val label: StringResource) {
    Morning(Res.string.stats_time_morning),
    Afternoon(Res.string.stats_time_afternoon),
    Evening(Res.string.stats_time_evening),
    Night(Res.string.stats_time_night),
}

// What the reading of a profile adds up to. A day is a number of days since 1970 on the clock of the device, so the days of a year are plain numbers.
data class ReadingStats(
    val libraryTitles: Int = 0,
    val chaptersRead: Int = 0,
    // The chapters of one title read on one day count as one sitting.
    val sittings: Int = 0,
    val activeDays: Int = 0,
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val chaptersToday: Int = 0,
    val chaptersThisWeek: Int = 0,
    val chaptersThisMonth: Int = 0,
    val kindCounts: Map<Kind, Int> = emptyMap(),
    val favorites: Int = 0,
    val daily: Map<Long, Int> = emptyMap(),
    val firstReadAt: Long? = null,
    val unreadChapters: Int = 0,
    // Counting Monday as 1.
    val busiestWeekday: Int? = null,
    val busiestTime: TimeOfDay? = null,
    // Today as a day number, so the screens can lay out the days without asking the clock.
    val today: Long = 0,
    val nowAt: Long = 0,
) {
    val perSitting: Double get() = if (sittings == 0) 0.0 else chaptersRead.toDouble() / sittings

    val perActiveDay: Double get() = if (activeDays == 0) 0.0 else chaptersRead.toDouble() / activeDays

    val perWeek: Double
        get() {
            val start = firstReadAt ?: return 0.0
            val weeks = ((nowAt - start) / DayMs + 1) / 7.0
            return chaptersRead / weeks.coerceAtLeast(1.0)
        }

    // How many weeks the unread chapters would take at the pace so far, 0 when nothing is left, and null when there is no pace to go by.
    val weeksToClearBacklog: Double?
        get() {
            if (unreadChapters <= 0) return 0.0
            val pace = perWeek
            return if (pace <= 0) null else unreadChapters / pace
        }

    companion object {
        const val DayMs = 24 * 60 * 60 * 1000L
    }
}

// The day of a moment on the clock of the device, counted in days since 1 January 1970.
fun dayOf(at: Long): Long = (at + localOffsetMillis(at)).floorDiv(DayMs)
