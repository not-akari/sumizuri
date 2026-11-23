package com.sumizuri.app.feature.tv.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.core.AppBuild
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.net.networkSupported
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.SettingsViewModel
import com.sumizuri.app.feature.settings.library.UpdateIntervals
import com.sumizuri.app.feature.settings.library.updateIntervalLabel
import com.sumizuri.app.feature.theme.rememberThemeModel
import com.sumizuri.app.feature.tv.onboarding.WatchingRows
import com.sumizuri.app.feature.tv.profile.TvPanel
import com.sumizuri.app.feature.tv.profile.WhoAsked
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.settings_about
import com.sumizuri.app.shared.resources.settings_logs
import com.sumizuri.app.shared.resources.settings_mode
import com.sumizuri.app.shared.resources.settings_network
import com.sumizuri.app.shared.resources.settings_oled
import com.sumizuri.app.shared.resources.settings_reduce_motion
import com.sumizuri.app.shared.resources.settings_storage
import com.sumizuri.app.shared.resources.settings_theme
import com.sumizuri.app.shared.resources.settings_version
import com.sumizuri.app.shared.resources.trackers_title
import com.sumizuri.app.shared.resources.tv_dev_title
import com.sumizuri.app.shared.resources.tv_dev_welcome
import com.sumizuri.app.shared.resources.tv_dev_who
import com.sumizuri.app.shared.resources.tv_library_phone
import com.sumizuri.app.shared.resources.tv_off
import com.sumizuri.app.shared.resources.tv_on
import com.sumizuri.app.shared.resources.tv_profile_phone_value
import com.sumizuri.app.shared.resources.tv_profile_sync
import com.sumizuri.app.shared.resources.tv_profile_trackers_value
import com.sumizuri.app.shared.resources.tv_settings_check
import com.sumizuri.app.shared.resources.tv_settings_skip_done
import com.sumizuri.app.shared.resources.tv_settings_skip_new
import com.sumizuri.app.ui.theme.ThemeMode
import com.sumizuri.app.ui.tv.TvChoiceRow
import com.sumizuri.app.ui.tv.TvLinkRow
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The settings of one part, the first of which the focus goes to when the remote moves into the part.
@Composable
internal fun SectionRows(
    section: TvSection,
    first: FocusRequester,
    onPanel: (TvPanel) -> Unit,
    onOpen: (SettingsTarget) -> Unit,
) {
    when (section) {
        TvSection.Look -> Rows { LookRows(first, onPanel) }
        TvSection.Watching -> WatchingRows(first, more = true)
        TvSection.Library -> Rows { LibraryRows(first) }
        TvSection.Account -> Rows { AccountRows(first, onPanel, onOpen) }
        TvSection.System -> Rows { SystemRows(first, onOpen) }
    }
}

// The rows of a part, one under another, that scroll when they do not fit.
@Composable
private fun Rows(content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
        content = content,
    )
}

@Composable
private fun onOff(): (Boolean) -> String {
    val on = stringResource(Res.string.tv_on)
    val off = stringResource(Res.string.tv_off)
    return { if (it) on else off }
}

// The theme, which opens the themes to pick from, the color mode, pure black and less motion.
@Composable
private fun LookRows(first: FocusRequester, onPanel: (TvPanel) -> Unit) {
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val theme by rememberThemeModel().active.collectAsStateWithLifecycle()
    val mode by settings.themeMode.collectAsStateWithLifecycle()
    val oled by settings.oled.collectAsStateWithLifecycle()
    val calm by settings.reduceMotion.collectAsStateWithLifecycle()
    val onOff = onOff()
    TvLinkRow(stringResource(Res.string.settings_theme), theme.name, {
        onPanel(TvPanel.Look)
    }, Modifier.focusRequester(first))
    TvChoiceRow(stringResource(Res.string.settings_mode), ThemeMode.entries, mode, {
        stringResource(it.label)
    }, settings::onThemeMode)
    TvChoiceRow(stringResource(Res.string.settings_oled), listOf(true, false), oled, { onOff(it) }, settings::onOled)
    TvChoiceRow(stringResource(Res.string.settings_reduce_motion), listOf(true, false), calm, {
        onOff(it)
    }, settings::onReduceMotion)
}

// How often the library is checked for new episodes, and which shows the check leaves out.
@Composable
private fun LibraryRows(first: FocusRequester) {
    val container = LocalAppContainer.current
    val settings = viewModel { SettingsViewModel(container.settings) }
    val hours by settings.updateHours.collectAsStateWithLifecycle()
    val skipDone by settings.skipCompleted.collectAsStateWithLifecycle()
    val skipNew by settings.skipNotStarted.collectAsStateWithLifecycle()
    val onOff = onOff()
    TvChoiceRow(
        stringResource(Res.string.tv_settings_check),
        UpdateIntervals,
        hours,
        { updateIntervalLabel(it) },
        settings::onUpdateHours,
        Modifier.focusRequester(first),
    )
    TvChoiceRow(stringResource(Res.string.tv_settings_skip_done), listOf(true, false), skipDone, {
        onOff(it)
    }, settings::onSkipCompleted)
    TvChoiceRow(stringResource(Res.string.tv_settings_skip_new), listOf(true, false), skipNew, {
        onOff(it)
    }, settings::onSkipNotStarted)
}

// Sync and a phone open over the settings, and the trackers open their own page.
@Composable
private fun AccountRows(first: FocusRequester, onPanel: (TvPanel) -> Unit, onOpen: (SettingsTarget) -> Unit) {
    val container = LocalAppContainer.current
    val account by LocalProfiles.current.syncAccounts.account
        .collectAsStateWithLifecycle()
    val trackers by remember(container) { container.trackers.signedIn }.collectAsStateWithLifecycle(emptyMap())
    TvLinkRow(
        stringResource(Res.string.tv_profile_sync),
        account?.username ?: stringResource(Res.string.tv_off),
        { onPanel(TvPanel.Sync) },
        Modifier.focusRequester(first),
    )
    TvLinkRow(stringResource(Res.string.tv_library_phone), stringResource(Res.string.tv_profile_phone_value), {
        onPanel(TvPanel.Phone)
    })
    TvLinkRow(
        stringResource(Res.string.trackers_title),
        pluralStringResource(Res.plurals.tv_profile_trackers_value, trackers.size, trackers.size),
        { onOpen(SettingsTarget.Trackers) },
    )
}

// The pages of the system, which open as they are.
@Composable
private fun SystemRows(first: FocusRequester, onOpen: (SettingsTarget) -> Unit) {
    val pages = buildList {
        if (networkSupported) add(Res.string.settings_network to SettingsTarget.Network)
        add(Res.string.settings_storage to SettingsTarget.Storage)
        add(Res.string.settings_logs to SettingsTarget.Logs)
        add(Res.string.settings_about to SettingsTarget.About)
    }
    pages.forEachIndexed { at, (name, target) ->
        TvLinkRow(
            stringResource(name),
            if (target ==
                SettingsTarget.About
            ) {
                stringResource(Res.string.settings_version, BuildInfo.Version)
            } else {
                null
            },
            { onOpen(target) },
            if (at == 0) Modifier.focusRequester(first) else Modifier,
        )
    }
    // Ways to see the screens that show only once, while making the app.
    if (AppBuild.isDebug) {
        val container = LocalAppContainer.current
        val scope = rememberCoroutineScope()
        val line = stringResource(Res.string.tv_dev_title)
        TvLinkRow(stringResource(Res.string.tv_dev_welcome), line, {
            scope.launch { container.settings.setFlag(SettingKey.OnboardingDone, false) }
        })
        TvLinkRow(stringResource(Res.string.tv_dev_who), line, { WhoAsked.preview = true })
    }
}
