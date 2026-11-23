package com.sumizuri.app.feature.tv.settings.system

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInHorizontally
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.net.Connection
import com.sumizuri.app.data.net.FieldKind
import com.sumizuri.app.data.net.FieldSpec
import com.sumizuri.app.feature.settings.system.connectionFileText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.network_delete
import com.sumizuri.app.shared.resources.network_file_bad
import com.sumizuri.app.shared.resources.network_file_choose
import com.sumizuri.app.shared.resources.network_hostkey_forget
import com.sumizuri.app.shared.resources.network_name
import com.sumizuri.app.shared.resources.network_state_failed
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.shared.resources.tv_network_delete_sure
import com.sumizuri.app.shared.resources.tv_network_not_ready
import com.sumizuri.app.shared.resources.tv_text_empty
import com.sumizuri.app.ui.kit.input.rememberFilePicker
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.TvChoiceRow
import com.sumizuri.app.ui.tv.TvOverlay
import com.sumizuri.app.ui.tv.TvTextEntry
import com.sumizuri.app.ui.tv.hiddenUnder
import com.sumizuri.app.ui.tv.shownValue
import org.jetbrains.compose.resources.stringResource

// The key of the name of the connection among the keys of its fields.
private const val NameKey = "\u0000name"

// Edits one connection on a TV, over the network page: a row for each field its kind lists, where OK on a written one opens it alone at the top of the screen. Back leaves without saving.
@Composable
internal fun TvConnectionEditor(
    start: Connection,
    isNew: Boolean,
    problem: String?,
    onSave: (Connection) -> Unit,
    onDelete: () -> Unit,
    onClose: () -> Unit,
) {
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) { onClose() }
    var draft by remember(start.id) { mutableStateOf(start) }
    var typing by remember { mutableStateOf<String?>(null) }
    var sure by remember { mutableStateOf(false) }
    var tried by remember { mutableStateOf(false) }
    val shown = remember { MutableTransitionState(false).apply { targetState = true } }
    val ms = motionMs(AppMotion.Page)
    val failed = stringResource(Res.string.network_state_failed)
    AnimatedVisibility(shown, enter = slideInHorizontally(tween(ms)) { it / 8 } + fadeIn(tween(ms))) {
        TvOverlay {
            TvSystemPage(
                stringResource(start.type.label),
                problem?.let { "$failed: $it" },
                Modifier.hiddenUnder(typing != null),
            ) { first ->
                TvInfoRow(
                    stringResource(Res.string.network_name),
                    null,
                    draft.name.ifBlank { stringResource(Res.string.tv_text_empty) },
                    { typing = NameKey },
                    Modifier.focusRequester(first),
                )
                for (field in draft.type.fields) {
                    FieldRow(field, draft, { typing = field.key }) { key, value -> draft = draft.with(key, value) }
                }
                if (tried && !(draft.ready && draft.name.isNotBlank())) {
                    Text(
                        stringResource(Res.string.tv_network_not_ready),
                        Modifier.padding(horizontal = 4.dp),
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
                Row(Modifier.padding(top = 6.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    TvButton(stringResource(Res.string.save), {
                        tried = true
                        if (draft.ready && draft.name.isNotBlank()) onSave(draft.copy(name = draft.name.trim()))
                    })
                    TvButton(stringResource(Res.string.cancel), onClose, main = false)
                    if (!isNew) {
                        TvButton(
                            stringResource(if (sure) Res.string.tv_network_delete_sure else Res.string.network_delete),
                            { if (sure) onDelete() else sure = true },
                            main = false,
                        )
                    }
                }
            }
            typing?.let { key ->
                val field = draft.type.fields.firstOrNull { it.key == key }
                TvTextEntry(
                    field?.label?.let { stringResource(it) } ?: stringResource(Res.string.network_name),
                    field?.hint?.let { stringResource(it) },
                    if (field == null) draft.name else draft[key],
                    field?.kind == FieldKind.Secret,
                ) { text ->
                    draft = when {
                        field == null -> draft.copy(name = text)
                        field.kind == FieldKind.Number -> draft.with(key, text.filter(Char::isDigit).take(5))
                        else -> draft.with(key, text)
                    }
                    typing = null
                }
            }
        }
    }
}

// One field by its kind: written ones open the big text box, a choice changes with left and right, a file opens the file picker of the system, and a fingerprint can be forgotten.
@Composable
private fun FieldRow(field: FieldSpec, connection: Connection, onType: () -> Unit, onChange: (String, String) -> Unit) {
    val value = connection[field.key]
    val label = stringResource(field.label)
    val hint = field.hint?.let { stringResource(it) }
    val empty = stringResource(Res.string.tv_text_empty)
    when (field.kind) {
        FieldKind.Text, FieldKind.Number, FieldKind.Secret ->
            TvInfoRow(label, hint, shownValue(value, field.kind == FieldKind.Secret) ?: empty, onType)

        FieldKind.Choice -> TvChoiceRow(label, field.choices, value, { it.uppercase() }, { onChange(field.key, it) })

        FieldKind.File -> {
            var wrong by remember { mutableStateOf(false) }
            val pick = rememberFilePicker { path ->
                val text = connectionFileText(path, field.key)
                wrong = text == null
                if (text != null) {
                    onChange(field.key, text.trim() + "\n")
                    onChange("${field.key}.name", path.name)
                }
            }
            val chosen = connection["${field.key}.name"].ifEmpty { if (value.isNotEmpty()) field.key else "" }
            TvInfoRow(
                label,
                if (wrong) stringResource(Res.string.network_file_bad) else hint,
                chosen.ifEmpty { stringResource(Res.string.network_file_choose) },
                pick,
                valueColor = if (wrong) MaterialTheme.colorScheme.error else Color.Unspecified,
            )
        }

        FieldKind.Fingerprint -> TvInfoRow(
            label,
            value.ifEmpty { hint.orEmpty() },
            if (value.isNotEmpty()) stringResource(Res.string.network_hostkey_forget) else null,
            { if (value.isNotEmpty()) onChange(field.key, "") },
        )
    }
}
