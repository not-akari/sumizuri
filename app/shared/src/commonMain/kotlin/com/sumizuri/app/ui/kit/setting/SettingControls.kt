package com.sumizuri.app.ui.kit.setting
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.input.InkSlider
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.theme.LocalCompactLists
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The most options that sit side by side as buttons.
private const val MostSegments = 4

// The room a choice takes around its words: their padding on both sides and its share of the track.
private val SegmentPadding = 30.dp

// The room an icon takes beside the word of a choice.
private val OptionIconSpace = 24.dp

// How far the words of a setting sit from its start when it has an icon: the icon and the gap after it.
private val IconSpace = 34.dp

// A choice of a few options whose words fit side by side shows them all as buttons under its name, so one tap picks one. Any other choice shows the one picked on a button that opens a menu of the others. The icon comes from the list of icons of the settings unless one is given.
@Composable
fun <T> ChoiceSetting(
    title: StringResource,
    options: List<T>,
    selected: T,
    label: @Composable (T) -> String,
    modifier: Modifier = Modifier,
    hint: StringResource? = null,
    icon: ImageVector? = settingIconOf(title),
    optionIcon: ((T) -> ImageVector)? = null,
    onSelect: (T) -> Unit,
) = ChoiceSetting(stringResource(title), options, selected, label, modifier, hint?.let { stringResource(it) }, icon, optionIcon, onSelect)

// The same with a name and a line that are already words, such as the choices a source gives.
@Composable
fun <T> ChoiceSetting(
    title: String,
    options: List<T>,
    selected: T,
    label: @Composable (T) -> String,
    modifier: Modifier = Modifier,
    hint: String? = null,
    icon: ImageVector? = null,
    optionIcon: ((T) -> ImageVector)? = null,
    onSelect: (T) -> Unit,
) {
    val words = options.map { label(it) }
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val measurer = rememberTextMeasurer()
        val style = MaterialTheme.typography.labelLarge
        val room = with(LocalDensity.current) { (maxWidth / options.size.coerceAtLeast(1) - SegmentPadding - if (optionIcon != null) OptionIconSpace else 0.dp).toPx() }
        // Side by side only when every option fits its share of the width on one line.
        val side = options.size in 2..MostSegments && words.all { measurer.measure(it, style, maxLines = 1).size.width <= room }
        if (side) {
            ButtonsChoice(title, options, selected, words, hint, icon, optionIcon, onSelect)
        } else {
            MenuChoice(title, options, selected, words, hint, icon, onSelect)
        }
    }
}

@Composable
private fun <T> ButtonsChoice(title: String, options: List<T>, selected: T, words: List<String>, hint: String?, icon: ImageVector?, optionIcon: ((T) -> ImageVector)?, onSelect: (T) -> Unit) {
    Column(Modifier.fillMaxWidth().padding(vertical = if (LocalCompactLists.current) 2.dp else 6.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SettingName(title, hint, icon, Modifier.fillMaxWidth())
        PartTabs(options, selected, { words[options.indexOf(it)] }, height = ChoiceTabsHeight, icon = optionIcon, accent = true, onSelect = onSelect)
    }
}

@Composable
private fun <T> MenuChoice(title: String, options: List<T>, selected: T, words: List<String>, hint: String?, icon: ImageVector?, onSelect: (T) -> Unit) {
    var open by remember { mutableStateOf(false) }
    // The line that explains the choice runs under the whole row, so the button does not squeeze it.
    Column(Modifier.fillMaxWidth().padding(vertical = if (LocalCompactLists.current) 0.dp else 4.dp)) {
        Row(Modifier.fillMaxWidth().heightIn(min = 44.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            SettingName(title, null, icon, Modifier.weight(1f))
            // The menu opens under the button, so the two are together in one box.
            Box {
                InkOutlinedButton({ open = true }, contentPadding = PaddingValues(start = 14.dp, end = 6.dp)) {
                    Text(words.getOrElse(options.indexOf(selected)) { "" }, style = MaterialTheme.typography.labelLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Icon(Icons.Filled.ArrowDropDown, null)
                }
                DropdownMenu(open, { open = false }) {
                    options.forEachIndexed { index, option ->
                        val chosen = option == selected
                        DropdownMenuItem(
                            { Text(words[index], color = if (chosen) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface) },
                            {
                                open = false
                                onSelect(option)
                            },
                            trailingIcon = if (chosen) ({ Icon(Icons.Filled.Check, null, tint = MaterialTheme.colorScheme.primary) }) else null,
                        )
                    }
                }
            }
        }
        if (hint != null) Text(hint, Modifier.padding(start = if (icon != null) IconSpace else 0.dp, bottom = 4.dp), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
    }
}

// A number picked on a slider, with its name, its icon and the number now in a small pill. The number follows the finger, and the value is given once the slider is let go, so it is saved once.
@Composable
fun SliderSetting(
    title: StringResource,
    value: Float,
    range: ClosedFloatingPointRange<Float>,
    text: @Composable (Float) -> String,
    modifier: Modifier = Modifier,
    hint: StringResource? = null,
    icon: ImageVector? = settingIconOf(title),
    steps: Int = 0,
    // Called as the slider moves, for a choice that shows its effect at once, such as the brightness of the reader.
    onMove: ((Float) -> Unit)? = null,
    onDone: (Float) -> Unit,
) = SliderSetting(stringResource(title), value, range, text, modifier, hint?.let { stringResource(it) }, icon, steps, onMove, onDone)

// The same with a name and a line that are already words.
@Composable
fun SliderSetting(
    title: String,
    value: Float,
    range: ClosedFloatingPointRange<Float>,
    text: @Composable (Float) -> String,
    modifier: Modifier = Modifier,
    hint: String? = null,
    icon: ImageVector? = null,
    steps: Int = 0,
    onMove: ((Float) -> Unit)? = null,
    onDone: (Float) -> Unit,
) {
    var live by remember(value) { mutableFloatStateOf(value) }
    val colors = MaterialTheme.colorScheme
    Column(modifier.fillMaxWidth().padding(top = 6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            SettingName(title, hint, icon, Modifier.weight(1f))
            Text(
                text(live),
                Modifier.background(colors.primary.copy(alpha = 0.14f), CircleShape).padding(horizontal = 10.dp, vertical = 3.dp),
                style = MaterialTheme.typography.labelLarge,
                color = colors.primary,
            )
        }
        InkSlider(live, {
            live = it
            onMove?.invoke(it)
        }, valueRange = range, steps = steps, onValueChangeFinished = { onDone(live) })
    }
}

// The icon, the name and the line under it, as every kind of setting starts.
@Composable
internal fun SettingName(title: String, hint: String?, icon: ImageVector?, modifier: Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        SettingIconOrRoom(icon)
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, style = MaterialTheme.typography.bodyLarge)
            if (hint != null) Text(hint, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
        }
    }
}

// A choice of any number of options, each a chip that is on or off, under the name of the choice. The options are pairs of what is kept and what is shown.
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ChipsSetting(title: String, options: List<Pair<String, String>>, selected: Set<String>, onToggle: (String) -> Unit, modifier: Modifier = Modifier, hint: String? = null, icon: ImageVector? = null) {
    Column(modifier.fillMaxWidth().padding(vertical = 6.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SettingName(title, hint, icon, Modifier.fillMaxWidth())
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            for ((value, words) in options) {
                val on = value in selected
                FilterChip(on, { onToggle(value) }, { Text(words) }, leadingIcon = if (on) ({ Icon(Icons.Filled.Check, null, Modifier.size(16.dp)) }) else null)
            }
        }
    }
}
