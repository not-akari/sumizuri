package com.sumizuri.app.feature.onboarding

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.keyframes
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.NotificationsActive
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.local.LocalSources
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.sync.UpdatePlatform
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.feature.settings.library.UpdateIntervals
import com.sumizuri.app.feature.settings.library.updateIntervalLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.onboarding_done_sources
import com.sumizuri.app.shared.resources.onboarding_done_text
import com.sumizuri.app.shared.resources.onboarding_done_title
import com.sumizuri.app.shared.resources.onboarding_updates_text
import com.sumizuri.app.shared.resources.onboarding_updates_title
import com.sumizuri.app.shared.resources.update_background
import com.sumizuri.app.shared.resources.update_background_hint
import com.sumizuri.app.shared.resources.update_interval
import com.sumizuri.app.shared.resources.update_notify
import com.sumizuri.app.shared.resources.update_notify_hint
import com.sumizuri.app.ui.kit.art.DrawnCheck
import com.sumizuri.app.ui.kit.art.rise
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// How often the library is looked through for new chapters, and whether a notice says so. The yes the system wants for notices is asked as the step is left.
@Composable
internal fun UpdatesStep() {
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val prefs = container.settings
    val scope = rememberCoroutineScope()
    val hours by settings.updateHours.collectAsStateWithLifecycle()
    val background by remember(
        prefs,
    ) { prefs.flag(SettingKey.UpdateInBackground, true) }.collectAsStateWithLifecycle(true)
    val notify by remember(prefs) { prefs.flag(SettingKey.UpdateNotify, true) }.collectAsStateWithLifecycle(true)
    StepHeader(
        stringResource(
            Res.string.onboarding_updates_title,
        ),
        stringResource(Res.string.onboarding_updates_text),
    )
    Box(Modifier.fillMaxWidth().rise(2), contentAlignment = Alignment.Center) { RingingBell(notify) }
    Box(Modifier.rise(3)) {
        SettingsSection {
            padded {
                ChoiceSetting(Res.string.update_interval, UpdateIntervals, hours, {
                    updateIntervalLabel(it)
                }) { settings.onUpdateHours(it) }
            }
            // Only where the system can run a check while the app is closed, and only with an interval to run on.
            if (UpdatePlatform.runsInBackground && hours > 0) {
                padded {
                    SwitchSetting(Res.string.update_background, background, { on ->
                        scope.launch {
                            prefs.setFlag(SettingKey.UpdateInBackground, on)
                        }
                    }, Res.string.update_background_hint)
                }
            }
            padded {
                SwitchSetting(Res.string.update_notify, notify, { on ->
                    scope.launch {
                        prefs.setFlag(SettingKey.UpdateNotify, on)
                    }
                }, Res.string.update_notify_hint)
            }
        }
    }
}

// A bell in a soft glow that rings now and then while notices are on, and rests when they are off.
@Composable
private fun RingingBell(ringing: Boolean) {
    val transition = rememberInfiniteTransition(label = "bell")
    val swing by transition.animateFloat(
        0f,
        0f,
        infiniteRepeatable(
            keyframes {
                durationMillis = 2_400
                0f at 0
                16f at 120
                -14f at 260
                10f at 400
                -6f at 540
                0f at 680
                0f at 2_400
            },
        ),
        label = "swing",
    )
    val glow by transition.animateFloat(
        0.5f,
        1f,
        infiniteRepeatable(tween(1_200, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "glow",
    )
    val color = MaterialTheme.colorScheme.primary
    Box(
        Modifier.size(96.dp).clip(CircleShape).background(
            Brush.radialGradient(
                listOf(
                    color.copy(
                        alpha = if (ringing) {
                            0.22f *
                                glow
                        } else {
                            0.08f
                        },
                    ),
                    Color.Transparent,
                ),
            ),
        ),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.Outlined.NotificationsActive,
            null,
            Modifier.size(44.dp).graphicsLayer {
                rotationZ = if (ringing) swing else 0f
                transformOrigin = TransformOrigin(0.5f, 0.1f)
            },
            tint = if (ringing) color else MaterialTheme.colorScheme.outline,
        )
    }
}

// The end: a tick that draws itself, a word on what to do next, and, when no source is installed yet, a pointer to the place to add one.
@Composable
internal fun DoneStep() {
    val container = LocalAppContainer.current
    val installed by remember(container) { container.sources.installed }.collectAsStateWithLifecycle(emptyList())
    val noSources = installed.none { it !in LocalSources.all }
    Column(
        Modifier.fillMaxWidth().padding(top = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(150.dp), contentAlignment = Alignment.Center) { DrawnCheck(Modifier.fillMaxSize()) }
        Text(
            stringResource(Res.string.onboarding_done_title),
            Modifier.rise(2),
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
        )
        Text(
            stringResource(Res.string.onboarding_done_text),
            Modifier.rise(3).padding(horizontal = 12.dp),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
        if (noSources) {
            Row(
                Modifier
                    .rise(4)
                    .padding(top = 8.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.55f))
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Icon(Icons.Outlined.Explore, null, Modifier.size(20.dp), tint = MaterialTheme.colorScheme.primary)
                Text(stringResource(Res.string.onboarding_done_sources), style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}
