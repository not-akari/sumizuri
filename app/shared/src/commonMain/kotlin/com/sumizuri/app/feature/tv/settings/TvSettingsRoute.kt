package com.sumizuri.app.feature.tv.settings

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.VideoLibrary
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.tv.onboarding.firstFocus
import com.sumizuri.app.feature.tv.profile.TvPanel
import com.sumizuri.app.feature.tv.profile.TvProfilePanel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.nav_library
import com.sumizuri.app.shared.resources.settings_group_system
import com.sumizuri.app.shared.resources.settings_title
import com.sumizuri.app.shared.resources.tv_profile_look
import com.sumizuri.app.shared.resources.tv_profile_watching
import com.sumizuri.app.shared.resources.tv_settings_account
import com.sumizuri.app.ui.tv.TvRow
import com.sumizuri.app.ui.tv.hiddenUnder
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The parts of the settings of a TV, in the order the list on the left has them.
internal enum class TvSection(val label: StringResource, val icon: ImageVector) {
    Look(Res.string.tv_profile_look, Icons.Outlined.Palette),
    Watching(Res.string.tv_profile_watching, Icons.Outlined.PlayCircle),
    Library(Res.string.nav_library, Icons.Outlined.VideoLibrary),
    Account(Res.string.tv_settings_account, Icons.Outlined.AccountCircle),
    System(Res.string.settings_group_system, Icons.Outlined.Tune),
}

// The settings on a TV in two panes: the parts on the left, and the settings of the part in focus on the right, which follow the focus as it moves down the list. Right or OK goes into a part, and back comes out of it to the list again. Only what matters on a TV is here, and the rarer pages open as they are.
@Composable
internal fun TvSettingsRoute(onOpen: (SettingsTarget) -> Unit) {
    var section by rememberSaveable { mutableStateOf(TvSection.Look) }
    var inside by remember { mutableStateOf(false) }
    var panel by rememberSaveable { mutableStateOf<TvPanel?>(null) }
    val chosen = remember { FocusRequester() }
    val right = remember { FocusRequester() }
    val first = firstFocus()
    // Back inside a part goes to the list first, and leaves the settings only from the list.
    val scope = rememberCoroutineScope()
    NavigationBackHandler(
        rememberNavigationEventState(NavigationEventInfo.None),
        isBackEnabled =
        inside && panel == null,
    ) {
        // The focus is asked for once the back key has let go of it.
        scope.launch {
            repeat(3) {
                delay(60)
                runCatching { chosen.requestFocus() }
            }
        }
    }
    Box(Modifier.fillMaxSize()) {
        Row(Modifier.fillMaxSize().hiddenUnder(panel != null).padding(top = 32.dp, bottom = 24.dp)) {
            Column(
                Modifier
                    .width(280.dp)
                    .fillMaxHeight()
                    .padding(start = 40.dp, end = 16.dp)
                    // Coming back into the list lands on the part that is open.
                    .focusProperties {
                        onEnter =
                            { if (requestedFocusDirection != FocusDirection.Enter) chosen.requestFocus() }
                    }.focusGroup(),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    stringResource(Res.string.settings_title),
                    Modifier.padding(start = 6.dp, bottom = 14.dp),
                    fontSize = 32.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                TvSection.entries.forEach { part ->
                    val open = part == section
                    TvRow(
                        onClick = { runCatching { right.requestFocus() } },
                        modifier = Modifier
                            .then(if (open) Modifier.focusRequester(chosen) else Modifier)
                            .then(if (part == TvSection.entries.first()) Modifier.focusRequester(first) else Modifier)
                            .onFocusChanged { if (it.isFocused) section = part },
                        chosen = open && inside,
                    ) {
                        Icon(part.icon, null, Modifier.size(24.dp), tint = MaterialTheme.colorScheme.primary)
                        Text(stringResource(part.label), Modifier.padding(start = 4.dp), fontSize = 18.sp)
                    }
                }
            }
            Box(
                Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .padding(start = 8.dp, end = 40.dp)
                    .onFocusChanged { inside = it.hasFocus }
                    // Coming in from the list starts at the first setting of the part.
                    .focusProperties {
                        onEnter =
                            { if (requestedFocusDirection != FocusDirection.Enter) right.requestFocus() }
                    }.focusGroup(),
            ) {
                AnimatedContent(
                    section,
                    transitionSpec = { fadeIn(tween(220, delayMillis = 60)) togetherWith fadeOut(tween(120)) },
                    label = "section",
                ) { shown ->
                    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                        Text(
                            stringResource(shown.label),
                            Modifier.padding(start = 6.dp, bottom = 4.dp, top = 6.dp),
                            fontSize = 24.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                        SectionRows(shown, right, onPanel = { panel = it }, onOpen = onOpen)
                    }
                }
            }
        }
        panel?.let { shown -> TvProfilePanel(shown, onClose = { panel = null }, onOpenPage = onOpen) }
    }
}
