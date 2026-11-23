package com.sumizuri.app.feature.tv.profile

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.profile.Profile
import com.sumizuri.app.feature.profile.ProfileAvatar
import com.sumizuri.app.feature.tv.onboarding.firstFocus
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tv_profile_title
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.theme.background.ambientBackground
import com.sumizuri.app.ui.tv.LocalTv
import com.sumizuri.app.ui.tv.TvOverlay
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.flow.MutableStateFlow
import org.jetbrains.compose.resources.stringResource

// How big a profile is in the picker.
private val Face = 132.dp

// Asks for the name of a profile just made on a TV, over the whole app, since making it opens it at its library.
internal object NewProfileName {
    val ask = MutableStateFlow(false)
}

// The name panel over everything once a new profile has opened.
@Composable
internal fun TvNewProfileName() {
    val asking by NewProfileName.ask.collectAsStateWithLifecycle()
    if (!asking) return
    Box(Modifier.fillMaxSize().ambientBackground()) {
        TvProfilePanel(TvPanel.Name, onClose = { NewProfileName.ask.value = false }, onOpenPage = {})
    }
}

// Whether the person already picked who is watching since the app started, so switching to that profile does not ask again.
internal object WhoAsked {
    var done = false

    // Asks again on the next frame, even with one profile, for trying the screen while making the app.
    var preview by mutableStateOf(false)
}

// When a TV with two or more profiles starts, it first asks who is watching, with each profile as a big round picture in one row and the one used last in focus. OK opens that profile. A TV with one profile goes straight to its library.
@Composable
internal fun TvWhoIsWatching() {
    if (!LocalTv.current) return
    val profiles = LocalProfiles.current
    val registry by profiles.state.collectAsStateWithLifecycle()
    var shown by remember { mutableStateOf(!WhoAsked.done && registry.profiles.size >= 2) }
    SideEffect { WhoAsked.done = true }
    LaunchedEffect(WhoAsked.preview) {
        if (WhoAsked.preview) {
            shown = true
            WhoAsked.preview = false
        }
    }
    TvNewProfileName()
    AnimatedVisibility(shown, enter = fadeIn(tween(0)), exit = fadeOut(tween(motionMs(AppMotion.Page)))) {
        val first = firstFocus()
        TvOverlay(Modifier.ambientBackground()) {
            Column(
                Modifier.fillMaxSize().padding(48.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text(stringResource(Res.string.tv_profile_title), fontSize = 36.sp, fontWeight = FontWeight.SemiBold)
                Row(Modifier.padding(top = 44.dp), horizontalArrangement = Arrangement.spacedBy(36.dp)) {
                    registry.profiles.forEach { profile ->
                        Pick(
                            profile,
                            if (profile.id ==
                                registry.activeId
                            ) {
                                Modifier.focusRequester(first)
                            } else {
                                Modifier
                            },
                        ) {
                            shown = false
                            if (profile.id != registry.activeId) profiles.switchTo(profile.id)
                        }
                    }
                }
            }
        }
    }
}

// One profile as a big round picture with its name under it.
@Composable
private fun Pick(profile: Profile, modifier: Modifier, onPick: () -> Unit) {
    Column(Modifier.width(Face + 40.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier.size(Face + 12.dp).tvCard(onPick, CircleShape).padding(6.dp),
            contentAlignment = Alignment.Center,
        ) {
            ProfileAvatar(profile.name, profile.avatar, Face)
        }
        Text(
            profile.name,
            Modifier.fillMaxWidth().padding(top = 14.dp),
            fontSize = 20.sp,
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
    }
}
