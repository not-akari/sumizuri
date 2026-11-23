package com.sumizuri.app.feature.tv.settings.system

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.appupdate.InstallResult
import com.sumizuri.app.data.appupdate.UpdatePrefs
import com.sumizuri.app.data.appupdate.UpdateState
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.about.Libraries
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.about_community
import com.sumizuri.app.shared.resources.about_discord
import com.sumizuri.app.shared.resources.about_github
import com.sumizuri.app.shared.resources.about_licenses
import com.sumizuri.app.shared.resources.about_licenses_hint
import com.sumizuri.app.shared.resources.about_licenses_note
import com.sumizuri.app.shared.resources.about_tagline
import com.sumizuri.app.shared.resources.about_website
import com.sumizuri.app.shared.resources.app_name
import com.sumizuri.app.shared.resources.appupdate_auto_check
import com.sumizuri.app.shared.resources.appupdate_cancel_download
import com.sumizuri.app.shared.resources.appupdate_check_now
import com.sumizuri.app.shared.resources.appupdate_checking
import com.sumizuri.app.shared.resources.appupdate_download
import com.sumizuri.app.shared.resources.appupdate_download_failed
import com.sumizuri.app.shared.resources.appupdate_failed
import com.sumizuri.app.shared.resources.appupdate_install
import com.sumizuri.app.shared.resources.appupdate_install_failed
import com.sumizuri.app.shared.resources.appupdate_install_permission
import com.sumizuri.app.shared.resources.appupdate_new_version
import com.sumizuri.app.shared.resources.appupdate_no_file
import com.sumizuri.app.shared.resources.appupdate_no_source
import com.sumizuri.app.shared.resources.appupdate_prerelease
import com.sumizuri.app.shared.resources.appupdate_title
import com.sumizuri.app.shared.resources.appupdate_title_hint
import com.sumizuri.app.shared.resources.appupdate_up_to_date
import com.sumizuri.app.shared.resources.legal_hint
import com.sumizuri.app.shared.resources.legal_title
import com.sumizuri.app.shared.resources.onboarding_replay
import com.sumizuri.app.shared.resources.onboarding_replay_hint
import com.sumizuri.app.shared.resources.privacy_hint
import com.sumizuri.app.shared.resources.privacy_title
import com.sumizuri.app.shared.resources.settings_about
import com.sumizuri.app.shared.resources.settings_version
import com.sumizuri.app.shared.resources.tv_about_saving
import com.sumizuri.app.ui.text.byteSizeText
import com.sumizuri.app.ui.tv.TvChoiceRow
import com.sumizuri.app.ui.tv.TvLinkRow
import com.sumizuri.app.ui.tv.TvRow
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// Where the project lives, written out, since a TV seldom has a browser to open them in.
private val Places = listOf(
    Res.string.about_website to "sumizuri.notakari.com",
    Res.string.about_discord to "discord.gg/JZaqv5VFj7",
    Res.string.about_github to "github.com/not-akari/sumizuri",
)

// The app on a TV: its version, its new versions from download to install, the welcome shown again, the legal pages and where the project lives.
@Composable
internal fun TvAboutRoute(onOpen: (SettingsTarget) -> Unit) {
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    val prefs by remember(container) { container.updater.prefs }.collectAsStateWithLifecycle(UpdatePrefs())
    val onOff = onOffWords()
    TvSystemPage(stringResource(Res.string.settings_about), stringResource(Res.string.about_tagline)) { first ->
        TvInfoRow(
            stringResource(Res.string.app_name),
            null,
            stringResource(Res.string.settings_version, BuildInfo.Version),
            {},
            Modifier.focusRequester(first),
        )
        TvGroupTitle(stringResource(Res.string.appupdate_title))
        UpdateRow()
        TvChoiceRow(stringResource(Res.string.appupdate_auto_check), listOf(true, false), prefs.autoCheck, {
            onOff(it)
        }, { on -> scope.launch { container.updater.setAutoCheck(on) } })
        TvChoiceRow(stringResource(Res.string.appupdate_prerelease), listOf(true, false), prefs.prerelease, {
            onOff(it)
        }, { on -> scope.launch { container.updater.setPrerelease(on) } })
        TvGroupTitle(stringResource(Res.string.settings_about))
        TvInfoRow(
            stringResource(Res.string.onboarding_replay),
            stringResource(Res.string.onboarding_replay_hint),
            null,
            // The first steps show again over the app as soon as they are marked not done.
            { scope.launch { container.settings.setFlag(SettingKey.OnboardingDone, false) } },
        )
        TvLinkRow(stringResource(Res.string.legal_title), stringResource(Res.string.legal_hint), {
            onOpen(SettingsTarget.Legal)
        })
        TvLinkRow(stringResource(Res.string.privacy_title), stringResource(Res.string.privacy_hint), {
            onOpen(SettingsTarget.Privacy)
        })
        TvLinkRow(stringResource(Res.string.about_licenses), stringResource(Res.string.about_licenses_hint), {
            onOpen(SettingsTarget.Licenses)
        })
        TvGroupTitle(stringResource(Res.string.about_community))
        for ((name, place) in Places) TvInfoRow(stringResource(name), null, place, {})
    }
}

// One row for new versions that does the next step on OK: check, download the file, then install it, telling how it goes under its name.
@Composable
private fun UpdateRow() {
    val container = LocalAppContainer.current
    val updater = container.updater
    val scope = rememberCoroutineScope()
    val state by updater.state.collectAsStateWithLifecycle()
    val download by updater.download.collectAsStateWithLifecycle()
    var note by remember { mutableStateOf<String?>(null) }
    val permission = stringResource(Res.string.appupdate_install_permission)
    val failed = stringResource(Res.string.appupdate_install_failed)
    val available = state as? UpdateState.Available
    val saving = download
    val line = note ?: when {
        saving?.error != null -> stringResource(Res.string.appupdate_download_failed)

        saving != null && !saving.finished -> stringResource(
            Res.string.tv_about_saving,
            byteSizeText(saving.done),
            saving.total?.let(::byteSizeText) ?: "?",
        )

        available != null && available.asset == null -> stringResource(Res.string.appupdate_no_file)

        available != null -> stringResource(Res.string.appupdate_new_version, available.latest.version)

        state is UpdateState.Checking -> stringResource(Res.string.appupdate_checking)

        state is UpdateState.UpToDate -> stringResource(Res.string.appupdate_up_to_date)

        state is UpdateState.NoSource -> stringResource(Res.string.appupdate_no_source)

        state is UpdateState.Failed -> stringResource(Res.string.appupdate_failed)

        else -> null
    }
    val action = when {
        saving != null && saving.finished -> Res.string.appupdate_install
        saving != null && saving.error == null -> Res.string.appupdate_cancel_download
        available?.asset != null -> Res.string.appupdate_download
        available != null -> null
        else -> Res.string.appupdate_check_now
    }
    // The group above already says what the row is for, so the row tells how it stands.
    TvInfoRow(
        line ?: stringResource(Res.string.appupdate_title_hint),
        null,
        action?.let { stringResource(it) },
        {
            note = null
            when (action) {
                Res.string.appupdate_install -> scope.launch {
                    note = when (updater.install()) {
                        InstallResult.Started -> null
                        InstallResult.NeedsPermission -> permission
                        InstallResult.Failed -> failed
                    }
                }

                Res.string.appupdate_cancel_download -> updater.cancelDownload()

                Res.string.appupdate_download -> available?.asset?.let(updater::startDownload)

                Res.string.appupdate_check_now -> scope.launch { updater.check() }

                else -> Unit
            }
        },
    )
}

// The libraries the app is built with, each a row the remote can move through.
@Composable
internal fun TvLicensesRoute() {
    TvSystemPage(stringResource(Res.string.about_licenses), stringResource(Res.string.about_licenses_note)) { first ->
        Libraries.forEachIndexed { at, (name, by) ->
            TvInfoRow(name, by, null, {}, if (at == 0) Modifier.focusRequester(first) else Modifier)
        }
    }
}

// A page of text on a TV, each paragraph a block the remote moves through, so the page scrolls with the arrows.
@Composable
internal fun TvTextRoute(title: String, intro: String, parts: List<Pair<StringResource, List<StringResource>>>) {
    TvSystemPage(title, intro) { first ->
        var at = 0
        for ((heading, paragraphs) in parts) {
            TvGroupTitle(stringResource(heading))
            for (paragraph in paragraphs) {
                val modifier = if (at++ == 0) Modifier.focusRequester(first) else Modifier
                TvRow({}, modifier) {
                    Text(
                        stringResource(paragraph),
                        Modifier.padding(vertical = 2.dp),
                        fontSize = 17.sp,
                        lineHeight = 26.sp,
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                }
            }
        }
    }
}
