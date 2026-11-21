package com.sumizuri.app.feature.migration

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.migration.MigrationItem
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.MigrationStatus
import com.sumizuri.app.data.migration.MoveProblem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_action_change
import com.sumizuri.app.shared.resources.mig_action_exclude
import com.sumizuri.app.shared.resources.mig_action_hand
import com.sumizuri.app.shared.resources.mig_action_move
import com.sumizuri.app.shared.resources.mig_action_open
import com.sumizuri.app.shared.resources.mig_action_reject
import com.sumizuri.app.shared.resources.mig_action_retry
import com.sumizuri.app.shared.resources.mig_card_from
import com.sumizuri.app.shared.resources.mig_card_moved
import com.sumizuri.app.shared.resources.mig_card_nothing
import com.sumizuri.app.shared.resources.mig_card_ruled_out
import com.sumizuri.app.shared.resources.mig_problem_chapters
import com.sumizuri.app.shared.resources.mig_problem_exists
import com.sumizuri.app.shared.resources.mig_problem_source
import com.sumizuri.app.shared.resources.more
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.text.displayName
import org.jetbrains.compose.resources.stringResource

// One title with what the work found for it. The cover, name and source come first with its state, then what the state calls for: the chosen match, the matches to choose between, the message of a failure, or where it went. Buttons under it search by hand, leave it out, say no match is right, try again, and move it.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun ResultCard(
    item: MigrationItem,
    busy: Boolean,
    session: MigrationSession,
    onOpenTitle: (Long) -> Unit,
    onHand: () -> Unit,
) {
    var all by remember { mutableStateOf(false) }
    AppCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                CoverArt(item.title, Modifier.width(36.dp), letterSize = 13)
                Column(Modifier.weight(1f)) {
                    Text(
                        item.title.displayName(),
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        stringResource(Res.string.mig_card_from, item.fromName),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                if (item.status ==
                    MigrationStatus.Searching
                ) {
                    InkCircularProgressIndicator(Modifier.width(18.dp), strokeWidth = 2.dp)
                }
                Text(
                    stringResource(item.status.label()),
                    style = MaterialTheme.typography.labelMedium,
                    color = if (item.status ==
                        MigrationStatus.Failed
                    ) {
                        MaterialTheme.colorScheme.error
                    } else {
                        MaterialTheme.colorScheme.primary
                    },
                )
            }
            when (item.status) {
                MigrationStatus.Found -> item.chosen?.let { chosen ->
                    OptionRow(chosen, true) {}
                    if (all) {
                        item.options.filter { it !== chosen }.forEach { option ->
                            OptionRow(option, false) {
                                session.choose(item.id, option)
                                all = false
                            }
                        }
                    }
                }

                MigrationStatus.Review -> item.options.forEach { option ->
                    OptionRow(option, item.chosen === option) {
                        session.choose(item.id, option)
                    }
                }

                MigrationStatus.NotFound -> {
                    Text(
                        stringResource(Res.string.mig_card_nothing),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline,
                    )
                    if (item.ruledOut >
                        0
                    ) {
                        Text(
                            stringResource(Res.string.mig_card_ruled_out, item.ruledOut),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.outline,
                        )
                    }
                }

                MigrationStatus.Failed -> {
                    val text = item.problem?.let { stringResource(problemLabel(it)) } ?: item.error
                    if (text !=
                        null
                    ) {
                        Text(
                            text,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.error,
                        )
                    }
                }

                MigrationStatus.Moved -> Text(
                    stringResource(
                        Res.string.mig_card_moved,
                        item.chosen
                            ?.source
                            ?.name
                            .orEmpty(),
                    ),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )

                else -> Unit
            }
            // The main actions sit in a row, and the rarer ones wait in a menu at its end, so the row fits on a phone.
            Row(verticalAlignment = Alignment.CenterVertically) {
                FlowRow(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    if (item.status == MigrationStatus.Moved) {
                        item.movedTo?.let {
                            TextButton(
                                { onOpenTitle(it) },
                            ) { Text(stringResource(Res.string.mig_action_open)) }
                        }
                    } else {
                        if (item.status == MigrationStatus.Found &&
                            item.options.size > 1
                        ) {
                            TextButton({ all = !all }) { Text(stringResource(Res.string.mig_action_change)) }
                        }
                        if (item.status == MigrationStatus.Found &&
                            item.chosen != null
                        ) {
                            TextButton(
                                { session.moveOne(item.id) },
                                enabled = !busy,
                            ) { Text(stringResource(Res.string.mig_action_move)) }
                        }
                        if (item.status == MigrationStatus.Found ||
                            item.status == MigrationStatus.Review
                        ) {
                            TextButton(
                                { session.reject(item.id) },
                            ) { Text(stringResource(Res.string.mig_action_reject)) }
                        }
                        if (item.status == MigrationStatus.Failed ||
                            item.status == MigrationStatus.NotFound
                        ) {
                            TextButton(
                                { session.requeue(setOf(item.id)) },
                            ) { Text(stringResource(Res.string.mig_action_retry)) }
                        }
                    }
                }
                if (item.status != MigrationStatus.Moved) {
                    var menu by remember { mutableStateOf(false) }
                    Box {
                        IconButton({ menu = true }) { Icon(Icons.Outlined.MoreVert, stringResource(Res.string.more)) }
                        AppMenu(menu, { menu = false }) {
                            AppMenuItem({ Text(stringResource(Res.string.mig_action_hand)) }, {
                                menu = false
                                onHand()
                            }, enabled = !busy)
                            AppMenuItem({ Text(stringResource(Res.string.mig_action_exclude)) }, {
                                menu = false
                                session.setIncluded(setOf(item.id), false)
                            })
                            AppMenuItem({ Text(stringResource(Res.string.mig_action_open)) }, {
                                menu = false
                                onOpenTitle(item.id)
                            })
                        }
                    }
                }
            }
        }
    }
}

private fun problemLabel(problem: MoveProblem) = when (problem) {
    MoveProblem.AlreadyInLibrary -> Res.string.mig_problem_exists
    MoveProblem.ChaptersUnavailable -> Res.string.mig_problem_chapters
    MoveProblem.SourceUnavailable -> Res.string.mig_problem_source
}
