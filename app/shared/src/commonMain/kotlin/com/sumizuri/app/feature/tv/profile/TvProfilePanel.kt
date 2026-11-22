package com.sumizuri.app.feature.tv.profile

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInHorizontally
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.sync.SyncRoute
import com.sumizuri.app.feature.tv.onboarding.ProfileNameRow
import com.sumizuri.app.feature.tv.onboarding.ThemeGrid
import com.sumizuri.app.feature.tv.onboarding.WatchingRows
import com.sumizuri.app.feature.tv.onboarding.firstFocus
import com.sumizuri.app.feature.tv.pair.TvPhonePair
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tv_profile_done
import com.sumizuri.app.shared.resources.tv_profile_look
import com.sumizuri.app.shared.resources.tv_profile_look_text
import com.sumizuri.app.shared.resources.tv_profile_name
import com.sumizuri.app.shared.resources.tv_profile_watching
import com.sumizuri.app.shared.resources.tv_profile_watching_text
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.TvOverlay
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// What opens over the profile page of a TV.
internal enum class TvPanel { Look, Watching, Name, Sync, Phone }

// One part of the profile over the whole page, sliding in from the side. Back closes it, and so does Done.
@Composable
internal fun TvProfilePanel(panel: TvPanel, onClose: () -> Unit, onOpenPage: (SettingsTarget) -> Unit) {
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) { onClose() }
    val shown = remember { MutableTransitionState(false).apply { targetState = true } }
    val ms = motionMs(AppMotion.Page)
    AnimatedVisibility(
        shown,
        enter = slideInHorizontally(tween(ms)) { it / 8 } + fadeIn(tween(ms)),
    ) {
        TvOverlay {
            when (panel) {
                TvPanel.Look -> Frame(Res.string.tv_profile_look, Res.string.tv_profile_look_text) { _ ->
                    ThemeGrid()
                    TvButton(stringResource(Res.string.tv_profile_done), onClose, main = false)
                }

                TvPanel.Watching -> Frame(
                    Res.string.tv_profile_watching,
                    Res.string.tv_profile_watching_text,
                ) { first ->
                    WatchingRows(first) {
                        TvButton(
                            stringResource(Res.string.tv_profile_done),
                            onClose,
                            Modifier.padding(top = 6.dp),
                            main = false,
                        )
                    }
                }

                TvPanel.Name -> Frame(Res.string.tv_profile_name, null) { first ->
                    ProfileNameRow(Modifier.widthIn(max = 640.dp))
                    TvButton(stringResource(Res.string.tv_profile_done), onClose, Modifier.focusRequester(first))
                }

                TvPanel.Phone -> TvPhonePair { onClose() }

                TvPanel.Sync -> Box(Modifier.padding(horizontal = 48.dp, vertical = 24.dp)) {
                    SyncRoute(onBack = onClose, onOpen = onOpenPage)
                }
            }
        }
    }
}

// A panel with its name and a line about it at the top, then what it sets, which takes the first focus.
@Composable
private fun Frame(title: StringResource, text: StringResource?, content: @Composable (FocusRequester) -> Unit) {
    val first = firstFocus()
    Column(
        Modifier.fillMaxSize().padding(horizontal = 56.dp, vertical = 36.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(stringResource(title), fontSize = 34.sp, fontWeight = FontWeight.SemiBold)
            text?.let {
                Text(
                    stringResource(it),
                    Modifier.widthIn(max = 640.dp),
                    fontSize = 17.sp,
                    lineHeight = 24.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        content(first)
    }
}
