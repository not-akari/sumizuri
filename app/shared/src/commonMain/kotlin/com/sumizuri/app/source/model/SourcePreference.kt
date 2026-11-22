package com.sumizuri.app.source.model

// A setting the reader can change for one source, such as a server or an image quality.
data class SourcePreference(
    val key: String,
    val title: String,
    val type: PreferenceType,
    val summary: String? = null,
    val defaultValue: Any? = null,
    val options: List<PreferenceOption> = emptyList(),
    val dialogTitle: String? = null,
    val dialogMessage: String? = null,
    // A password or a key, hidden on screen and locked with the key of this device.
    val secure: Boolean = false,
)

data class PreferenceOption(val label: String, val value: String)

enum class PreferenceType { EditText, Switch, List, MultiSelectList }
