package com.sumizuri.app.feature.browse.hub

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Code
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.PowerSettingsNew
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.local.LocalSources
import com.sumizuri.app.data.net.siteNameOf
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.browse_badge_old
import com.sumizuri.app.shared.resources.browse_badge_update
import com.sumizuri.app.shared.resources.browse_pin
import com.sumizuri.app.shared.resources.browse_pinned
import com.sumizuri.app.shared.resources.browse_turn_off
import com.sumizuri.app.shared.resources.browse_turn_on
import com.sumizuri.app.shared.resources.browse_unpin
import com.sumizuri.app.shared.resources.ext_edit_open_code
import com.sumizuri.app.shared.resources.local_on_device
import com.sumizuri.app.shared.resources.more
import com.sumizuri.app.shared.resources.source_remove_menu
import com.sumizuri.app.shared.resources.title_action_web
import com.sumizuri.app.source.repo.EngineKind
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.ui.kit.card.softPress
import com.sumizuri.app.ui.kit.cover.SourceMark
import com.sumizuri.app.ui.kit.cover.shownName
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import com.sumizuri.app.ui.text.languageName
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// A shortcut in the row of pinned and lately used sources is this wide.
private val JumpWidth = 76.dp

// One source: its icon, its name with a pin when it is pinned, the language under it when its group mixes languages and its site otherwise, marks for an update or the old format, and a menu. A source that is turned off is faded, and a tap turns it on.
@Composable
internal fun SourceTile(
    source: InstalledSource,
    pinned: Boolean,
    update: Boolean,
    showLanguage: Boolean,
    actions: BrowseHubActions,
    modifier: Modifier,
) {
    val off = !source.enabled
    val old = source.engineKind == EngineKind.Old
    Row(
        modifier
            .alpha(if (off) 0.6f else 1f)
            .softPress({ if (off) actions.onEnabled(source, true) else actions.onOpenSource(source) })
            .padding(start = 12.dp, top = 10.dp, bottom = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SourceMark(source.iconUrl, size = 40.dp, sourceId = source.id)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(
                    source.shownName(),
                    Modifier.weight(1f, fill = false),
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (pinned) {
                    Icon(
                        Icons.Outlined.PushPin,
                        stringResource(Res.string.browse_pinned),
                        Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.primary,
                    )
                }
            }
            val under = when {
                off -> stringResource(Res.string.browse_turn_on)
                LocalSources.isLocal(source.id) -> stringResource(Res.string.local_on_device)
                showLanguage -> languageName(source.lang)
                else -> siteNameOf(source.baseUrl)
            }
            // A source with no site, such as one made by hand, keeps its name in the middle.
            if (under.isNotBlank()) {
                Text(
                    under,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            if (update || old) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.padding(top = 2.dp)) {
                    if (update) Mark(Res.string.browse_badge_update, MaterialTheme.colorScheme.primary)
                    if (old) Mark(Res.string.browse_badge_old, MaterialTheme.colorScheme.error)
                }
            }
        }
        SourceMenu(source, pinned, actions)
    }
}

// A small word on a tinted pill.
@Composable
private fun Mark(text: StringResource, color: Color) {
    Text(
        stringResource(text),
        Modifier
            .background(
                color.copy(alpha = 0.16f),
                RoundedCornerShape(50),
            ).padding(horizontal = 7.dp, vertical = 1.dp),
        style = MaterialTheme.typography.labelSmall,
        color = color,
        fontWeight = FontWeight.SemiBold,
    )
}

// What can be done with a source: pin it, turn it off or on, open its site, open its code, and remove it. The sources for the files on the device are part of the app, so they keep only the pin.
@Composable
private fun SourceMenu(source: InstalledSource, pinned: Boolean, actions: BrowseHubActions) {
    var open by remember { mutableStateOf(false) }
    val openSite = LocalOpenSite.current
    val local = LocalSources.isLocal(source.id)
    Box {
        IconButton({
            open = true
        }) { Icon(Icons.Outlined.MoreVert, stringResource(Res.string.more), tint = MaterialTheme.colorScheme.outline) }
        AppMenu(open, { open = false }) {
            MenuItem(if (pinned) Res.string.browse_unpin else Res.string.browse_pin, Icons.Outlined.PushPin) {
                open = false
                actions.onPin(source)
            }
            if (!local) {
                MenuItem(
                    if (source.enabled) Res.string.browse_turn_off else Res.string.browse_turn_on,
                    Icons.Outlined.PowerSettingsNew,
                ) {
                    open = false
                    actions.onEnabled(source, !source.enabled)
                }
                if (source.baseUrl.isNotBlank()) {
                    MenuItem(Res.string.title_action_web, Icons.Outlined.Public) {
                        open = false
                        openSite(source.baseUrl)
                    }
                }
                MenuItem(Res.string.ext_edit_open_code, Icons.Outlined.Code) {
                    open = false
                    actions.onEditCode(source)
                }
                MenuItem(Res.string.source_remove_menu, Icons.Outlined.DeleteOutline, MaterialTheme.colorScheme.error) {
                    open = false
                    actions.onRemove(source)
                }
            }
        }
    }
}

@Composable
private fun MenuItem(label: StringResource, icon: ImageVector, color: Color = Color.Unspecified, onClick: () -> Unit) {
    AppMenuItem(
        text = { Text(stringResource(label), color = color) },
        leadingIcon = {
            Icon(
                icon,
                null,
                Modifier.size(20.dp),
                tint = if (color ==
                    Color.Unspecified
                ) {
                    MaterialTheme.colorScheme.onSurfaceVariant
                } else {
                    color
                },
            )
        },
        onClick = onClick,
    )
}

// The pinned sources, then the ones used lately, as icons with their names in one sideways row.
@Composable
internal fun JumpRow(sources: List<InstalledSource>, pinned: Set<String>, onOpen: (InstalledSource) -> Unit) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        items(sources, key = { it.id }) { source ->
            Column(
                Modifier
                    .animateItem()
                    .width(JumpWidth)
                    .clip(RoundedCornerShape(16.dp))
                    .clickable { onOpen(source) }
                    .padding(vertical = 6.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Box {
                    SourceMark(source.iconUrl, size = 52.dp, sourceId = source.id)
                    if (source.id in pinned) {
                        Icon(
                            Icons.Outlined.PushPin,
                            null,
                            Modifier
                                .align(Alignment.TopEnd)
                                .size(18.dp)
                                .background(MaterialTheme.colorScheme.primaryContainer, RoundedCornerShape(50))
                                .padding(3.dp),
                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                        )
                    }
                }
                Text(
                    source.shownName(),
                    style = MaterialTheme.typography.labelMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

// The site a source reads from, as a person would say it.
