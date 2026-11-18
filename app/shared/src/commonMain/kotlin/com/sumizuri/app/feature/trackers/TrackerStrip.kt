package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_track_hint
import org.jetbrains.compose.resources.stringResource

// One slim row per tracker the profile is signed in to, under the buttons of a saved title: how the title stands there, or that it is not linked yet. A tap opens it.
@Composable
internal fun TrackerStrip(title: Title, modifier: Modifier = Modifier) {
    val container = LocalAppContainer.current
    val accounts by remember(container) { container.trackers.signedIn }.collectAsStateWithLifecycle(emptyMap())
    if (accounts.isEmpty()) return
    val links by remember(container, title.id) {
        container.trackerSync.linksOf(title.id)
    }.collectAsStateWithLifecycle(emptyList())
    // A tracker shows for a title it is linked to, and for one of a kind it is used for that was not left out.
    val offered by remember(container, title.id, title.kind) {
        container.trackerSync.use.offeredFor(title.id, title.kind)
    }.collectAsStateWithLifecycle(emptySet())
    var open by remember { mutableStateOf<TrackerId?>(null) }
    val colors = MaterialTheme.colorScheme
    val shown = TrackerId.entries.filter { tracker ->
        tracker in accounts && (tracker in offered || links.any { it.tracker == tracker.id })
    }
    if (shown.isEmpty()) return
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for (tracker in shown) {
            val link = links.firstOrNull { it.tracker == tracker.id }
            Surface(
                { open = tracker },
                Modifier.fillMaxWidth(),
                shape = MaterialTheme.shapes.small,
                color = if (link != null &&
                    !link.gone
                ) {
                    colors.primary.copy(alpha = 0.14f)
                } else {
                    colors.surfaceContainerHighest
                },
            ) {
                Row(
                    Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    TrackerLogo(tracker, 26.dp)
                    Column(Modifier.weight(1f)) {
                        Text(tracker.label, style = MaterialTheme.typography.labelLarge)
                        Text(
                            link?.let { linkLine(it, tracker, accounts[tracker]?.scoreFormat) }
                                ?: stringResource(Res.string.tracker_track_hint, tracker.label),
                            style = MaterialTheme.typography.bodySmall,
                            color = if (link?.gone == true) colors.error else colors.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    Icon(
                        Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                        null,
                        Modifier.size(18.dp),
                        tint = colors.outline,
                    )
                }
            }
        }
    }
    open?.let { TrackSheet(it, title.id, title.name, title.kind) { open = null } }
}
