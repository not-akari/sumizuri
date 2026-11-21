package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_track_hint
import com.sumizuri.app.shared.resources.trackers_title
import com.sumizuri.app.ui.kit.card.CardButton
import com.sumizuri.app.ui.kit.card.StripAction
import com.sumizuri.app.ui.kit.page.AppSheet
import org.jetbrains.compose.resources.stringResource

// How many logos the button stacks, and how far each moves over the one before it.
private const val LogosShown = 3
private val LogoStep = 8.dp

// The trackers of a saved title as one action of the strip beside the library and the favorite: the logos of the trackers stacked in it, on while the title is linked to one of them, and a dot when an entry was removed on a tracker. A tap opens the list of them, where each opens its own sheet. Nothing shows when no tracker is offered for the title.
@Composable
internal fun RowScope.TrackersAction(title: Title, ink: Color) {
    val container = LocalAppContainer.current
    val accounts by remember(container) { container.trackers.signedIn }.collectAsStateWithLifecycle(emptyMap())
    val links by remember(container, title.id) {
        container.trackerSync.linksOf(title.id)
    }.collectAsStateWithLifecycle(emptyList())
    // A tracker shows for a title it is linked to, and for one of a kind it is used for that was not left out.
    val offered by remember(container, title.id, title.kind) {
        container.trackerSync.use.offeredFor(title.id, title.kind)
    }.collectAsStateWithLifecycle(emptySet())
    val shown = remember(accounts, offered, links) {
        TrackerId.entries.filter { tracker ->
            tracker in accounts && (tracker in offered || links.any { it.tracker == tracker.id })
        }
    }
    if (shown.isEmpty()) return
    var listing by remember { mutableStateOf(false) }
    var open by remember { mutableStateOf<TrackerId?>(null) }
    StripAction(
        stringResource(Res.string.trackers_title),
        on = links.any { !it.gone },
        ink = ink,
        accent = MaterialTheme.colorScheme.primary,
        onClick = { listing = true },
        alert = links.any { it.gone },
    ) {
        Box {
            shown.take(LogosShown).forEachIndexed { index, tracker ->
                Box(Modifier.padding(start = LogoStep * index)) { TrackerLogo(tracker, 15.dp) }
            }
        }
    }
    if (listing) {
        AppSheet({ listing = false }, spacing = 8.dp, title = stringResource(Res.string.trackers_title)) {
            for (tracker in shown) {
                TrackerRow(tracker, links.firstOrNull { it.tracker == tracker.id }, accounts[tracker]) {
                    listing = false
                    open = tracker
                }
            }
        }
    }
    open?.let { TrackSheet(it, title.id, title.name, title.kind) { open = null } }
}

// One tracker in the list: its logo, its name and how the title stands there, or that it is not linked yet.
@Composable
private fun TrackerRow(tracker: TrackerId, link: TrackerLinkEntity?, account: TrackerAccount?, onClick: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    CardButton(onClick, Modifier.fillMaxWidth()) {
        Row(
            Modifier.weight(1f).padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            TrackerLogo(tracker, 28.dp)
            Column(Modifier.weight(1f)) {
                Text(tracker.label, style = MaterialTheme.typography.labelLarge)
                Text(
                    link?.let { linkLine(it, tracker, account?.scoreFormat) }
                        ?: stringResource(Res.string.tracker_track_hint, tracker.label),
                    style = MaterialTheme.typography.bodySmall,
                    color = if (link?.gone == true) colors.error else colors.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, Modifier.size(18.dp), tint = colors.outline)
        }
    }
}
