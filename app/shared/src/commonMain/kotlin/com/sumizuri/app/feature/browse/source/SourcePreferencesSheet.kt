package com.sumizuri.app.feature.browse.source

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Router
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_home_network
import com.sumizuri.app.shared.resources.browse_home_network_hint
import com.sumizuri.app.shared.resources.browse_preferences
import com.sumizuri.app.shared.resources.browse_secret_hide
import com.sumizuri.app.shared.resources.browse_secret_show
import com.sumizuri.app.source.host.store.HomeNetworkKey
import com.sumizuri.app.source.model.PreferenceType
import com.sumizuri.app.source.model.SourcePreference
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.setting.ChipsSetting
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import org.jetbrains.compose.resources.stringResource

// The settings a source lets the reader change, together in one card, each saved as soon as it is changed.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SourcePreferencesSheet(
    preferences: List<SourcePreference>,
    values: Map<String, Any?>,
    onChange: (String, Any?) -> Unit,
    onDismiss: () -> Unit,
) {
    AppSheet(onDismiss, spacing = 12.dp, title = stringResource(Res.string.browse_preferences)) {
        SettingsSection {
            // Built into every source with settings, for servers a person runs at home.
            padded {
                SwitchSetting(
                    Res.string.browse_home_network,
                    values[HomeNetworkKey].let { it == true || it == "true" },
                    { onChange(HomeNetworkKey, it) },
                    Res.string.browse_home_network_hint,
                    icon = Icons.Outlined.Router,
                )
            }
            for (preference in preferences) {
                padded {
                    PreferenceRow(
                        preference,
                        values[preference.key] ?: preference.defaultValue,
                        onChange,
                    )
                }
            }
        }
    }
}

@Composable
private fun PreferenceRow(preference: SourcePreference, value: Any?, onChange: (String, Any?) -> Unit) {
    when (preference.type) {
        PreferenceType.Switch -> SwitchSetting(preference.title, value == true || value == "true", {
            onChange(preference.key, it)
        }, preference.summary)

        PreferenceType.EditText -> {
            var text by remember(preference.key) { mutableStateOf(value?.toString().orEmpty()) }
            // A password or a key stays hidden until the person asks to see it.
            var shown by remember(preference.key) { mutableStateOf(false) }
            val hidden = preference.secure && !shown
            AppTextField(
                text,
                {
                    text = it
                    onChange(preference.key, it)
                },
                Modifier.fillMaxWidth().padding(vertical = 6.dp),
                label = { Text(preference.title) },
                supportingText = preference.summary?.let { summary -> { Text(summary) } },
                singleLine = true,
                visualTransformation = if (hidden) PasswordVisualTransformation() else VisualTransformation.None,
                keyboardOptions = if (preference.secure) {
                    KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrectEnabled = false)
                } else {
                    KeyboardOptions.Default
                },
                trailingIcon = if (preference.secure) {
                    {
                        IconButton({ shown = !shown }) {
                            Icon(
                                if (shown) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility,
                                stringResource(
                                    if (shown) Res.string.browse_secret_hide else Res.string.browse_secret_show,
                                ),
                            )
                        }
                    }
                } else {
                    null
                },
            )
        }

        PreferenceType.List -> ChoiceSetting(
            preference.title,
            preference.options.map { it.value },
            value?.toString(),
            { option ->
                preference.options
                    .firstOrNull { it.value == option }
                    ?.label
                    .orEmpty()
            },
            hint = preference.summary,
        ) { onChange(preference.key, it) }

        PreferenceType.MultiSelectList -> {
            val now = (value as? List<*>).orEmpty().map { it.toString() }
            ChipsSetting(
                preference.title,
                preference.options.map { it.value to it.label },
                now.toSet(),
                { option -> onChange(preference.key, if (option in now) now - option else now + option) },
                hint = preference.summary,
            )
        }
    }
}
