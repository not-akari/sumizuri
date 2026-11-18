package com.sumizuri.app.navigation

import androidx.compose.runtime.staticCompositionLocalOf
import com.sumizuri.app.data.model.Kind

// Opens the search of every installed source with these words. The app gives it, so a page deep in the settings can look for a title too.
val LocalSearchSources = staticCompositionLocalOf<(String, Kind?) -> Unit> { { _, _ -> } }
