package com.sumizuri.app.feature.settings.system

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.net.Connection
import com.sumizuri.app.data.net.FieldKind
import com.sumizuri.app.data.net.FieldSpec
import com.sumizuri.app.data.net.qrTextOf
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.network_delete
import com.sumizuri.app.shared.resources.network_file_bad
import com.sumizuri.app.shared.resources.network_file_choose
import com.sumizuri.app.shared.resources.network_file_none
import com.sumizuri.app.shared.resources.network_hostkey_forget
import com.sumizuri.app.shared.resources.network_name
import com.sumizuri.app.shared.resources.network_qr
import com.sumizuri.app.shared.resources.network_qr_name
import com.sumizuri.app.shared.resources.network_state_failed
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.input.rememberFilePicker
import com.sumizuri.app.ui.kit.input.rememberImagePicker
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import org.jetbrains.compose.resources.stringResource

// The largest file taken for a field. A key or a WireGuard config is a few kilobytes, so anything bigger is the wrong file.
private const val FileMaxBytes = 64L * 1024

// What a file must hold to be taken for a field, so a public key or a picture is turned away at once.
private val FileMarks = mapOf("key" to "PRIVATE KEY", "config" to "[Interface]")

// The text of a file chosen for a field, or null when it is too big or not the right kind.
internal fun connectionFileText(path: Path, key: String): String? = runCatching {
    val size = FileSystem.SYSTEM.metadataOrNull(path)?.size ?: 0
    if (size > FileMaxBytes) null else FileSystem.SYSTEM.read(path) { readUtf8() }
}.getOrNull()?.takeIf { text -> FileMarks[key]?.let { it in text } != false }

// Edits one connection, drawing the fields its kind lists, so every kind is edited the same way.
@Composable
internal fun ConnectionDialog(
    start: Connection,
    isNew: Boolean,
    problem: String?,
    onSave: (Connection) -> Unit,
    onDelete: () -> Unit,
    onDismiss: () -> Unit,
) {
    var draft by remember(start.id) { mutableStateOf(start) }
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(start.type.label)) },
        text = {
            Column(
                Modifier.heightIn(max = 520.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                // Why the last try to connect failed, told in full here since the list only says that it failed.
                if (problem != null) {
                    Text(
                        stringResource(Res.string.network_state_failed) + ": " + problem,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
                LineField(draft.name, stringResource(Res.string.network_name), null, ready = draft.name.isNotBlank()) {
                    draft = draft.copy(name = it)
                }
                for (field in draft.type.fields) {
                    Field(field, draft) { key, value -> draft = draft.with(key, value) }
                }
            }
        },
        confirmButton = {
            InkButton(
                { onSave(draft.copy(name = draft.name.trim())) },
                enabled = draft.ready && draft.name.isNotBlank(),
            ) {
                Text(stringResource(Res.string.save))
            }
        },
        dismissButton = {
            Row {
                if (!isNew) {
                    TextButton(onDelete) {
                        Text(stringResource(Res.string.network_delete), color = MaterialTheme.colorScheme.error)
                    }
                }
                TextButton(onDismiss) { Text(stringResource(Res.string.cancel)) }
            }
        },
    )
}

// One field by its kind.
@Composable
private fun Field(field: FieldSpec, connection: Connection, onChange: (String, String) -> Unit) {
    val value = connection[field.key]
    val hint = field.hint?.let { stringResource(it) }
    val ready = connection.fieldReady(field)
    when (field.kind) {
        FieldKind.Text -> LineField(value, stringResource(field.label), hint, ready) { onChange(field.key, it) }

        FieldKind.Number -> LineField(value, stringResource(field.label), hint, ready, keyboard = KeyboardType.Number) {
            onChange(field.key, it.filter(Char::isDigit).take(5))
        }

        FieldKind.Secret -> LineField(value, stringResource(field.label), hint, ready, secret = true) {
            onChange(field.key, it)
        }

        FieldKind.Choice -> ChoiceSetting(stringResource(field.label), field.choices, value, {
            it.uppercase()
        }) { onChange(field.key, it) }

        FieldKind.File -> FileField(field, connection, hint, onChange)

        FieldKind.Fingerprint -> Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(stringResource(field.label), style = MaterialTheme.typography.bodyMedium)
                Text(
                    value.ifEmpty {
                        hint.orEmpty()
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
            if (value.isNotEmpty()) {
                TextButton({
                    onChange(field.key, "")
                }) { Text(stringResource(Res.string.network_hostkey_forget)) }
            }
        }
    }
}

// A file whose text is kept in the field, with the name it came with beside it.
@Composable
private fun FileField(field: FieldSpec, connection: Connection, hint: String?, onChange: (String, String) -> Unit) {
    var wrong by remember { mutableStateOf(false) }
    val pick = rememberFilePicker { path ->
        val text = connectionFileText(path, field.key)
        wrong = text == null
        if (!wrong && text != null) {
            onChange(field.key, text.trim() + "\n")
            onChange("${field.key}.name", path.name)
        }
    }
    val chosen = connection["${field.key}.name"].ifEmpty { if (connection[field.key].isNotEmpty()) field.key else "" }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(stringResource(field.label), style = MaterialTheme.typography.bodyMedium)
            Text(
                when {
                    wrong -> stringResource(Res.string.network_file_bad)
                    chosen.isEmpty() -> hint ?: stringResource(Res.string.network_file_none)
                    else -> chosen
                },
                style = MaterialTheme.typography.bodySmall,
                color = if (wrong) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.outline,
            )
        }
        // A WireGuard config is often shared as a QR code, which a picture of it or a screenshot can be read from.
        if (field.key == "config") {
            val scope = rememberCoroutineScope()
            val qrName = stringResource(Res.string.network_qr_name)
            val pickQr = rememberImagePicker { bytes ->
                scope.launch {
                    val text = withContext(Dispatchers.Default) { qrTextOf(bytes) }
                    wrong = text == null || "[Interface]" !in text
                    if (!wrong && text != null) {
                        onChange(field.key, text.trim() + "\n")
                        onChange("${field.key}.name", qrName)
                    }
                }
            }
            TextButton(pickQr) { Text(stringResource(Res.string.network_qr)) }
        }
        TextButton(pick) { Text(stringResource(Res.string.network_file_choose)) }
    }
}

// One line of text. A secret is hidden until the eye is pressed.
@Composable
private fun LineField(
    value: String,
    label: String,
    hint: String?,
    ready: Boolean,
    secret: Boolean = false,
    keyboard: KeyboardType = KeyboardType.Text,
    onChange: (String) -> Unit,
) {
    var shown by remember { mutableStateOf(false) }
    AppTextField(
        value,
        onChange,
        Modifier.fillMaxWidth(),
        label = { Text(label) },
        supportingText = hint?.let { { Text(it) } },
        isError = value.isNotEmpty() && !ready,
        singleLine = true,
        visualTransformation = if (secret && !shown) PasswordVisualTransformation() else VisualTransformation.None,
        keyboardOptions = KeyboardOptions(keyboardType = if (secret) KeyboardType.Password else keyboard),
        trailingIcon = if (secret) {
            {
                IconButton(
                    { shown = !shown },
                ) { Icon(if (shown) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility, null) }
            }
        } else {
            null
        },
    )
}
