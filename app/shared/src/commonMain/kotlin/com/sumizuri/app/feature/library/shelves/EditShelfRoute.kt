package com.sumizuri.app.feature.library.shelves

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.UpdateDisabled
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.LibrarySortField
import com.sumizuri.app.data.model.library.SortRule
import com.sumizuri.app.data.model.library.shelf.ShelfCondition
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.edit_leave
import com.sumizuri.app.shared.resources.edit_leave_message
import com.sumizuri.app.shared.resources.edit_leave_title
import com.sumizuri.app.shared.resources.edit_name
import com.sumizuri.app.shared.resources.rule_own_order
import com.sumizuri.app.shared.resources.rule_status
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.shared.resources.shelves_delete
import com.sumizuri.app.shared.resources.shelves_delete_message
import com.sumizuri.app.shared.resources.shelves_edit
import com.sumizuri.app.shared.resources.shelves_every_kind
import com.sumizuri.app.shared.resources.shelves_exclude
import com.sumizuri.app.shared.resources.shelves_kind
import com.sumizuri.app.shared.resources.sort_ascending
import com.sumizuri.app.shared.resources.sort_by
import com.sumizuri.app.shared.resources.sort_descending
import com.sumizuri.app.shared.resources.sort_direction
import com.sumizuri.app.shared.resources.sort_then
import com.sumizuri.app.shared.resources.sort_then_direction
import com.sumizuri.app.shared.resources.sort_then_none
import com.sumizuri.app.shared.resources.status_any
import com.sumizuri.app.ui.kit.art.InkTonalButton
import com.sumizuri.app.ui.kit.card.CardButton
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsRows
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import org.jetbrains.compose.resources.stringResource

// The statuses a shelf can be told to show, with null for all of them.
private val Statuses: List<Status?> = listOf(null, Status.Ongoing, Status.Completed, Status.Hiatus, Status.Cancelled)

// The page that changes one shelf, opened by tapping it on the shelves page.
@Composable
fun EditShelfRoute(shelfId: Long, onBack: () -> Unit) {
    val container = LocalAppContainer.current
    val viewModel = viewModel { ShelvesViewModel(container.categories, container.library, container.sources) }
    val categories by viewModel.categories.collectAsStateWithLifecycle()
    val shelf = categories?.firstOrNull { it.id == shelfId } ?: return
    EditShelfScreen(
        shelf,
        viewModel::countMatches,
        onSave = { edit ->
            viewModel.onSave(shelf, edit)
            onBack()
        },
        onDelete = {
            viewModel.onDelete(shelf.id)
            onBack()
        },
        onBack = onBack,
    )
}

// What a shelf can be changed to: its name and kind, the conditions that put titles on it by themselves, an order of its own with a second field for ties, the one status it shows, and whether its titles are left out of the check for new chapters. Save is in the bar, leaving with changes asks first, and deleting asks again.
@Composable
private fun EditShelfScreen(
    shelf: Category,
    countMatches: (List<ShelfCondition>, Boolean) -> Int,
    onSave: (ShelfEdit) -> Unit,
    onDelete: () -> Unit,
    onBack: () -> Unit,
) {
    var name by remember(shelf.id) { mutableStateOf(shelf.name) }
    var exclude by remember(shelf.id) { mutableStateOf(shelf.excludeFromUpdate) }
    var kind by remember(shelf.id) { mutableStateOf(shelf.kind) }
    var rule by remember(shelf.id) { mutableStateOf(shelf.rule) }
    var status by remember(shelf.id) { mutableStateOf(shelf.status) }
    var conditions by remember(shelf.id) { mutableStateOf(shelf.conditions) }
    var matchAll by remember(shelf.id) { mutableStateOf(shelf.matchAll) }
    var leaving by remember { mutableStateOf(false) }
    var deleting by remember { mutableStateOf(false) }
    val edit = ShelfEdit(name, exclude, kind, rule, status, conditions, matchAll)
    val dirty = edit.differsFrom(shelf)
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = dirty) {
        leaving = true
    }
    SettingsPageFrame(
        Res.string.shelves_edit,
        onBack = { if (dirty) leaving = true else onBack() },
        actions = {
            InkTonalButton({ onSave(edit) }, Modifier.padding(end = 8.dp), enabled = dirty && name.isNotBlank()) {
                Text(stringResource(Res.string.save))
            }
        },
    ) {
        SettingsSection {
            padded {
                AppTextField(
                    name,
                    { name = it },
                    Modifier.fillMaxWidth().padding(top = 6.dp),
                    singleLine = true,
                    label = { Text(stringResource(Res.string.edit_name)) },
                )
            }
            padded {
                ChoiceSetting(Res.string.shelves_kind, listOf<Kind?>(null) + Kind.entries, kind, {
                    it?.let { shown -> stringResource(shown.label) } ?: stringResource(Res.string.shelves_every_kind)
                }) { kind = it }
            }
        }
        SettingsSection {
            padded {
                ConditionEditor(conditions, matchAll, countMatches(conditions, matchAll), { conditions = it }, {
                    matchAll = it
                })
            }
        }
        SettingsSection {
            padded {
                SwitchSetting(
                    Res.string.rule_own_order,
                    rule != null,
                    { on -> rule = if (on) SortRule() else null },
                )
            }
            rule?.let { own -> orderRows(own) { rule = it } }
            padded {
                ChoiceSetting(Res.string.rule_status, Statuses, status, {
                    it?.let { shown -> stringResource(shown.label) } ?: stringResource(Res.string.status_any)
                }) { status = it }
            }
            padded {
                SwitchSetting(
                    Res.string.shelves_exclude,
                    exclude,
                    { exclude = it },
                    icon = Icons.Outlined.UpdateDisabled,
                )
            }
        }
        CardButton({ deleting = true }) {
            Icon(
                Icons.Outlined.DeleteOutline,
                null,
                Modifier.padding(start = 12.dp),
                tint = MaterialTheme.colorScheme.error,
            )
            Text(
                stringResource(Res.string.shelves_delete),
                Modifier.padding(horizontal = 12.dp, vertical = 11.dp),
                color = MaterialTheme.colorScheme.error,
            )
        }
    }
    if (leaving) {
        ConfirmDialog(
            stringResource(Res.string.edit_leave_title),
            stringResource(Res.string.edit_leave_message),
            stringResource(Res.string.edit_leave),
            onConfirm = {
                leaving = false
                onBack()
            },
            onDismiss = { leaving = false },
        )
    }
    if (deleting) {
        ConfirmDialog(
            stringResource(Res.string.shelves_delete) + ": " + shelf.name,
            stringResource(Res.string.shelves_delete_message),
            stringResource(Res.string.shelves_delete),
            onConfirm = {
                deleting = false
                onDelete()
            },
            onDismiss = { deleting = false },
        )
    }
}

// The rows of an order of its own: the field, its direction, a second field for ties and the direction of that one.
private fun SettingsRows.orderRows(own: SortRule, onRule: (SortRule) -> Unit) {
    val directions = listOf(true, false)
    padded {
        ChoiceSetting(Res.string.sort_by, LibrarySortField.entries, own.sort, { stringResource(it.label) }) {
            onRule(own.copy(sort = it, then = own.then?.takeIf { next -> next != it }))
        }
    }
    padded {
        ChoiceSetting(Res.string.sort_direction, directions, own.ascending, { directionLabel(it) }) {
            onRule(own.copy(ascending = it))
        }
    }
    padded {
        ChoiceSetting(
            Res.string.sort_then,
            listOf<LibrarySortField?>(null) + LibrarySortField.entries.filter { it != own.sort },
            own.then,
            { it?.let { field -> stringResource(field.label) } ?: stringResource(Res.string.sort_then_none) },
        ) { onRule(own.copy(then = it)) }
    }
    if (own.then != null) {
        padded {
            ChoiceSetting(Res.string.sort_then_direction, directions, own.thenAscending, { directionLabel(it) }) {
                onRule(own.copy(thenAscending = it))
            }
        }
    }
}

@Composable
private fun directionLabel(ascending: Boolean): String =
    stringResource(if (ascending) Res.string.sort_ascending else Res.string.sort_descending)
