package com.sumizuri.app.feature.share

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material.icons.outlined.FileOpen
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material.icons.outlined.Save
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.exportData
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.reposData
import com.sumizuri.app.data.text.dateText
import com.sumizuri.app.feature.theme.rememberThemeModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.import_choose
import com.sumizuri.app.shared.resources.import_choose_hint
import com.sumizuri.app.shared.resources.import_drop_hint
import com.sumizuri.app.shared.resources.import_dropping
import com.sumizuri.app.shared.resources.import_out_backup
import com.sumizuri.app.shared.resources.import_out_backup_hint
import com.sumizuri.app.shared.resources.import_out_backup_last
import com.sumizuri.app.shared.resources.import_out_repos
import com.sumizuri.app.shared.resources.import_out_repos_hint
import com.sumizuri.app.shared.resources.import_out_section
import com.sumizuri.app.shared.resources.import_out_settings
import com.sumizuri.app.shared.resources.import_out_settings_hint
import com.sumizuri.app.shared.resources.import_out_theme
import com.sumizuri.app.shared.resources.import_out_theme_hint
import com.sumizuri.app.shared.resources.share_kind_repos
import com.sumizuri.app.shared.resources.share_kind_settings
import com.sumizuri.app.shared.resources.share_title
import com.sumizuri.app.ui.kit.card.CardShape
import com.sumizuri.app.ui.kit.card.cardEdge
import com.sumizuri.app.ui.kit.card.cardFill
import com.sumizuri.app.ui.kit.input.canDropFiles
import com.sumizuri.app.ui.kit.input.fileDrop
import com.sumizuri.app.ui.kit.setting.SettingLinkRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonElement
import okio.Path
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// What the share window shows: its title, the name of the file, and what is in it.
private data class Sharing(val title: String, val name: String, val kind: ShareKind, val data: JsonElement)

// The page when nothing is open: a big place to choose or drop a file, then what this device can share.
@Composable
internal fun ImportHome(onPick: () -> Unit, onDrop: (Path) -> Unit, onOpenBackup: () -> Unit) {
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    val theme by rememberThemeModel().active.collectAsStateWithLifecycle()
    val repos by container.repos.repos.collectAsStateWithLifecycle(emptyList())
    val backups by container.autoBackups.saved.collectAsStateWithLifecycle()
    var sharing by remember { mutableStateOf<Sharing?>(null) }
    sharing?.let { now -> ShareDialog(now.title, now.name, now.kind, now.data) { sharing = null } }

    val settingsTitle = stringResource(Res.string.share_title, stringResource(Res.string.share_kind_settings))
    val reposTitle = stringResource(Res.string.share_title, stringResource(Res.string.share_kind_repos))
    val themeTitle = stringResource(Res.string.share_title, theme.name)
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        DropArea(onPick, onDrop)
        SettingsSection(Res.string.import_out_section) {
            row {
                val last = backups.firstOrNull()
                val hint = if (last != null) {
                    stringResource(Res.string.import_out_backup_last, dateText(last.at))
                } else {
                    stringResource(Res.string.import_out_backup_hint)
                }
                SettingLinkRow(Icons.Outlined.Save, stringResource(Res.string.import_out_backup), hint, onOpenBackup)
            }
            row {
                SettingLinkRow(
                    Icons.Outlined.Tune,
                    stringResource(Res.string.import_out_settings),
                    stringResource(Res.string.import_out_settings_hint),
                ) {
                    scope.launch {
                        val data = container.settings.exportData()
                        sharing = Sharing(settingsTitle, "Sumizuri settings", ShareKind.Settings, data)
                    }
                }
            }
            row {
                SettingLinkRow(
                    Icons.Outlined.Palette,
                    stringResource(Res.string.import_out_theme),
                    stringResource(Res.string.import_out_theme_hint, theme.name),
                ) { sharing = Sharing(themeTitle, theme.name, ShareKind.Theme, container.themes.toData(theme)) }
            }
            if (repos.isNotEmpty()) {
                row {
                    SettingLinkRow(
                        Icons.Outlined.Extension,
                        stringResource(Res.string.import_out_repos),
                        pluralStringResource(Res.plurals.import_out_repos_hint, repos.size, repos.size),
                    ) {
                        sharing = Sharing(reposTitle, "Sumizuri repos", ShareKind.Repos, reposData(repos))
                    }
                }
            }
        }
    }
}

// The big place to choose a file, which on a desktop also takes a file dropped on it and lights up while one is held over it.
@Composable
private fun DropArea(onPick: () -> Unit, onDrop: (Path) -> Unit) {
    var over by remember { mutableStateOf(false) }
    val colors = MaterialTheme.colorScheme
    val edge by animateColorAsState(if (over) colors.primary else cardEdge(true), label = "edge")
    val fill by animateColorAsState(
        if (over) colors.primaryContainer.copy(alpha = 0.5f) else cardFill(),
        label = "fill",
    )
    val shape = CardShape
    Column(
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .drawBehind {
                val outline = shape.createOutline(size, layoutDirection, this)
                val dash = PathEffect.dashPathEffect(floatArrayOf(10.dp.toPx(), 6.dp.toPx()))
                drawOutline(outline, fill)
                drawOutline(outline, edge, style = Stroke(1.5.dp.toPx(), pathEffect = dash))
            }.fileDrop({ over = it }, onDrop)
            .clickable(onClick = onPick)
            .padding(horizontal = 20.dp, vertical = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(Icons.Outlined.FileOpen, null, Modifier.size(34.dp), tint = colors.primary)
        Text(
            stringResource(if (over) Res.string.import_dropping else Res.string.import_choose),
            style = MaterialTheme.typography.titleMedium,
        )
        Text(
            stringResource(if (canDropFiles()) Res.string.import_drop_hint else Res.string.import_choose_hint),
            style = MaterialTheme.typography.bodySmall,
            color = colors.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}
