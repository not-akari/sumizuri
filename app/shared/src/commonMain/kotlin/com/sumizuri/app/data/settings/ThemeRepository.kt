package com.sumizuri.app.data.settings

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.theme.spec.ThemePresets
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement

private const val ActiveKey = "theme.active"
private const val CustomPrefix = "theme.custom."

// The same reading of a theme everywhere, which lets a file written by a newer version keep working and fills in what an older one lacks.
private val ThemeJson = Json {
    ignoreUnknownKeys = true
    encodeDefaults = true
    coerceInputValues = true
    prettyPrint = true
}

// The theme in use and the themes a person made, which are kept as one setting row each.
class ThemeRepository(private val db: AppDatabase) {
    // The themes a person made, by name.
    val custom: Flow<List<AppThemeSpec>> = db
        .settings()
        .observeWithPrefix(
            CustomPrefix,
        ).distinctUntilChanged()
        .map { rows ->
            rows
                .mapNotNull {
                    runCatching { ThemeJson.decodeFromString<AppThemeSpec>(it.value) }.getOrNull()
                }.sortedBy { it.name.lowercase() }
        }

    // The theme in use. One that is gone, or never chosen, is the first built in theme.
    val active: Flow<AppThemeSpec> =
        combine(db.settings().observe(ActiveKey).distinctUntilChanged(), custom) { id, mine ->
            (ThemePresets + mine).firstOrNull { it.id == id } ?: ThemePresets.first()
        }

    suspend fun select(id: String) = db.settings().put(SettingEntity(ActiveKey, id))

    // Keeps a theme the person made, or changes it when the id is already there.
    suspend fun save(theme: AppThemeSpec) = db.settings().put(
        SettingEntity(CustomPrefix + theme.id, ThemeJson.encodeToString(AppThemeSpec.serializer(), theme)),
    )

    suspend fun delete(id: String) = db.settings().delete(CustomPrefix + id)

    // A theme as the content of a file of the app. Only what differs from the values every theme starts with is in it, so the file stays short.
    fun toData(theme: AppThemeSpec): JsonElement = DataJson.encodeToJsonElement(AppThemeSpec.serializer(), theme)

    // The theme the content of a file holds, or null when it holds none.
    fun fromData(data: JsonElement): AppThemeSpec? =
        runCatching { DataJson.decodeFromJsonElement(AppThemeSpec.serializer(), data) }.getOrNull()
}

// Shared themes leave out the values every theme starts with.
private val DataJson = Json {
    ignoreUnknownKeys = true
    encodeDefaults = false
    coerceInputValues = true
}
