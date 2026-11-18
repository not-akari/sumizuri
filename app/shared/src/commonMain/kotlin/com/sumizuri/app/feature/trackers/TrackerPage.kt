package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Category
import androidx.compose.material.icons.outlined.History
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.db.tracker.LibraryTitle
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.LinkOutcome
import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.feature.settings.PageRow
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_account_section
import com.sumizuri.app.shared.resources.sync_settings_section
import com.sumizuri.app.shared.resources.tracker_add_all_done
import com.sumizuri.app.shared.resources.tracker_add_button
import com.sumizuri.app.shared.resources.tracker_add_done
import com.sumizuri.app.shared.resources.tracker_add_hint
import com.sumizuri.app.shared.resources.tracker_add_hint_missed
import com.sumizuri.app.shared.resources.tracker_add_not_found
import com.sumizuri.app.shared.resources.tracker_add_pick
import com.sumizuri.app.shared.resources.tracker_add_stopped
import com.sumizuri.app.shared.resources.tracker_add_title
import com.sumizuri.app.shared.resources.tracker_details_hint
import com.sumizuri.app.shared.resources.tracker_details_title
import com.sumizuri.app.shared.resources.tracker_filter_gone
import com.sumizuri.app.shared.resources.tracker_filter_left_out
import com.sumizuri.app.shared.resources.tracker_filter_linked
import com.sumizuri.app.shared.resources.tracker_filter_not_found
import com.sumizuri.app.shared.resources.tracker_filter_only_on
import com.sumizuri.app.shared.resources.tracker_filter_unlinked
import com.sumizuri.app.shared.resources.tracker_linking_progress
import com.sumizuri.app.shared.resources.tracker_linking_start
import com.sumizuri.app.shared.resources.tracker_search_again
import com.sumizuri.app.shared.resources.tracker_sign_out
import com.sumizuri.app.shared.resources.tracker_sign_out_message
import com.sumizuri.app.shared.resources.tracker_sign_out_title
import com.sumizuri.app.shared.resources.tracker_use_hint
import com.sumizuri.app.shared.resources.tracker_use_title
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.setting.ChipsSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// Which titles the page lists.
private enum class Shown { Linked, Unlinked, NotFound, Gone, LeftOut, OnTracker }

// A tracker this profile is signed in to, on one page with no tabs: how its sync stands, the titles in one list with chips that pick which, and its settings and account at the end.
@Composable
internal fun TrackerHome(tracker: TrackerId, account: TrackerAccount, onOpen: (SettingsTarget) -> Unit) {
    val container = LocalAppContainer.current
    val sync = container.trackerSync
    val scope = rememberCoroutineScope()
    var leaving by remember { mutableStateOf(false) }
    if (leaving) {
        ConfirmDialog(
            stringResource(Res.string.tracker_sign_out_title, tracker.label),
            stringResource(Res.string.tracker_sign_out_message, tracker.label),
            stringResource(Res.string.tracker_sign_out),
            onConfirm = {
                leaving = false
                scope.launch { container.trackers.signOut(tracker) }
            },
            onDismiss = { leaving = false },
        )
    }
    val links by remember(sync, tracker) { sync.links(tracker) }.collectAsStateWithLifecycle(null)
    val unlinked by remember(sync, tracker) { sync.linker.unlinked(tracker) }.collectAsStateWithLifecycle(emptyList())
    val leftOut by remember(sync, tracker) { sync.linker.leftOut(tracker) }.collectAsStateWithLifecycle(emptyList())
    val missed by remember(sync, tracker) { sync.use.missed(tracker) }.collectAsStateWithLifecycle(emptySet())
    // Titles a search found nothing for are kept apart from those not searched yet, so the person sees which need a hand.
    val (notFound, fresh) = remember(unlinked, missed) { unlinked.partition { it.id in missed } }
    var shown by rememberSaveable(tracker) { mutableStateOf(Shown.Linked) }
    val (gone, linked) = remember(links) { links.orEmpty().partition { it.gone } }
    // A choice whose chip went away, such as the last removed entry being settled, goes back to the linked titles.
    val now = when {
        shown == Shown.Gone && gone.isEmpty() -> Shown.Linked
        shown == Shown.LeftOut && leftOut.isEmpty() -> Shown.Linked
        shown == Shown.NotFound && notFound.isEmpty() -> Shown.Unlinked
        else -> shown
    }
    // The state of the sync and what to do about it, then the settings and the account.
    val side: @Composable () -> Unit = {
        TrackerHead(tracker, account)
        TrackerStats(tracker, linked)
        AddLibraryCard(tracker, fresh.size, notFound.size) { shown = Shown.NotFound }
    }
    val end: @Composable () -> Unit = {
        SettingsSection(Res.string.sync_settings_section) {
            padded { UseChips(tracker) }
            row {
                PageRow(
                    Icons.Outlined.History,
                    stringResource(
                        Res.string.tracker_details_title,
                    ),
                    stringResource(Res.string.tracker_details_hint),
                    {
                        onOpen(SettingsTarget.TrackerDetails)
                    },
                )
            }
        }
        RulesRow(onOpen)
        SettingsSection(Res.string.sync_account_section) { row { SignedInRow(account) { leaving = true } } }
    }
    val titles: @Composable () -> Unit = {
        if (links != null) TitlePart(tracker, account, now, linked, gone, fresh, notFound, leftOut) { shown = it }
    }
    // A wide window keeps the sync and settings in a column on the left and gives the rest of the width to the covers. A phone stacks them.
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        if (maxWidth >= WideFrom) {
            Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                Column(Modifier.width(SideWidth), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    side()
                    end()
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(14.dp)) { titles() }
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                side()
                titles()
                end()
            }
        }
    }
}

// The width from which the page puts its parts side by side, and how wide the side column is then.
private val WideFrom = 840.dp
private val SideWidth = 360.dp

// The chips that pick which titles show, and those titles.
@Composable
private fun TitlePart(
    tracker: TrackerId,
    account: TrackerAccount,
    now: Shown,
    linked: List<TrackerLinkEntity>,
    gone: List<TrackerLinkEntity>,
    unlinked: List<LibraryTitle>,
    notFound: List<LibraryTitle>,
    leftOut: List<LibraryTitle>,
    onShow: (Shown) -> Unit,
) {
    ChipRow {
        ChoiceChip(stringResource(Res.string.tracker_filter_linked, linked.size), now == Shown.Linked) {
            onShow(Shown.Linked)
        }
        ChoiceChip(stringResource(Res.string.tracker_filter_unlinked, unlinked.size), now == Shown.Unlinked) {
            onShow(Shown.Unlinked)
        }
        if (notFound.isNotEmpty()) {
            ChoiceChip(stringResource(Res.string.tracker_filter_not_found, notFound.size), now == Shown.NotFound) {
                onShow(Shown.NotFound)
            }
        }
        if (gone.isNotEmpty()) {
            ChoiceChip(stringResource(Res.string.tracker_filter_gone, gone.size, tracker.label), now == Shown.Gone) {
                onShow(Shown.Gone)
            }
        }
        if (leftOut.isNotEmpty()) {
            ChoiceChip(stringResource(Res.string.tracker_filter_left_out, leftOut.size), now == Shown.LeftOut) {
                onShow(Shown.LeftOut)
            }
        }
        ChoiceChip(stringResource(Res.string.tracker_filter_only_on, tracker.label), now == Shown.OnTracker) {
            onShow(Shown.OnTracker)
        }
    }
    when (now) {
        Shown.Linked -> LinkedView(tracker, account, linked, "linked")
        Shown.Unlinked -> LibraryView(tracker, unlinked, LibraryList.Unlinked)
        Shown.NotFound -> LibraryView(tracker, notFound, LibraryList.NotFound)
        Shown.Gone -> LinkedView(tracker, account, gone, "gone")
        Shown.LeftOut -> LibraryView(tracker, leftOut, LibraryList.LeftOut)
        Shown.OnTracker -> OnTrackerTab(tracker, account)
    }
}

// The kinds of titles the tracker is used for, from those it keeps. A title of a kind turned off does not show the tracker, and is not linked to it.
@Composable
private fun UseChips(tracker: TrackerId) {
    val use = LocalAppContainer.current.trackerSync.use
    val scope = rememberCoroutineScope()
    val kinds by remember(use, tracker) { use.kinds(tracker) }.collectAsStateWithLifecycle(tracker.kinds)
    ChipsSetting(
        stringResource(Res.string.tracker_use_title),
        tracker.kinds.sortedBy { it.code }.map { it.code.toString() to stringResource(it.label) },
        kinds.map { it.code.toString() }.toSet(),
        { code -> scope.launch { use.toggle(tracker, Kind.fromCode(code.toInt())) } },
        hint = stringResource(Res.string.tracker_use_hint, tracker.label),
        icon = Icons.Outlined.Category,
    )
}

// The library titles not searched on the tracker yet and the button that adds them all, found by their names. After a run it says what came of it, and titles a search found nothing for go to the person to pick, so the same search is not run again for nothing.
@Composable
private fun AddLibraryCard(tracker: TrackerId, waiting: Int, missed: Int, onPick: () -> Unit) {
    val linker = LocalAppContainer.current.trackerSync.linker
    val progress by linker.progress.collectAsStateWithLifecycle()
    val outcomes by linker.outcome.collectAsStateWithLifecycle()
    val running = progress[tracker]
    val ended = outcomes[tracker]
    if (waiting == 0 && missed == 0 && running == null && ended == null) return
    val result = (ended as? LinkOutcome.Done)?.result
    val line = when {
        running != null && running.total == 0 -> stringResource(Res.string.tracker_linking_start)

        running != null -> stringResource(Res.string.tracker_linking_progress, running.done + 1, running.total)

        result != null && result.stopped -> stringResource(
            Res.string.tracker_add_stopped,
            result.linked,
            waiting,
            tracker.label,
        )

        ended is LinkOutcome.Failed -> problemText(ended.problem, tracker, signedIn = true)

        waiting > 0 && missed > 0 -> stringResource(Res.string.tracker_add_hint_missed, waiting, tracker.label, missed)

        waiting > 0 -> stringResource(Res.string.tracker_add_hint, waiting, tracker.label)

        missed > 0 && result != null -> stringResource(Res.string.tracker_add_done, result.linked, missed)

        missed > 0 -> stringResource(Res.string.tracker_add_not_found, missed, tracker.label)

        else -> stringResource(Res.string.tracker_add_all_done, result?.linked ?: 0)
    }
    AppCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(
                        stringResource(Res.string.tracker_add_title, tracker.label),
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(
                        line,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                if (running != null) InkCircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 3.dp)
            }
            if (running == null && (waiting > 0 || missed > 0)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (waiting > 0) {
                        InkButton(
                            { linker.startLinking(tracker) },
                        ) { Text(stringResource(Res.string.tracker_add_button)) }
                    } else {
                        InkButton(onPick) { Text(stringResource(Res.string.tracker_add_pick)) }
                        TextButton({ linker.startLinking(tracker, again = true) }) {
                            Text(stringResource(Res.string.tracker_search_again))
                        }
                    }
                }
            }
        }
    }
}
