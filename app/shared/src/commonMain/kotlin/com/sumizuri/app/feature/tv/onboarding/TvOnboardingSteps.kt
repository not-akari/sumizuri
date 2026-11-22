package com.sumizuri.app.feature.tv.onboarding

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.player.AudioPreference
import com.sumizuri.app.data.model.player.PlayerPrefs
import com.sumizuri.app.data.model.player.QualityMode
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.feature.player.overlay.speedText
import com.sumizuri.app.feature.profile.ProfileAvatar
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_percent
import com.sumizuri.app.shared.resources.onboarding_next
import com.sumizuri.app.shared.resources.player_audio_any
import com.sumizuri.app.shared.resources.player_audio_dub
import com.sumizuri.app.shared.resources.player_audio_sub
import com.sumizuri.app.shared.resources.player_hide_never
import com.sumizuri.app.shared.resources.player_quality_highest
import com.sumizuri.app.shared.resources.player_quality_lowest
import com.sumizuri.app.shared.resources.player_quality_middle
import com.sumizuri.app.shared.resources.player_quality_remember
import com.sumizuri.app.shared.resources.player_set_ambient
import com.sumizuri.app.shared.resources.player_set_audio_pref
import com.sumizuri.app.shared.resources.player_set_hide
import com.sumizuri.app.shared.resources.player_set_skip
import com.sumizuri.app.shared.resources.player_set_speed
import com.sumizuri.app.shared.resources.player_set_sub_size
import com.sumizuri.app.shared.resources.player_set_watched
import com.sumizuri.app.shared.resources.player_size_large
import com.sumizuri.app.shared.resources.player_size_medium
import com.sumizuri.app.shared.resources.player_size_small
import com.sumizuri.app.shared.resources.player_speed_value
import com.sumizuri.app.shared.resources.player_unit_seconds
import com.sumizuri.app.shared.resources.profile_name
import com.sumizuri.app.shared.resources.tv_autoplay
import com.sumizuri.app.shared.resources.tv_done_button
import com.sumizuri.app.shared.resources.tv_done_text
import com.sumizuri.app.shared.resources.tv_done_title
import com.sumizuri.app.shared.resources.tv_library_fresh
import com.sumizuri.app.shared.resources.tv_library_fresh_hint
import com.sumizuri.app.shared.resources.tv_library_phone
import com.sumizuri.app.shared.resources.tv_library_phone_hint
import com.sumizuri.app.shared.resources.tv_library_sync
import com.sumizuri.app.shared.resources.tv_library_sync_hint
import com.sumizuri.app.shared.resources.tv_library_text
import com.sumizuri.app.shared.resources.tv_library_title
import com.sumizuri.app.shared.resources.tv_off
import com.sumizuri.app.shared.resources.tv_on
import com.sumizuri.app.shared.resources.tv_profile_text
import com.sumizuri.app.shared.resources.tv_profile_title
import com.sumizuri.app.shared.resources.tv_quality
import com.sumizuri.app.shared.resources.tv_resume
import com.sumizuri.app.shared.resources.tv_start
import com.sumizuri.app.shared.resources.tv_subtitles
import com.sumizuri.app.shared.resources.tv_watching_text
import com.sumizuri.app.shared.resources.tv_watching_title
import com.sumizuri.app.shared.resources.tv_welcome_text
import com.sumizuri.app.shared.resources.tv_welcome_title
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.text.languageName
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.TvChoiceRow
import com.sumizuri.app.ui.tv.TvRow
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The subtitle languages offered first, after Off and any language. One the person chose before is added when it is not here.
private val SubtitleLanguages = listOf("en", "es", "pt", "fr", "de", "it", "ar", "ru", "id", "ja")

// A focus for the first thing of a step, given once the step has come in, so the remote starts there.
@Composable
internal fun firstFocus(): FocusRequester {
    val first = remember { FocusRequester() }
    // It is asked until it takes it, for up to three seconds, since the step may still be coming in on a slow TV.
    LaunchedEffect(Unit) {
        repeat(20) {
            delay(150)
            if (runCatching { first.requestFocus() }.getOrDefault(false)) return@LaunchedEffect
        }
    }
    return first
}

@Composable
internal fun WelcomeStep(onStart: () -> Unit) {
    val first = firstFocus()
    EndFrame(stringResource(Res.string.tv_welcome_title), stringResource(Res.string.tv_welcome_text)) {
        TvButton(stringResource(Res.string.tv_start), onStart, Modifier.focusRequester(first))
    }
}

// The name of the profile that is open, kept once typing pauses, beside its picture.
@Composable
internal fun ProfileStep(step: TvStep, onNext: () -> Unit) {
    val first = firstFocus()
    StepFrame(step, stringResource(Res.string.tv_profile_title), stringResource(Res.string.tv_profile_text)) {
        ProfileNameRow()
        TvButton(
            stringResource(Res.string.onboarding_next),
            onNext,
            Modifier.padding(top = 12.dp).focusRequester(first),
        )
    }
}

// The picture of the profile that is open beside a field for its name, which is kept once typing pauses.
@Composable
internal fun ProfileNameRow(modifier: Modifier = Modifier) {
    val profiles = LocalProfiles.current
    val registry by profiles.state.collectAsStateWithLifecycle()
    val profile = registry.active
    var name by remember(profile.id) { mutableStateOf(profile.name) }
    LaunchedEffect(name) {
        delay(400)
        val trimmed = name.trim()
        if (trimmed.isNotEmpty() && trimmed != profile.name) profiles.rename(profile.id, trimmed)
    }
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(20.dp)) {
        ProfileAvatar(name, profile.avatar, 96.dp)
        AppTextField(
            name,
            { name = it },
            Modifier.weight(1f),
            singleLine = true,
            label = { Text(stringResource(Res.string.profile_name)) },
        )
    }
}

// Where the library of this TV comes from: sync with an account, or nothing yet.
@Composable
internal fun LibraryStep(step: TvStep, signedIn: Boolean, onSync: () -> Unit, onPhone: () -> Unit, onNext: () -> Unit) {
    val first = firstFocus()
    StepFrame(step, stringResource(Res.string.tv_library_title), stringResource(Res.string.tv_library_text)) {
        ChoiceCard(
            if (signedIn) Icons.Outlined.CheckCircle else Icons.Outlined.Sync,
            stringResource(Res.string.tv_library_sync),
            stringResource(Res.string.tv_library_sync_hint),
            onSync,
            Modifier.focusRequester(first),
        )
        ChoiceCard(
            Icons.Outlined.PhoneAndroid,
            stringResource(Res.string.tv_library_phone),
            stringResource(Res.string.tv_library_phone_hint),
            onPhone,
        )
        ChoiceCard(
            Icons.Outlined.AutoAwesome,
            stringResource(Res.string.tv_library_fresh),
            stringResource(Res.string.tv_library_fresh_hint),
            onNext,
        )
    }
}

@Composable
private fun ChoiceCard(
    icon: ImageVector,
    title: String,
    hint: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    TvRow(onClick, modifier) {
        Icon(icon, null, Modifier.size(30.dp), tint = MaterialTheme.colorScheme.primary)
        Column(Modifier.weight(1f).padding(start = 8.dp, top = 6.dp, bottom = 6.dp)) {
            Text(title, fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
            Text(hint, fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

// What every video starts with: the quality, sub or dub, the subtitles and their size, the next episode by itself, and going on where it was left.
@Composable
internal fun WatchingStep(step: TvStep, onNext: () -> Unit) {
    val first = firstFocus()
    StepFrame(step, stringResource(Res.string.tv_watching_title), stringResource(Res.string.tv_watching_text)) {
        WatchingRows(first) {
            TvButton(stringResource(Res.string.onboarding_next), onNext, Modifier.padding(top = 6.dp))
        }
    }
}

// The rows of how videos start, one choice each, that scroll when they do not fit, with what comes after them. More adds the rest of what the player keeps: its speed, the skip button, when an episode counts as watched, how long the controls stay and the light around a video.
@Composable
internal fun WatchingRows(
    first: FocusRequester,
    more: Boolean = false,
    after: @Composable ColumnScope.() -> Unit = {},
) {
    val container = LocalAppContainer.current
    val prefs by container.playerPrefs.prefs.collectAsStateWithLifecycle(PlayerPrefs())
    val scope = rememberCoroutineScope()
    val change: ((PlayerPrefs) -> PlayerPrefs) -> Unit = { edit -> scope.launch { container.playerPrefs.update(edit) } }
    val on = stringResource(Res.string.tv_on)
    val off = stringResource(Res.string.tv_off)
    Column(
        Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        TvChoiceRow(
            stringResource(Res.string.tv_quality),
            listOf(QualityMode.Best, QualityMode.Middle, QualityMode.Lowest, QualityMode.Remember),
            prefs.qualityMode,
            { stringResource(qualityLabel(it)) },
            { mode -> change { it.copy(qualityMode = mode) } },
            Modifier.focusRequester(first),
        )
        TvChoiceRow(
            stringResource(Res.string.player_set_audio_pref),
            AudioPreference.entries,
            prefs.audioPreference,
            { stringResource(audioLabel(it)) },
            { audio -> change { it.copy(audioPreference = audio) } },
        )
        // Off, any language, then the usual ones, where the empty code means any language.
        val shownLanguage: String? = if (prefs.showSubtitles) prefs.subtitleLanguage else null
        val languages =
            listOf<String?>(null, "") +
                (SubtitleLanguages + listOfNotNull(prefs.subtitleLanguage.ifEmpty { null })).distinct()
        TvChoiceRow(
            stringResource(Res.string.tv_subtitles),
            languages,
            shownLanguage,
            { code ->
                when (code) {
                    null -> off
                    "" -> on
                    else -> languageName(code)
                }
            },
            { code ->
                change {
                    it.copy(
                        showSubtitles = code != null,
                        subtitleLanguage = code ?: it.subtitleLanguage,
                    )
                }
            },
        )
        TvChoiceRow(
            stringResource(Res.string.player_set_sub_size),
            PlayerPrefs.SubtitleSizes.indices.toList(),
            prefs.subtitleSize,
            {
                stringResource(
                    listOf(
                        Res.string.player_size_small,
                        Res.string.player_size_medium,
                        Res.string.player_size_large,
                    )[it],
                )
            },
            { size -> change { it.copy(subtitleSize = size) } },
        )
        TvChoiceRow(
            stringResource(Res.string.tv_autoplay),
            listOf(true, false),
            prefs.autoNext,
            { if (it) on else off },
            { next -> change { it.copy(autoNext = next) } },
        )
        TvChoiceRow(
            stringResource(Res.string.tv_resume),
            listOf(true, false),
            prefs.resume,
            { if (it) on else off },
            { resume -> change { it.copy(resume = resume) } },
        )
        if (more) {
            TvChoiceRow(
                stringResource(Res.string.player_set_speed),
                PlayerPrefs.Speeds,
                prefs.speed,
                { stringResource(Res.string.player_speed_value, speedText(it)) },
                { speed -> change { it.copy(speed = speed) } },
            )
            TvChoiceRow(
                stringResource(Res.string.player_set_skip),
                PlayerPrefs.SkipSteps,
                prefs.skipSeconds,
                { stringResource(Res.string.player_unit_seconds, it) },
                { seconds -> change { it.copy(skipSeconds = seconds) } },
            )
            TvChoiceRow(
                stringResource(Res.string.player_set_watched),
                PlayerPrefs.WatchedAt,
                prefs.watchedAt,
                { stringResource(Res.string.display_percent, it) },
                { share -> change { it.copy(watchedAt = share) } },
            )
            TvChoiceRow(
                stringResource(Res.string.player_set_hide),
                PlayerPrefs.HideSteps,
                prefs.hideControlsSeconds,
                {
                    if (it ==
                        0
                    ) {
                        stringResource(Res.string.player_hide_never)
                    } else {
                        stringResource(Res.string.player_unit_seconds, it)
                    }
                },
                { seconds -> change { it.copy(hideControlsSeconds = seconds) } },
            )
            TvChoiceRow(
                stringResource(Res.string.player_set_ambient),
                listOf(true, false),
                prefs.ambient,
                { if (it) on else off },
                { glow -> change { it.copy(ambient = glow) } },
            )
        }
        after()
    }
}

@Composable
internal fun DoneStep(onFinish: () -> Unit) {
    val first = firstFocus()
    EndFrame(stringResource(Res.string.tv_done_title), stringResource(Res.string.tv_done_text)) {
        TvButton(stringResource(Res.string.tv_done_button), onFinish, Modifier.focusRequester(first))
    }
}

internal fun qualityLabel(mode: QualityMode): StringResource = when (mode) {
    QualityMode.Remember -> Res.string.player_quality_remember
    QualityMode.Best -> Res.string.player_quality_highest
    QualityMode.Middle -> Res.string.player_quality_middle
    QualityMode.Lowest -> Res.string.player_quality_lowest
}

private fun audioLabel(audio: AudioPreference): StringResource = when (audio) {
    AudioPreference.Any -> Res.string.player_audio_any
    AudioPreference.Sub -> Res.string.player_audio_sub
    AudioPreference.Dub -> Res.string.player_audio_dub
}
