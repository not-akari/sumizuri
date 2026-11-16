package com.sumizuri.app.feature.theme

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.FileOpen
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.readSharedFile
import com.sumizuri.app.feature.share.ShareDialog
import com.sumizuri.app.feature.theme.panel.CardAction
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.editor_copy_suffix
import com.sumizuri.app.shared.resources.share_action
import com.sumizuri.app.shared.resources.share_title
import com.sumizuri.app.shared.resources.theme_customize
import com.sumizuri.app.shared.resources.theme_delete
import com.sumizuri.app.shared.resources.theme_duplicate
import com.sumizuri.app.shared.resources.theme_edit
import com.sumizuri.app.shared.resources.theme_import
import com.sumizuri.app.shared.resources.theme_mine
import com.sumizuri.app.shared.resources.theme_new
import com.sumizuri.app.shared.resources.theme_ready_made
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.input.rememberFilePicker
import com.sumizuri.app.ui.kit.setting.SettingsHeading
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.theme.spec.ThemePresets
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// The gallery of themes: the ones that come with the app and the ones a person made, each drawn in its own colors. Tapping one uses it. A menu on each customizes, duplicates, shares or removes it, and a row makes a new theme from the one in use or reads one from a file.
@Composable
internal fun ColumnScope.ThemeGallery(onEdit: (String) -> Unit) {
    val container = LocalAppContainer.current
    val model = rememberThemeModel()
    val active by model.active.collectAsStateWithLifecycle()
    val mine by model.custom.collectAsStateWithLifecycle()
    val dark = MaterialTheme.colorScheme.background.luminance() < 0.5f
    // The theme in the share window, while it is open.
    var sharing by remember { mutableStateOf<AppThemeSpec?>(null) }
    sharing?.let { theme ->
        ShareDialog(
            stringResource(Res.string.share_title, theme.name),
            theme.name,
            ShareKind.Theme,
            remember(theme) { container.themes.toData(theme) },
        ) {
            sharing =
                null
        }
    }
    // A .sumizuri file that holds a theme is added at once and used. Any other file is left alone.
    val scope = rememberCoroutineScope()
    val pickFile = rememberFilePicker { path ->
        scope.launch {
            val theme = readSharedFile(path, ShareKind.Theme)?.let { container.themes.fromData(it.data) }
            if (theme != null) model.save(theme.copy(id = AppThemeSpec.CustomPrefix + newThemeId()))
        }
    }
    AppListRow(
        stringResource(Res.string.theme_new),
        leading = { Icon(Icons.Outlined.Add, null, tint = MaterialTheme.colorScheme.onSurfaceVariant) },
        onClick = { onEdit(active.id) },
    )
    AppListRow(
        stringResource(Res.string.theme_import),
        leading = { Icon(Icons.Outlined.FileOpen, null, tint = MaterialTheme.colorScheme.onSurfaceVariant) },
        onClick = pickFile,
    )
    if (mine.isNotEmpty()) {
        SettingsHeading(stringResource(Res.string.theme_mine))
        Grid(mine) { theme ->
            val copyName = stringResource(Res.string.editor_copy_suffix, theme.name)
            ThemeCard(
                theme,
                dark,
                theme.id == active.id,
                listOf(
                    CardAction(Res.string.theme_edit) { onEdit(theme.id) },
                    CardAction(Res.string.theme_duplicate) {
                        model.save(
                            theme.copy(
                                id =
                                AppThemeSpec.CustomPrefix + newThemeId(),
                                name = copyName,
                            ),
                            use = false,
                        )
                    },
                    CardAction(Res.string.share_action) { sharing = theme },
                    CardAction(Res.string.theme_delete) { model.delete(theme.id) },
                ),
                { model.select(theme.id) },
            )
        }
    }
    SettingsHeading(stringResource(Res.string.theme_ready_made))
    Grid(ThemePresets) { theme ->
        ThemeCard(
            theme,
            dark,
            theme.id == active.id,
            listOf(
                CardAction(Res.string.theme_customize) { onEdit(theme.id) },
                CardAction(Res.string.share_action) { sharing = theme },
            ),
            { model.select(theme.id) },
        )
    }
}

// Only the themes that come with the app, without their menus, for the first steps after installing. Tapping one uses it, and the app changes to it at once.
@Composable
internal fun ThemePresetGrid() {
    val model = rememberThemeModel()
    val active by model.active.collectAsStateWithLifecycle()
    val dark = MaterialTheme.colorScheme.background.luminance() < 0.5f
    Grid(
        ThemePresets,
    ) { theme -> ThemeCard(theme, dark, theme.id == active.id, emptyList(), { model.select(theme.id) }) }
}

// The cards in as many columns as fit.
@Composable
private fun Grid(themes: List<AppThemeSpec>, card: @Composable (AppThemeSpec) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val columns = maxOf(2, (maxWidth / 168.dp).toInt())
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            for (rowOfThemes in themes.chunked(columns)) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    for (theme in rowOfThemes) Box(Modifier.weight(1f)) { card(theme) }
                    repeat(columns - rowOfThemes.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
    }
}
