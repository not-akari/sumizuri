package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Undo
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.EditNote
import androidx.compose.material.icons.outlined.LinkOff
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.TrackStatus
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_delete
import com.sumizuri.app.shared.resources.tracker_leave_out_short
import com.sumizuri.app.shared.resources.tracker_pick_failed
import com.sumizuri.app.shared.resources.tracker_pick_remove_message
import com.sumizuri.app.shared.resources.tracker_pick_remove_title
import com.sumizuri.app.shared.resources.tracker_pick_status
import com.sumizuri.app.shared.resources.tracker_take_back
import com.sumizuri.app.shared.resources.tracker_unlink
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.dock.DockAction
import com.sumizuri.app.ui.kit.dock.PickDock
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The titles picked on a tracker page with a long press. While some are picked a tap picks or lets go too.
internal class Picking {
    var ids by mutableStateOf(emptySet<Long>())
    val on: Boolean get() = ids.isNotEmpty()

    fun toggle(id: Long) {
        ids = if (id in ids) ids - id else ids + id
    }
}

// What can be done to the picked titles of a list, which depends on the list.
internal enum class PickActions { Linked, Unlinked, LeftOut }

// The bar over the covers while titles are picked: how many, picking all of the list or none, and what can be done to them together.
@Composable
internal fun PickBar(tracker: TrackerId, picking: Picking, shownIds: List<Long>, actions: PickActions, kind: Kind) {
    val sync = LocalAppContainer.current.trackerSync
    val scope = rememberCoroutineScope()
    var busy by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(0) }
    var removing by remember { mutableStateOf(false) }

    // Runs one action on the picked titles and lets go of them when it ends.
    fun run(step: suspend (Set<Long>) -> Int) {
        val ids = picking.ids
        busy = true
        scope.launch {
            failed = runCatching { step(ids) }.getOrDefault(ids.size)
            busy = false
            picking.ids = emptySet()
        }
    }
    val all = shownIds.isNotEmpty() && picking.ids.containsAll(shownIds)
    // The same dock of picked items as the library, with what can be done on the tracker.
    PickDock(picking.ids.size, all, { picking.ids = if (all) emptySet() else picking.ids + shownIds }, {
        picking.ids =
            emptySet()
    }) {
        if (busy) {
            Box(Modifier.weight(1f).height(40.dp), contentAlignment = Alignment.Center) {
                InkCircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
            }
            return@PickDock
        }
        when (actions) {
            PickActions.Linked -> {
                StatusPick(kind) { status ->
                    run { ids ->
                        sync.changeStatus(tracker, ids, status.code)
                        0
                    }
                }
                DockAction(Icons.Outlined.LinkOff, stringResource(Res.string.tracker_unlink), false, {
                    run { sync.unlinkMany(tracker, it, removeThere = false) }
                })
                DockAction(
                    Icons.Outlined.DeleteOutline,
                    stringResource(
                        Res.string.tracker_delete,
                        tracker.label,
                    ),
                    false,
                    {
                        removing =
                            true
                    },
                )
            }

            PickActions.Unlinked -> DockAction(
                Icons.Outlined.VisibilityOff,
                stringResource(
                    Res.string.tracker_leave_out_short,
                ),
                false,
                {
                    run { ids ->
                        sync.use.leaveOut(tracker, ids)
                        0
                    }
                },
            )

            PickActions.LeftOut -> DockAction(
                Icons.AutoMirrored.Outlined.Undo,
                stringResource(
                    Res.string.tracker_take_back,
                ),
                false,
                {
                    run { ids ->
                        sync.use.takeBack(tracker, ids)
                        0
                    }
                },
            )
        }
    }
    if (failed > 0) {
        Text(
            pluralStringResource(Res.plurals.tracker_pick_failed, failed, failed, tracker.label),
            color = MaterialTheme.colorScheme.error,
            style = MaterialTheme.typography.bodySmall,
        )
    }
    if (removing) {
        val count = picking.ids.size
        ConfirmDialog(
            pluralStringResource(Res.plurals.tracker_pick_remove_title, count, count, tracker.label),
            stringResource(Res.string.tracker_pick_remove_message, tracker.label),
            stringResource(Res.string.tracker_delete, tracker.label),
            onConfirm = {
                removing = false
                run { sync.unlinkMany(tracker, it, removeThere = true) }
            },
            onDismiss = { removing = false },
        )
    }
}

// The action that gives the picked titles one status, picked from a menu that opens over it.
@Composable
private fun RowScope.StatusPick(kind: Kind, onPick: (TrackStatus) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box(Modifier.weight(1f)) {
        Row {
            DockAction(
                Icons.Outlined.EditNote,
                stringResource(Res.string.tracker_pick_status),
                open,
                { open = true },
            )
        }
        AppMenu(open, { open = false }) {
            for (status in TrackStatus.entries) {
                AppMenuItem({ Text(statusLabel(status, kind)) }, {
                    open = false
                    onPick(status)
                })
            }
        }
    }
}
