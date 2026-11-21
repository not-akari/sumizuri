package com.sumizuri.app.feature.library.shelves

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.library.shelf.ConditionField
import com.sumizuri.app.data.model.library.shelf.ShelfCondition
import com.sumizuri.app.data.model.library.shelf.ValueKind
import com.sumizuri.app.data.text.enumNamed
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.cond_no
import com.sumizuri.app.shared.resources.cond_remove
import com.sumizuri.app.shared.resources.cond_unit_days
import com.sumizuri.app.shared.resources.cond_unit_percent
import com.sumizuri.app.shared.resources.cond_unit_rating
import com.sumizuri.app.shared.resources.cond_value
import com.sumizuri.app.shared.resources.cond_yes
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.input.MenuButton
import org.jetbrains.compose.resources.stringResource

// The statuses a condition can name.
private val Statuses = Status.entries.filter { it != Status.Unknown }

// One condition: the field, how to compare it and the value, with the way the value is entered following from the field. A choice, a yes or no, a piece of text and a number each have their own control. Changing the field starts the value again.
@Composable
internal fun ConditionRow(condition: ShelfCondition, onChange: (ShelfCondition) -> Unit, onRemove: () -> Unit) {
    val field = condition.field
    Surface(Modifier.fillMaxWidth(), MaterialTheme.shapes.small, MaterialTheme.colorScheme.surfaceContainerHighest) {
        Column(
            Modifier.padding(start = 10.dp, top = 6.dp, bottom = 8.dp, end = 4.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                MenuButton(ConditionField.entries, field, { stringResource(it.label) }, Modifier.weight(1f)) { next ->
                    onChange(ShelfCondition(next, next.ops.first(), startOf(next)))
                }
                MenuButton(field.ops, condition.op, {
                    stringResource(it.label)
                }, Modifier.weight(1f)) { onChange(condition.copy(op = it)) }
                IconButton(onRemove) { Icon(Icons.Outlined.Close, stringResource(Res.string.cond_remove)) }
            }
            when (field.value) {
                ValueKind.Choice -> {
                    val options: List<String> = if (field ==
                        ConditionField.Status
                    ) {
                        Statuses.map { it.name }
                    } else {
                        Kind.entries.map { it.name }
                    }
                    MenuButton(
                        options,
                        condition.value.takeIf {
                            it in options
                        } ?: options.first(),
                        { name -> labelOf(field, name) },
                    ) { onChange(condition.copy(value = it)) }
                }

                ValueKind.Flag -> MenuButton(listOf("true", "false"), condition.value.ifBlank { "true" }, {
                    stringResource(
                        if (it ==
                            "true"
                        ) {
                            Res.string.cond_yes
                        } else {
                            Res.string.cond_no
                        },
                    )
                }) { onChange(condition.copy(value = it)) }

                ValueKind.Number -> AppTextField(
                    condition.value,
                    { onChange(condition.copy(value = it.filter { char -> char.isDigit() || char == '.' })) },
                    Modifier.fillMaxWidth().padding(end = 6.dp),
                    singleLine = true,
                    label = { Text(stringResource(Res.string.cond_value)) },
                    suffix = unitOf(field)?.let { unit -> { Text(stringResource(unit)) } },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                )

                ValueKind.Text -> AppTextField(condition.value, {
                    onChange(condition.copy(value = it))
                }, Modifier.fillMaxWidth().padding(end = 6.dp), singleLine = true, label = {
                    Text(stringResource(Res.string.cond_value))
                })
            }
        }
    }
}

// What a field starts with when it is chosen: the first of its choices, yes, or nothing for the fields that are typed.
private fun startOf(field: ConditionField): String = when (field.value) {
    ValueKind.Choice -> if (field == ConditionField.Status) Statuses.first().name else Kind.entries.first().name
    ValueKind.Flag -> "true"
    else -> ""
}

@Composable
private fun labelOf(field: ConditionField, name: String): String = if (field == ConditionField.Status) {
    enumNamed<Status>(name)?.let { stringResource(it.label) } ?: name
} else {
    enumNamed<Kind>(name)?.let { stringResource(it.label) } ?: name
}

private fun unitOf(field: ConditionField) = when (field) {
    ConditionField.Progress -> Res.string.cond_unit_percent
    ConditionField.Added -> Res.string.cond_unit_days
    ConditionField.Rating -> Res.string.cond_unit_rating
    else -> null
}
