package com.sumizuri.app.feature.sync.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.account.BigChange
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_big_allow
import com.sumizuri.app.shared.resources.sync_big_allow_hint
import com.sumizuri.app.shared.resources.sync_big_keep
import com.sumizuri.app.shared.resources.sync_big_names
import com.sumizuri.app.shared.resources.sync_big_title
import com.sumizuri.app.shared.resources.sync_big_titles
import com.sumizuri.app.shared.resources.sync_big_unread
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.motion.entrance
import org.jetbrains.compose.resources.stringResource

// A sync that would take a lot from this device and waits: what it would take, the first titles, and the two ways on. Keep mine puts this device first for those titles, and Allow makes a backup and then lets the change through.
@Composable
internal fun BigChangeCard(change: BigChange, enabled: Boolean, onKeep: () -> Unit, onAllow: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    Column(
        Modifier
            .fillMaxWidth()
            .entrance()
            .softCard()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(Icons.Outlined.WarningAmber, null, tint = colors.error)
            Text(
                stringResource(Res.string.sync_big_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
        }
        if (change.removed > 0) Text(stringResource(Res.string.sync_big_titles, change.removed, change.library))
        if (change.unread > 0) Text(stringResource(Res.string.sync_big_unread, change.unread))
        if (change.names.isNotEmpty()) {
            Text(
                stringResource(Res.string.sync_big_names, change.names.joinToString()),
                style = MaterialTheme.typography.bodySmall,
                color = colors.onSurfaceVariant,
            )
        }
        Row(Modifier.padding(top = 4.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            InkButton(onKeep, Modifier.weight(1f), enabled = enabled) { Text(stringResource(Res.string.sync_big_keep)) }
            InkOutlinedButton(
                onAllow,
                Modifier.weight(1f),
                enabled = enabled,
            ) { Text(stringResource(Res.string.sync_big_allow)) }
        }
        Text(
            stringResource(Res.string.sync_big_allow_hint),
            style = MaterialTheme.typography.bodySmall,
            color = colors.outline,
        )
    }
}
