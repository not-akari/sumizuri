package com.sumizuri.app.data.settings

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

// How many searches each place keeps.
private const val Kept = 8

// The shortest words worth keeping.
private const val Shortest = 2

// The reader settings every title starts from, which hold incognito.
private const val AnyTitle = 0L

// The searches are memos, so they stay on this device and are left out of the settings file and of sync.
private const val Prefix = "memo.search."

// The searches typed lately, one list for each place that searches. Nothing is kept while reading incognito, or once the person turns it off.
class SearchHistory(private val settings: SettingsRepository, private val reading: ReaderSettingsRepository) {
    val on: Flow<Boolean> = settings.flag(SettingKey.SearchHistory, true)

    fun recent(place: String): Flow<List<String>> =
        settings.text(Prefix + place).map { saved -> saved.orEmpty().split('\n').filter(String::isNotBlank) }

    suspend fun add(place: String, words: String) {
        val clean = words.trim()
        if (clean.length < Shortest || !on.first() || reading.observe(AnyTitle).first().incognito) return
        val now = recent(place).first()
        // A longer search takes the place of its start typed before, so a pause halfway through a name is not kept beside the whole name.
        val kept = (
            listOf(clean) +
                now.filterNot { it.equals(clean, ignoreCase = true) || clean.startsWith(it, ignoreCase = true) }
            ).take(Kept)
        if (kept != now) settings.setText(Prefix + place, kept.joinToString("\n"))
    }

    suspend fun clear(place: String) = settings.setText(Prefix + place, "")

    suspend fun clearAll() = settings.reset(Prefix)
}
