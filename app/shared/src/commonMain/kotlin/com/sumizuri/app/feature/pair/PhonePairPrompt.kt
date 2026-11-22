package com.sumizuri.app.feature.pair

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.pair.PairLink
import com.sumizuri.app.data.pair.PairPackage
import com.sumizuri.app.data.pair.PairSource
import com.sumizuri.app.data.pair.PairSync
import com.sumizuri.app.data.pair.isHomeAddress
import com.sumizuri.app.data.pair.sealFor
import com.sumizuri.app.data.pair.sendPair
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.navigation.AppLinks
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.pair_code
import com.sumizuri.app.shared.resources.pair_done
import com.sumizuri.app.shared.resources.pair_failed
import com.sumizuri.app.shared.resources.pair_not_home
import com.sumizuri.app.shared.resources.pair_password
import com.sumizuri.app.shared.resources.pair_repos
import com.sumizuri.app.shared.resources.pair_send
import com.sumizuri.app.shared.resources.pair_sending
import com.sumizuri.app.shared.resources.pair_sent
import com.sumizuri.app.shared.resources.pair_sources
import com.sumizuri.app.shared.resources.pair_sync
import com.sumizuri.app.shared.resources.pair_title
import com.sumizuri.app.shared.resources.pair_to
import com.sumizuri.app.shared.resources.pair_trackers
import com.sumizuri.app.source.repo.originId
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.input.CheckRow
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// How far sending to a TV has got.
private enum class Sending { Ready, Busy, Sent, Failed }

// Opens the window of sending to a TV when the camera opened the code of one in the app.
@Composable
fun PhonePairPrompt() {
    val link by AppLinks.pairWith.collectAsStateWithLifecycle()
    link?.let { PhonePairDialog(it, AppLinks::pairTaken) }
}

// What this phone sends to the TV of the code: the repos ticked, all at first, the video sources it installed from them, the trackers it is signed in to, and a sign in to sync with the password typed here, which the TV uses to sign in as a device of its own. Nothing is sent to an address outside a home network.
@Composable
private fun PhonePairDialog(link: PairLink, onClose: () -> Unit) {
    val container = LocalAppContainer.current
    val account by LocalProfiles.current.syncAccounts.account
        .collectAsStateWithLifecycle()
    val repos by remember(container) { container.repos.repos }.collectAsStateWithLifecycle(emptyList())
    val installed by remember(container) { container.sources.installed }.collectAsStateWithLifecycle(emptyList())
    val libraryId by remember(container) {
        container.settings.text(SettingKey.SyncLibraryId)
    }.collectAsStateWithLifecycle(null)
    var left by remember { mutableStateOf(emptySet<String>()) }
    var withSources by remember { mutableStateOf(true) }
    val trackers by remember(container) { container.trackers.signedIn }.collectAsStateWithLifecycle(emptyMap())
    var withTrackers by remember { mutableStateOf(true) }
    var withSync by remember(account) { mutableStateOf(account != null) }
    var password by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    var stage by remember { mutableStateOf(Sending.Ready) }
    val scope = rememberCoroutineScope()
    val home = isHomeAddress(link.address)
    val chosen = repos.map { it.url }.filter { it !in left }
    val videos = installed.filter { it.kind == Kind.Anime && it.repoUrl in chosen }
    val send: () -> Unit = {
        stage = Sending.Busy
        val sync = account
            ?.takeIf {
                withSync
            }?.let { PairSync(it.server, it.username, password, code, libraryId?.toLongOrNull()) }
        val pack = PairPackage(
            repos = chosen,
            sources = if (withSources) {
                videos.mapNotNull { source ->
                    source.repoUrl?.let {
                        PairSource(it, source.originId)
                    }
                }
            } else {
                emptyList()
            },
            sync = sync,
            trackers = if (withTrackers) trackers.mapKeys { it.key.id } else emptyMap(),
        )
        scope.launch { stage = if (sendPair(link, pack.sealFor(link))) Sending.Sent else Sending.Failed }
    }
    AppDialog(
        onDismissRequest = onClose,
        title = { Text(stringResource(Res.string.pair_title)) },
        text = {
            Column(
                Modifier.heightIn(max = 460.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                if (!home) {
                    Text(stringResource(Res.string.pair_not_home), color = MaterialTheme.colorScheme.error)
                    return@Column
                }
                Text(stringResource(Res.string.pair_to, link.address.substringBefore(':')))
                if (repos.isNotEmpty()) {
                    Text(stringResource(Res.string.pair_repos), fontWeight = FontWeight.SemiBold)
                    repos.forEach { repo ->
                        CheckRow(repo.name, repo.url !in left, { on ->
                            left =
                                if (on) left - repo.url else left + repo.url
                        }, hint = repo.url)
                    }
                    if (videos.isNotEmpty()) {
                        CheckRow(
                            pluralStringResource(
                                Res.plurals.pair_sources,
                                videos.size,
                                videos.size,
                            ),
                            withSources,
                            {
                                withSources =
                                    it
                            },
                        )
                    }
                }
                if (trackers.isNotEmpty()) {
                    CheckRow(
                        stringResource(Res.string.pair_trackers, trackers.keys.joinToString(", ") { it.label }),
                        withTrackers,
                        { withTrackers = it },
                    )
                }
                account?.let { signedIn ->
                    CheckRow(stringResource(Res.string.pair_sync, signedIn.username), withSync, { withSync = it })
                    if (withSync) {
                        AppTextField(
                            password,
                            { password = it },
                            Modifier.fillMaxWidth(),
                            singleLine = true,
                            label = { Text(stringResource(Res.string.pair_password)) },
                            visualTransformation = PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                        )
                        AppTextField(
                            code,
                            { code = it.filter(Char::isDigit).take(8) },
                            Modifier.fillMaxWidth(),
                            singleLine = true,
                            label = { Text(stringResource(Res.string.pair_code)) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        )
                    }
                }
                when (stage) {
                    Sending.Ready -> Unit

                    Sending.Busy -> Text(
                        stringResource(Res.string.pair_sending),
                        color = MaterialTheme.colorScheme.primary,
                    )

                    Sending.Sent -> Text(
                        stringResource(Res.string.pair_sent),
                        color = MaterialTheme.colorScheme.primary,
                    )

                    Sending.Failed -> Text(
                        stringResource(Res.string.pair_failed),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            }
        },
        confirmButton = {
            if (stage == Sending.Sent) {
                InkButton(onClose) { Text(stringResource(Res.string.pair_done)) }
            } else {
                val ready =
                    home && stage != Sending.Busy &&
                        (chosen.isNotEmpty() || withSync || (withTrackers && trackers.isNotEmpty())) &&
                        (!withSync || account == null || password.isNotBlank())
                InkButton(send, enabled = ready) { Text(stringResource(Res.string.pair_send)) }
            }
        },
        dismissButton = { if (stage != Sending.Sent) CancelButton(onClose) },
    )
}
