package com.sumizuri.app.feature.tv.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.feature.trackers.TrackerLogo
import com.sumizuri.app.feature.tv.onboarding.firstFocus
import com.sumizuri.app.feature.tv.pair.TvPhonePair
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.trackers_title
import com.sumizuri.app.shared.resources.tv_profile_phone_value
import com.sumizuri.app.shared.resources.tv_trackers_not_signed_in
import com.sumizuri.app.shared.resources.tv_trackers_sign_out
import com.sumizuri.app.shared.resources.tv_trackers_sign_out_sure
import com.sumizuri.app.shared.resources.tv_trackers_signed_in
import com.sumizuri.app.shared.resources.tv_trackers_text
import com.sumizuri.app.ui.tv.TvOverlay
import com.sumizuri.app.ui.tv.TvRow
import com.sumizuri.app.ui.tv.hiddenUnder
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The trackers on a TV: each one that keeps lists of videos, with the account it is signed in to. Signing in is done from a phone, which sends its accounts over, and signing out asks for a second press first.
@Composable
internal fun TvTrackersRoute() {
    val container = LocalAppContainer.current
    val signedIn by remember(container) { container.trackers.signedIn }.collectAsStateWithLifecycle(emptyMap())
    var phone by rememberSaveable { mutableStateOf(false) }
    var asking by remember { mutableStateOf<TrackerId?>(null) }
    val scope = rememberCoroutineScope()
    val first = firstFocus()
    val trackers = TrackerId.entries.filter { Kind.Anime in it.kinds }
    Box(Modifier.fillMaxSize()) {
        Column(
            Modifier.fillMaxSize().hiddenUnder(phone).padding(horizontal = 56.dp, vertical = 36.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(stringResource(Res.string.trackers_title), fontSize = 34.sp, fontWeight = FontWeight.SemiBold)
            Text(
                stringResource(Res.string.tv_trackers_text),
                Modifier.widthIn(max = 640.dp).padding(bottom = 8.dp),
                fontSize = 17.sp,
                lineHeight = 24.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            trackers.forEachIndexed { at, tracker ->
                val account = signedIn[tracker]
                TvRow(
                    onClick = {
                        when {
                            account == null -> phone = true

                            asking == tracker -> {
                                asking = null
                                scope.launch { container.trackers.signOut(tracker) }
                            }

                            else -> asking = tracker
                        }
                    },
                    modifier = if (at == 0) Modifier.focusRequester(first) else Modifier,
                ) {
                    TrackerLogo(tracker, 40.dp)
                    Column(Modifier.weight(1f).padding(start = 10.dp)) {
                        Text(tracker.label, fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
                        Text(
                            account?.let { stringResource(Res.string.tv_trackers_signed_in, it.name) }
                                ?: stringResource(Res.string.tv_trackers_not_signed_in),
                            fontSize = 15.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Text(
                        when {
                            account == null -> stringResource(Res.string.tv_profile_phone_value)
                            asking == tracker -> stringResource(Res.string.tv_trackers_sign_out_sure)
                            else -> stringResource(Res.string.tv_trackers_sign_out)
                        },
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = if (asking ==
                            tracker
                        ) {
                            MaterialTheme.colorScheme.error
                        } else {
                            MaterialTheme.colorScheme.primary
                        },
                    )
                }
            }
        }
        if (phone) {
            NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) {
                phone =
                    false
            }
            TvOverlay { TvPhonePair { phone = false } }
        }
    }
}
