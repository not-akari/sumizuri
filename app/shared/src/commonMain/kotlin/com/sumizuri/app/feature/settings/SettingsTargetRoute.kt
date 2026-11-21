package com.sumizuri.app.feature.settings

import androidx.compose.runtime.Composable
import com.sumizuri.app.feature.appupdate.AppUpdateRoute
import com.sumizuri.app.feature.downloads.DownloadsRoute
import com.sumizuri.app.feature.settings.about.AboutRoute
import com.sumizuri.app.feature.settings.about.LegalRoute
import com.sumizuri.app.feature.settings.about.LicensesRoute
import com.sumizuri.app.feature.settings.about.PrivacyRoute
import com.sumizuri.app.feature.settings.controls.ControlsHubRoute
import com.sumizuri.app.feature.settings.controls.ControlsPage
import com.sumizuri.app.feature.settings.data.DownloadSettingsRoute
import com.sumizuri.app.feature.settings.data.MissingSourcesRoute
import com.sumizuri.app.feature.settings.data.StorageDataRoute
import com.sumizuri.app.feature.settings.data.StorageDownloadsRoute
import com.sumizuri.app.feature.settings.data.StorageImagesRoute
import com.sumizuri.app.feature.settings.data.StorageReaderRoute
import com.sumizuri.app.feature.settings.data.StorageRoute
import com.sumizuri.app.feature.settings.library.ChapterListRoute
import com.sumizuri.app.feature.settings.library.LibraryUpdatesRoute
import com.sumizuri.app.feature.settings.look.AppearanceRoute
import com.sumizuri.app.feature.settings.look.LayoutRoute
import com.sumizuri.app.feature.settings.reading.PlayerSettingsRoute
import com.sumizuri.app.feature.settings.reading.ReadingRoute
import com.sumizuri.app.feature.settings.system.AdvancedRoute
import com.sumizuri.app.feature.settings.system.DiagnosticsRoute
import com.sumizuri.app.feature.settings.system.PerformanceRoute
import com.sumizuri.app.feature.settings.system.NetworkRoute
import com.sumizuri.app.feature.settings.system.SecurityRoute
import com.sumizuri.app.feature.sync.SyncRoute
import com.sumizuri.app.feature.sync.account.SyncDeleteRoute
import com.sumizuri.app.feature.sync.account.SyncDetailsRoute
import com.sumizuri.app.feature.sync.account.SyncDevicesRoute
import com.sumizuri.app.feature.sync.account.SyncLinkRoute
import com.sumizuri.app.feature.sync.account.SyncPasswordRoute
import com.sumizuri.app.feature.sync.account.SyncRecoveryRoute
import com.sumizuri.app.feature.sync.account.SyncTwoStepRoute
import com.sumizuri.app.feature.sync.account.SyncUsernameRoute
import com.sumizuri.app.feature.sync.account.SyncWhatRoute
import com.sumizuri.app.feature.sync.account.SyncWhenRoute
import com.sumizuri.app.feature.sync.admin.SyncAdminInvitesRoute
import com.sumizuri.app.feature.sync.admin.SyncAdminLogRoute
import com.sumizuri.app.feature.sync.admin.SyncAdminPeopleRoute
import com.sumizuri.app.feature.sync.admin.SyncAdminSettingsRoute
import com.sumizuri.app.feature.sync.admin.SyncAdminUserRoute
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.feature.trackers.TrackerDetailsRoute
import com.sumizuri.app.feature.trackers.TrackerRoute
import com.sumizuri.app.feature.trackers.TrackerRulesRoute
import com.sumizuri.app.feature.trackers.TrackersRoute
import com.sumizuri.app.feature.settings.system.ExperimentalRoute
import com.sumizuri.app.feature.sync.home.SyncServerRoute
import com.sumizuri.app.feature.sync.home.SyncAccountRoute
import com.sumizuri.app.feature.sync.home.SyncAdminRoute
import com.sumizuri.app.feature.settings.look.AppIconRoute

// The page a target of the settings stands for, for the targets that have no page of their own above. A page that leads on to another asks for it with onOpen, the page of the controls opens one of them with onOpenControls, and the page of the missing sources moves a title with onMove.
@Composable
fun SettingsTargetRoute(target: SettingsTarget, onBack: () -> Unit, onOpen: (SettingsTarget) -> Unit, onMove: (Long) -> Unit, onMigrate: (List<Long>) -> Unit, onEditTheme: (String) -> Unit, onOpenControls: (ControlsPage) -> Unit) {
    when (target) {
        SettingsTarget.Controls -> ControlsHubRoute(onBack, onOpenControls)
        SettingsTarget.Appearance -> AppearanceRoute(onBack, onEditTheme)
        SettingsTarget.AppIcon -> AppIconRoute(onBack)
        SettingsTarget.Layout -> LayoutRoute(onBack) { onOpen(SettingsTarget.LibraryDisplay) }
        SettingsTarget.LibraryUpdates -> LibraryUpdatesRoute(onBack) { onOpen(SettingsTarget.Shelves) }
        SettingsTarget.MissingSources -> MissingSourcesRoute(onBack, onMove, onMigrate)
        SettingsTarget.Reading -> ReadingRoute(onBack)
        SettingsTarget.Player -> PlayerSettingsRoute(onBack)
        SettingsTarget.Storage -> StorageRoute(onBack, onOpen)
        SettingsTarget.StorageDownloads -> StorageDownloadsRoute(onBack, onOpen)
        SettingsTarget.StorageImages -> StorageImagesRoute(onBack)
        SettingsTarget.StorageReader -> StorageReaderRoute(onBack)
        SettingsTarget.StorageData -> StorageDataRoute(onBack)
        SettingsTarget.Downloads -> DownloadsRoute(onBack) { onOpen(SettingsTarget.DownloadOptions) }
        SettingsTarget.DownloadOptions -> DownloadSettingsRoute(onBack) { onOpen(SettingsTarget.Downloads) }
        SettingsTarget.Sync -> SyncRoute(onBack, onOpen)
        SettingsTarget.SyncLink -> SyncLinkRoute(onBack)
        SettingsTarget.SyncServer -> SyncServerRoute(onBack)
        SettingsTarget.SyncAccount -> SyncAccountRoute(onBack, onOpen)
        SettingsTarget.SyncAdmin -> SyncAdminRoute(onBack, onOpen)
        SettingsTarget.SyncWhat -> SyncWhatRoute(onBack)
        SettingsTarget.SyncWhen -> SyncWhenRoute(onBack)
        SettingsTarget.SyncDevices -> SyncDevicesRoute(onBack)
        SettingsTarget.SyncAdminPeople -> SyncAdminPeopleRoute(onBack, onOpen)
        SettingsTarget.SyncAdminUser -> SyncAdminUserRoute(onBack)
        SettingsTarget.SyncAdminInvites -> SyncAdminInvitesRoute(onBack)
        SettingsTarget.SyncAdminSettings -> SyncAdminSettingsRoute(onBack)
        SettingsTarget.SyncPassword -> SyncPasswordRoute(onBack)
        SettingsTarget.SyncUsername -> SyncUsernameRoute(onBack)
        SettingsTarget.SyncRecovery -> SyncRecoveryRoute(onBack)
        SettingsTarget.SyncDelete -> SyncDeleteRoute(onBack)
        SettingsTarget.SyncTwoStep -> SyncTwoStepRoute(onBack)
        SettingsTarget.SyncDetails -> SyncDetailsRoute(onBack)
        SettingsTarget.SyncAdminLog -> SyncAdminLogRoute(onBack)
        SettingsTarget.Security -> SecurityRoute(onBack)
        SettingsTarget.Network -> NetworkRoute(onBack)
        SettingsTarget.Advanced -> AdvancedRoute(onBack, onOpen)
        SettingsTarget.Performance -> PerformanceRoute(onBack)
        SettingsTarget.Experimental -> ExperimentalRoute(onBack)
        SettingsTarget.Diagnostics -> DiagnosticsRoute(onBack) { onOpen(SettingsTarget.Logs) }
        SettingsTarget.About -> AboutRoute(onBack, onOpen)
        SettingsTarget.Licenses -> LicensesRoute(onBack)
        SettingsTarget.Legal -> LegalRoute(onBack)
        SettingsTarget.Privacy -> PrivacyRoute(onBack)
        SettingsTarget.AppUpdate -> AppUpdateRoute(onBack)
        SettingsTarget.ChapterList -> ChapterListRoute(onBack)
        SettingsTarget.Trackers -> TrackersRoute(onBack, onOpen)

        SettingsTarget.TrackerDetails -> TrackerDetailsRoute(onBack)

        SettingsTarget.TrackerAniList -> TrackerRoute(TrackerId.AniList, onBack, onOpen)
        SettingsTarget.TrackerMal -> TrackerRoute(TrackerId.Mal, onBack, onOpen)
        SettingsTarget.TrackerKitsu -> TrackerRoute(TrackerId.Kitsu, onBack, onOpen)
        SettingsTarget.TrackerMangaBaka -> TrackerRoute(TrackerId.MangaBaka, onBack, onOpen)
        SettingsTarget.TrackerRules -> TrackerRulesRoute(onBack)
        SettingsTarget.LibraryDisplay, SettingsTarget.Shelves, SettingsTarget.Migration, SettingsTarget.Backup, SettingsTarget.Import, SettingsTarget.Logs -> Unit
    }
}
