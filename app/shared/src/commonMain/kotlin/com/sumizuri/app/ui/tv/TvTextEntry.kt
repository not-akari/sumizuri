package com.sumizuri.app.ui.tv

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_secret_hide
import com.sumizuri.app.shared.resources.browse_secret_show
import com.sumizuri.app.shared.resources.tv_profile_done
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// On a TV the keyboard of the system lies over the app instead of pushing it up, as a TV has no room for both.
@Composable
fun Modifier.keyboardOverOnTv(): Modifier = if (LocalTv.current) consumeWindowInsets(WindowInsets.ime) else this

// One written value on a TV, alone at the top of the screen so the keyboard below never covers it. The keyboard opens at once, and its done key, Done or Back keep what was written.
@Composable
fun TvTextEntry(title: String, hint: String?, value: String, secret: Boolean, onDone: (String) -> Unit) {
    var text by remember { mutableStateOf(TextFieldValue(value, TextRange(value.length))) }
    var open by remember { mutableStateOf(false) }
    val finish = { onDone(text.text) }
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) { finish() }
    val field = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current
    LaunchedEffect(Unit) {
        repeat(10) {
            delay(80)
            if (runCatching { field.requestFocus() }.getOrDefault(false)) {
                keyboard?.show()
                return@LaunchedEffect
            }
        }
    }
    val shown = remember { MutableTransitionState(false).apply { targetState = true } }
    val ms = motionMs(AppMotion.Page)
    AnimatedVisibility(shown, enter = slideInVertically(tween(ms)) { -it / 8 } + fadeIn(tween(ms))) {
        TvOverlay {
            Column(
                Modifier.padding(horizontal = 56.dp, vertical = 36.dp).widthIn(max = 900.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Text(title, fontSize = 30.sp, fontWeight = FontWeight.SemiBold)
                hint?.takeIf { it.isNotBlank() }?.let {
                    Text(it, fontSize = 16.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    AppTextField(
                        text,
                        { text = it },
                        Modifier.weight(1f).focusRequester(field),
                        textStyle = MaterialTheme.typography.titleLarge,
                        singleLine = true,
                        visualTransformation = if (secret &&
                            !open
                        ) {
                            PasswordVisualTransformation()
                        } else {
                            VisualTransformation.None
                        },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = if (secret) KeyboardType.Password else KeyboardType.Text,
                            autoCorrectEnabled = false,
                            imeAction = ImeAction.Done,
                        ),
                        keyboardActions = KeyboardActions(onDone = { finish() }),
                    )
                    if (secret) {
                        TvButton(
                            stringResource(if (open) Res.string.browse_secret_hide else Res.string.browse_secret_show),
                            { open = !open },
                            main = false,
                        )
                    }
                    TvButton(stringResource(Res.string.tv_profile_done), finish)
                }
            }
        }
    }
}

// How a written value shows in a row: dots for a password or a key, and nothing for an empty one.
fun shownValue(value: String, secret: Boolean): String? = when {
    value.isEmpty() -> null
    secret -> "•".repeat(8)
    else -> value
}
