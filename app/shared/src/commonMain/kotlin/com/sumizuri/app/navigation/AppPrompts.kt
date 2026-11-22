package com.sumizuri.app.navigation

import androidx.compose.runtime.Composable
import com.sumizuri.app.feature.pair.PhonePairPrompt
import com.sumizuri.app.feature.trackers.TrackerRemovePrompt
import com.sumizuri.app.feature.tv.profile.TvWhoIsWatching
import com.sumizuri.app.ui.theme.ThemeWipeLayer

// The prompts any screen can raise over the app: what to do on the trackers with titles just removed, sending to a TV whose code was opened, on a TV who is watching when it starts, and the ink of a change of look.
@Composable
internal fun AppPrompts() {
    TrackerRemovePrompt()
    PhonePairPrompt()
    TvWhoIsWatching()
    ThemeWipeLayer()
}
