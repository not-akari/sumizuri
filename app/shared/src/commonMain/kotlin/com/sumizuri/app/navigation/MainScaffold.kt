package com.sumizuri.app.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.sumizuri.app.navigation.bar.BottomNavBar
import com.sumizuri.app.navigation.bar.IslandMetrics
import com.sumizuri.app.navigation.bar.IslandNavBar
import com.sumizuri.app.navigation.bar.NavAvatar
import com.sumizuri.app.navigation.bar.NavLabels
import com.sumizuri.app.navigation.bar.NavStyle
import com.sumizuri.app.ui.kit.page.LocalBottomClearance
import com.sumizuri.app.ui.kit.page.LocalHideBottomBar
import com.sumizuri.app.ui.motion.Rise

// The frame of the tabs: the bar the person chose, placed where its style puts it, around the page of the open tab. A floating bar lies over the page, which leaves room for it at its bottom through LocalBottomClearance.
@Composable
fun MainScaffold(
    tabs: List<Destination>,
    style: NavStyle,
    labels: NavLabels,
    swipe: Boolean,
    selected: Destination,
    avatar: NavAvatar?,
    badges: Map<Destination, Int>,
    onSelect: (Destination) -> Unit,
    content: @Composable () -> Unit,
) {
    // The floating bar rises into place when the tabs first show.
    var rose by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { rose = true }
    // A page can ask for the bar at the bottom to step aside while it shows a bar of its own there.
    var hidden by remember { mutableStateOf(false) }
    val hide: (Boolean) -> Unit = remember { { hidden = it } }
    CompositionLocalProvider(LocalHideBottomBar provides hide) {
        BoxWithConstraints(Modifier.fillMaxSize()) {
            // Adaptive keeps the tabs in a bar along the bottom of a phone, which never lies over the page, and in a rail down the side of a wide window. The floating bar is there for whoever picks it.
            val shown = shownNavStyle(style, maxWidth)
            // A swipe is left out where a tab already uses it, which the library and the updates do to change the shelf.
            val swipeHere = swipe && selected != Destination.Library && selected != Destination.Updates
            val page = Modifier.swipeTabs(swipeHere && shown in Bottom, tabs, selected, onSelect)
            when (shown) {
                NavStyle.Island -> {
                    val bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                    Box(Modifier.fillMaxSize()) {
                        CompositionLocalProvider(LocalBottomClearance provides if (hidden) bottom else bottom + IslandMetrics.Reach) {
                            Box(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal)).then(page)) { content() }
                        }
                        Rise(rose && !hidden, Modifier.align(Alignment.BottomCenter).padding(bottom = bottom + IslandMetrics.Margin)) { IslandNavBar(tabs, selected, labels, avatar, badges, onSelect) }
                    }
                }

                NavStyle.Bar, NavStyle.Auto -> Column(Modifier.fillMaxSize()) {
                    Box(
                        Modifier
                            .weight(1f)
                            .fillMaxWidth()
                            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal))
                            .then(page),
                    ) { content() }
                    Rise(!hidden) { BottomNavBar(tabs, selected, labels, avatar, badges, onSelect) }
                }

                // The tabs down the side are drawn over everything by SideNav, so the page only keeps clear of them.
                NavStyle.Rail, NavStyle.Drawer -> Box(
                    Modifier
                        .fillMaxSize()
                        .padding(start = LocalSideNavWidth.current)
                        .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.End + WindowInsetsSides.Bottom)),
                ) { content() }
            }
        }
    }
}

// The styles that put the bar at the bottom, where a swipe between tabs makes sense.
private val Bottom = setOf(NavStyle.Island, NavStyle.Bar)
