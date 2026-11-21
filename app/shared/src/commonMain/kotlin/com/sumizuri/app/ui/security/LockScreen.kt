package com.sumizuri.app.ui.security

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.security.AppLock
import com.sumizuri.app.data.security.DeviceUnlock
import com.sumizuri.app.data.security.LockPrefs
import com.sumizuri.app.data.security.SecureScreen
import com.sumizuri.app.data.settings.ReaderSettingsRepository
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.lock_pin
import com.sumizuri.app.shared.resources.lock_pin_wrong
import com.sumizuri.app.shared.resources.lock_prompt
import com.sumizuri.app.shared.resources.lock_title
import com.sumizuri.app.shared.resources.lock_unlock
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.input.AppTextField
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The longest a PIN may be.
internal const val PinMaxLength = 12

// What guards the app over everything else: the screen hidden from screenshots when the person chose so, always or while reading incognito, and the lock.
@Composable
fun AppGuard(lock: AppLock, reading: ReaderSettingsRepository) {
    val prefs by lock.prefs.collectAsStateWithLifecycle(LockPrefs())
    val incognito by remember(reading) {
        reading.observe(AnyTitle).map { it.incognito }.distinctUntilChanged()
    }.collectAsStateWithLifecycle(false)
    SecureWindow(
        when (prefs.secureScreen) {
            SecureScreen.Always -> true
            SecureScreen.Incognito -> incognito
            SecureScreen.Off -> false
        },
    )
    LockGate(lock)
}

// Incognito is the same for every title, so any number reads it.
private const val AnyTitle = 0L

// Drawn over the whole app: nothing while the lock is open, a plain cover while the choices are read, and the lock while it is closed. Where a window losing the focus means the app is away, it is watched here.
@Composable
private fun LockGate(lock: AppLock) {
    val locked by lock.locked.collectAsStateWithLifecycle()
    if (DeviceUnlock.awayOnBlur) {
        val focused = LocalWindowInfo.current.isWindowFocused
        LaunchedEffect(focused) { if (focused) lock.onBack() else lock.onAway() }
    }
    when (locked) {
        null -> Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {}
        true -> LockScreen(lock)
        false -> Unit
    }
}

// The lock: the mark of the app and the way to open it, with the lock of the system, which is asked for at once, or with the PIN of the app. Nothing under it can be seen or touched, and back does nothing.
@Composable
private fun LockScreen(lock: AppLock) {
    val prompt = stringResource(Res.string.lock_prompt)
    val ask = rememberSystemUnlock(prompt) { lock.unlock() }
    val backState = rememberNavigationEventState(NavigationEventInfo.None)
    NavigationBackHandler(backState, isBackEnabled = true) {}
    Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        Box(Modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
            Column(
                Modifier.widthIn(max = 360.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Box(
                    Modifier
                        .size(
                            72.dp,
                        ).background(MaterialTheme.colorScheme.primaryContainer, MaterialTheme.shapes.extraLarge),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        Icons.Outlined.Lock,
                        null,
                        Modifier.size(36.dp),
                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                    )
                }
                Text(
                    stringResource(Res.string.lock_title),
                    style = MaterialTheme.typography.titleLarge,
                    textAlign = TextAlign.Center,
                )
                if (DeviceUnlock.usesSystem) {
                    val open = {
                        lock.onPrompt()
                        ask()
                    }
                    LaunchedEffect(Unit) { open() }
                    InkButton(open) { Text(stringResource(Res.string.lock_unlock)) }
                } else {
                    PinEntry(lock)
                }
            }
        }
    }
}

// The field for the PIN of the app, which opens the lock when the PIN is right and says so when it is not.
@Composable
private fun PinEntry(lock: AppLock) {
    var pin by remember { mutableStateOf("") }
    var wrong by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) { runCatching { focus.requestFocus() } }
    val check = {
        val typed = pin
        scope.launch {
            if (lock.checkPin(typed)) {
                lock.unlock()
            } else {
                wrong = true
                pin = ""
            }
        }
        Unit
    }
    AppTextField(
        pin,
        { typed ->
            pin = typed.filter(Char::isDigit).take(PinMaxLength)
            wrong = false
        },
        Modifier.focusRequester(focus),
        label = { Text(stringResource(Res.string.lock_pin)) },
        isError = wrong,
        supportingText = if (wrong) ({ Text(stringResource(Res.string.lock_pin_wrong)) }) else null,
        singleLine = true,
        visualTransformation = PasswordVisualTransformation(),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword, imeAction = ImeAction.Done),
        keyboardActions = KeyboardActions(onDone = { check() }),
    )
    InkButton(check, enabled = pin.isNotEmpty()) { Text(stringResource(Res.string.lock_unlock)) }
}
