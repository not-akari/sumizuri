package com.sumizuri.app.feature.library.display

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_hint
import com.sumizuri.app.shared.resources.display_title
import kotlinx.coroutines.launch

// The page in the settings where the look of the library is set, the same choices as the sheet over the library.
@Composable
fun LibraryDisplayRoute(onBack: () -> Unit) {
    val repository = LocalAppContainer.current.libraryPrefs
    val prefs by repository.prefs.collectAsStateWithLifecycle(LibraryPrefs())
    val scope = rememberCoroutineScope()
    SettingsPageFrame(Res.string.display_title, onBack, subtitle = Res.string.display_hint, jumps = displayJumps()) {
        LibraryDisplayBody(prefs) { change -> scope.launch { repository.update(change) } }
    }
}
