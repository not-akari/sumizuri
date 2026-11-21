package com.sumizuri.app.navigation.bar

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.profile.ProfileAvatar
import com.sumizuri.app.navigation.Destination
import org.jetbrains.compose.resources.stringResource

// The icon of a tab, filled when it is the chosen one, with the count of what is new on its upper corner, starting halfway across it and growing to the right. The tab of the profile shows the picture of the open profile.
@Composable
internal fun NavIcon(
    destination: Destination,
    selected: Boolean,
    avatar: NavAvatar?,
    tint: Color,
    size: Dp = 24.dp,
    badge: Int = 0,
    // The color behind the count, which rings it so it looks cut out of the icon.
    ring: Color = Color.Unspecified,
) {
    Box(Modifier.size(size), contentAlignment = Alignment.Center) {
        if (destination == Destination.Profile && avatar != null) {
            ProfileAvatar(avatar.name, avatar.avatar, size)
        } else {
            Icon(
                if (selected) destination.selectedIcon else destination.icon,
                stringResource(destination.label),
                Modifier.size(size),
                tint = tint,
            )
        }
        NavBadge(
            badge,
            Modifier
                .align(Alignment.TopStart)
                .wrapContentSize(Alignment.TopStart, unbounded = true)
                .offset(x = size * 0.5f, y = (-7).dp),
            ring,
        )
    }
}
