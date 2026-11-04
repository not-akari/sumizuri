package com.sumizuri.app.feature.settings.look

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.AddToHomeScreen
import androidx.compose.material.icons.outlined.Restore
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.AppIcon
import com.sumizuri.app.data.AppIconShown
import com.sumizuri.app.data.AppIcons
import com.sumizuri.app.data.IconBack
import com.sumizuri.app.data.IconBook
import com.sumizuri.app.data.IconDesign
import com.sumizuri.app.data.IconPart
import com.sumizuri.app.data.IconRing
import com.sumizuri.app.data.appIconsShown
import com.sumizuri.app.feature.theme.panel.ColorPicker
import com.sumizuri.app.feature.theme.panel.hexOf
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.allStringResources
import com.sumizuri.app.shared.resources.app_icon
import com.sumizuri.app.shared.resources.app_icon_hint
import com.sumizuri.app.shared.resources.app_icon_hint_window
import com.sumizuri.app.shared.resources.app_icon_no_ring
import com.sumizuri.app.shared.resources.app_icon_pin
import com.sumizuri.app.shared.resources.app_icon_start
import com.sumizuri.app.shared.resources.app_icon_usual
import com.sumizuri.app.shared.resources.editor_color_reset
import com.sumizuri.app.ui.kit.art.AppIconTile
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.appName
import com.sumizuri.app.ui.theme.spec.toLong
import org.jetbrains.compose.resources.stringResource

// From this width the parts sit in a list beside the picker, and below it they wrap above the picker.
private val WideFrom = 560.dp

// The width of the list of parts beside the picker.
private val PartListWidth = 230.dp

// A few built-in icons to start from, the usual one first.
private val Starts = listOf(
    AppIcon.Usual,
    AppIcon(IconBack.Paper, IconBook.Classic, IconRing.Cream),
    AppIcon(IconBack.Sakura, IconBook.Classic, IconRing.Cream),
    AppIcon(IconBack.Indigo, IconBook.Classic, IconRing.Cream),
    AppIcon(IconBack.Matcha, IconBook.Classic, IconRing.Cream),
    AppIcon(IconBack.Night, IconBook.Moon, IconRing.Gold),
    AppIcon(IconBack.Ink, IconBook.Gold, IconRing.Gold),
    AppIcon(IconBack.Ink, IconBook.Mono, IconRing.White),
    AppIcon(IconBack.Paper, IconBook.Mono, IconRing.None),
    AppIcon(IconBack.Indigo, IconBook.Moon, IconRing.Cream),
).map { IconDesign.of(it) }

// The icon made like a theme: the icon with its buttons, a row of icons to start from, then the parts with one picker for the part picked. Dragging shows the color on the icon at once, and letting go keeps it. On a phone the launcher shows the closest built-in icon and the exact one can go on the home screen. On a computer it is the icon of the window, the taskbar and the dock.
@Composable
internal fun AppIconSection() {
    if (!appIconsShown || !AppIcons.supported) return
    val design = AppIconShown.now()
    var trying by remember { mutableStateOf<IconDesign?>(null) }
    var picked by rememberSaveable { mutableStateOf(IconPart.Back) }
    val shown = trying ?: design
    val hint = if (AppIcons.launcher) Res.string.app_icon_hint else Res.string.app_icon_hint_window
    SettingsSection(Res.string.app_icon, hint) {
        padded { IconHead(shown, design) }
        padded {
            StartRow(shown) {
                trying = null
                AppIconShown.pick(it)
            }
        }
        padded {
            BoxWithConstraints(Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
                val picker: @Composable () -> Unit = {
                    PartPicker(design, picked, onTry = { trying = it }) {
                        trying = null
                        AppIconShown.pick(it)
                    }
                }
                if (maxWidth >= WideFrom) {
                    Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        Column(Modifier.width(PartListWidth), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            for (part in IconPart.entries) PartLine(part, shown, part == picked) { picked = part }
                        }
                        Box(Modifier.weight(1f)) { picker() }
                    }
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        PartChips(shown, picked) { picked = it }
                        picker()
                    }
                }
            }
        }
    }
}

// The icon as it is now, with the way back to the usual one and, where the system allows, the way onto the home screen.
@Composable
private fun IconHead(shown: IconDesign, design: IconDesign) {
    val label = appName()
    Row(
        Modifier.padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        IconPreview(shown, 96.dp)
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            InkOutlinedButton({ AppIconShown.pick(IconDesign.Usual) }) {
                Icon(Icons.Outlined.Restore, null, Modifier.size(18.dp))
                Text(stringResource(Res.string.app_icon_usual), Modifier.padding(start = 8.dp))
            }
            if (AppIcons.canPin) {
                InkOutlinedButton({ AppIcons.pin(design, label) }) {
                    Icon(Icons.AutoMirrored.Outlined.AddToHomeScreen, null, Modifier.size(18.dp))
                    Text(stringResource(Res.string.app_icon_pin), Modifier.padding(start = 8.dp))
                }
            }
        }
    }
}

// The icon on its tile, rounded the way a launcher rounds it.
@Composable
private fun IconPreview(design: IconDesign, size: Dp, modifier: Modifier = Modifier) {
    AppIconTile(design, RoundedCornerShape(size * 0.3f), modifier.size(size))
}

// Built-in icons to start from, in a row that scrolls, the one in use ringed.
@Composable
private fun StartRow(shown: IconDesign, onPick: (IconDesign) -> Unit) {
    val colors = MaterialTheme.colorScheme
    Column(Modifier.padding(vertical = 6.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            stringResource(Res.string.app_icon_start),
            style = MaterialTheme.typography.labelLarge,
            color = colors.outline,
        )
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            for (start in Starts) {
                val ring by animateColorAsState(if (start == shown) colors.primary else Color.Transparent)
                IconPreview(
                    start,
                    44.dp,
                    Modifier
                        .border(2.dp, ring, RoundedCornerShape(16.dp))
                        .padding(4.dp)
                        .clip(RoundedCornerShape(13.dp))
                        .clickable { onPick(start) },
                )
            }
        }
    }
}

// One picker for the part picked. Its marks start again on the color of each part.
@Composable
private fun PartPicker(design: IconDesign, part: IconPart, onTry: (IconDesign) -> Unit, onPick: (IconDesign) -> Unit) {
    key(part) {
        ColorPicker(
            Color(design.color(part)),
            onTry = { onTry(design.with(part, it.toLong())) },
            onPick = { onPick(design.with(part, it.toLong())) },
            onUsual = { onPick(design.with(part, null)) },
            usualLabel = if (part == IconPart.Ring) Res.string.app_icon_no_ring else Res.string.editor_color_reset,
        )
    }
}

// A part in the list beside the picker: its swatch, its name and its color, filled in when picked.
@Composable
private fun PartLine(part: IconPart, design: IconDesign, picked: Boolean, onClick: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val back by animateColorAsState(if (picked) colors.primary.copy(alpha = 0.14f) else Color.Transparent)
    Row(
        Modifier
            .fillMaxWidth()
            .clip(MaterialTheme.shapes.medium)
            .background(back)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Swatch(part, design, 22.dp)
        Text(
            partName(part),
            Modifier.weight(1f),
            style = MaterialTheme.typography.bodyMedium,
            color = if (picked) colors.onSurface else colors.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(colorText(part, design), style = MaterialTheme.typography.labelSmall, color = colors.outline)
    }
}

// The parts as small chips that wrap, for a narrow screen.
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun PartChips(design: IconDesign, picked: IconPart, onPick: (IconPart) -> Unit) {
    val colors = MaterialTheme.colorScheme
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for (part in IconPart.entries) {
            val on = part == picked
            val edge by animateColorAsState(if (on) colors.primary else colors.outlineVariant)
            val back by animateColorAsState(if (on) colors.primary.copy(alpha = 0.14f) else Color.Transparent)
            Row(
                Modifier
                    .clip(CircleShape)
                    .background(back)
                    .border(1.dp, edge, CircleShape)
                    .clickable { onPick(part) }
                    .padding(start = 6.dp, end = 12.dp, top = 6.dp, bottom = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Swatch(part, design, 18.dp)
                Text(partName(part), style = MaterialTheme.typography.labelLarge)
            }
        }
    }
}

// A round swatch of the color of a part, left empty for a ring that is off.
@Composable
private fun Swatch(part: IconPart, design: IconDesign, size: Dp) {
    val off = part == IconPart.Ring && !design.ring
    Box(
        Modifier
            .size(size)
            .clip(CircleShape)
            .background(if (off) Color.Transparent else Color(design.color(part)))
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, CircleShape),
    )
}

@Composable
private fun partName(part: IconPart): String =
    stringResource(Res.allStringResources.getValue("app_icon_part_${part.name.lowercase()}"))

@Composable
private fun colorText(part: IconPart, design: IconDesign): String = if (part == IconPart.Ring && !design.ring) {
    stringResource(Res.string.app_icon_no_ring)
} else {
    "#" + hexOf(Color(design.color(part)))
}
