package com.sumizuri.app.ui.kit.chips

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Sort
import androidx.compose.material.icons.outlined.ArrowDownward
import androidx.compose.material.icons.outlined.ArrowUpward
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.all
import com.sumizuri.app.ui.kit.scroll.mouseDragScroll
import org.jetbrains.compose.resources.stringResource

// One row of chips under the top bar of a page, which scrolls sideways when the window is narrow. Every page puts its order, kinds and filters here. A long row can wrap onto more lines instead, on a window wide enough for that.
@Composable
fun ChipRow(modifier: Modifier = Modifier, wrap: Boolean = false, content: @Composable RowScope.() -> Unit) {
    if (wrap) {
        FlowRow(
            modifier,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) { content() }
        return
    }
    val scroll = rememberScrollState()
    Row(
        modifier.mouseDragScroll(scroll, horizontal = true).horizontalScroll(scroll),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content,
    )
}

// A thin line between groups of chips.
@Composable
fun ChipSeparator() = VerticalDivider(Modifier.height(20.dp).padding(horizontal = 2.dp))

// A chip that is on or off, with a tick while it is on.
@Composable
fun ToggleChip(label: String, on: Boolean, onClick: () -> Unit, icon: ImageVector? = null) {
    SoftChip(
        selected = on,
        onClick = onClick,
        label = { Text(label) },
        leadingIcon = when {
            on -> ({ Icon(Icons.Outlined.Check, null, Modifier.size(16.dp)) })
            icon != null -> ({ Icon(icon, null, Modifier.size(16.dp)) })
            else -> null
        },
    )
}

// A chip that says which of a few things is chosen, without a tick, for the kinds and other single choices.
@Composable
fun ChoiceChip(label: String, on: Boolean, onClick: () -> Unit) {
    SoftChip(selected = on, onClick = onClick, label = { Text(label) })
}

// The order of a page in a chip: what it is ordered by and which way, which opens the place to change it.
@Composable
fun SortChip(label: String, ascending: Boolean, onClick: () -> Unit, description: String? = null) {
    SoftActionChip(
        onClick = onClick,
        label = { Text(label) },
        leadingIcon = { Icon(Icons.AutoMirrored.Outlined.Sort, description, Modifier.size(18.dp)) },
        trailingIcon = {
            Icon(
                if (ascending) Icons.Outlined.ArrowUpward else Icons.Outlined.ArrowDownward,
                null,
                Modifier.size(16.dp),
            )
        },
    )
}

// All the kinds and each one alone, as chips. Null stands for all of them. Only the kinds the page has are offered, and with fewer than two there is nothing to choose, so no chip shows.
@Composable
fun KindChips(selected: Kind?, available: Set<Kind> = Kind.entries.toSet(), onSelect: (Kind?) -> Unit) {
    val offered = offeredKinds(available, selected)
    if (offered.size < 2) return
    for (kind in listOf<Kind?>(null) + offered) {
        ChoiceChip(
            if (kind ==
                null
            ) {
                stringResource(Res.string.all)
            } else {
                stringResource(kind.label)
            },
            selected == kind,
        ) { onSelect(kind) }
    }
}

// The kinds a page offers to narrow by: the ones it has, in their usual order, and the chosen one even when it has none of it, so the choice can be undone.
fun offeredKinds(available: Set<Kind>, selected: Kind?): List<Kind> = Kind.entries.filter {
    it in available ||
        it == selected
}

// Whether a page has kinds to choose between, so its row of kind chips earns a place.
fun hasKindChoice(available: Set<Kind>, selected: Kind?): Boolean = offeredKinds(available, selected).size >= 2
