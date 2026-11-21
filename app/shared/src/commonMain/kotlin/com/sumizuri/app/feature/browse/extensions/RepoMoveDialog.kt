package com.sumizuri.app.feature.browse.extensions

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.data.sources.RepoMatch
import com.sumizuri.app.data.sources.RepoMovePlan
import com.sumizuri.app.data.sources.RepoMoveResult
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.repo_move_busy
import com.sumizuri.app.shared.resources.repo_move_comparing
import com.sumizuri.app.shared.resources.repo_move_done
import com.sumizuri.app.shared.resources.repo_move_failed
import com.sumizuri.app.shared.resources.repo_move_go
import com.sumizuri.app.shared.resources.repo_move_match_id
import com.sumizuri.app.shared.resources.repo_move_match_name
import com.sumizuri.app.shared.resources.repo_move_match_none
import com.sumizuri.app.shared.resources.repo_move_match_site
import com.sumizuri.app.shared.resources.repo_move_no_other
import com.sumizuri.app.shared.resources.repo_move_nothing
import com.sumizuri.app.shared.resources.repo_move_pick
import com.sumizuri.app.shared.resources.repo_move_remove_old
import com.sumizuri.app.shared.resources.repo_move_result
import com.sumizuri.app.shared.resources.repo_move_title
import com.sumizuri.app.shared.resources.repo_move_titles
import com.sumizuri.app.shared.resources.repo_move_unmatched
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.CheckRow
import org.jetbrains.compose.resources.stringResource

// Moves the sources of a repo to another, in three steps in one window: the repo to move to is picked, every source is matched in it and the matches are shown before anything changes, and then the move runs and says what it did.
@Composable
internal fun RepoMoveDialog(
    state: RepoMoveState,
    others: List<Repo>,
    onTarget: (Repo) -> Unit,
    onRemoveOld: (Boolean) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    val plan = state.plan
    val result = state.result
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.repo_move_title, state.from.name)) },
        text = {
            Column(
                Modifier.heightIn(max = 460.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                when {
                    result != null -> MoveResult(result)
                    plan != null -> MovePlan(plan, state, onRemoveOld)
                    state.busy -> Busy(stringResource(Res.string.repo_move_comparing))
                    else -> PickTarget(others, state.problem, onTarget)
                }
            }
        },
        confirmButton = {
            when {
                result != null -> InkButton(onDismiss) { Text(stringResource(Res.string.repo_move_done)) }

                plan != null && plan.items.any { it.match != null } ->
                    InkButton(onConfirm, enabled = !state.busy) { Text(stringResource(Res.string.repo_move_go)) }
            }
        },
        dismissButton = {
            if (result == null && !state.busy) CancelButton(onDismiss)
        },
    )
}

@Composable
private fun PickTarget(others: List<Repo>, problem: String?, onTarget: (Repo) -> Unit) {
    if (others.isEmpty()) {
        Text(stringResource(Res.string.repo_move_no_other))
        return
    }
    Text(stringResource(Res.string.repo_move_pick), color = MaterialTheme.colorScheme.onSurfaceVariant)
    for (repo in others) {
        Column(Modifier.fillMaxWidth().clickable { onTarget(repo) }.padding(vertical = 8.dp)) {
            Text(repo.name, style = MaterialTheme.typography.bodyLarge)
            Text(
                repo.url,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline,
                maxLines = 1,
            )
        }
    }
    problem?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall) }
}

// The matches, each source with what it matched and how, the titles that move with the ones found under another id, and the choice to take the old repo away.
@Composable
private fun MovePlan(plan: RepoMovePlan, state: RepoMoveState, onRemoveOld: (Boolean) -> Unit) {
    if (plan.items.isEmpty()) {
        Text(stringResource(Res.string.repo_move_nothing))
        return
    }
    for (item in plan.items) {
        val how = when (item.how) {
            RepoMatch.SameId -> stringResource(Res.string.repo_move_match_id)
            RepoMatch.SameSite -> stringResource(Res.string.repo_move_match_site, item.match?.name.orEmpty())
            RepoMatch.SameName -> stringResource(Res.string.repo_move_match_name, item.match?.name.orEmpty())
            RepoMatch.None -> stringResource(Res.string.repo_move_match_none)
        }
        val moves = item.how == RepoMatch.SameSite || item.how == RepoMatch.SameName
        Column {
            Text(item.installed.name, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
            Text(
                if (moves &&
                    item.titles > 0
                ) {
                    how + " " + stringResource(Res.string.repo_move_titles, item.titles)
                } else {
                    how
                },
                style = MaterialTheme.typography.bodySmall,
                color = if (item.how ==
                    RepoMatch.None
                ) {
                    MaterialTheme.colorScheme.error
                } else {
                    MaterialTheme.colorScheme.outline
                },
            )
        }
    }
    CheckRow(
        stringResource(Res.string.repo_move_remove_old, plan.from.name),
        state.removeOld,
        onRemoveOld,
        enabled = !state.busy,
    )
    if (state.busy) {
        Text(
            stringResource(Res.string.repo_move_busy, state.done, state.total),
            style = MaterialTheme.typography.bodySmall,
        )
        InkLinearProgressIndicator({
            if (state.total ==
                0
            ) {
                0f
            } else {
                state.done.toFloat() / state.total
            }
        }, Modifier.fillMaxWidth())
    }
}

@Composable
private fun MoveResult(result: RepoMoveResult) {
    Text(stringResource(Res.string.repo_move_result, result.moved, result.titlesMoved, result.titlesKept))
    if (result.unmatched.isNotEmpty()) {
        Text(
            stringResource(Res.string.repo_move_unmatched, result.unmatched.joinToString(", ")),
            color = MaterialTheme.colorScheme.outline,
        )
    }
    if (result.failed.isNotEmpty()) {
        Text(
            stringResource(Res.string.repo_move_failed, result.failed.joinToString(", ")),
            color = MaterialTheme.colorScheme.error,
        )
    }
}

@Composable
private fun Busy(text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        InkCircularProgressIndicator(strokeWidth = 3.dp)
        Text(text)
    }
}
