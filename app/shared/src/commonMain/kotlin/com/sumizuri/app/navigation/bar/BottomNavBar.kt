package com.sumizuri.app.navigation.bar

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sumizuri.app.navigation.Destination
import com.sumizuri.app.ui.kit.card.Hairline
import com.sumizuri.app.ui.kit.card.softFill

// The bar along the bottom edge, with every tab the same width.
@Composable
internal fun BottomNavBar(
    tabs: List<Destination>,
    selected: Destination,
    labels: NavLabels,
    avatar: NavAvatar?,
    badges: Map<Destination, Int>,
    onSelect: (Destination) -> Unit,
) {
    // No panel of its own: the bar lies on the background of the page, under a faint line.
    val marker = rememberInkMarker()
    marker.Follow(tabs.indexOf(selected), vertical = false)
    val fill = softFill(strong = true)
    val ring = MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
    Surface(Modifier.fillMaxWidth(), color = Color.Transparent) {
        Column {
            Hairline(alpha = 0.5f)
            Row(
                Modifier
                    .fillMaxWidth()
                    .windowInsetsPadding(
                        WindowInsets.navigationBars,
                    ).padding(vertical = 8.dp)
                    .inkLayer(marker, vertical = false, fill, ring),
            ) {
                tabs.forEachIndexed { at, tab ->
                    NavItem(tab, tab == selected, avatar, badges[tab] ?: 0, labels, wide = false, onClick = {
                        onSelect(tab)
                    }, modifier = Modifier.weight(1f), spot = Modifier.inkSpot(marker, at))
                }
            }
        }
    }
}
