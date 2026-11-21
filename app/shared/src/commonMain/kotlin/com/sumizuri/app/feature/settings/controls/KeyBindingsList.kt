package com.sumizuri.app.feature.settings.controls

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.keys_add
import com.sumizuri.app.shared.resources.keys_none
import com.sumizuri.app.shared.resources.keys_reset
import com.sumizuri.app.shared.resources.keys_reset_all
import com.sumizuri.app.ui.controls.KeyChord
import com.sumizuri.app.ui.controls.text
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.input.ActionButton
import com.sumizuri.app.ui.motion.entrance
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// Every action with its keys. A key is added by pressing it in a small window, taken off with the cross on its chip, and an action goes back to its usual keys with Reset.
@OptIn(ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
internal fun <T> KeyBindingsList(
    rows: List<KeyRow<T>>,
    keys: Map<T, List<KeyChord>>,
    needsModifier: Boolean,
    onAdd: (T, KeyChord) -> Unit,
    onRemove: (T, KeyChord) -> Unit,
    onReset: (T) -> Unit,
    onResetAll: () -> Unit,
) {
    var recording by remember { mutableStateOf<KeyRow<T>?>(null) }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for (row in rows) {
            val chords = keys[row.action].orEmpty()
            AppCard(Modifier.entrance().fillMaxWidth()) {
                Column(
                    Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            stringResource(row.label),
                            Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.SemiBold,
                        )
                        TextButton({ onReset(row.action) }) { Text(stringResource(Res.string.keys_reset)) }
                    }
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        if (chords.isEmpty()) {
                            Text(
                                stringResource(Res.string.keys_none),
                                Modifier.padding(vertical = 8.dp),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.outline,
                            )
                        }
                        for (chord in chords) {
                            SoftChip(
                                selected = false,
                                onClick = { onRemove(row.action, chord) },
                                label = { Text(chord.text()) },
                                trailingIcon = { Icon(Icons.Outlined.Close, null, Modifier.size(16.dp)) },
                            )
                        }
                        TextButton({ recording = row }) {
                            Icon(Icons.Outlined.Add, null, Modifier.size(18.dp))
                            Text(stringResource(Res.string.keys_add), Modifier.padding(start = 4.dp))
                        }
                    }
                }
            }
        }
        ActionButton(Res.string.keys_reset_all, onResetAll)
    }
    recording?.let { row ->
        KeyRecorderDialog(
            action = stringResource(row.label),
            takenBy = { chord ->
                rows
                    .firstOrNull { it.action != row.action && chord in keys[it.action].orEmpty() }
                    ?.label
            },
            needsModifier = needsModifier,
            onRecorded = { chord ->
                onAdd(row.action, chord)
                recording = null
            },
            onDismiss = { recording = null },
        )
    }
}

// One action in the list, with the label the person reads for it.
internal class KeyRow<T>(val action: T, val label: StringResource)
