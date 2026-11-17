package com.sumizuri.app.feature.appupdate

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.Link
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.appupdate.InstallResult
import com.sumizuri.app.data.appupdate.UpdatePrefs
import com.sumizuri.app.data.appupdate.UpdateState
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.appupdate_auto_check
import com.sumizuri.app.shared.resources.appupdate_auto_check_hint
import com.sumizuri.app.shared.resources.appupdate_changes
import com.sumizuri.app.shared.resources.appupdate_current_notes
import com.sumizuri.app.shared.resources.appupdate_group_options
import com.sumizuri.app.shared.resources.appupdate_install_failed
import com.sumizuri.app.shared.resources.appupdate_install_permission
import com.sumizuri.app.shared.resources.appupdate_new_version
import com.sumizuri.app.shared.resources.appupdate_open_page
import com.sumizuri.app.shared.resources.appupdate_prerelease
import com.sumizuri.app.shared.resources.appupdate_prerelease_hint
import com.sumizuri.app.shared.resources.appupdate_skip
import com.sumizuri.app.shared.resources.appupdate_skipped
import com.sumizuri.app.shared.resources.appupdate_source
import com.sumizuri.app.shared.resources.appupdate_source_built_in
import com.sumizuri.app.shared.resources.appupdate_source_none
import com.sumizuri.app.shared.resources.appupdate_title
import com.sumizuri.app.shared.resources.appupdate_title_hint
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// How long a check counts as fresh, so going back and forth does not ask the site again.
private const val RecheckMs = 60_000L

// The page of new versions of the app: this version and what the last check found, the notes of what changed in every newer version, saving the newest and installing it, and the choices of the updater.
@Composable
fun AppUpdateRoute(onBack: () -> Unit) {
    val updater = LocalAppContainer.current.updater
    val state by updater.state.collectAsStateWithLifecycle()
    val download by updater.download.collectAsStateWithLifecycle()
    val opening by updater.opening.collectAsStateWithLifecycle()
    val prefs by remember(updater) { updater.prefs }.collectAsStateWithLifecycle(UpdatePrefs())
    val scope = rememberCoroutineScope()
    val openSite = LocalOpenSite.current
    var installNote by remember { mutableStateOf<StringResource?>(null) }
    var editingSource by remember { mutableStateOf(false) }
    // The page checks when it opens, unless a check is running or one ran a moment ago.
    LaunchedEffect(updater) {
        val now = updater.state.value
        val stale = nowMillis() - updater.prefs.first().lastCheck > RecheckMs
        if (now is UpdateState.Idle || (now !is UpdateState.Checking && stale)) updater.check()
    }
    SettingsPageFrame(Res.string.appupdate_title, onBack, subtitle = Res.string.appupdate_title_hint, onReset = {
        updater.resetChoices()
    }) {
        StatusCard(state, prefs) { scope.launch { updater.check() } }
        (state as? UpdateState.Available)?.let { found ->
            val latest = found.latest
            SettingsSection(stringResource(Res.string.appupdate_new_version, latest.version)) {
                padded {
                    DownloadPart(
                        found.asset != null,
                        download,
                        installNote,
                        onDownload = { found.asset?.let(updater::startDownload) },
                        onCancel = updater::cancelDownload,
                        onInstall = {
                            scope.launch {
                                installNote = when (updater.install()) {
                                    InstallResult.Started -> null
                                    InstallResult.NeedsPermission -> Res.string.appupdate_install_permission
                                    InstallResult.Failed -> Res.string.appupdate_install_failed
                                }
                            }
                        },
                        opening = opening,
                    )
                }
                if (latest.pageUrl.isNotBlank()) {
                    row {
                        SettingRow(
                            stringResource(
                                Res.string.appupdate_open_page,
                            ),
                            subtitle = latest.pageUrl,
                            subtitleLines = 1,
                            leading = {
                                SettingIcon(Icons.AutoMirrored.Outlined.OpenInNew)
                            },
                            onClick = { openSite(latest.pageUrl) },
                        )
                    }
                }
                padded {
                    val skipped = prefs.skipped == latest.version
                    SwitchSetting(Res.string.appupdate_skip, skipped, { on ->
                        scope.launch {
                            updater.skip(if (on) latest.version else null)
                        }
                    }, if (skipped) Res.string.appupdate_skipped else null)
                }
            }
            SettingsSection(Res.string.appupdate_changes) {
                found.newer.forEachIndexed { index, release ->
                    padded {
                        ReleaseNotes(
                            release,
                            startOpen = index == 0,
                        )
                    }
                }
            }
        }
        updater.current()?.takeIf { state is UpdateState.UpToDate && it.notes.isNotBlank() }?.let { release ->
            SettingsSection(Res.string.appupdate_current_notes) { padded { ReleaseNotes(release) } }
        }
        SettingsSection(Res.string.appupdate_group_options) {
            padded {
                SwitchSetting(Res.string.appupdate_auto_check, prefs.autoCheck, { on ->
                    scope.launch {
                        updater.setAutoCheck(on)
                    }
                }, Res.string.appupdate_auto_check_hint)
            }
            padded {
                SwitchSetting(Res.string.appupdate_prerelease, prefs.prerelease, { on ->
                    scope.launch {
                        updater.setPrerelease(on)
                    }
                }, Res.string.appupdate_prerelease_hint)
            }
            row {
                val source = prefs.source.ifBlank { BuildInfo.UpdateRepo }
                SettingRow(
                    stringResource(Res.string.appupdate_source),
                    leading = { SettingIcon(Icons.Outlined.Link) },
                    subtitle = when {
                        source.isBlank() -> stringResource(Res.string.appupdate_source_none)
                        prefs.source.isBlank() -> stringResource(Res.string.appupdate_source_built_in, source)
                        else -> source
                    },
                    subtitleLines = 1,
                    onClick = { editingSource = true },
                )
            }
        }
    }
    if (editingSource) {
        SourceDialog(prefs.source, onDismiss = { editingSource = false }) { address ->
            editingSource = false
            scope.launch {
                updater.setSource(address)
                updater.check()
            }
        }
    }
}
