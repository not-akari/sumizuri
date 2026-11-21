package com.sumizuri.app

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import com.sumizuri.app.data.model.library.LibrarySection
import com.sumizuri.app.feature.browse.hub.BrowseHubRoute
import com.sumizuri.app.feature.history.HistoryRoute
import com.sumizuri.app.feature.library.LibraryRoute
import com.sumizuri.app.feature.profile.ProfileRoute
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.updates.UpdatesRoute
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.navigation.NavigationViewModel
import com.sumizuri.app.navigation.Page

// The page of each tab of the app, with where each of its links leads.
@Composable
internal fun AppTab(tab: Destination, tabs: List<Destination>, navigation: NavigationViewModel) {
    when (tab) {
        Destination.Library -> LibraryRoute(
            onOpenTitle = { navigation.push(Page.Saved(it)) },
            onOpenChapter = { navigation.push(Page.Reader(it)) },
            onOpenShelves = { navigation.push(Page.Shelves) },
            onMove = { navigation.push(Page.Migrate(it)) },
            onMigrate = { navigation.push(Page.Migration(it)) },
            onSeeAll = { section ->
                val target = if (section == LibrarySection.Updates) Destination.Updates else Destination.History
                if (target in
                    tabs
                ) {
                    navigation.select(target)
                } else {
                    navigation.push(
                        if (target ==
                            Destination.Updates
                        ) {
                            Page.Updates
                        } else {
                            Page.History
                        },
                    )
                }
            },
            onOpenMissing = { navigation.push(Page.SettingsPage(SettingsTarget.MissingSources)) },
            onOpenDownloads = { navigation.push(Page.SettingsPage(SettingsTarget.Downloads)) },
            onSearchSources = { navigation.push(Page.GlobalSearch(it)) },
        )

        Destination.Updates -> UpdatesRoute({
            navigation.push(Page.Saved(it))
        }, { navigation.push(Page.SettingsPage(SettingsTarget.MissingSources)) })

        Destination.History -> HistoryRoute { navigation.push(Page.Saved(it)) }

        Destination.Browse -> BrowseHubRoute(
            onOpenSource = { navigation.push(Page.Source(it)) },
            onOpenRepo = { navigation.push(Page.RepoSources(it)) },
            onOpenSearch = { navigation.push(Page.GlobalSearch(it)) },
            onNewExtension = { navigation.push(Page.ExtensionEditor(null)) },
            onEditSource = { navigation.push(Page.ExtensionEditor(it.id)) },
        )

        Destination.Profile -> ProfileRoute(
            onOpenSettings = { navigation.push(Page.Settings) },
            onOpenSync = { navigation.push(Page.SettingsPage(SettingsTarget.Sync)) },
            onOpenTrackers = { navigation.push(Page.SettingsPage(SettingsTarget.Trackers)) },
            onArrange = { navigation.push(Page.ArrangeBlocks) },
            onLayouts = { navigation.push(Page.ProfileLayouts) },
            onOpenMissing = { navigation.push(Page.SettingsPage(SettingsTarget.MissingSources)) },
            onOpenTitle = { navigation.push(Page.Saved(it)) },
        )
    }
}
