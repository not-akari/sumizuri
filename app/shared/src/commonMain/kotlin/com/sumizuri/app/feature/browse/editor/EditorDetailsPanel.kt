package com.sumizuri.app.feature.browse.editor

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.ext_edit_fill
import com.sumizuri.app.shared.resources.ext_edit_fill_hint
import com.sumizuri.app.shared.resources.ext_edit_icon
import com.sumizuri.app.shared.resources.ext_edit_lang
import com.sumizuri.app.shared.resources.ext_edit_lang_hint
import com.sumizuri.app.shared.resources.ext_edit_repo_note
import com.sumizuri.app.shared.resources.ext_edit_saved_as
import com.sumizuri.app.shared.resources.ext_edit_site
import com.sumizuri.app.shared.resources.extensions_file_kind
import com.sumizuri.app.shared.resources.extensions_file_name
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.stringResource

// What the app shows about the source: its name, language, site, icon and kind, with a button that takes them from the code. A note says where saving goes.
@Composable
internal fun EditorDetailsPanel(
    state: ExtensionEditorState,
    actions: ExtensionEditorActions,
    padding: PaddingValues,
    modifier: Modifier,
) {
    Column(
        modifier.verticalScroll(rememberScrollState()).padding(padding),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (state.fromRepo && state.savedAs == null) Note(stringResource(Res.string.ext_edit_repo_note))
        state.savedAs?.let { Note(stringResource(Res.string.ext_edit_saved_as, it)) }
        AppTextField(state.name, actions.onName, Modifier.fillMaxWidth(), label = {
            Text(stringResource(Res.string.extensions_file_name))
        }, singleLine = true)
        AppTextField(
            state.lang,
            actions.onLang,
            Modifier.fillMaxWidth(),
            label = { Text(stringResource(Res.string.ext_edit_lang)) },
            supportingText = {
                Text(
                    if (state.lang.isBlank()) {
                        stringResource(
                            Res.string.ext_edit_lang_hint,
                        )
                    } else {
                        languageName(state.lang)
                    },
                )
            },
            singleLine = true,
        )
        AppTextField(
            state.baseUrl,
            actions.onBaseUrl,
            Modifier.fillMaxWidth(),
            label = { Text(stringResource(Res.string.ext_edit_site)) },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri, autoCorrectEnabled = false),
        )
        AppTextField(
            state.iconUrl,
            actions.onIconUrl,
            Modifier.fillMaxWidth(),
            label = { Text(stringResource(Res.string.ext_edit_icon)) },
            singleLine = true,
            trailingIcon = { SourceMark(state.iconUrl, size = 28.dp) },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri, autoCorrectEnabled = false),
        )
        Text(stringResource(Res.string.extensions_file_kind), style = MaterialTheme.typography.labelLarge)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for (kind in Kind.entries) {
                SoftChip(state.kind == kind, {
                    actions.onKind(kind)
                }, { Text(stringResource(kind.label)) })
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            InkOutlinedButton(actions.onFillFromCode, enabled = state.test.running == null) {
                Text(stringResource(Res.string.ext_edit_fill))
            }
            Text(
                stringResource(Res.string.ext_edit_fill_hint),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline,
            )
            // What went wrong when the code was started for its details, as the tests show theirs on their own tab.
            if (state.test.failed ==
                TestStep.Start
            ) {
                state.test.error?.let {
                    Text(
                        it,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
            }
        }
    }
}

@Composable
private fun Note(text: String) {
    AppCard(Modifier.fillMaxWidth()) {
        Text(text, Modifier.padding(14.dp), style = MaterialTheme.typography.bodyMedium)
    }
}
