package com.sumizuri.app.setup

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.LibraryBooks
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.setup_cancel
import com.sumizuri.app.shared.resources.setup_close
import com.sumizuri.app.shared.resources.setup_done_text
import com.sumizuri.app.shared.resources.setup_done_title
import com.sumizuri.app.shared.resources.setup_done_updated
import com.sumizuri.app.shared.resources.setup_failed_text
import com.sumizuri.app.shared.resources.setup_failed_title
import com.sumizuri.app.shared.resources.setup_open
import com.sumizuri.app.shared.resources.setup_remove
import com.sumizuri.app.shared.resources.setup_remove_data
import com.sumizuri.app.shared.resources.setup_remove_data_hint
import com.sumizuri.app.shared.resources.setup_remove_text
import com.sumizuri.app.shared.resources.setup_remove_title
import com.sumizuri.app.shared.resources.setup_removed_kept
import com.sumizuri.app.shared.resources.setup_removed_text
import com.sumizuri.app.shared.resources.setup_removed_title
import com.sumizuri.app.shared.resources.setup_retry
import com.sumizuri.app.ui.kit.art.AnimatedLogo
import com.sumizuri.app.ui.kit.art.DrawnCheck
import com.sumizuri.app.ui.kit.art.MainButton
import com.sumizuri.app.ui.kit.art.QuietButton
import com.sumizuri.app.ui.kit.art.rise
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import org.jetbrains.compose.resources.stringResource
import java.io.File
import kotlin.math.sin

@Composable
internal fun DonePage(model: SetupModel, onClose: () -> Unit) {
    SetupPage(
        stringResource(if (model.updating) Res.string.setup_done_updated else Res.string.setup_done_title),
        stringResource(Res.string.setup_done_text, model.appFolder.path, model.dataFolder.path),
        bottom = {
            QuietButton(stringResource(Res.string.setup_close), onClose)
            Spacer(Modifier.weight(1f))
            MainButton(stringResource(Res.string.setup_open), {
                model.openWhenClosed()
                onClose()
            }, Icons.AutoMirrored.Outlined.OpenInNew)
        },
        top = { DrawnCheck(Modifier.size(96.dp)) },
    ) {}
}

// What went wrong, with an icon that shakes once, the reason, and where the log is to look further.
@Composable
internal fun FailedPage(model: SetupModel, log: File, onClose: () -> Unit) {
    val shake = remember { Animatable(0f) }
    var details by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { shake.animateTo(1f, tween(600)) }
    SetupPage(
        stringResource(Res.string.setup_failed_title),
        null,
        bottom = {
            QuietButton(stringResource(Res.string.setup_close), onClose)
            Spacer(Modifier.weight(1f))
            if (model.mode ==
                SetupMode.Install
            ) {
                MainButton(stringResource(Res.string.setup_retry), model::install, Icons.Rounded.Refresh)
            }
        },
        top = {
            Icon(
                Icons.Outlined.ErrorOutline,
                null,
                Modifier.size(60.dp).graphicsLayer {
                    translationX = sin(shake.value * 6 * Math.PI).toFloat() * (1f - shake.value) * 14.dp.toPx()
                },
                tint = MaterialTheme.colorScheme.error,
            )
        },
        scroll = true,
    ) {
        SelectionContainer(Modifier.rise(2)) {
            Text(
                stringResource(Res.string.setup_failed_text, model.failure.orEmpty(), log.path),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        LogFold(model, details, { details = !details }, Modifier.rise(3))
    }
}

// Asks before taking the app away, with the library kept unless the person turns on its removal.
@Composable
internal fun RemovePage(model: SetupModel, onClose: () -> Unit) {
    SetupPage(
        stringResource(Res.string.setup_remove_title),
        stringResource(Res.string.setup_remove_text),
        bottom = {
            QuietButton(stringResource(Res.string.setup_cancel), onClose)
            Spacer(Modifier.weight(1f))
            MainButton(
                stringResource(Res.string.setup_remove),
                model::remove,
                Icons.Outlined.DeleteOutline,
                danger = true,
            )
        },
    ) {
        Box(Modifier.rise(2)) {
            SettingsSection {
                padded {
                    SwitchSetting(
                        stringResource(Res.string.setup_remove_data),
                        model.removeData,
                        { model.removeData = it },
                        stringResource(Res.string.setup_remove_data_hint, model.dataFolder.path),
                        Icons.AutoMirrored.Outlined.LibraryBooks,
                    )
                }
            }
        }
        RunningNotice(model)
    }
}

// The farewell: the icon, a thank you, and where the library stayed when it was kept. Closing starts the removal.
@Composable
internal fun RemovedPage(model: SetupModel, onClose: () -> Unit) {
    SetupPage(
        stringResource(Res.string.setup_removed_title),
        stringResource(Res.string.setup_removed_text),
        bottom = {
            Spacer(Modifier.weight(1f))
            MainButton(stringResource(Res.string.setup_close), onClose, icon = null)
        },
        top = { AnimatedLogo(64.dp) },
    ) {
        if (!model.removeData) {
            Text(
                stringResource(Res.string.setup_removed_kept, model.dataFolder.path),
                Modifier.rise(3),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline,
            )
        }
    }
}
