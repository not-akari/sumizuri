package com.sumizuri.app.feature.title.info

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Comment
import androidx.compose.material.icons.filled.LibraryAddCheck
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.CenterFocusStrong
import androidx.compose.material.icons.outlined.LibraryAdd
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.layout.TileHeight
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.comments_title
import com.sumizuri.app.shared.resources.more
import com.sumizuri.app.shared.resources.title_action_background
import com.sumizuri.app.shared.resources.title_action_move
import com.sumizuri.app.shared.resources.title_action_web
import com.sumizuri.app.shared.resources.title_add
import com.sumizuri.app.shared.resources.title_favorite
import com.sumizuri.app.shared.resources.title_in_library
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import org.jetbrains.compose.resources.stringResource

// How wide the square button of the menu is.
private val MoreWidth = 56.dp

// The row of slim buttons under the continue button, each a small icon beside a word: the library, the favorite star when there is one, the comments when the source has them, and a menu for the rest, which are the page of the title on its site, moving it to another source and choosing what the backdrop centres on.
@Composable
internal fun PosterActions(
    state: TitleState,
    title: Title,
    calls: TitleCallbacks,
    onBackground: () -> Unit,
    modifier: Modifier = Modifier,
    fixedHeight: Boolean = false,
) {
    val uri = LocalUriHandler.current
    val openSite = LocalOpenSite.current
    val web = title.webUrl?.takeIf { it.isNotBlank() }
    val saved = title.inLibrary && !state.preview
    // A title that cannot be reached has a button for moving it of its own.
    val move = !state.preview && state.readable
    val background = !state.preview && !title.coverUrl.isNullOrBlank()
    // A title seen from a source is only read once it is saved, so saving it is the main button there.
    if (state.preview && !title.inLibrary) {
        Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            InkButton(calls.onToggleLibrary, Modifier.weight(1f).height(40.dp), enabled = !state.loading) {
                Icon(Icons.Outlined.LibraryAdd, null, Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text(stringResource(Res.string.title_add))
            }
            // The comments can be read before the title is saved.
            state.comments?.let { target ->
                FilledTonalIconButton({ calls.onComments(target) }, Modifier.size(40.dp)) {
                    Icon(Icons.AutoMirrored.Outlined.Comment, stringResource(Res.string.comments_title))
                }
            }
        }
        return
    }
    Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        val each = Modifier.weight(1f)
        val tile = if (fixedHeight) Modifier.height(TileHeight) else Modifier
        // The library has an icon of its own, so the heart is not mistaken for the favourite, which is the star everywhere.
        PosterAction(
            icon = if (saved) Icons.Filled.LibraryAddCheck else Icons.Outlined.LibraryAdd,
            label = stringResource(if (saved) Res.string.title_in_library else Res.string.title_add),
            onClick = calls.onToggleLibrary,
            modifier = each.then(tile),
            active = saved,
            enabled = saved || !state.loading || !state.preview,
        )
        if (saved && state.favoritesEnabled) {
            PosterAction(
                icon = if (title.favorite) Icons.Filled.Star else Icons.Outlined.StarBorder,
                label = stringResource(Res.string.title_favorite),
                onClick = calls.onToggleFavorite,
                modifier = each.then(tile),
                active = title.favorite,
            )
        }
        state.comments?.let { target ->
            PosterAction(Icons.AutoMirrored.Outlined.Comment, stringResource(Res.string.comments_title), {
                calls.onComments(target)
            }, each.then(tile))
        }
        if (web != null || move || background) {
            var open by remember { mutableStateOf(false) }
            // The menu opens under its tile, so the two are in one box. It is a square with only its icon, so the library and the other buttons get the room.
            Box {
                PosterAction(Icons.Outlined.MoreHoriz, stringResource(Res.string.more), {
                    open = true
                }, Modifier.width(MoreWidth).then(tile), iconOnly = true)
                DropdownMenu(open, { open = false }) {
                    if (web != null) {
                        DropdownMenuItem({ Text(stringResource(Res.string.title_action_web)) }, {
                            open = false
                            openSite(web)
                        }, leadingIcon = { Icon(Icons.Outlined.Public, null) })
                    }
                    if (move) {
                        DropdownMenuItem({ Text(stringResource(Res.string.title_action_move)) }, {
                            open = false
                            calls.onMigrate()
                        }, leadingIcon = { Icon(Icons.Outlined.SwapHoriz, null) })
                    }
                    if (background) {
                        DropdownMenuItem({ Text(stringResource(Res.string.title_action_background)) }, {
                            open = false
                            onBackground()
                        }, leadingIcon = { Icon(Icons.Outlined.CenterFocusStrong, null) })
                    }
                }
            }
        }
    }
}

// One slim button: a small icon beside a short word on a soft card. An active one is tinted.
@Composable
private fun PosterAction(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    active: Boolean = false,
    enabled: Boolean = true,
    iconOnly: Boolean = false,
) {
    val colors = MaterialTheme.colorScheme
    Surface(
        onClick,
        modifier.heightIn(min = 40.dp),
        enabled = enabled,
        shape = MaterialTheme.shapes.small,
        color = if (active) colors.primary.copy(alpha = 0.14f) else colors.surfaceContainerHighest,
    ) {
        Row(
            Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            Icon(icon, label.takeIf { iconOnly }, Modifier.size(18.dp), tint = colors.primary)
            if (iconOnly) return@Row
            Spacer(Modifier.width(6.dp))
            Text(
                label,
                style = MaterialTheme.typography.labelLarge,
                color = if (active) colors.primary else colors.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
            )
        }
    }
}
