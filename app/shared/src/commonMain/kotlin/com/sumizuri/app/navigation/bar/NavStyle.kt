package com.sumizuri.app.navigation.bar

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.nav_labels_always
import com.sumizuri.app.shared.resources.nav_labels_never
import com.sumizuri.app.shared.resources.nav_labels_selected
import com.sumizuri.app.shared.resources.nav_style_auto
import com.sumizuri.app.shared.resources.nav_style_bar
import com.sumizuri.app.shared.resources.nav_style_drawer
import com.sumizuri.app.shared.resources.nav_style_island
import com.sumizuri.app.shared.resources.nav_style_rail
import org.jetbrains.compose.resources.StringResource

// Where the tabs are: floating over the bottom, along the bottom edge, in a rail down the side, in a wide panel down the side, or by the width of the window.
enum class NavStyle(val label: StringResource) {
    Auto(Res.string.nav_style_auto),
    Island(Res.string.nav_style_island),
    Bar(Res.string.nav_style_bar),
    Rail(Res.string.nav_style_rail),
    Drawer(Res.string.nav_style_drawer),
}

// When the name of a tab is shown under its icon, for the bottom bar and the rail.
enum class NavLabels(val label: StringResource) {
    Always(Res.string.nav_labels_always),
    Selected(Res.string.nav_labels_selected),
    Never(Res.string.nav_labels_never),
}

// The name and the picture of the open profile, which the tab of the profile shows in place of its icon.
data class NavAvatar(val name: String, val avatar: String?)

// The sizes of the floating bar: how tall its icons are, the room around them, the space under it and how far it reaches up from the bottom edge, which the pages under it leave free.
internal object IslandMetrics {
    val SlotHeight = 44.dp
    val Padding = 5.dp
    val Margin = 16.dp
    val MaxSlot = 52.dp
    val MinSlot = 36.dp
    val Reach = Margin + SlotHeight + Padding * 2 + 8.dp
}

// The faint line down the right edge of the tabs at the side, which sets them apart from the page without a panel.
@Composable
internal fun Modifier.sideEdge(): Modifier {
    val line = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
    return drawBehind {
        drawLine(line, Offset(size.width - 0.5f, 0f), Offset(size.width - 0.5f, size.height), strokeWidth = 1f)
    }
}
