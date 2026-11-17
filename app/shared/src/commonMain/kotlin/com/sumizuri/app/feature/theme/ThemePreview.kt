package com.sumizuri.app.feature.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CollectionsBookmark
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.navigation.bar.NavLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_sample_button
import com.sumizuri.app.shared.resources.editor_sample_chip
import com.sumizuri.app.shared.resources.editor_sample_dialog
import com.sumizuri.app.shared.resources.editor_sample_dialog_text
import com.sumizuri.app.shared.resources.editor_sample_row
import com.sumizuri.app.shared.resources.editor_sample_row_hint
import com.sumizuri.app.shared.resources.editor_sample_switch
import com.sumizuri.app.shared.resources.editor_sample_tab_a
import com.sumizuri.app.shared.resources.editor_sample_tab_b
import com.sumizuri.app.shared.resources.editor_sample_tab_c
import com.sumizuri.app.shared.resources.editor_sample_title
import com.sumizuri.app.shared.resources.nav_browse
import com.sumizuri.app.shared.resources.nav_history
import com.sumizuri.app.shared.resources.nav_library
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.card.ListChevron
import com.sumizuri.app.ui.kit.chips.FilterTabs
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.ReadProgress
import com.sumizuri.app.ui.kit.cover.badge.UnreadBadge
import com.sumizuri.app.ui.kit.input.AppSwitch
import com.sumizuri.app.ui.theme.LocalThemeSpec
import com.sumizuri.app.ui.theme.SumizuriTheme
import com.sumizuri.app.ui.theme.ThemeMode
import com.sumizuri.app.ui.theme.background.ambientBackground
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import org.jetbrains.compose.resources.stringResource

// Titles made up for the preview of an empty library, with some read and some unread. A phone shows the first three and a desktop as many as its rows of covers hold.
private val Samples = listOf(
    Title(1, "Moonlit Garden", Kind.Manga, null, 3, Status.Ongoing, "", inLibrary = true, chapterCount = 20),
    Title(2, "Paper Lanterns", Kind.Manga, null, 8, Status.Ongoing, "", inLibrary = true, chapterCount = 24),
    Title(3, "The Quiet Tide", Kind.Manga, null, 0, Status.Completed, "", inLibrary = true, chapterCount = 12),
    Title(4, "Ink and Ember", Kind.Manga, null, 5, Status.Ongoing, "", inLibrary = true, chapterCount = 30),
    Title(5, "Northern Letters", Kind.Novel, null, 1, Status.Ongoing, "", inLibrary = true, chapterCount = 9),
    Title(6, "Salt Road", Kind.Manga, null, 0, Status.Completed, "", inLibrary = true, chapterCount = 16),
    Title(7, "Glass Orchard", Kind.Manga, null, 2, Status.Ongoing, "", inLibrary = true, chapterCount = 40),
    Title(8, "The Last Ferry", Kind.Manga, null, 0, Status.Completed, "", inLibrary = true, chapterCount = 10),
    Title(9, "Cloud Archive", Kind.Novel, null, 12, Status.Ongoing, "", inLibrary = true, chapterCount = 60),
    Title(10, "Winter Station", Kind.Manga, null, 4, Status.Ongoing, "", inLibrary = true, chapterCount = 22),
    Title(11, "Hollow Bell", Kind.Manga, null, 0, Status.Ongoing, "", inLibrary = true, chapterCount = 35),
    Title(12, "Copper Kites", Kind.Manga, null, 7, Status.Ongoing, "", inLibrary = true, chapterCount = 18),
    Title(13, "River of Pages", Kind.Novel, null, 0, Status.Completed, "", inLibrary = true, chapterCount = 14),
    Title(14, "Small Hours", Kind.Manga, null, 1, Status.Ongoing, "", inLibrary = true, chapterCount = 8),
    Title(15, "Fox and Lantern", Kind.Manga, null, 9, Status.Ongoing, "", inLibrary = true, chapterCount = 27),
    Title(16, "Blue Harbor", Kind.Manga, null, 0, Status.Completed, "", inLibrary = true, chapterCount = 50),
)

// The narrowest a cover gets in the desktop preview, which sets how many fit across, and about how tall the rest of that page is.
private val DesktopCoverWidth = 140.dp
private val DesktopFixedHeight = 340.dp

// How wide the column of tabs down the side of the desktop preview is, as in the app.
private val RailWidth = 84.dp

// A page of the app drawn in a theme, with a piece of each part of the app on it, for the editor to show, laid out as on a phone or as in a desktop window. Every piece is marked as a part, so a tap on it selects that part, and none of them takes a touch of its own.
@Composable
internal fun ThemePreview(
    spec: AppThemeSpec,
    dark: Boolean,
    desktop: Boolean,
    modifier: Modifier = Modifier,
    height: Dp = 0.dp,
    titles: List<Title> = emptyList(),
) {
    // The titles of the library when it has any, so the preview looks like the app as it is.
    val shown = titles.ifEmpty { Samples }
    SumizuriTheme(if (dark) ThemeMode.Dark else ThemeMode.Light, spec, fade = false) {
        if (desktop) {
            DesktopPage(
                modifier.heightIn(min = height),
                height,
                shown,
            )
        } else {
            PhonePage(modifier.heightIn(min = height), shown)
        }
    }
}

// The page as a phone has it: one column, with the floating bar at the bottom.
@Composable
private fun PhonePage(modifier: Modifier, titles: List<Title>) {
    Column(
        modifier.ambientBackground().editTarget(EditorPart.App).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Heading()
        Tabs()
        Covers(titles.take(3), 3)
        Row(Modifier.editTarget(EditorPart.Cards), verticalAlignment = Alignment.CenterVertically) { Sample() }
        Buttons()
        Controls()
        DialogSample()
        NavSample()
    }
}

// The page as a desktop window has it: the tabs in a column down the side, a grid of covers with as many across and down as the window has room for, and the rows and controls beside a dialog.
@Composable
private fun DesktopPage(modifier: Modifier, height: Dp, titles: List<Title>) {
    val rail = MaterialTheme.colorScheme.surfaceContainer
    val aspect = LocalThemeSpec.current.options.covers.aspect.ratio
    // The column of tabs is painted behind the row, so it reaches the bottom of the page however tall the page is.
    Row(
        modifier.ambientBackground().editTarget(EditorPart.App).drawBehind {
            drawRect(rail, size = Size(RailWidth.toPx(), size.height))
        },
    ) {
        Column(
            Modifier.width(RailWidth).padding(vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            NavSampleItem(Icons.Outlined.CollectionsBookmark, stringResource(Res.string.nav_library), true)
            NavSampleItem(Icons.Outlined.History, stringResource(Res.string.nav_history), false)
            NavSampleItem(Icons.Outlined.Explore, stringResource(Res.string.nav_browse), false)
        }
        BoxWithConstraints(Modifier.weight(1f).padding(20.dp)) {
            val across = (maxWidth / DesktopCoverWidth).toInt().coerceIn(4, 8)
            val coverHeight = (maxWidth - 12.dp * (across - 1)) / across / aspect + 40.dp
            // The rows of covers fill what the heading, the tabs and the pieces under them leave, from one row to three.
            val down = ((height - DesktopFixedHeight) / coverHeight).toInt().coerceIn(1, 3)
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Heading()
                Tabs()
                for (row in titles.take(across * down).chunked(across)) Covers(row, across)
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                        Row(
                            Modifier.editTarget(EditorPart.Cards),
                            verticalAlignment = Alignment.CenterVertically,
                        ) { Sample() }
                        Buttons()
                        Controls()
                    }
                    Box(Modifier.weight(1f)) { DialogSample() }
                }
            }
        }
    }
}

@Composable
private fun Heading() {
    Text(
        stringResource(Res.string.editor_sample_title),
        Modifier.editTarget(EditorPart.Text),
        style = MaterialTheme.typography.headlineSmall,
        fontWeight = FontWeight.Bold,
    )
}

// A row of covers, each read as far as its title says, with empty room kept for missing ones so a short row does not stretch. One that is read to the end has no bar.
@Composable
private fun Covers(titles: List<Title>, slots: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        for (title in titles) {
            val done = if (title.chapterCount >
                0
            ) {
                (title.chapterCount - title.unread).toFloat() / title.chapterCount
            } else {
                0f
            }
            Cover(title, done.coerceIn(0f, 1f), Modifier.weight(1f))
        }
        repeat(slots - titles.size) { Spacer(Modifier.weight(1f)) }
    }
}

@Composable
private fun Tabs() {
    FilterTabs(
        listOf(
            0 to stringResource(Res.string.editor_sample_tab_a),
            1 to stringResource(Res.string.editor_sample_tab_b),
            2 to stringResource(Res.string.editor_sample_tab_c),
        ),
        1,
        {},
        Modifier,
        enabled = false,
    )
}

@Composable
private fun Cover(title: Title, done: Float, modifier: Modifier) {
    val lines = LocalThemeSpec.current.options.covers.titleLines
    Column(modifier, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Box(Modifier.editTarget(EditorPart.Cover)) {
            CoverArt(title)
            if (title.unread > 0) UnreadBadge(title.unread, Modifier.align(Alignment.TopEnd).padding(6.dp))
            ReadProgress(done, Modifier.align(Alignment.BottomCenter))
        }
        Text(title.name, style = MaterialTheme.typography.bodySmall, maxLines = lines, overflow = TextOverflow.Ellipsis)
    }
}

// One list row as the settings have them, with the tile and the arrow the theme asks for.
@Composable
private fun Sample() {
    val colors = MaterialTheme.colorScheme
    val spec = LocalThemeSpec.current
    AppListRow(
        stringResource(Res.string.editor_sample_row),
        subtitle = stringResource(Res.string.editor_sample_row_hint),
        leading = {
            if (spec.options.components.listIconTiles) {
                val shape = spec.shapes.iconTile.toShape()
                Box(
                    Modifier
                        .size(
                            40.dp,
                        ).background(
                            colors.surfaceContainerHighest,
                            shape,
                        ).border(spec.shapes.borderWidth.dp, colors.outlineVariant, shape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Outlined.Palette, null, Modifier.size(19.dp), tint = colors.onSurfaceVariant)
                }
            } else {
                Icon(Icons.Outlined.Palette, null, tint = colors.onSurfaceVariant)
            }
        },
        trailing = if (spec.options.components.listChevron) ({ ListChevron(colors.outline) }) else null,
    )
}

@Composable
private fun Buttons() {
    val spec = LocalThemeSpec.current
    Row(
        Modifier.editTarget(EditorPart.Buttons),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primary) {
            Text(
                stringResource(Res.string.editor_sample_button),
                Modifier.padding(horizontal = 18.dp, vertical = 10.dp),
                color = MaterialTheme.colorScheme.onPrimary,
                style = MaterialTheme.typography.labelLarge,
            )
        }
        Surface(shape = spec.shapes.chip.toShape(), color = MaterialTheme.colorScheme.secondaryContainer) {
            Text(
                stringResource(Res.string.editor_sample_chip),
                Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                color = MaterialTheme.colorScheme.onSecondaryContainer,
                style = MaterialTheme.typography.labelLarge,
            )
        }
    }
}

@Composable
private fun Controls() {
    val colors = MaterialTheme.colorScheme
    Row(
        Modifier.editTarget(EditorPart.Controls).fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            stringResource(Res.string.editor_sample_switch),
            Modifier.weight(1f),
            style = MaterialTheme.typography.bodyMedium,
        )
        AppSwitch(true, null)
        // A slider drawn by hand, since a real one would take the touches.
        Box(Modifier.widthIn(max = 90.dp).weight(0.6f).height(20.dp), contentAlignment = Alignment.CenterStart) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .clip(CircleShape)
                    .background(colors.surfaceContainerHighest),
            )
            Box(
                Modifier
                    .fillMaxWidth(0.6f)
                    .height(4.dp)
                    .clip(CircleShape)
                    .background(colors.primary),
            )
        }
    }
}

@Composable
private fun DialogSample() {
    val spec = LocalThemeSpec.current
    Surface(
        Modifier.editTarget(EditorPart.Popups).fillMaxWidth(),
        shape = spec.shapes.dialog.toShape(),
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
        shadowElevation = 4.dp,
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(stringResource(Res.string.editor_sample_dialog), style = MaterialTheme.typography.titleMedium)
            Text(
                stringResource(Res.string.editor_sample_dialog_text),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

// The floating bar at the bottom of the app, in the corners of the theme.
@Composable
private fun NavSample() {
    val colors = MaterialTheme.colorScheme
    val shape = LocalThemeSpec.current.shapes.navBar
        .toShape()
    Row(
        Modifier
            .editTarget(EditorPart.Navigation)
            .fillMaxWidth()
            .padding(horizontal = 8.dp)
            .shadow(6.dp, shape)
            .clip(shape)
            .background(colors.surfaceContainerHigh)
            .border(0.8.dp, colors.outlineVariant.copy(alpha = 0.35f), shape)
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
    ) {
        NavSampleItem(Icons.Outlined.CollectionsBookmark, stringResource(Res.string.nav_library), true)
        NavSampleItem(Icons.Outlined.History, stringResource(Res.string.nav_history), false)
        NavSampleItem(Icons.Outlined.Explore, stringResource(Res.string.nav_browse), false)
    }
}

@Composable
private fun NavSampleItem(icon: ImageVector, label: String, chosen: Boolean) {
    val colors = MaterialTheme.colorScheme
    // As on the real bar, the chosen tab takes the accent colour, with a small bar under its name.
    val tint = if (chosen) colors.primary else colors.onSurfaceVariant
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Box(Modifier.padding(horizontal = 18.dp, vertical = 4.dp)) {
            Icon(icon, null, tint = tint)
        }
        NavLabel(label, chosen, tint)
    }
}
