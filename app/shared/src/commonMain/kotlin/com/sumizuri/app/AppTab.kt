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
import com.sumizuri.app.feature.tv.browse.TvBrowseRoute
import com.sumizuri.app.feature.tv.feed.TvHistoryRoute
import com.sumizuri.app.feature.tv.feed.TvUpdatesRoute
import com.sumizuri.app.feature.tv.library.TvLibraryRoute
import com.sumizuri.app.feature.tv.profile.TvProfileRoute
import com.sumizuri.app.feature.updates.UpdatesRoute
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.navigation.NavigationViewModel
import com.sumizuri.app.navigation.Page
import com.sumizuri.app.ui.tv.LocalTv

// The page of each tab of the app, with where each of its links leads.
@Composable
internal fun AppTab(tab: Destination, tabs: List<Destination>, navigation: NavigationViewModel) {
    val tv = LocalTv.current
    when (tab) {
        // A TV has a library of its own, videos only and moved with the remote.
        Destination.Library -> if (tv) {
            TvLibraryRoute(
                onOpenTitle = { navigation.push(Page.Saved(it)) },
                onPlay = { navigation.push(Page.Reader(it)) },
                onBrowse = { navigation.select(Destination.Browse) },
                onOpenFound = { navigation.push(Page.Preview(it.source, it.entry)) },
            )
        } else {
            LibraryRoute(
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
        }

        // A TV has the new and the watched episodes as rows of cards, played with OK.
        Destination.Updates -> if (tv) {
            TvUpdatesRoute({ navigation.push(Page.Reader(it)) }, { navigation.push(Page.Saved(it)) })
        } else {
            UpdatesRoute({
                navigation.push(Page.Saved(it))
            }, { navigation.push(Page.SettingsPage(SettingsTarget.MissingSources)) })
        }

        Destination.History -> if (tv) {
            TvHistoryRoute({ navigation.push(Page.Reader(it)) }, { navigation.push(Page.Saved(it)) })
        } else {
            HistoryRoute { navigation.push(Page.Saved(it)) }
        }

        // A TV has a Browse of its own, with the video sources and the repos made for the remote.
        Destination.Browse -> if (tv) {
            TvBrowseRoute(onOpenSource = {
                navigation.push(Page.Source(it))
            }, onOpenRepo = { navigation.push(Page.RepoSources(it)) })
        } else {
            BrowseHubRoute(
                onOpenSource = { navigation.push(Page.Source(it)) },
                onOpenRepo = { navigation.push(Page.RepoSources(it)) },
                onOpenSearch = { navigation.push(Page.GlobalSearch(it)) },
                onNewExtension = { navigation.push(Page.ExtensionEditor(null)) },
                onEditSource = { navigation.push(Page.ExtensionEditor(it.id)) },
            )
        }

        // A TV has a profile of its own, with the profiles to switch between and what is set from the remote.
        Destination.Profile -> if (tv) {
            TvProfileRoute(
                onOpenTrackers = { navigation.push(Page.SettingsPage(SettingsTarget.Trackers)) },
                onOpenSettings = { navigation.push(Page.Settings) },
                onOpenPage = { navigation.push(Page.SettingsPage(it)) },
            )
        } else {
            ProfileRoute(
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
}
