package com.sumizuri.app.feature.library.shelves

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.library.shelf.ConditionField
import com.sumizuri.app.data.model.library.shelf.ConditionOp
import com.sumizuri.app.data.model.library.shelf.ShelfCondition
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.shelf_template_aside
import com.sumizuri.app.shared.resources.shelf_template_done
import com.sumizuri.app.shared.resources.shelf_template_fresh
import com.sumizuri.app.shared.resources.shelf_template_reading
import com.sumizuri.app.shared.resources.shelf_template_untouched
import com.sumizuri.app.ui.kit.chips.SoftActionChip
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// A smart shelf ready to use, which the person can change after.
private class ShelfTemplate(val label: StringResource, val conditions: List<ShelfCondition>)

private val Templates = listOf(
    // Started and not finished.
    ShelfTemplate(
        Res.string.shelf_template_reading,
        listOf(
            ShelfCondition(ConditionField.Progress, ConditionOp.Greater, "0"),
            ShelfCondition(ConditionField.Unread, ConditionOp.Greater, "0"),
        ),
    ),
    // A new chapter this week that is not read yet.
    ShelfTemplate(
        Res.string.shelf_template_fresh,
        listOf(
            ShelfCondition(ConditionField.Updated, ConditionOp.Less, "7"),
            ShelfCondition(ConditionField.Unread, ConditionOp.Greater, "0"),
        ),
    ),
    // Chapters left, and not opened for a month.
    ShelfTemplate(
        Res.string.shelf_template_aside,
        listOf(
            ShelfCondition(ConditionField.LastRead, ConditionOp.Greater, "30"),
            ShelfCondition(ConditionField.Unread, ConditionOp.Greater, "0"),
        ),
    ),
    ShelfTemplate(
        Res.string.shelf_template_untouched,
        listOf(ShelfCondition(ConditionField.Progress, ConditionOp.Is, "0")),
    ),
    // Finished by its makers, and every chapter read.
    ShelfTemplate(
        Res.string.shelf_template_done,
        listOf(
            ShelfCondition(ConditionField.Status, ConditionOp.Is, Status.Completed.name),
            ShelfCondition(ConditionField.Unread, ConditionOp.Is, "0"),
        ),
    ),
)

// Smart shelves ready to use, offered one tap away. A pick replaces the conditions, and every title must meet all of them.
@Composable
internal fun ShelfTemplates(onPick: (List<ShelfCondition>) -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        for (template in Templates) {
            SoftActionChip({ onPick(template.conditions) }, { Text(stringResource(template.label)) })
        }
    }
}
