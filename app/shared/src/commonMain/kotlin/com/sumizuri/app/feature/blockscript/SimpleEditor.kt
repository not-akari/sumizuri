package com.sumizuri.app.feature.blockscript

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.FormatColorReset
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.blocks.SimpleBlock
import com.sumizuri.app.data.blocks.SimpleLibraryKeys
import com.sumizuri.app.data.blocks.SimpleReadKeys
import com.sumizuri.app.data.blocks.SimpleTitles
import com.sumizuri.app.data.blocks.SimpleValues
import com.sumizuri.app.data.blocks.numberText
import com.sumizuri.app.feature.profile.blocks.viewColor
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.library_title
import com.sumizuri.app.shared.resources.profile_chapters_read
import com.sumizuri.app.shared.resources.simple_all
import com.sumizuri.app.shared.resources.simple_by
import com.sumizuri.app.shared.resources.simple_caption
import com.sumizuri.app.shared.resources.simple_color
import com.sumizuri.app.shared.resources.simple_count
import com.sumizuri.app.shared.resources.simple_days_n
import com.sumizuri.app.shared.resources.simple_formula
import com.sumizuri.app.shared.resources.simple_goal
import com.sumizuri.app.shared.resources.simple_how_many
import com.sumizuri.app.shared.resources.simple_label
import com.sumizuri.app.shared.resources.simple_range
import com.sumizuri.app.shared.resources.simple_shape
import com.sumizuri.app.shared.resources.simple_show
import com.sumizuri.app.shared.resources.simple_style
import com.sumizuri.app.shared.resources.simple_text
import com.sumizuri.app.shared.resources.simple_theme_color
import com.sumizuri.app.shared.resources.simple_title
import com.sumizuri.app.shared.resources.simple_titles
import com.sumizuri.app.shared.resources.simple_top
import com.sumizuri.app.shared.resources.simple_value
import com.sumizuri.app.shared.resources.simple_weeks_n
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.input.AppTextField
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The simple editor: a block made by tapping. First what it shows, then where its data comes from, then how it looks. Every tap writes the script again, which the preview shows at once. Only what the chosen view uses is asked.
@Composable
internal fun SimpleEditor(block: SimpleBlock, onChange: (SimpleBlock) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Part(Res.string.simple_show) { Chips(ShowNames, block.show) { onChange(block.copy(show = it)) } }
        when (block.show) {
            "number", "ring", "bar" -> {
                Part(Res.string.simple_value) {
                    Chips(
                        SimpleValues.map {
                            it.first
                        } + "formula",
                        block.value,
                        { ValueNames.getValue(it) },
                    ) { onChange(block.copy(value = it)) }
                }
                if (block.value ==
                    "formula"
                ) {
                    Field(
                        block.formula,
                        Res.string.simple_formula,
                        code = true,
                    ) { onChange(block.copy(formula = it)) }
                }
                if (block.show != "number") {
                    // The goal keeps what is typed, as "1." on the way to "1.5" is no number yet.
                    var goal by remember { mutableStateOf(numberText(block.goal)) }
                    Field(goal, Res.string.simple_goal, number = true) { typed ->
                        goal = typed
                        typed.replace(',', '.').toDoubleOrNull()?.let { onChange(block.copy(goal = it)) }
                    }
                }
            }

            "chart", "list" -> {
                Part(Res.string.simple_count) {
                    Chips(
                        listOf("library" to Res.string.library_title, "reads" to Res.string.profile_chapters_read),
                        block.source,
                    ) { source ->
                        val keys = if (source == "reads") SimpleReadKeys else SimpleLibraryKeys
                        onChange(block.copy(source = source, by = block.by.takeIf { it in keys } ?: keys.first()))
                    }
                }
                Part(Res.string.simple_by) {
                    Chips(
                        if (block.source ==
                            "reads"
                        ) {
                            SimpleReadKeys
                        } else {
                            SimpleLibraryKeys
                        },
                        block.by,
                        { KeyNames.getValue(it) },
                    ) { onChange(block.copy(by = it)) }
                }
                if (block.source ==
                    "reads"
                ) {
                    Part(Res.string.simple_range) { DaysChips(block.days) { onChange(block.copy(days = it)) } }
                }
                if (block.by !in setOf("day", "weekday", "time", "hour", "month")) {
                    Part(
                        Res.string.simple_top,
                    ) { NumberChips(listOf(3, 5, 8, 10, 0), block.top) { onChange(block.copy(top = it)) } }
                }
                if (block.show ==
                    "chart"
                ) {
                    Part(
                        Res.string.simple_style,
                    ) { Chips(StyleNames, block.style) { onChange(block.copy(style = it)) } }
                }
            }

            "covers" -> {
                Part(Res.string.simple_titles) {
                    Chips(
                        SimpleTitles,
                        block.titles,
                        { TitlesNames.getValue(it) },
                    ) { onChange(block.copy(titles = it)) }
                }
                if (block.titles ==
                    "recent"
                ) {
                    Part(
                        Res.string.simple_range,
                    ) { DaysChips(block.days, all = false) { onChange(block.copy(days = it)) } }
                }
                Part(
                    Res.string.simple_how_many,
                ) { NumberChips(listOf(6, 12, 20), block.count) { onChange(block.copy(count = it)) } }
            }

            "heatmap" -> {
                Part(Res.string.simple_range) {
                    WordChips(
                        listOf(13, 26, 53).map {
                            it.toString()
                        },
                        block.weeks.toString(),
                        {
                            stringResource(Res.string.simple_weeks_n, it.toInt())
                        },
                    ) { onChange(block.copy(weeks = it.toInt())) }
                }
                Part(Res.string.simple_shape) { Chips(ShapeNames, block.shape) { onChange(block.copy(shape = it)) } }
            }

            "text" -> {
                Field(block.text, Res.string.simple_text, lines = 3) { onChange(block.copy(text = it)) }
                Part(
                    Res.string.simple_style,
                ) { Chips(TextStyleNames, block.textStyle) { onChange(block.copy(textStyle = it)) } }
            }

            "section" -> Part(
                Res.string.simple_show,
            ) { Chips(SectionNames, block.section) { onChange(block.copy(section = it)) } }
        }
        if (block.show != "section") {
            AppSectionLabel(stringResource(Res.string.simple_title))
            Field(block.title, Res.string.simple_title) { onChange(block.copy(title = it)) }
            if (block.show != "text") Field(block.label, Res.string.simple_label) { onChange(block.copy(label = it)) }
            if (block.show ==
                "number"
            ) {
                Field(block.caption, Res.string.simple_caption) { onChange(block.copy(caption = it)) }
            }
            if (block.show !in
                setOf("text", "list", "covers")
            ) {
                Part(Res.string.simple_color) { Swatches(block.color) { onChange(block.copy(color = it)) } }
            }
        }
    }
}

@Composable
private fun Part(title: StringResource, content: @Composable () -> Unit) {
    AppSectionLabel(stringResource(title))
    content()
}

// A row of chips that wraps, one of which is chosen.
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun WordChips(
    keys: List<String>,
    chosen: String,
    name: @Composable (String) -> String,
    onPick: (String) -> Unit,
) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        for (key in keys) SoftChip(selected = key == chosen, onClick = { onPick(key) }, label = { Text(name(key)) })
    }
}

@Composable
private fun Chips(choices: List<Pair<String, StringResource>>, chosen: String, onPick: (String) -> Unit) =
    WordChips(choices.map { it.first }, chosen, { key ->
        stringResource(
            choices
                .first {
                    it.first ==
                        key
                }.second,
        )
    }, onPick)

@Composable
private fun Chips(keys: List<String>, chosen: String, name: (String) -> StringResource, onPick: (String) -> Unit) =
    WordChips(keys, chosen, { stringResource(name(it)) }, onPick)

// How far back reads go: a few spans of days, and all of them.
@Composable
private fun DaysChips(days: Int, all: Boolean = true, onPick: (Int) -> Unit) {
    val choices = listOf(7, 30, 90, 365) + if (all) listOf(0) else emptyList()
    WordChips(choices.map { it.toString() }, days.toString(), {
        if (it ==
            "0"
        ) {
            stringResource(Res.string.simple_all)
        } else {
            stringResource(Res.string.simple_days_n, it.toInt())
        }
    }) { onPick(it.toInt()) }
}

@Composable
private fun NumberChips(choices: List<Int>, chosen: Int, onPick: (Int) -> Unit) =
    WordChips(choices.map { it.toString() }, chosen.toString(), {
        if (it ==
            "0"
        ) {
            stringResource(Res.string.simple_all)
        } else {
            it
        }
    }) { onPick(it.toInt()) }

@Composable
private fun Field(
    value: String,
    label: StringResource,
    code: Boolean = false,
    number: Boolean = false,
    lines: Int = 1,
    onChange: (String) -> Unit,
) {
    AppTextField(
        value,
        onChange,
        Modifier.fillMaxWidth(),
        label = { Text(stringResource(label)) },
        singleLine = lines == 1,
        minLines = lines,
        textStyle = if (code) {
            MaterialTheme.typography.bodyMedium.copy(
                fontFamily = FontFamily.Monospace,
            )
        } else {
            MaterialTheme.typography.bodyLarge
        },
        keyboardOptions = if (number) KeyboardOptions(keyboardType = KeyboardType.Decimal) else KeyboardOptions.Default,
    )
}

// The colours as dots, the first the colour of the theme, with the chosen one ticked.
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun Swatches(chosen: String, onPick: (String) -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        for (name in listOf("") + ColorNames) {
            val color = viewColor(name.ifEmpty { null })
            Box(
                Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(color)
                    .border(2.dp, if (name == chosen) MaterialTheme.colorScheme.onSurface else color, CircleShape)
                    .clickable { onPick(name) },
                contentAlignment = Alignment.Center,
            ) {
                when {
                    name == chosen -> Icon(
                        Icons.Outlined.Check,
                        null,
                        Modifier.size(18.dp),
                        tint = MaterialTheme.colorScheme.surface,
                    )

                    name.isEmpty() -> Icon(
                        Icons.Outlined.FormatColorReset,
                        stringResource(Res.string.simple_theme_color),
                        Modifier.size(18.dp),
                        tint = MaterialTheme.colorScheme.surface,
                    )
                }
            }
        }
    }
}
