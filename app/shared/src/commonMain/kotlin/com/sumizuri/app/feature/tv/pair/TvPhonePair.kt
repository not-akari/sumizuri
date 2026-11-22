package com.sumizuri.app.feature.tv.pair

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.pair.PairLink
import com.sumizuri.app.data.pair.PairPlace
import com.sumizuri.app.data.pair.PairResult
import com.sumizuri.app.data.pair.applyPair
import com.sumizuri.app.data.pair.openPackage
import com.sumizuri.app.data.pair.openPairListener
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tv_cancel
import com.sumizuri.app.shared.resources.tv_done_button
import com.sumizuri.app.shared.resources.tv_pair_applying
import com.sumizuri.app.shared.resources.tv_pair_no_network
import com.sumizuri.app.shared.resources.tv_pair_problems
import com.sumizuri.app.shared.resources.tv_pair_qr
import com.sumizuri.app.shared.resources.tv_pair_repos
import com.sumizuri.app.shared.resources.tv_pair_sources
import com.sumizuri.app.shared.resources.tv_pair_step_one
import com.sumizuri.app.shared.resources.tv_pair_step_three
import com.sumizuri.app.shared.resources.tv_pair_step_two
import com.sumizuri.app.shared.resources.tv_pair_synced
import com.sumizuri.app.shared.resources.tv_pair_title
import com.sumizuri.app.shared.resources.tv_pair_trackers
import com.sumizuri.app.shared.resources.tv_pair_waiting
import com.sumizuri.app.shared.resources.tv_pair_wrong
import com.sumizuri.app.ui.tv.TvButton
import io.github.alexzhirkevich.qrose.rememberQrCodePainter
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// Where taking in a package from a phone has got.
private sealed interface PairStage {
    data object Waiting : PairStage

    data object Wrong : PairStage

    data object Applying : PairStage

    data class Done(val result: PairResult) : PairStage
}

// A TV shows a QR code that the camera of a phone opens in Sumizuri on the same home network. The phone then sends its repos, the same video sources and a sign in to sync, and the TV takes them in and says what it did. It listens only while this page is open, for one phone, at a path and with a key that only the code holds.
@Composable
internal fun TvPhonePair(onClose: (done: Boolean) -> Unit) {
    val container = LocalAppContainer.current
    val accounts = LocalProfiles.current.syncAccounts
    val listener = remember { openPairListener() }
    val link = remember(listener) { listener?.let { PairLink.make(it.address) } }
    var stage by remember { mutableStateOf<PairStage>(PairStage.Waiting) }
    DisposableEffect(listener) { onDispose { listener?.close() } }
    LaunchedEffect(listener) {
        if (listener == null || link == null) return@LaunchedEffect
        while (true) {
            val body = runCatching { listener.receive(link.token) }.getOrNull() ?: return@LaunchedEffect
            val pack = openPackage(link, body)
            if (pack == null) {
                stage = PairStage.Wrong
                continue
            }
            stage = PairStage.Applying
            val place =
                PairPlace(
                    container.repos,
                    container.sources,
                    container.manager,
                    accounts,
                    container.settings,
                    container.trackers,
                )
            stage = PairStage.Done(applyPair(pack, place))
            listener.close()
            return@LaunchedEffect
        }
    }
    val first = remember { FocusRequester() }
    LaunchedEffect(stage is PairStage.Done) {
        repeat(4) {
            delay(150)
            runCatching { first.requestFocus() }
        }
    }
    Row(
        Modifier.fillMaxSize().padding(horizontal = 72.dp, vertical = 48.dp),
        horizontalArrangement = Arrangement.spacedBy(56.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(stringResource(Res.string.tv_pair_title), fontSize = 34.sp, fontWeight = FontWeight.SemiBold)
            if (link == null) {
                Text(
                    stringResource(Res.string.tv_pair_no_network),
                    fontSize = 18.sp,
                    color = MaterialTheme.colorScheme.error,
                )
            } else {
                listOf(
                    Res.string.tv_pair_step_one,
                    Res.string.tv_pair_step_two,
                    Res.string.tv_pair_step_three,
                ).forEachIndexed { at, step ->
                    Text(
                        "${at + 1}.  " + stringResource(step),
                        fontSize = 18.sp,
                        lineHeight = 26.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            when (val now = stage) {
                PairStage.Waiting -> if (link !=
                    null
                ) {
                    Line(stringResource(Res.string.tv_pair_waiting), MaterialTheme.colorScheme.primary)
                }

                PairStage.Wrong -> Line(stringResource(Res.string.tv_pair_wrong), MaterialTheme.colorScheme.error)

                PairStage.Applying -> Line(
                    stringResource(Res.string.tv_pair_applying),
                    MaterialTheme.colorScheme.primary,
                )

                is PairStage.Done -> Summary(now.result)
            }
            val done = stage is PairStage.Done
            TvButton(
                stringResource(if (done) Res.string.tv_done_button else Res.string.tv_cancel),
                { onClose(done) },
                Modifier.padding(top = 10.dp).focusRequester(first),
                main = done,
            )
        }
        if (link != null && stage !is PairStage.Done) {
            Box(Modifier.background(Color.White, RoundedCornerShape(16.dp)).padding(16.dp)) {
                Image(rememberQrCodePainter(link.text), stringResource(Res.string.tv_pair_qr), Modifier.size(260.dp))
            }
        }
    }
}

@Composable
private fun Line(text: String, color: Color) {
    Text(text, Modifier.widthIn(max = 520.dp), fontSize = 18.sp, fontWeight = FontWeight.SemiBold, color = color)
}

// What the TV took in: the repos and the sources it added, the account it signed in to, and what could not be done.
@Composable
private fun Summary(result: PairResult) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Line(
            pluralStringResource(Res.plurals.tv_pair_repos, result.repos, result.repos),
            MaterialTheme.colorScheme.primary,
        )
        Line(
            pluralStringResource(Res.plurals.tv_pair_sources, result.sources, result.sources),
            MaterialTheme.colorScheme.primary,
        )
        if (result.trackers >
            0
        ) {
            Line(
                pluralStringResource(Res.plurals.tv_pair_trackers, result.trackers, result.trackers),
                MaterialTheme.colorScheme.primary,
            )
        }
        result.syncedAs?.let { Line(stringResource(Res.string.tv_pair_synced, it), MaterialTheme.colorScheme.primary) }
        if (result.problems.isNotEmpty()) {
            Line(
                stringResource(Res.string.tv_pair_problems, result.problems.joinToString(", ")),
                MaterialTheme.colorScheme.error,
            )
        }
    }
}
