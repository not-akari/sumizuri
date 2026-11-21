package com.sumizuri.app.navigation

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.navigation.bar.NavAvatar
import com.sumizuri.app.navigation.bar.NavLabels
import com.sumizuri.app.navigation.bar.NavStyle
import com.sumizuri.app.navigation.bar.SideNavDrawer
import com.sumizuri.app.navigation.bar.SideNavRail
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs

// Below this width the tabs float or sit at the bottom, above it they go down the side.
internal val CompactWidth = 600.dp

// How wide the rail and the drawer are.
internal val RailWidth = 84.dp
internal val DrawerWidth = 232.dp

// Below this width the drawer would squeeze the page, so the rail stands in for it.
private val DrawerMinWindow = 720.dp

// How much room the tabs down the side take at the left of the window, which the tabs and the pages keep their content clear of. Nothing when the tabs are at the bottom.
val LocalSideNavWidth = compositionLocalOf { 0.dp }

// The style the tabs show in at this width. Adaptive keeps them in a bar along the bottom of a phone and in a rail down the side of a wide window.
internal fun shownNavStyle(style: NavStyle, width: Dp): NavStyle = when {
    style == NavStyle.Drawer && width < DrawerMinWindow -> NavStyle.Rail
    style != NavStyle.Auto -> style
    width < CompactWidth -> NavStyle.Bar
    else -> NavStyle.Rail
}

// The room the tabs take at the side in this style.
internal fun sideNavWidth(style: NavStyle): Dp = when (style) {
    NavStyle.Rail -> RailWidth
    NavStyle.Drawer -> DrawerWidth
    else -> 0.dp
}

// A page that takes the whole window, so the tabs at the side step away while it is open: the reader, the theme editor, a title, a site and the settings.
val Page.fullWindow: Boolean get() = this is Page.Reader || this is Page.ThemeEditor || this is Page.Saved ||
    this is Page.Preview || this is Page.Web || settingsPart

// The settings and the pages opened from them.
private val Page.settingsPart: Boolean get() = this is Page.Settings || this is Page.SettingsPage ||
    this is Page.Controls || this is Page.Logs || this is Page.Backup || this is Page.Import ||
    this is Page.LibraryDisplay

// The tabs down the side, over the tabs and the pages alike, so they stay one click away on every page. They lie on the background of whatever is under them, and slide out of the way for a page that takes the whole window.
@Composable
internal fun SideNav(
    style: NavStyle,
    visible: Boolean,
    tabs: List<Destination>,
    selected: Destination,
    labels: NavLabels,
    avatar: NavAvatar?,
    badges: Map<Destination, Int>,
    onSelect: (Destination) -> Unit,
    modifier: Modifier = Modifier,
) {
    val ms = motionMs(AppMotion.Medium)
    AnimatedVisibility(
        visible,
        modifier,
        enter = slideInHorizontally(tween(ms, easing = AppMotion.Entrance)) { -it } + fadeIn(tween(ms)),
        exit = slideOutHorizontally(tween(ms, easing = AppMotion.Leave)) { -it } + fadeOut(tween(ms)),
    ) {
        if (style == NavStyle.Drawer) {
            SideNavDrawer(tabs, selected, avatar, badges, onSelect)
        } else {
            SideNavRail(tabs, selected, labels, avatar, badges, onSelect)
        }
    }
}
