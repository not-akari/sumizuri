package com.sumizuri.app.feature.player.overlay

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.feature.player.FailureKind
import com.sumizuri.app.feature.player.SessionState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_close
import com.sumizuri.app.shared.resources.player_dont_ask_again
import com.sumizuri.app.shared.resources.player_error_mpv
import com.sumizuri.app.shared.resources.player_failed_title
import com.sumizuri.app.shared.resources.player_failure_didnotstart
import com.sumizuri.app.shared.resources.player_failure_network
import com.sumizuri.app.shared.resources.player_failure_nosource
import com.sumizuri.app.shared.resources.player_failure_novideos
import com.sumizuri.app.shared.resources.player_failure_playback
import com.sumizuri.app.shared.resources.player_retry
import com.sumizuri.app.shared.resources.player_solve
import com.sumizuri.app.shared.resources.player_try_other
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import org.jetbrains.compose.resources.stringResource

// What fills the screen when an episode cannot play: black with what went wrong in words and what can be done. It can pass a bot check, try another source, try again, or close. Trying another source can also be set to happen by itself from then on, so the person is not asked again.
@Composable
internal fun PlayerFailureView(
    state: SessionState,
    onSolve: () -> Unit,
    onAnother: (always: Boolean) -> Unit,
    onRetry: () -> Unit,
    onClose: () -> Unit,
) {
    val failure = state.failure ?: return
    var always by remember { mutableStateOf(false) }
    val reason = failure.note?.let { stringResource(it) } ?: stringResource(
        when (failure.kind) {
            FailureKind.Source -> Res.string.player_failure_nosource
            FailureKind.NoVideos -> Res.string.player_failure_novideos
            FailureKind.DidNotStart -> Res.string.player_failure_didnotstart
            FailureKind.Network -> Res.string.player_failure_network
            FailureKind.EngineMissing -> Res.string.player_error_mpv
            FailureKind.Playback -> Res.string.player_failure_playback
        },
    )
    Box(Modifier.fillMaxSize().background(Color.Black).padding(24.dp), contentAlignment = Alignment.Center) {
        Column(Modifier.widthIn(max = 420.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Outlined.ErrorOutline, null, Modifier.size(44.dp), tint = Color.White.copy(alpha = 0.7f))
            Text(
                stringResource(Res.string.player_failed_title),
                Modifier.padding(top = 16.dp),
                color = Color.White,
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
            )
            Text(
                reason,
                Modifier.padding(top = 8.dp),
                color = Color.White.copy(alpha = 0.7f),
                textAlign = TextAlign.Center,
            )
            failure.detail?.takeIf { it.isNotBlank() }?.let { detail ->
                SelectionContainer {
                    Text(
                        detail,
                        Modifier.padding(top = 10.dp),
                        color = Color.White.copy(alpha = 0.38f),
                        fontSize = 12.sp,
                        textAlign = TextAlign.Center,
                    )
                }
            }
            Column(
                Modifier.padding(top = 24.dp).fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                if (failure.kind != FailureKind.EngineMissing) {
                    if (failure.challengeUrl !=
                        null
                    ) {
                        InkButton(
                            onSolve,
                            Modifier.fillMaxWidth(),
                        ) { Text(stringResource(Res.string.player_solve)) }
                    }
                    if (state.hasAnotherVideo) {
                        InkButton({ onAnother(always) }, Modifier.fillMaxWidth()) {
                            Text(stringResource(Res.string.player_try_other))
                        }
                        Row(
                            Modifier.fillMaxWidth().toggleable(always, role = Role.Checkbox) { always = it },
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Checkbox(
                                always,
                                null,
                                colors = CheckboxDefaults.colors(
                                    checkedColor = Color.White,
                                    uncheckedColor = Color.White.copy(alpha = 0.7f),
                                    checkmarkColor = Color.Black,
                                ),
                            )
                            Text(
                                stringResource(Res.string.player_dont_ask_again),
                                color = Color.White.copy(alpha = 0.7f),
                                fontSize = 13.sp,
                            )
                        }
                    }
                    InkOutlinedButton(onRetry, Modifier.fillMaxWidth()) {
                        Text(stringResource(Res.string.player_retry), color = Color.White)
                    }
                }
                TextButton(onClose) { Text(stringResource(Res.string.player_close), color = Color.White) }
            }
        }
    }
}
