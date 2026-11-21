package com.sumizuri.app.feature.browse.source

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_save_tab
import com.sumizuri.app.shared.resources.browse_save_tab_confirm
import com.sumizuri.app.shared.resources.browse_save_tab_name
import com.sumizuri.app.shared.resources.browse_tab_delete
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import org.jetbrains.compose.resources.stringResource

// Asks for the name of the tab that a search is kept under. With a delete action it is also how a saved tab is renamed or removed.
@Composable
fun SavedTabDialog(
    initial: String,
    onConfirm: (String) -> Unit,
    onDismiss: () -> Unit,
    onDelete: (() -> Unit)? = null,
) {
    var name by remember { mutableStateOf(initial) }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.browse_save_tab)) },
        text = {
            AppTextField(name, {
                name = it
            }, label = { Text(stringResource(Res.string.browse_save_tab_name)) }, singleLine = true)
        },
        confirmButton = {
            InkButton({
                onConfirm(name)
                onDismiss()
            }, enabled = name.isNotBlank()) { Text(stringResource(Res.string.browse_save_tab_confirm)) }
        },
        dismissButton = {
            CancelButton(onDismiss)
            if (onDelete != null) {
                TextButton({
                    onDelete()
                    onDismiss()
                }) { Text(stringResource(Res.string.browse_tab_delete), color = MaterialTheme.colorScheme.error) }
            }
        },
    )
}
