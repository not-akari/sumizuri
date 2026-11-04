package com.sumizuri.app.feature.onboarding

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.AppIcons
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.appIconsShown
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.profile.ProfileHost
import com.sumizuri.app.feature.profile.ProfileAvatar
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.feature.settings.look.AppIconSection
import com.sumizuri.app.feature.settings.look.modeIcon
import com.sumizuri.app.feature.theme.ThemePresetGrid
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.onboarding_look_text
import com.sumizuri.app.shared.resources.onboarding_look_title
import com.sumizuri.app.shared.resources.onboarding_profile_photo
import com.sumizuri.app.shared.resources.onboarding_profile_text
import com.sumizuri.app.shared.resources.onboarding_profile_title
import com.sumizuri.app.shared.resources.onboarding_welcome_text
import com.sumizuri.app.shared.resources.onboarding_welcome_title
import com.sumizuri.app.shared.resources.profile_name
import com.sumizuri.app.shared.resources.settings_language
import com.sumizuri.app.shared.resources.settings_language_system
import com.sumizuri.app.shared.resources.settings_mode
import com.sumizuri.app.shared.resources.settings_theme
import com.sumizuri.app.ui.kit.art.AnimatedLogo
import com.sumizuri.app.ui.kit.art.KindTiles
import com.sumizuri.app.ui.kit.art.QuietButton
import com.sumizuri.app.ui.kit.art.rise
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.input.rememberImagePicker
import com.sumizuri.app.ui.kit.input.squareAvatar
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.language.AppLanguage
import com.sumizuri.app.ui.theme.ThemeMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okio.FileSystem
import org.jetbrains.compose.resources.stringResource

// A picture for a profile is kept this many pixels wide and high, as the profile page keeps it.
private const val AvatarSize = 512

// The welcome: the icon springing in with its ring of light, a line about the app, and the three things it holds floating side by side.
@Composable
internal fun WelcomeStep() {
    Column(
        Modifier.fillMaxWidth().padding(top = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        AnimatedLogo(84.dp)
        Text(
            stringResource(Res.string.onboarding_welcome_title),
            Modifier.rise(1),
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
        )
        Text(
            stringResource(Res.string.onboarding_welcome_text),
            Modifier.rise(2).padding(horizontal = 12.dp),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
    KindTiles(3, Modifier.padding(top = 12.dp))
}

// The language, light or dark, and a theme from the cards, each drawn in its own colors. The app takes each choice at once, so the step itself changes as it is chosen.
@Composable
internal fun LookStep() {
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val language by settings.language.collectAsStateWithLifecycle()
    val mode by settings.themeMode.collectAsStateWithLifecycle()
    StepHeader(stringResource(Res.string.onboarding_look_title), stringResource(Res.string.onboarding_look_text))
    Box(Modifier.rise(2)) {
        SettingsSection {
            padded {
                ChoiceSetting(Res.string.settings_language, AppLanguage.entries, language, {
                    it.nativeName
                        ?: stringResource(Res.string.settings_language_system)
                }) { settings.onLanguage(it) }
            }
            padded {
                ChoiceSetting(Res.string.settings_mode, ThemeMode.entries, mode, {
                    stringResource(it.label)
                }, optionIcon = { modeIcon(it) }) { settings.onThemeMode(it) }
            }
        }
    }
    // The icon in the launcher, where the system lets the app change it, once the icons are ready.
    if (appIconsShown && AppIcons.supported) Box(Modifier.rise(3)) { AppIconSection() }
    Column(Modifier.rise(4)) {
        AppSectionLabel(Res.string.settings_theme)
        ThemePresetGrid()
    }
}

// The name and the picture of the profile that is open, kept as they are typed and picked.
@Composable
internal fun ProfileStep() {
    val profiles = LocalProfiles.current
    val registry by profiles.state.collectAsStateWithLifecycle()
    val profile = registry.active
    var name by remember(profile.id) { mutableStateOf(profile.name) }
    val scope = rememberCoroutineScope()
    // The name is kept once typing pauses, so each key does not rewrite the list of profiles.
    LaunchedEffect(name) {
        delay(400)
        val trimmed = name.trim()
        if (trimmed.isNotEmpty() && trimmed != profile.name) profiles.rename(profile.id, trimmed)
    }
    val pick =
        rememberImagePicker { bytes ->
            scope.launch {
                keepAvatar(profiles, bytes)?.let { profiles.setAvatar(profile.id, it) }
            }
        }
    StepHeader(stringResource(Res.string.onboarding_profile_title), stringResource(Res.string.onboarding_profile_text))
    Column(
        Modifier.fillMaxWidth().rise(2),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(Modifier.size(150.dp), contentAlignment = Alignment.Center) {
            AvatarRing(Modifier.fillMaxSize())
            ProfileAvatar(name, profile.avatar, 116.dp)
        }
        QuietButton(stringResource(Res.string.onboarding_profile_photo), pick, Icons.Outlined.PhotoCamera)
    }
    OutlinedTextField(name, {
        name = it
    }, Modifier.fillMaxWidth().rise(3), singleLine = true, label = { Text(stringResource(Res.string.profile_name)) })
}

// A ring of the theme's color turning slowly round the picture of the profile.
@Composable
private fun AvatarRing(modifier: Modifier) {
    val transition = rememberInfiniteTransition(label = "avatar ring")
    val spin by transition.animateFloat(
        0f,
        360f,
        infiniteRepeatable(tween(6_000, easing = LinearEasing)),
        label = "spin",
    )
    val color = MaterialTheme.colorScheme.primary
    Canvas(modifier) {
        val stroke = 3.dp.toPx()
        rotate(spin) {
            drawArc(
                Brush.sweepGradient(listOf(color.copy(alpha = 0f), color, color.copy(alpha = 0f))),
                0f,
                300f,
                false,
                topLeft = Offset(stroke, stroke),
                size = Size(size.width - stroke * 2, size.height - stroke * 2),
                style = Stroke(stroke, cap = StrokeCap.Round),
            )
        }
        drawCircle(
            Brush.radialGradient(listOf(color.copy(alpha = 0.16f), Color.Transparent)),
            radius =
            size.minDimension / 2,
        )
    }
}

// Writes the picture to the avatars folder, squared as the profile page squares it, and gives its path, or null when it is no picture.
private suspend fun keepAvatar(host: ProfileHost, picture: ByteArray): String? = withContext(Dispatchers.IO) {
    val square = squareAvatar(picture, AvatarSize) ?: return@withContext null
    val path = host.registry.newAvatarPath()
    FileSystem.SYSTEM.write(path) { write(square) }
    path.toString()
}
