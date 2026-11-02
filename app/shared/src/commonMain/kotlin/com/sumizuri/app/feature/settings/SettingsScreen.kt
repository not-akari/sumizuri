package com.sumizuri.app.feature.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.settings_new
import com.sumizuri.app.shared.resources.settings_no_match
import com.sumizuri.app.shared.resources.settings_search_hint
import com.sumizuri.app.shared.resources.settings_title
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.page.pageScroll
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.theme.LocalThemeSpec
import org.jetbrains.compose.resources.stringResource

// The width of the list when a page is open beside it.
private val ListWidth = 380.dp

// The home of the settings: a search, then every page in groups, each with an icon and what it is set to now. Typing in the search turns the list into the pages and the single settings that match, and each opens its page. On a wide window the page that is open stands beside the list, and its row is marked.
@Composable
internal fun SettingsScreen(
    pages: List<SettingsPage>,
    onBack: () -> Unit,
    selected: SettingsTarget? = null,
    pane: (@Composable () -> Unit)? = null,
) {
    var query by remember { mutableStateOf("") }
    val text = query.trim()
    val list: @Composable () -> Unit = {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(stringResource(Res.string.settings_title), onBack = onBack)
            Column(
                Modifier.weight(1f).pageScroll(keep = "settings").padding(horizontal = PageGutter, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                AppSearchBar(query, { query = it }, stringResource(Res.string.settings_search_hint))
                when {
                    text.isNotEmpty() -> Results(pages, text, selected)
                    else -> NavGroups(pages, selected, arrows = pane == null)
                }
            }
        }
    }
    if (pane == null) {
        ReadableColumn { list() }
        return
    }
    Row(Modifier.fillMaxSize()) {
        Box(Modifier.width(ListWidth).fillMaxHeight()) { list() }
        VerticalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
        Box(
            Modifier.weight(1f).fillMaxHeight(),
        ) { CompositionLocalProvider(LocalSettingsBeside provides true) { pane() } }
    }
}

// The pages whose name or note has the words, and the settings in pages whose name has them, each opening its page.
@Composable
private fun Results(pages: List<SettingsPage>, query: String, selected: SettingsTarget?) {
    class Hit(
        val icon: ImageVector,
        val title: String,
        val note: String,
        val target: SettingsTarget,
        val open: () -> Unit,
    )
    val hits = mutableListOf<Hit>()
    for (page in pages) {
        if (page.title.contains(query, ignoreCase = true) ||
            page.summary.contains(query, ignoreCase = true)
        ) {
            hits +=
                Hit(page.icon, page.title, page.summary, page.target, page.open)
        }
        for (item in page.items) {
            val title = stringResource(item)
            if (title.contains(query, ignoreCase = true)) {
                hits +=
                    Hit(page.icon, title, page.title, page.target, page.open)
            }
        }
    }
    if (hits.isNotEmpty()) {
        SettingsSection {
            for (hit in hits) {
                row {
                    PageRow(
                        hit.icon,
                        hit.title,
                        hit.note,
                        hit.open,
                        selected = hit.target == selected,
                    )
                }
            }
        }
    }
    if (hits.isEmpty()) {
        Column(
            Modifier.fillMaxWidth().padding(vertical = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(Icons.Outlined.SearchOff, null, Modifier.size(44.dp), tint = MaterialTheme.colorScheme.outline)
            Text(
                stringResource(Res.string.settings_no_match, query),
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.outline,
            )
        }
    }
}

// One line of the list: the icon tile, the name, what it is set to, and an arrow. The row of the page open beside the list is tinted. The profile lists its ways to other pages with it too.
@Composable
internal fun PageRow(
    icon: ImageVector,
    title: String,
    summary: String,
    onClick: () -> Unit,
    selected: Boolean = false,
    fresh: Boolean = false,
) {
    SettingRow(
        title,
        modifier = if (selected) {
            Modifier.background(
                MaterialTheme.colorScheme.primary.copy(alpha = 0.12f),
            )
        } else {
            Modifier
        },
        subtitle = summary,
        leading = { IconTile(icon) },
        trailing = {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (fresh) NewMark()
                if (LocalThemeSpec.current.options.components.listChevron) ListChevron()
            }
        },
        onClick = onClick,
        strong = true,
    )
}

// A small rounded square with an icon in it, as the rows of the Flutter settings have, or only the icon when the theme has no tiles.
@Composable
internal fun IconTile(icon: ImageVector) {
    val colors = MaterialTheme.colorScheme
    val theme = LocalThemeSpec.current
    if (!theme.options.components.listIconTiles) {
        Icon(icon, null, Modifier.size(24.dp), tint = colors.onSurfaceVariant)
        return
    }
    val shape = theme.shapes.iconTile.toShape()
    Box(
        Modifier
            .size(
                40.dp,
            ).background(
                colors.surfaceContainerHighest,
                shape,
            ).border(theme.shapes.borderWidth.dp, colors.outlineVariant, shape),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, null, Modifier.size(19.dp), tint = colors.onSurfaceVariant) }
}

// A small pill that says a page is new.
@Composable
private fun NewMark() {
    Text(
        stringResource(Res.string.settings_new),
        Modifier.background(MaterialTheme.colorScheme.primary, CircleShape).padding(horizontal = 8.dp, vertical = 2.dp),
        style = MaterialTheme.typography.labelSmall,
        fontWeight = FontWeight.Bold,
        color = MaterialTheme.colorScheme.onPrimary,
    )
}
