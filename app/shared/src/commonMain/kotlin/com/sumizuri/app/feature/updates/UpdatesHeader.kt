package com.sumizuri.app.feature.updates

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.library.UncategorizedShelf
import com.sumizuri.app.feature.library.top.ConnectionLostNotice
import com.sumizuri.app.feature.library.top.FailuresNotice
import com.sumizuri.app.feature.library.top.MissingSourcesNotice
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.all
import com.sumizuri.app.shared.resources.shelf_none
import com.sumizuri.app.shared.resources.updates_hidden
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.FilterTabs
import com.sumizuri.app.ui.kit.chips.KindChips
import com.sumizuri.app.ui.kit.chips.hasKindChoice
import com.sumizuri.app.ui.motion.Unfold
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// What stands above the feed and scrolls with it: the notes, which unfold as they come and go, the shelves as tabs when there are shelves, and the kinds as chips when the new chapters are of more than one kind, laid out as on the library.
@Composable
internal fun UpdatesHeader(state: UpdatesState, calls: UpdatesCalls, onShowFailures: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Unfold(state.failures.isNotEmpty()) {
            FailuresNotice(state.failures.size, onShowFailures, calls.onDismissFailures)
        }
        Unfold(state.unchecked > 0 && state.progress == null) {
            ConnectionLostNotice(state.unchecked, calls.onUpdate, calls.onDismissFailures)
        }
        Unfold(state.hidden > 0) {
            MissingSourcesNotice(
                pluralStringResource(Res.plurals.updates_hidden, state.hidden, state.hidden),
                calls.onOpenMissing,
            )
        }
        if (state.tabs.isNotEmpty()) {
            val all = stringResource(Res.string.all)
            val none = stringResource(Res.string.shelf_none)
            val names = state.shelves.associate { it.id to it.name }
            FilterTabs(
                state.tabs.map { id ->
                    id to when (id) {
                        null -> all
                        UncategorizedShelf -> none
                        else -> names.getValue(id)
                    }
                },
                state.shelf,
                calls.onShelf,
            )
        }
        if (hasKindChoice(state.kinds, state.kind)) ChipRow { KindChips(state.kind, state.kinds, calls.onKind) }
    }
}
