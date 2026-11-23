package com.sumizuri.app.feature.tv.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.stats.ReadingStats
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.feature.profile.ProfileAvatar
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.tv.library.meltLeftAndDown
import com.sumizuri.app.feature.tv.library.rememberWideArt
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.profile_new
import com.sumizuri.app.shared.resources.tv_profile_fig_days
import com.sumizuri.app.shared.resources.tv_profile_fig_shows
import com.sumizuri.app.shared.resources.tv_profile_fig_streak
import com.sumizuri.app.shared.resources.tv_profile_numbered
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.focus.focusAlignment
import com.sumizuri.app.ui.kit.cover.focus.rememberCoverFocus
import com.sumizuri.app.ui.tv.hiddenUnder
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// How big the picture of the open profile is, and the pictures of the others.
private val FaceSize = 72.dp
private val SmallFace = 50.dp

// The profile on a TV, laid out like the library: the art of the show watched last melts in from the right, with the open profile, how its watching adds up and the other profiles of this TV on the left, and a row of tiles along the bottom for what is set from here. The look, how videos start, the name, sync and a phone open over the page and back closes them, and trackers and every other setting open their own pages.
@Composable
internal fun TvProfileRoute(
    onOpenTrackers: () -> Unit,
    onOpenSettings: () -> Unit,
    onOpenPage: (SettingsTarget) -> Unit,
) {
    val container = LocalAppContainer.current
    val profiles = LocalProfiles.current
    val registry by profiles.state.collectAsStateWithLifecycle()
    val reading by remember(container) { container.statistics.reading }.collectAsStateWithLifecycle(null)
    // The show watched last, for the art at the top.
    val last by remember(container) {
        container.library.history.map { items -> items.firstOrNull { it.title.kind == Kind.Anime }?.title }
    }.collectAsStateWithLifecycle(null)
    var panel by rememberSaveable { mutableStateOf<TvPanel?>(null) }
    val scope = rememberCoroutineScope()
    val newName = stringResource(Res.string.tv_profile_numbered, registry.profiles.size + 1)
    Box(Modifier.fillMaxSize()) {
        val covered = panel != null
        Box(Modifier.fillMaxSize().hiddenUnder(covered)) { last?.let { Art(it) } }
        Column(Modifier.fillMaxSize().hiddenUnder(covered).padding(top = 36.dp, bottom = 32.dp)) {
            Column(
                Modifier.padding(horizontal = 48.dp).widthIn(max = 520.dp),
                verticalArrangement = Arrangement.spacedBy(22.dp),
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(18.dp),
                ) {
                    ProfileAvatar(registry.active.name, registry.active.avatar, FaceSize)
                    Text(
                        registry.active.name,
                        fontSize = 40.sp,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                reading?.stats?.let { Figures(it) }
                // The other profiles, to switch to, and a way to add one, which opens at once and asks for its name.
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    registry.profiles.filter { it.id != registry.activeId }.forEach { profile ->
                        Face(
                            profile.name,
                            { profiles.switchTo(profile.id) },
                        ) { ProfileAvatar(profile.name, profile.avatar, SmallFace) }
                    }
                    Face(stringResource(Res.string.profile_new), {
                        scope.launch {
                            if (profiles.create(newName, null) !=
                                null
                            ) {
                                NewProfileName.ask.value = true
                            }
                        }
                    }) {
                        Icon(Icons.Outlined.Add, null, Modifier.size(26.dp), tint = MaterialTheme.colorScheme.primary)
                    }
                }
            }
            Box(Modifier.weight(1f))
            ProfileTiles(
                open = panel,
                onOpen = { panel = it },
                onOpenTrackers = onOpenTrackers,
                onOpenSettings = onOpenSettings,
            )
        }
        panel?.let { shown -> TvProfilePanel(shown, onClose = { panel = null }, onOpenPage = onOpenPage) }
    }
}

// The art of a show over the right of the page, fading out to the left and down so the words stay clear.
@Composable
private fun Art(shown: Title) {
    val title = rememberWideArt(shown)
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopEnd) {
        BoxWithConstraints(Modifier.fillMaxWidth(0.62f).fillMaxHeight(0.74f).meltLeftAndDown()) {
            val focus by rememberCoverFocus(title.coverUrl)
            CoverArt(
                title,
                Modifier.fillMaxSize(),
                letterSize = 48,
                aspect = maxWidth / maxHeight,
                alignment = focusAlignment(focus, maxWidth.value, maxHeight.value),
            )
        }
    }
}

// The shows in the library, the days something was watched and the days in a row up to now, as big numbers.
@Composable
private fun Figures(stats: ReadingStats) {
    Row(horizontalArrangement = Arrangement.spacedBy(40.dp)) {
        Figure(stats.kindCounts[Kind.Anime] ?: 0, stringResource(Res.string.tv_profile_fig_shows))
        Figure(stats.activeDays, stringResource(Res.string.tv_profile_fig_days))
        Figure(stats.currentStreak, stringResource(Res.string.tv_profile_fig_streak))
    }
}

@Composable
private fun Figure(value: Int, label: String) {
    Column {
        Text(
            value.toString(),
            fontSize = 34.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.primary,
        )
        Text(label, fontSize = 14.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

// Another profile, or the way to add one, as a small round card with its name under it.
@Composable
private fun Face(name: String, onClick: () -> Unit, face: @Composable () -> Unit) {
    Column(
        Modifier.width(SmallFace + 26.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(
            Modifier.size(SmallFace + 8.dp).tvCard(onClick, CircleShape).padding(4.dp),
            contentAlignment = Alignment.Center,
        ) { face() }
        Text(
            name,
            Modifier.fillMaxWidth(),
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
    }
}
