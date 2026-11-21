package com.sumizuri.app.feature.migration

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.MigrationState
import com.sumizuri.app.data.migration.MigrationStatus
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_back
import com.sumizuri.app.shared.resources.mig_bar_move
import com.sumizuri.app.shared.resources.mig_bar_moving
import com.sumizuri.app.shared.resources.mig_bar_picked
import com.sumizuri.app.shared.resources.mig_bar_searching
import com.sumizuri.app.shared.resources.mig_bar_sources
import com.sumizuri.app.shared.resources.mig_bar_start
import com.sumizuri.app.shared.resources.mig_bar_stop
import com.sumizuri.app.shared.resources.mig_bar_summary
import com.sumizuri.app.shared.resources.mig_next
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.art.InkTonalButton
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.page.PageGutter
import org.jetbrains.compose.resources.stringResource

// The soft bar under the steps: what the step holds and the buttons that move on. On the last step it starts or stops a search and moves what was found.
@Composable
internal fun MigrationBar(
    state: MigrationState,
    session: MigrationSession,
    step: MigrationStep,
    onStep: (MigrationStep) -> Unit,
) {
    val open = state.items.count {
        it.included &&
            (
                it.status == MigrationStatus.Queued || it.status == MigrationStatus.NotFound ||
                    it.status == MigrationStatus.Failed
                )
    }
    val found = state.count(MigrationStatus.Found)
    val picked = state.items.count { it.included }
    val sourcesOn = state.sources.count { it.included }
    val canSearch = open > 0 && sourcesOn > 0
    Column(
        Modifier
            .padding(horizontal = PageGutter, vertical = 10.dp)
            .fillMaxWidth()
            .softCard(shape = MaterialTheme.shapes.medium)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        // The last step has its own card for how far a search is, so the line shows only on the others.
        if (state.busy && state.total > 0 && step != MigrationStep.Search) {
            InkLinearProgressIndicator(
                progress = { state.processed.toFloat() / state.total },
                modifier = Modifier.fillMaxWidth(),
            )
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            val note = when {
                state.running -> stringResource(
                    Res.string.mig_bar_searching,
                    state.currentSource.orEmpty(),
                    state.processed,
                    state.total,
                )

                state.moving -> stringResource(Res.string.mig_bar_moving, state.processed, state.total)

                step == MigrationStep.Titles -> stringResource(Res.string.mig_bar_picked, picked, state.items.size)

                step == MigrationStep.Sources -> stringResource(
                    Res.string.mig_bar_sources,
                    sourcesOn,
                    state.sources.size,
                )

                else -> stringResource(
                    Res.string.mig_bar_summary,
                    found,
                    state.count(MigrationStatus.Review),
                    state.count(MigrationStatus.NotFound),
                    open,
                )
            }
            Text(note, Modifier.weight(1f), style = MaterialTheme.typography.bodySmall, maxLines = 2)
            when {
                state.busy -> InkOutlinedButton(session::stop) { Text(stringResource(Res.string.mig_bar_stop)) }

                step == MigrationStep.Titles -> InkButton({ onStep(MigrationStep.Sources) }, enabled = picked > 0) {
                    Text(stringResource(Res.string.mig_next))
                }

                step == MigrationStep.Sources -> {
                    InkOutlinedButton({ onStep(MigrationStep.Titles) }) { Text(stringResource(Res.string.mig_back)) }
                    // With nothing left to search the button only goes on to the results.
                    if (open > 0) {
                        InkButton({
                            session.start()
                            onStep(MigrationStep.Search)
                        }, enabled = canSearch) { Text(stringResource(Res.string.mig_bar_start, open)) }
                    } else {
                        InkButton({ onStep(MigrationStep.Search) }) { Text(stringResource(Res.string.mig_next)) }
                    }
                }

                else -> {
                    if (found > 0) {
                        InkTonalButton({ session.moveFound() }) { Text(stringResource(Res.string.mig_bar_move, found)) }
                    }
                    if (open > 0) {
                        InkButton({ session.start() }, enabled = canSearch) {
                            Text(stringResource(Res.string.mig_bar_start, open))
                        }
                    }
                }
            }
        }
    }
}
