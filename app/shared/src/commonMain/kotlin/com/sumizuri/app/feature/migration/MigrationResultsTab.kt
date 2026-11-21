package com.sumizuri.app.feature.migration

import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.sumizuri.app.data.migration.MigrationItem
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.MigrationState
import com.sumizuri.app.data.migration.MigrationStatus
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.all
import com.sumizuri.app.shared.resources.mig_bulk_clear
import com.sumizuri.app.shared.resources.mig_bulk_exclude_lost
import com.sumizuri.app.shared.resources.mig_bulk_retry_failed
import com.sumizuri.app.shared.resources.mig_bulk_retry_lost
import com.sumizuri.app.shared.resources.mig_bulk_take_best
import com.sumizuri.app.shared.resources.mig_results_empty
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.FilterTabs
import com.sumizuri.app.ui.kit.chips.SoftActionChip
import com.sumizuri.app.ui.kit.page.PageList
import org.jetbrains.compose.resources.stringResource

// What the work found, a state at a time. The tabs count the titles in each state, the buttons act on all the titles of a state, and each title has a card for what it needs.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun MigrationResultsTab(state: MigrationState, session: MigrationSession, onOpenTitle: (Long) -> Unit) {
    var status by remember { mutableStateOf<MigrationStatus?>(null) }
    var hand by remember { mutableStateOf<MigrationItem?>(null) }
    val worked = remember(state.items) { state.items.filter { it.included && it.status != MigrationStatus.Queued } }
    val present = MigrationStatus.entries.filter { s -> s != MigrationStatus.Queued && worked.any { it.status == s } }
    val shown = remember(worked, status) { worked.filter { status == null || it.status == status } }
    val all = stringResource(Res.string.all)
    PageList {
        if (state.busy || worked.isNotEmpty()) item { ProgressCard(state) }
        item {
            val tabs =
                listOf<Pair<MigrationStatus?, String>>(null to "$all (${worked.size})") +
                    present.map { s -> s to "${stringResource(s.label())} (${worked.count { it.status == s }})" }
            FilterTabs(tabs, status.takeIf { it in present }, { status = it })
        }
        item {
            ChipRow(wrap = true) {
                val review = worked.count { it.status == MigrationStatus.Review }
                val failed = worked.filter { it.status == MigrationStatus.Failed }
                val lost = worked.filter { it.status == MigrationStatus.NotFound }
                if (review >
                    0
                ) {
                    SoftActionChip(
                        { session.acceptBest() },
                        { Text(stringResource(Res.string.mig_bulk_take_best, review)) },
                    )
                }
                if (failed.isNotEmpty()) {
                    SoftActionChip({
                        session.requeue(failed.map { it.id }.toSet())
                    }, { Text(stringResource(Res.string.mig_bulk_retry_failed, failed.size)) })
                }
                if (lost.isNotEmpty()) {
                    SoftActionChip({
                        session.requeue(lost.map { it.id }.toSet())
                    }, { Text(stringResource(Res.string.mig_bulk_retry_lost, lost.size)) })
                    SoftActionChip({
                        session.setIncluded(
                            lost
                                .map {
                                    it.id
                                }.toSet(),
                            false,
                        )
                    }, { Text(stringResource(Res.string.mig_bulk_exclude_lost, lost.size)) })
                }
                val moved = worked.count { it.status == MigrationStatus.Moved }
                if (moved >
                    0
                ) {
                    SoftActionChip({ session.clearMoved() }, { Text(stringResource(Res.string.mig_bulk_clear, moved)) })
                }
            }
        }
        if (shown.isEmpty()) {
            item {
                Text(stringResource(Res.string.mig_results_empty), color = MaterialTheme.colorScheme.outline)
            }
        }
        items(shown, key = { it.id }) { item -> ResultCard(item, state.busy, session, onOpenTitle) { hand = item } }
    }
    hand?.let { item -> ManualMatchDialog(item, state.sources, session) { hand = null } }
}
