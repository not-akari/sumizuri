package com.sumizuri.app.feature.library.top

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
import androidx.compose.material3.TextButton
import androidx.compose.material3.TriStateCheckbox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.shelves_add
import com.sumizuri.app.shared.resources.shelves_apply
import com.sumizuri.app.shared.resources.shelves_new
import com.sumizuri.app.shared.resources.shelves_none
import com.sumizuri.app.shared.resources.shelves_title
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// Puts the picked titles on shelves. A shelf has a box that is ticked when every picked title is on it, half ticked when some are, and empty when none is. A new shelf can be made here and is ticked at once.
@Composable
internal fun ShelvesDialog(
    categories: List<Category>,
    picked: Int,
    onShelves: Map<Long, Int>,
    onCreate: suspend (String) -> Long?,
    onApply: (add: Set<Long>, remove: Set<Long>) -> Unit,
    onDismiss: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val now = remember { mutableStateMapOf<Long, ToggleableState>() }
    fun start(id: Long): ToggleableState = (onShelves[id] ?: 0).let {
        if (it == 0) {
            ToggleableState.Off
        } else if (it >= picked) {
            ToggleableState.On
        } else {
            ToggleableState.Indeterminate
        }
    }
    var name by remember { mutableStateOf("") }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.shelves_title)) },
        text = {
            Column(Modifier.heightIn(max = 420.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())) {
                    if (categories.isEmpty()) {
                        Text(
                            stringResource(Res.string.shelves_none),
                            color = MaterialTheme.colorScheme.outline,
                        )
                    }
                    for (shelf in categories) {
                        val state = now[shelf.id] ?: start(shelf.id)
                        Row(
                            Modifier.fillMaxWidth().clickable {
                                now[shelf.id] =
                                    if (state ==
                                        ToggleableState.On
                                    ) {
                                        ToggleableState.Off
                                    } else {
                                        ToggleableState.On
                                    }
                            },
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            TriStateCheckbox(state, null, Modifier.padding(end = 8.dp))
                            Text(shelf.name, style = MaterialTheme.typography.bodyLarge)
                        }
                    }
                }
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    AppTextField(name, {
                        name = it
                    }, Modifier.weight(1f), singleLine = true, label = { Text(stringResource(Res.string.shelves_new)) })
                    TextButton({
                        scope.launch {
                            onCreate(name)?.let { id -> now[id] = ToggleableState.On }
                            name = ""
                        }
                    }, enabled = name.isNotBlank()) { Text(stringResource(Res.string.shelves_add)) }
                }
            }
        },
        confirmButton = {
            InkButton({
                val add = now
                    .filter { (id, state) ->
                        state == ToggleableState.On && start(
                            id,
                        ) != ToggleableState.On
                    }.keys
                val remove = now
                    .filter { (id, state) ->
                        state == ToggleableState.Off &&
                            start(id) != ToggleableState.Off
                    }.keys
                onApply(add.toSet(), remove.toSet())
            }) { Text(stringResource(Res.string.shelves_apply)) }
        },
        dismissButton = { CancelButton(onDismiss) },
    )
}
