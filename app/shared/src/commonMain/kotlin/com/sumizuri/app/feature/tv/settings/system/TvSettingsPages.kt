package com.sumizuri.app.feature.tv.settings.system

import androidx.compose.runtime.Composable
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.about.LegalParts
import com.sumizuri.app.feature.settings.about.PrivacyParts
import com.sumizuri.app.feature.tv.profile.TvTrackersRoute
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.legal_intro
import com.sumizuri.app.shared.resources.legal_title
import com.sumizuri.app.shared.resources.privacy_intro
import com.sumizuri.app.shared.resources.privacy_title
import org.jetbrains.compose.resources.stringResource

// The settings pages a TV has its own of, made for the remote, or null for a page it shows as other devices do.
internal fun tvSettingsPage(target: SettingsTarget, onOpen: (SettingsTarget) -> Unit): (@Composable () -> Unit)? =
    when (target) {
        SettingsTarget.Trackers -> {
            { TvTrackersRoute() }
        }

        SettingsTarget.Storage -> {
            { TvStorageRoute() }
        }

        SettingsTarget.Logs -> {
            { TvLogsRoute() }
        }

        SettingsTarget.Network -> {
            { TvNetworkRoute() }
        }

        SettingsTarget.About -> {
            { TvAboutRoute(onOpen) }
        }

        SettingsTarget.Licenses -> {
            { TvLicensesRoute() }
        }

        SettingsTarget.Legal -> {
            { TvTextRoute(stringResource(Res.string.legal_title), stringResource(Res.string.legal_intro), LegalParts) }
        }

        SettingsTarget.Privacy -> {
            {
                TvTextRoute(
                    stringResource(Res.string.privacy_title),
                    stringResource(Res.string.privacy_intro),
                    PrivacyParts,
                )
            }
        }

        else -> null
    }
