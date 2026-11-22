package com.sumizuri.app.navigation.bar

import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.navigation.RailWidth
import com.sumizuri.app.ui.kit.card.softFill

// The narrow column of tabs down the side of a wide window. It has no panel of its own and lies on the background of the page, with a faint line between them. The tabs start at the top, level with the name of the page, and the profile stands apart at the bottom, as the account does in most desktop apps.
@Composable
internal fun SideNavRail(
    tabs: List<Destination>,
    selected: Destination,
    labels: NavLabels,
    avatar: NavAvatar?,
    badges: Map<Destination, Int>,
    onSelect: (Destination) -> Unit,
) {
    val marker = rememberInkMarker()
    marker.Follow(tabs.indexOf(selected), vertical = true)
    val fill = softFill(strong = true)
    val ring = MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
    val current = remember { FocusRequester() }
    Surface(Modifier.fillMaxHeight().width(RailWidth).sideEdge(), color = Color.Transparent) {
        Column(
            Modifier
                .fillMaxHeight()
                .inkLayer(
                    marker,
                    vertical = true,
                    fill,
                    ring,
                ).windowInsetsPadding(WindowInsets.safeDrawing)
                .padding(vertical = 12.dp)
                // A remote coming in lands on the open tab, and up and down stay in the rail instead of falling into the page.
                .focusProperties {
                    onEnter = { if (requestedFocusDirection != FocusDirection.Enter) current.requestFocus() }
                    onExit =
                        {
                            if (requestedFocusDirection == FocusDirection.Up ||
                                requestedFocusDirection == FocusDirection.Down
                            ) {
                                cancelFocusChange()
                            }
                        }
                }.focusGroup(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            tabs.forEachIndexed { at, tab ->
                if (tab == Destination.Profile) Spacer(Modifier.weight(1f))
                NavItem(
                    tab,
                    tab == selected,
                    avatar,
                    badges[tab] ?: 0,
                    labels,
                    wide = true,
                    onClick = { onSelect(tab) },
                    modifier = if (tab == selected) Modifier.focusRequester(current) else Modifier,
                    spot = Modifier.inkSpot(marker, at),
                )
            }
        }
    }
}
