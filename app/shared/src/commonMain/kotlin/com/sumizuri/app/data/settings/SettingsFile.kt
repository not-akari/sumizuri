package com.sumizuri.app.data.settings

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.put

// What a file of settings leaves out: where the app was and when it last checked, the lock and its PIN, notes about covers, and what one title chose for itself. These belong to one device or one title, not to the way a person likes the app.
private val LocalPrefixes = listOf("sync.", "session.place", "session.hidden.", "memo.", "security.", "reader.title.", "debug.perfOverlayAt", "appupdate.lastCheck", "appupdate.lastRun")
private val LocalNames = setOf("lastUpdateCheck", "lastSourceCheck", SettingKey.NoticeAsked, SettingKey.DownloadsPaused)

private fun shared(name: String) = name !in LocalNames && LocalPrefixes.none { name.startsWith(it) }

// Every choice of the settings, to put in a file of settings.
suspend fun SettingsRepository.exportData(): JsonObject =
    buildJsonObject { for ((name, value) in everything().toList().sortedBy { it.first }) if (shared(name)) put(name, value) }

// How many choices a file of settings holds that this device would take.
fun settingsCount(data: JsonObject): Int = data.keys.count(::shared)

// Keeps each choice of a file of settings, over the one there was. Choices it does not name stay as they are. Gives how many it kept.
suspend fun SettingsRepository.importData(data: JsonObject): Int {
    var kept = 0
    for ((name, value) in data) {
        val saved = (value as? JsonPrimitive)?.contentOrNull ?: continue
        if (!shared(name)) continue
        setText(name, saved)
        kept++
    }
    return kept
}
