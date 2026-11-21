package com.sumizuri.app.feature.sync.signin

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_create_section
import com.sumizuri.app.shared.resources.sync_password_match
import com.sumizuri.app.shared.resources.sync_password_mismatch
import com.sumizuri.app.shared.resources.sync_password_short
import com.sumizuri.app.shared.resources.sync_signin_section
import com.sumizuri.app.shared.resources.sync_signup_closed
import com.sumizuri.app.shared.resources.sync_signup_invite
import com.sumizuri.app.shared.resources.sync_signup_open
import com.sumizuri.app.shared.resources.sync_step_account
import com.sumizuri.app.shared.resources.sync_step_key
import com.sumizuri.app.shared.resources.sync_step_profile
import com.sumizuri.app.shared.resources.sync_step_server
import com.sumizuri.app.shared.resources.sync_strength_great
import com.sumizuri.app.shared.resources.sync_strength_okay
import com.sumizuri.app.shared.resources.sync_strength_strong
import com.sumizuri.app.shared.resources.sync_strength_weak
import com.sumizuri.app.shared.resources.sync_welcome_home
import com.sumizuri.app.shared.resources.sync_welcome_own
import com.sumizuri.app.shared.resources.sync_welcome_title
import com.sumizuri.app.shared.resources.sync_welcome_what
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.kit.chips.FilterTabs
import com.sumizuri.app.ui.kit.step.StepTrack
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.sync.core.SignupMode
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The steps of getting sync going, in order: the server, the account on it, the recovery key of a new account, and the profile on the server to sync with.
internal enum class SetupStep(val label: StringResource) {
    Server(Res.string.sync_step_server),
    Account(Res.string.sync_step_account),
    Key(Res.string.sync_step_key),
    Profile(Res.string.sync_step_profile),
}

// Which step of getting sync going a part of the sign in is, or null once it is going.
internal fun SyncStep.setupStep(): SetupStep? = when (this) {
    SyncStep.Address -> SetupStep.Server
    is SyncStep.Server -> SetupStep.Account
    is SyncStep.SaveRecovery -> SetupStep.Key
    is SyncStep.ChooseProfile -> SetupStep.Profile
    is SyncStep.Connected -> null
}

// What sync does, in three short points, before anything is asked.
@Composable
internal fun WelcomeCard() {
    val colors = MaterialTheme.colorScheme
    Column(
        Modifier
            .fillMaxWidth()
            .entrance()
            .softCard(shape = MaterialTheme.shapes.large)
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Box(
                Modifier.size(44.dp).clip(CircleShape).background(softFill(strong = true)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Outlined.Sync, null, Modifier.size(24.dp), tint = colors.primary)
            }
            Text(
                stringResource(Res.string.sync_welcome_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
            )
        }
        for (point in listOf(Res.string.sync_welcome_own, Res.string.sync_welcome_what, Res.string.sync_welcome_home)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Icon(Icons.Outlined.CheckCircle, null, Modifier.size(18.dp), tint = colors.primary)
                Text(
                    stringResource(point),
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.onSurfaceVariant,
                )
            }
        }
    }
}

// The steps of getting sync going, on the shared step track.
@Composable
internal fun StepBar(current: SetupStep, modifier: Modifier = Modifier) {
    StepTrack(SetupStep.entries.map { stringResource(it.label) }, current.ordinal, modifier)
}

// Making an account and signing in as two plain tabs, so either is one tap away on a server that takes new accounts.
@Composable
internal fun AccountChoice(mode: SyncMode, signup: SignupMode, onChoose: (SyncMode) -> Unit) {
    if (signup == SignupMode.Closed || (mode != SyncMode.Create && mode != SyncMode.SignIn)) return
    FilterTabs(
        listOf(
            SyncMode.Create to stringResource(Res.string.sync_create_section),
            SyncMode.SignIn to stringResource(Res.string.sync_signin_section),
        ),
        mode,
        onChoose,
    )
}

// How strong a new password is, from nothing to four: long enough, longer still, a mix of kinds of letters, and very long.
internal fun passwordScore(password: String, minPassword: Int): Int {
    if (password.length < minPassword) return 0
    val kinds = listOf(
        password.any(Char::isLowerCase),
        password.any(Char::isUpperCase),
        password.any(Char::isDigit),
        password.any { !it.isLetterOrDigit() },
    ).count { it }
    return 1 + (if (password.length >= minPassword + 4) 1 else 0) + (if (kinds >= 3) 1 else 0) +
        (if (password.length >= 16) 1 else 0)
}

private val StrengthWords = listOf(
    Res.string.sync_strength_weak,
    Res.string.sync_strength_okay,
    Res.string.sync_strength_strong,
    Res.string.sync_strength_great,
)

// A bar of four parts that fill as the password gets stronger, with a word for how strong it is.
@Composable
internal fun PasswordMeter(password: String, minPassword: Int) {
    if (password.isEmpty()) return
    val colors = MaterialTheme.colorScheme
    val score = passwordScore(password, minPassword)
    val ms = motionMs(AppMotion.Medium)
    val tint by animateColorAsState(
        when (score) {
            0 -> colors.error
            1 -> colors.tertiary
            else -> colors.primary
        },
        tween(ms),
        label = "strength",
    )
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            repeat(4) { part ->
                val on by animateColorAsState(
                    if (part <
                        score.coerceAtLeast(1)
                    ) {
                        tint
                    } else {
                        colors.outlineVariant
                    },
                    tween(ms),
                    label = "strength part",
                )
                Box(
                    Modifier
                        .weight(1f)
                        .height(4.dp)
                        .clip(CircleShape)
                        .background(on),
                )
            }
        }
        Text(
            if (score ==
                0
            ) {
                stringResource(Res.string.sync_password_short, minPassword)
            } else {
                stringResource(
                    StrengthWords[
                        score -
                            1,
                    ],
                )
            },
            style = MaterialTheme.typography.labelSmall,
            color = tint,
        )
    }
}

// Whether the second password is the same as the first, said as soon as it is typed.
@Composable
internal fun MatchLine(password: String, repeat: String) {
    if (repeat.isEmpty()) return
    val same = password == repeat
    val colors = MaterialTheme.colorScheme
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(
            if (same) Icons.Outlined.CheckCircle else Icons.Outlined.ErrorOutline,
            null,
            Modifier.size(16.dp),
            tint = if (same) colors.primary else colors.error,
        )
        Text(
            stringResource(if (same) Res.string.sync_password_match else Res.string.sync_password_mismatch),
            style = MaterialTheme.typography.labelSmall,
            color = if (same) colors.primary else colors.error,
        )
    }
}

// The word for who may make an account on a server.
internal fun signupWord(mode: SignupMode) = when (mode) {
    SignupMode.Open -> Res.string.sync_signup_open
    SignupMode.Invite -> Res.string.sync_signup_invite
    SignupMode.Closed -> Res.string.sync_signup_closed
}
