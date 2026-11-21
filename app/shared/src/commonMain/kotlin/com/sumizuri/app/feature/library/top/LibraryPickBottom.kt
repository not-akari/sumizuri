package com.sumizuri.app.feature.library.top

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Label
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.PlaylistRemove
import androidx.compose.material.icons.outlined.RemoveDone
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.sumizuri.app.feature.library.LibraryPickCalls
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.library_shelves
import com.sumizuri.app.shared.resources.pick_favorite
import com.sumizuri.app.shared.resources.pick_migrate
import com.sumizuri.app.shared.resources.pick_read
import com.sumizuri.app.shared.resources.pick_unfavorite
import com.sumizuri.app.shared.resources.pick_unread
import com.sumizuri.app.shared.resources.remove
import com.sumizuri.app.shared.resources.title_action_move
import com.sumizuri.app.ui.kit.dock.DockAction
import com.sumizuri.app.ui.kit.dock.PickDock
import org.jetbrains.compose.resources.stringResource

// The dock of the picked titles: how many with the ways to pick all, flip and stop, and what can be done to them. Moving to another source is done for one title in a page of its own, and for several in the page for moving many. The favorite action is null when favorites are off, and otherwise says whether it adds or takes off.
@Composable
internal fun LibraryPickBottom(
    count: Int,
    total: Int,
    favorite: Boolean?,
    calls: LibraryPickCalls,
    modifier: Modifier = Modifier,
) {
    PickDock(count, count == total, calls.onSelectAll, calls.onClose, modifier, onInvert = calls.onInvert) {
        DockAction(Icons.Outlined.DoneAll, stringResource(Res.string.pick_read), false, { calls.onMarkRead(true) })
        DockAction(
            Icons.Outlined.RemoveDone,
            stringResource(Res.string.pick_unread),
            false,
            { calls.onMarkRead(false) },
        )
        if (favorite != null) {
            DockAction(
                if (favorite) Icons.Outlined.StarBorder else Icons.Outlined.Star,
                stringResource(if (favorite) Res.string.pick_favorite else Res.string.pick_unfavorite),
                false,
                { calls.onFavorite(favorite) },
            )
        }
        DockAction(
            Icons.AutoMirrored.Outlined.Label,
            stringResource(Res.string.library_shelves),
            false,
            calls.onShelves,
        )
        if (count == 1) {
            DockAction(Icons.Outlined.SwapHoriz, stringResource(Res.string.title_action_move), false, calls.onMove)
        } else {
            DockAction(Icons.Outlined.SwapHoriz, stringResource(Res.string.pick_migrate), false, calls.onMigrate)
        }
        DockAction(Icons.Outlined.PlaylistRemove, stringResource(Res.string.remove), false, calls.onRemove)
    }
}
