package com.sumizuri.app.ui.kit.sync

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_now
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.AppCard
import org.jetbrains.compose.resources.stringResource
import androidx.compose.foundation.layout.BoxWithConstraints

// How a sync stands, for the round mark of its card.
enum class SyncMark { Ready, Running, Failed }

// The other side of a sync in one quiet line with an icon, which a tap can ask again.
class SyncOther(val icon: ImageVector, val text: String, val alert: Boolean = false, val onClick: (() -> Unit)? = null)

// The head of a page that syncs, the same for the sync server and the trackers: how it stands in a few words, when it last synced, the other side, and the button that syncs now.
@Composable
fun SyncHeadCard(
    title: String,
    line: String?,
    mark: SyncMark,
    other: SyncOther?,
    canSync: Boolean,
    onSync: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val failed = mark == SyncMark.Failed
    // On a wide window the button sits at the end of the first line, so it is not a long bar across the card.
    val button: @Composable (Modifier) -> Unit = { place ->
        InkButton(onSync, place.height(46.dp), enabled = canSync && mark != SyncMark.Running) {
            Icon(Icons.Outlined.Sync, null, Modifier.size(18.dp))
            Box(Modifier.width(8.dp))
            Text(stringResource(Res.string.sync_now))
        }
    }
    AppCard(Modifier.fillMaxWidth()) {
        BoxWithConstraints {
        val wide = maxWidth >= 600.dp
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                // A round mark that says the state at a glance: a turning circle while it syncs.
                Box(
                    Modifier
                        .size(
                            52.dp,
                        ).background(
                            if (failed) colors.errorContainer else colors.primary.copy(alpha = 0.14f),
                            CircleShape,
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    if (mark == SyncMark.Running) {
                        InkCircularProgressIndicator(Modifier.size(26.dp), strokeWidth = 3.dp)
                    } else {
                        Icon(
                            if (failed) Icons.Outlined.ErrorOutline else Icons.Outlined.Sync,
                            null,
                            Modifier.size(26.dp),
                            tint = if (failed) colors.onErrorContainer else colors.primary,
                        )
                    }
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    if (line != null && mark != SyncMark.Running) {
                        Text(line, style = MaterialTheme.typography.bodySmall, color = colors.onSurfaceVariant)
                    }
                }
                if (wide) button(Modifier.padding(start = 8.dp))
            }
            if (other != null) {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clip(
                            MaterialTheme.shapes.small,
                        ).clickable(enabled = other.onClick != null) {
                            other.onClick?.invoke()
                        },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        other.icon,
                        null,
                        Modifier.size(16.dp),
                        tint = if (other.alert) colors.error else colors.outline,
                    )
                    Box(Modifier.width(8.dp))
                    Text(
                        other.text,
                        Modifier.weight(1f),
                        style = MaterialTheme.typography.labelMedium,
                        color = colors.outline,
                    )
                }
            }
            if (!wide) button(Modifier.fillMaxWidth())
        }
        }
    }
}
