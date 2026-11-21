package com.sumizuri.app.feature.browse.extensions

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.add
import com.sumizuri.app.shared.resources.extensions_file_kind
import com.sumizuri.app.shared.resources.extensions_file_lang
import com.sumizuri.app.shared.resources.extensions_file_name
import com.sumizuri.app.shared.resources.extensions_file_reading
import com.sumizuri.app.shared.resources.extensions_file_site
import com.sumizuri.app.shared.resources.extensions_file_title
import com.sumizuri.app.shared.resources.extensions_file_trust
import com.sumizuri.app.shared.resources.ok
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.stringResource

// What the person gets after picking a source file: a wait while it is read, the reason when it cannot be used, or what it says about itself with a name to change and the kind of the source to choose, and a note that the code is somebody else's.
@Composable
internal fun ImportSourceDialog(
    state: ImportSourceState,
    onName: (String) -> Unit,
    onKind: (Kind) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.extensions_file_title)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                when {
                    state.busy -> {
                        Text(stringResource(Res.string.extensions_file_reading))
                        InkCircularProgressIndicator(strokeWidth = 2.dp)
                    }

                    state.problem != null -> Text(state.problem, color = MaterialTheme.colorScheme.error)

                    else -> {
                        Text(
                            stringResource(Res.string.extensions_file_trust),
                            style = MaterialTheme.typography.bodyMedium,
                        )
                        AppTextField(state.name, onName, label = {
                            Text(stringResource(Res.string.extensions_file_name))
                        }, singleLine = true)
                        if (state.lang.isNotBlank()) {
                            Text(
                                stringResource(Res.string.extensions_file_lang, languageName(state.lang)),
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                        if (state.baseUrl.isNotBlank()) {
                            Text(
                                stringResource(Res.string.extensions_file_site, state.baseUrl),
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                        Text(
                            stringResource(Res.string.extensions_file_kind),
                            style = MaterialTheme.typography.labelLarge,
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            for (kind in Kind.entries) {
                                SoftChip(
                                    state.kind == kind,
                                    { onKind(kind) },
                                    { Text(stringResource(kind.label)) },
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            if (state.usable) {
                TextButton(onConfirm, enabled = state.name.isNotBlank()) { Text(stringResource(Res.string.add)) }
            } else if (!state.busy) {
                TextButton(onDismiss) { Text(stringResource(Res.string.ok)) }
            }
        },
        dismissButton = if (state.usable) ({ CancelButton(onDismiss) }) else null,
    )
}

// A source file that was picked, with what it says about itself and the kind the person gives it. The kind is not in the file, so it is asked for. A problem with no code means the file could not be used.
data class ImportSourceState(
    val name: String = "",
    val lang: String = "",
    val baseUrl: String = "",
    val iconUrl: String = "",
    val kind: Kind = Kind.Manga,
    val code: String = "",
    // The file is being read and started once to see what it says.
    val busy: Boolean = false,
    val problem: String? = null,
) {
    val usable: Boolean get() = code.isNotEmpty() && problem == null
}
