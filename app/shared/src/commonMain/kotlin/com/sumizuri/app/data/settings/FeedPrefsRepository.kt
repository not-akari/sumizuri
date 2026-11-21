package com.sumizuri.app.data.settings

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.model.feed.FeedPrefs
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

// How a feed page is set, kept as a setting row for each choice under the name of the page, such as updates. A choice that was never made has its usual value.
class FeedPrefsRepository(private val db: AppDatabase, page: String) {
    private val prefix = "$page."

    val prefs: Flow<FeedPrefs> = db.settings().observeWithPrefix(prefix).distinctUntilChanged().map { rows ->
        val saved = SavedChoices(rows.associate { it.name.removePrefix(prefix) to it.value })
        val usual = FeedPrefs()
        FeedPrefs(
            style = saved.choice("style", usual.style),
            rowStyle = saved.choice("rowStyle", usual.rowStyle),
            swipeMarksRead = saved.flag("swipeMarksRead", usual.swipeMarksRead),
            upcomingSide = saved.choice("upcomingSide", usual.upcomingSide),
        )
    }

    // Applies a change to the choices as they are now, and saves what it made different.
    suspend fun update(change: (FeedPrefs) -> FeedPrefs) {
        val before = prefs.first()
        val after = change(before)
        if (after.style != before.style) put("style", after.style.name)
        if (after.rowStyle != before.rowStyle) put("rowStyle", after.rowStyle.name)
        if (after.swipeMarksRead != before.swipeMarksRead) put("swipeMarksRead", after.swipeMarksRead.toString())
        if (after.upcomingSide != before.upcomingSide) put("upcomingSide", after.upcomingSide.name)
    }

    private suspend fun put(name: String, value: String) = db.settings().put(SettingEntity(prefix + name, value))
}
