package com.sumizuri.app.feature.tv.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Insights
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.player.PlayerPrefs
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.feature.theme.rememberThemeModel
import com.sumizuri.app.feature.tv.onboarding.firstFocus
import com.sumizuri.app.feature.tv.onboarding.qualityLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.trackers_title
import com.sumizuri.app.shared.resources.tv_off
import com.sumizuri.app.shared.resources.tv_profile_all
import com.sumizuri.app.shared.resources.tv_profile_all_value
import com.sumizuri.app.shared.resources.tv_profile_look
import com.sumizuri.app.shared.resources.tv_profile_name
import com.sumizuri.app.shared.resources.tv_profile_phone
import com.sumizuri.app.shared.resources.tv_profile_phone_value
import com.sumizuri.app.shared.resources.tv_profile_sync
import com.sumizuri.app.shared.resources.tv_profile_trackers_value
import com.sumizuri.app.shared.resources.tv_profile_watching
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// A tile of the row: its icon, its name, what it is set to now, and what OK does.
private class Tile(
    val icon: ImageVector,
    val name: String,
    val value: String,
    val panel: TvPanel? = null,
    val onClick: () -> Unit,
)

// What is set from the profile of a TV as a row of square tiles, each with what it is set to now. The first takes the focus when the page opens.
@Composable
internal fun ProfileTiles(
    open: TvPanel?,
    onOpen: (TvPanel) -> Unit,
    onOpenTrackers: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    val container = LocalAppContainer.current
    val profiles = LocalProfiles.current
    val registry by profiles.state.collectAsStateWithLifecycle()
    val account by profiles.syncAccounts.account.collectAsStateWithLifecycle()
    val theme by rememberThemeModel().active.collectAsStateWithLifecycle()
    val prefs by container.playerPrefs.prefs.collectAsStateWithLifecycle(PlayerPrefs())
    val trackers by remember(container) { container.trackers.signedIn }.collectAsStateWithLifecycle(emptyMap())
    val tiles = listOf(
        Tile(Icons.Outlined.Palette, stringResource(Res.string.tv_profile_look), theme.name, TvPanel.Look) {
            onOpen(TvPanel.Look)
        },
        Tile(
            Icons.Outlined.PlayCircle,
            stringResource(Res.string.tv_profile_watching),
            stringResource(qualityLabel(prefs.qualityMode)),
            TvPanel.Watching,
        ) {
            onOpen(TvPanel.Watching)
        },
        Tile(Icons.Outlined.Edit, stringResource(Res.string.tv_profile_name), registry.active.name, TvPanel.Name) {
            onOpen(TvPanel.Name)
        },
        Tile(
            Icons.Outlined.Sync,
            stringResource(Res.string.tv_profile_sync),
            account?.username ?: stringResource(Res.string.tv_off),
            TvPanel.Sync,
        ) {
            onOpen(TvPanel.Sync)
        },
        Tile(
            Icons.Outlined.PhoneAndroid,
            stringResource(Res.string.tv_profile_phone),
            stringResource(Res.string.tv_profile_phone_value),
            TvPanel.Phone,
        ) {
            onOpen(TvPanel.Phone)
        },
        Tile(
            Icons.Outlined.Insights,
            stringResource(Res.string.trackers_title),
            pluralStringResource(Res.plurals.tv_profile_trackers_value, trackers.size, trackers.size),
            onClick = onOpenTrackers,
        ),
        Tile(
            Icons.Outlined.Settings,
            stringResource(Res.string.tv_profile_all),
            stringResource(Res.string.tv_profile_all_value),
            onClick = onOpenSettings,
        ),
    )
    val first = firstFocus()
    // The tile that opened a panel takes the focus back when the panel closes, so OK does not land on something else.
    val opener = remember { FocusRequester() }
    var opened by remember { mutableStateOf<TvPanel?>(null) }
    LaunchedEffect(open) {
        if (open != null) {
            opened = open
            return@LaunchedEffect
        }
        if (opened == null) return@LaunchedEffect
        repeat(4) {
            delay(100)
            runCatching { opener.requestFocus() }
        }
    }
    LazyRow(contentPadding = PaddingValues(horizontal = 48.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        itemsIndexed(tiles, key = { _, tile -> tile.icon.name }) { at, tile ->
            Column(
                Modifier
                    .size(width = 150.dp, height = 124.dp)
                    .then(if (at == 0) Modifier.focusRequester(first) else Modifier)
                    .then(if (tile.panel != null && tile.panel == opened) Modifier.focusRequester(opener) else Modifier)
                    .tvCard(tile.onClick, RoundedCornerShape(16.dp))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                Icon(tile.icon, null, Modifier.size(28.dp), tint = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.weight(1f))
                Text(
                    tile.name,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    tile.value,
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}
