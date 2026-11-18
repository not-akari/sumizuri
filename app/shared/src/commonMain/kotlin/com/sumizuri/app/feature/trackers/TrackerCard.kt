package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.tracker.SignIn
import com.sumizuri.app.data.tracker.SignInWay
import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.data.tracker.TrackerProblem
import com.sumizuri.app.data.tracker.TrackerRun
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.sync_last_never
import com.sumizuri.app.shared.resources.sync_now
import com.sumizuri.app.shared.resources.tracker_checking
import com.sumizuri.app.shared.resources.tracker_count_all
import com.sumizuri.app.shared.resources.tracker_count_gone
import com.sumizuri.app.shared.resources.tracker_count_linked
import com.sumizuri.app.shared.resources.tracker_count_unlinked
import com.sumizuri.app.shared.resources.tracker_list_signed_in
import com.sumizuri.app.shared.resources.tracker_sign_in
import com.sumizuri.app.shared.resources.tracker_sign_in_form_hint
import com.sumizuri.app.shared.resources.tracker_sign_in_hint
import com.sumizuri.app.shared.resources.tracker_sign_in_token_hint
import com.sumizuri.app.shared.resources.tracker_waiting
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.text.agoText
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// Starts signing in to a tracker the way it signs in: the browser for most, and a form here for one that takes a password or a token.
@Composable
internal fun rememberConnect(tracker: TrackerId): () -> Unit {
    val trackers = LocalAppContainer.current.trackers
    val scope = rememberCoroutineScope()
    val uri = LocalUriHandler.current
    var asking by remember(tracker) { mutableStateOf(false) }
    if (asking) {
        val withToken = trackers.way(tracker) == SignInWay.Token
        TrackerPasswordDialog(
            tracker,
            withToken,
            trackers.tokenPage(tracker),
            onSignIn = { email, secret ->
                asking = false
                if (withToken) {
                    trackers.signInWithToken(
                        tracker,
                        secret,
                    )
                } else {
                    trackers.signInWithPassword(tracker, email, secret)
                }
            },
            onDismiss = { asking = false },
        )
    }
    return {
        if (trackers.way(tracker) != SignInWay.Browser) {
            asking = true
        } else {
            scope.launch { trackers.begin(tracker)?.let { runCatching { uri.openUri(it) } } }
        }
    }
}

// One tracker on the Trackers page: who is signed in and when it last synced with the button that syncs now, how many titles are linked and what needs a look, or how to log in.
@Composable
internal fun TrackerCard(
    tracker: TrackerId,
    account: TrackerAccount?,
    modifier: Modifier = Modifier,
    onOpen: () -> Unit,
) {
    val container = LocalAppContainer.current
    val trackers = container.trackers
    val sync = container.trackerSync
    val scope = rememberCoroutineScope()
    val states by trackers.signIn.collectAsStateWithLifecycle()
    val state = states[tracker] ?: SignIn.Idle
    val connect = rememberConnect(tracker)
    val colors = MaterialTheme.colorScheme
    AppCard(modifier.fillMaxWidth(), onClick = if (account != null) onOpen else null) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                TrackerLogo(tracker, 44.dp)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(tracker.label, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text(
                        if (account != null) signedInLine(tracker, account) else signedOutLine(tracker, state),
                        style = MaterialTheme.typography.bodySmall,
                        color = if (state is SignIn.Failed &&
                            account == null
                        ) {
                            colors.error
                        } else {
                            colors.onSurfaceVariant
                        },
                        maxLines = 3,
                    )
                }
                if (account != null) {
                    val runs by sync.run.collectAsStateWithLifecycle()
                    if (runs[tracker] == TrackerRun.Running) {
                        InkCircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 3.dp)
                    } else {
                        IconButton({ scope.launch { runCatching { sync.sync(tracker, whole = true) } } }) {
                            Icon(Icons.Outlined.Sync, stringResource(Res.string.sync_now), tint = colors.primary)
                        }
                    }
                } else {
                    when (state) {
                        SignIn.Waiting -> TextButton(
                            { scope.launch { trackers.cancel(tracker) } },
                        ) { Text(stringResource(Res.string.cancel)) }

                        SignIn.Checking -> InkCircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 3.dp)

                        else -> InkButton(connect) { Text(stringResource(Res.string.tracker_sign_in)) }
                    }
                }
            }
            if (account != null) TrackerCounts(tracker)
        }
    }
}

// Who is signed in and when the last sync worked.
@Composable
private fun signedInLine(tracker: TrackerId, account: TrackerAccount): String {
    val sync = LocalAppContainer.current.trackerSync
    val log by remember(sync, tracker) { sync.log(tracker) }.collectAsStateWithLifecycle(emptyList())
    val last = log.firstOrNull()
    if (last != null && !last.ok) return problemText(TrackerProblem.of(last.message), tracker, signedIn = true)
    val worked = log.firstOrNull { it.ok }?.let { agoText(it.at) } ?: stringResource(Res.string.sync_last_never)
    return stringResource(Res.string.tracker_list_signed_in, account.name, worked)
}

// What logging in does, how it stands while the browser is open, or why it did not work.
@Composable
private fun signedOutLine(tracker: TrackerId, state: SignIn): String = when (state) {
    SignIn.Idle -> stringResource(
        when (LocalAppContainer.current.trackers.way(tracker)) {
            SignInWay.Browser -> Res.string.tracker_sign_in_hint
            SignInWay.Password -> Res.string.tracker_sign_in_form_hint
            SignInWay.Token -> Res.string.tracker_sign_in_token_hint
        },
        tracker.label,
    )

    SignIn.Waiting -> stringResource(Res.string.tracker_waiting)

    SignIn.Checking -> stringResource(Res.string.tracker_checking)

    is SignIn.Failed -> problemText(state.problem, tracker)
}

// How many titles are linked and not linked, and how many were removed on the tracker, which need a look.
@Composable
private fun TrackerCounts(tracker: TrackerId) {
    val sync = LocalAppContainer.current.trackerSync
    val links by remember(sync, tracker) { sync.links(tracker) }.collectAsStateWithLifecycle(emptyList())
    val unlinked by remember(sync, tracker) { sync.linker.unlinked(tracker) }.collectAsStateWithLifecycle(emptyList())
    val gone = links.count { it.gone }
    val colors = MaterialTheme.colorScheme
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        // With every title linked one plain line says so, instead of a count of nothing left.
        if (unlinked.isEmpty() && links.size > gone) {
            Text(
                stringResource(Res.string.tracker_count_all, links.size - gone, tracker.label),
                style = MaterialTheme.typography.labelMedium,
                color = colors.outline,
            )
        } else {
            Text(
                stringResource(Res.string.tracker_count_linked, links.size - gone),
                style = MaterialTheme.typography.labelMedium,
                color = colors.outline,
            )
            Text(
                stringResource(Res.string.tracker_count_unlinked, unlinked.size),
                style = MaterialTheme.typography.labelMedium,
                color = colors.outline,
            )
        }
        if (gone > 0) {
            Text(
                stringResource(Res.string.tracker_count_gone, gone, tracker.label),
                style = MaterialTheme.typography.labelMedium,
                color = colors.error,
            )
        }
    }
}
