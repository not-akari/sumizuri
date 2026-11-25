package com.sumizuri.app.data.text

import java.text.DateFormat
import java.text.DateFormatSymbols
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

// The languages the bundled Java has the formats of dates for, which are only those the app is translated to.
private val keptLanguages: Set<String> by lazy { DateFormat.getAvailableLocales().map { it.language }.toSet() }

// The language dates are written in: the one of the computer when its formats are there, else English, which the texts of the app are in then too. Without this a missing language falls back to short root forms such as Mon.
private fun formatLocale(): Locale = Locale.getDefault().let {
    if (it.language in
        keptLanguages
    ) {
        it
    } else {
        Locale.ENGLISH
    }
}

actual fun localOffsetMillis(at: Long): Long = TimeZone.getDefault().getOffset(at).toLong()

actual fun monthYearText(at: Long): String = SimpleDateFormat("LLLL yyyy", formatLocale()).format(Date(at))

actual fun monthYearShort(at: Long): String = SimpleDateFormat("LLL yyyy", formatLocale()).format(Date(at))

actual fun weekdayName(weekday: Int): String = DateFormatSymbols.getInstance(formatLocale()).weekdays[
    weekday % 7 +
        1,
]

actual fun dateText(at: Long): String = DateFormat.getDateInstance(DateFormat.MEDIUM, formatLocale()).format(Date(at))

actual fun monthIndexOf(at: Long): Int = Calendar.getInstance().apply { timeInMillis = at }.let {
    it.get(Calendar.YEAR) *
        12 +
        it.get(Calendar.MONTH)
}
