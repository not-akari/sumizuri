package com.sumizuri.app.feature.tv.browse

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInHorizontally
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.feature.tv.onboarding.firstFocus
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_home_network
import com.sumizuri.app.shared.resources.browse_home_network_hint
import com.sumizuri.app.shared.resources.browse_preferences
import com.sumizuri.app.shared.resources.tv_off
import com.sumizuri.app.shared.resources.tv_on
import com.sumizuri.app.shared.resources.tv_profile_done
import com.sumizuri.app.shared.resources.tv_text_empty
import com.sumizuri.app.source.host.store.HomeNetworkKey
import com.sumizuri.app.source.model.PreferenceType
import com.sumizuri.app.source.model.SourcePreference
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.TvChoiceRow
import com.sumizuri.app.ui.tv.TvLinkRow
import com.sumizuri.app.ui.tv.TvOverlay
import com.sumizuri.app.ui.tv.TvTextEntry
import com.sumizuri.app.ui.tv.hiddenUnder
import com.sumizuri.app.ui.tv.shownValue
import org.jetbrains.compose.resources.stringResource

// The settings of one source over its page on a TV, sliding in from the side, each saved as soon as it is changed. Back closes it, and so does Done.
@Composable
internal fun TvSourceSettings(
    preferences: List<SourcePreference>,
    values: Map<String, Any?>,
    onChange: (String, Any?) -> Unit,
    onClose: () -> Unit,
) {
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) { onClose() }
    val shown = remember { MutableTransitionState(false).apply { targetState = true } }
    // The written value open to change, over the list.
    var editing by remember { mutableStateOf<SourcePreference?>(null) }
    val ms = motionMs(AppMotion.Page)
    AnimatedVisibility(shown, enter = slideInHorizontally(tween(ms)) { it / 8 } + fadeIn(tween(ms))) {
        TvOverlay {
            val first = firstFocus()
            Column(
                Modifier
                    .fillMaxSize()
                    .hiddenUnder(editing != null)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 56.dp, vertical = 36.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(stringResource(Res.string.browse_preferences), fontSize = 34.sp, fontWeight = FontWeight.SemiBold)
                Column(Modifier.widthIn(max = 760.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    OnOffRow(
                        stringResource(Res.string.browse_home_network),
                        values[HomeNetworkKey].let { it == true || it == "true" },
                        { onChange(HomeNetworkKey, it) },
                        Modifier.focusRequester(first),
                    )
                    Hint(stringResource(Res.string.browse_home_network_hint))
                    for (preference in preferences) {
                        PreferenceRow(preference, values[preference.key] ?: preference.defaultValue, onChange) {
                            editing =
                                it
                        }
                    }
                    TvButton(
                        stringResource(Res.string.tv_profile_done),
                        onClose,
                        Modifier.padding(top = 6.dp),
                        main = false,
                    )
                }
            }
            editing?.let { preference ->
                TvTextEntry(
                    preference.title,
                    preference.summary,
                    (values[preference.key] ?: preference.defaultValue)?.toString().orEmpty(),
                    preference.secure,
                ) { text ->
                    if (text != values[preference.key]?.toString()) onChange(preference.key, text)
                    editing = null
                }
            }
        }
    }
}

@Composable
private fun PreferenceRow(
    preference: SourcePreference,
    value: Any?,
    onChange: (String, Any?) -> Unit,
    onEdit: (SourcePreference) -> Unit,
) {
    when (preference.type) {
        PreferenceType.Switch -> OnOffRow(preference.title, value == true || value == "true", {
            onChange(preference.key, it)
        })

        PreferenceType.EditText -> TextRow(preference, value?.toString().orEmpty(), onEdit)

        PreferenceType.List -> if (preference.options.isNotEmpty()) {
            val values = preference.options.map { it.value }
            TvChoiceRow(
                preference.title,
                values,
                value?.toString()?.takeIf { it in values } ?: values.first(),
                { option -> preference.options.first { it.value == option }.label },
                { onChange(preference.key, it) },
            )
        }

        PreferenceType.MultiSelectList -> {
            val now = (value as? List<*>).orEmpty().map { it.toString() }
            Text(preference.title, fontSize = 18.sp, modifier = Modifier.padding(top = 6.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                for (option in preference.options) {
                    val on = option.value in now
                    TvButton(
                        option.label,
                        { onChange(preference.key, if (on) now - option.value else now + option.value) },
                        main = on,
                    )
                }
            }
        }
    }
    preference.summary?.takeIf { it.isNotBlank() }?.let { Hint(it) }
}

// A written value, such as a server address or a user name, shown as a row. OK opens it alone at the top of the screen to write it.
@Composable
private fun TextRow(preference: SourcePreference, value: String, onEdit: (SourcePreference) -> Unit) {
    TvLinkRow(
        preference.title,
        shownValue(value, preference.secure) ?: stringResource(Res.string.tv_text_empty),
        { onEdit(preference) },
    )
}

@Composable
private fun OnOffRow(name: String, on: Boolean, onChange: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val yes = stringResource(Res.string.tv_on)
    val no = stringResource(Res.string.tv_off)
    TvChoiceRow(name, listOf(true, false), on, { if (it) yes else no }, onChange, modifier)
}

@Composable
private fun Hint(text: String) {
    Text(
        text,
        Modifier.padding(horizontal = 22.dp),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}
