package com.sumizuri.app.feature.settings

import androidx.compose.ui.graphics.vector.ImageVector
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.settings_group_data
import com.sumizuri.app.shared.resources.settings_group_library
import com.sumizuri.app.shared.resources.settings_group_look
import com.sumizuri.app.shared.resources.settings_group_reading
import com.sumizuri.app.shared.resources.settings_group_system
import org.jetbrains.compose.resources.StringResource

// The pages the settings home can open, apart from the pages of the controls. The navigation turns a target into the page it shows.
enum class SettingsTarget {
    Appearance,
    AppIcon,
    Layout,
    LibraryDisplay,
    Shelves,
    LibraryUpdates,
    MissingSources,
    Migration,
    Downloads,
    DownloadOptions,
    Reading,
    Player,
    Controls,
    Storage,
    StorageDownloads,
    StorageImages,
    StorageReader,
    StorageData,
    Backup,
    Import,
    Sync,
    SyncLink,
    SyncWhat,
    SyncWhen,
    SyncDevices,
    SyncAdminPeople,
    SyncAdminUser,
    SyncAdminInvites,
    SyncAdminSettings,
    SyncAdminLog,
    SyncPassword,
    SyncUsername,
    SyncRecovery,
    SyncDelete,
    SyncTwoStep,
    SyncDetails,
    SyncServer,
    SyncAccount,
    SyncAdmin,
    Security,
    Network,
    Advanced,
    Experimental,
    Performance,
    Diagnostics,
    Logs,
    About,
    Licenses,
    Legal,
    Privacy,
    AppUpdate,
    ChapterList,
    Trackers,
    TrackerDetails,
    TrackerAniList,
    TrackerMal,
    TrackerKitsu,
    TrackerMangaBaka,
    TrackerRules,
}

// The groups the pages of the settings are listed in.
internal enum class SettingsGroup(val label: StringResource) {
    Look(Res.string.settings_group_look),
    Library(Res.string.settings_group_library),
    Reading(Res.string.settings_group_reading),
    Data(Res.string.settings_group_data),
    System(Res.string.settings_group_system),
}

// One page of the settings as the home lists it: where it belongs, how it is told apart, what it is set to now, and the settings in it that the search finds.
internal class SettingsPage(
    val group: SettingsGroup,
    val icon: ImageVector,
    val title: String,
    val summary: String,
    val items: List<StringResource>,
    // The target the page is, so the list can mark the one open beside it on a wide window.
    val target: SettingsTarget,
    // A page new in this version that was not opened yet, which the home marks.
    val fresh: Boolean = false,
    val open: () -> Unit,
)

// The pages that are new in this version. The home marks each until it is opened once.
internal val NewPages = setOf(SettingsTarget.AppUpdate, SettingsTarget.ChapterList)
