package com.sumizuri.app.feature.migration

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.migration.MigrationState
import com.sumizuri.app.data.migration.MigrationStatus
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_bar_source_of
import com.sumizuri.app.shared.resources.mig_progress_done
import com.sumizuri.app.shared.resources.mig_progress_moving
import com.sumizuri.app.shared.resources.mig_progress_searching
import com.sumizuri.app.shared.resources.mig_progress_steps
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.text.progressTimeText
import org.jetbrains.compose.resources.stringResource

// How far the work is: a ring that fills as titles are done with the share in its middle, what runs now, which source of how many, and the time left. When nothing runs it says how many of the picked titles were searched.
@Composable
internal fun ProgressCard(state: MigrationState) {
    val picked = state.items.count { it.included }
    val searched = state.items.count { it.included && it.status != MigrationStatus.Queued }
    val share = when {
        state.busy && state.total > 0 -> state.processed.toFloat() / state.total
        picked > 0 -> searched.toFloat() / picked
        else -> 0f
    }
    val ring by animateFloatAsState(share, tween(motionMs(AppMotion.Medium)), label = "ring")
    AppCard(Modifier.entrance()) {
        Row(
            Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Box(Modifier.size(64.dp), contentAlignment = Alignment.Center) {
                InkCircularProgressIndicator(
                    { ring },
                    Modifier.size(64.dp),
                    strokeWidth = 6.dp,
                    trackColor = softFill(strong = true),
                )
                Text(
                    "${(share * 100).toInt()}%",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                )
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                val title = when {
                    state.running -> stringResource(Res.string.mig_progress_searching, state.currentSource.orEmpty())
                    state.moving -> stringResource(Res.string.mig_progress_moving)
                    else -> stringResource(Res.string.mig_progress_done, searched, picked)
                }
                Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, maxLines = 2)
                if (state.busy) {
                    val lines = listOfNotNull(
                        stringResource(Res.string.mig_progress_steps, state.processed, state.total),
                        if (state.running && state.sourceCount > 1) {
                            stringResource(Res.string.mig_bar_source_of, state.sourceIndex, state.sourceCount)
                        } else {
                            null
                        },
                        progressTimeText(state.processed, state.total),
                    )
                    for (line in lines) {
                        Text(
                            line,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
        }
    }
}
