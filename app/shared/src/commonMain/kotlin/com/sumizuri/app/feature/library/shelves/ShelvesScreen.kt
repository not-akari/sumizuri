package com.sumizuri.app.feature.library.shelves

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Label
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.shelf.forKind
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.all
import com.sumizuri.app.shared.resources.shelves_add
import com.sumizuri.app.shared.resources.shelves_empty
import com.sumizuri.app.shared.resources.shelves_hint
import com.sumizuri.app.shared.resources.shelves_new
import com.sumizuri.app.shared.resources.shelves_title
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.KindChips
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.scroll.DragReorderColumn
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.motion.entrance
import org.jetbrains.compose.resources.stringResource

// The page where shelves are made, put in order by dragging, changed by tapping them and deleted. It is built like the editor of the top of the library.
@Composable
internal fun ShelvesScreen(categories: List<Category>?, onBack: () -> Unit, calls: ShelfCalls) {
    // The kind whose shelves are shown, where no kind shows them all.
    var kind by remember { mutableStateOf<Kind?>(null) }
    var name by remember { mutableStateOf("") }
    SettingsPageFrame(Res.string.shelves_title, onBack, subtitle = Res.string.shelves_hint) {
        // A new shelf is named in a card of its own, for the kind picked under it.
        SettingsSection {
            padded {
                Row(
                    Modifier.fillMaxWidth().padding(vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    AppTextField(name, {
                        name = it
                    }, Modifier.weight(1f), singleLine = true, label = { Text(stringResource(Res.string.shelves_new)) })
                    InkButton({
                        calls.onAdd(name, kind)
                        name = ""
                    }, enabled = name.isNotBlank()) { Text(stringResource(Res.string.shelves_add)) }
                }
            }
        }
        ChipRow { KindChips(kind) { kind = it } }
        val shown = categories.orEmpty().forKind(kind)
        // With no shelves for the kind, a soft card says so in place of the list.
        if (categories != null && shown.isEmpty()) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .entrance()
                    .softCard()
                    .padding(horizontal = 16.dp, vertical = 18.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Icon(Icons.AutoMirrored.Outlined.Label, null, tint = MaterialTheme.colorScheme.primary)
                Text(
                    stringResource(Res.string.shelves_empty),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        if (shown.isNotEmpty()) {
            DragReorderColumn(shown, {
                it.id
            }, { ordered ->
                calls.onReorder(
                    withOrder(
                        categories.orEmpty(),
                        ordered.map {
                            it.id
                        },
                    ),
                )
            }) { shelf, lifted, handle, rowModifier ->
                ShelfCard(shelf, lifted, handle, onEdit = { calls.onEdit(shelf.id) }, modifier = rowModifier)
            }
        }
    }
}

// The order of every shelf when the ones that are shown are put in the order given, which takes the places the shown ones had and leaves the others where they are.
private fun withOrder(all: List<Category>, shown: List<Long>): List<Long> {
    val places = shown.toMutableList()
    val here = shown.toSet()
    return all.map { if (it.id in here) places.removeAt(0) else it.id }
}
