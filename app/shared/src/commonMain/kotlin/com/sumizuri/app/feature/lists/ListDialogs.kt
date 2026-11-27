package com.sumizuri.app.feature.lists

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.lists.ListAboutLimit
import com.sumizuri.app.data.lists.ListNameLimit
import com.sumizuri.app.data.lists.ListNoteLimit
import com.sumizuri.app.data.lists.TitleNameLimit
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.edit_name
import com.sumizuri.app.shared.resources.list_about
import com.sumizuri.app.shared.resources.list_add_title
import com.sumizuri.app.shared.resources.list_edit
import com.sumizuri.app.shared.resources.list_note
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.shared.resources.shelves_add
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// Changes the name of a list and the line about it.
@Composable
internal fun EditListDialog(
    name: String,
    about: String,
    onSave: (String, String) -> Unit,
    onDismiss: () -> Unit,
    title: StringResource = Res.string.list_edit,
    confirm: StringResource = Res.string.save,
    notice: ListNotice? = null,
) {
    var newName by rememberSaveable { mutableStateOf(name) }
    var newAbout by rememberSaveable { mutableStateOf(about) }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(title)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Field(
                    newName,
                    { newName = it.take(ListNameLimit) },
                    stringResource(Res.string.edit_name),
                    single = true,
                )
                Field(newAbout, { newAbout = it.take(ListAboutLimit) }, stringResource(Res.string.list_about))
                NoticeLine(notice)
            }
        },
        confirmButton = {
            InkButton({ onSave(newName, newAbout) }, enabled = newName.isNotBlank()) {
                Text(stringResource(confirm))
            }
        },
        dismissButton = { CancelButton(onDismiss) },
    )
}

// Changes the note of one title on a list. An empty note takes it away.
@Composable
internal fun NoteDialog(title: String, note: String, onSave: (String) -> Unit, onDismiss: () -> Unit) {
    var text by rememberSaveable { mutableStateOf(note) }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Field(text, { text = it.take(ListNoteLimit) }, stringResource(Res.string.list_note)) },
        confirmButton = { InkButton({ onSave(text) }) { Text(stringResource(Res.string.save)) } },
        dismissButton = { CancelButton(onDismiss) },
    )
}

@Composable
private fun Field(value: String, onChange: (String) -> Unit, label: String, single: Boolean = false) {
    AppTextField(value, onChange, Modifier.fillMaxWidth(), singleLine = single, label = { Text(label) })
}
