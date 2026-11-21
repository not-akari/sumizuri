package com.sumizuri.app.setup

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.LibraryBooks
import androidx.compose.material.icons.outlined.Apps
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.DesktopWindows
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material.icons.outlined.PersonOutline
import androidx.compose.material.icons.outlined.RocketLaunch
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material.icons.rounded.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.core.windows.WindowsFileDialog
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.setup_back
import com.sumizuri.app.shared.resources.setup_change
import com.sumizuri.app.shared.resources.setup_customize
import com.sumizuri.app.shared.resources.setup_desktop
import com.sumizuri.app.shared.resources.setup_desktop_hint
import com.sumizuri.app.shared.resources.setup_fact_size
import com.sumizuri.app.shared.resources.setup_fact_user
import com.sumizuri.app.shared.resources.setup_install
import com.sumizuri.app.shared.resources.setup_library_found
import com.sumizuri.app.shared.resources.setup_library_inside
import com.sumizuri.app.shared.resources.setup_library_new
import com.sumizuri.app.shared.resources.setup_options_app
import com.sumizuri.app.shared.resources.setup_options_library
import com.sumizuri.app.shared.resources.setup_options_text
import com.sumizuri.app.shared.resources.setup_options_title
import com.sumizuri.app.shared.resources.setup_pick_folder
import com.sumizuri.app.shared.resources.setup_running
import com.sumizuri.app.shared.resources.setup_shortcuts_title
import com.sumizuri.app.shared.resources.setup_space
import com.sumizuri.app.shared.resources.setup_space_low
import com.sumizuri.app.shared.resources.setup_start_menu
import com.sumizuri.app.shared.resources.setup_start_menu_hint
import com.sumizuri.app.shared.resources.setup_startup
import com.sumizuri.app.shared.resources.setup_startup_hint
import com.sumizuri.app.shared.resources.setup_update
import com.sumizuri.app.shared.resources.setup_update_text
import com.sumizuri.app.shared.resources.setup_update_text_plain
import com.sumizuri.app.shared.resources.setup_update_title
import com.sumizuri.app.shared.resources.setup_welcome_text
import com.sumizuri.app.shared.resources.setup_welcome_title
import com.sumizuri.app.ui.kit.art.Fact
import com.sumizuri.app.ui.kit.art.KindTiles
import com.sumizuri.app.ui.kit.art.MainButton
import com.sumizuri.app.ui.kit.art.Notice
import com.sumizuri.app.ui.kit.art.QuietButton
import com.sumizuri.app.ui.kit.art.rise
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.setting.SettingsHeading
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource
import java.awt.Window
import java.io.File

// The frame of a page: an optional picture, its title and a line under it rising in, what it holds, and its buttons in a soft bar at the bottom. A tall page scrolls above the bar.
@Composable
internal fun SetupPage(
    title: String,
    text: String?,
    bottom: @Composable RowScope.() -> Unit,
    top: (@Composable () -> Unit)? = null,
    scroll: Boolean = false,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(Modifier.fillMaxSize()) {
        Column(Modifier.weight(1f).fillMaxWidth().then(if (scroll) Modifier.verticalScroll(rememberScrollState()) else Modifier)) {
            // The picture over the title keeps the same room above and below it. The page already starts a little under the steps, so less is added above.
            if (top != null) Box(Modifier.padding(bottom = 24.dp)) { top() }
            Text(title, Modifier.rise(0), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
            if (text != null) Text(text, Modifier.padding(top = 6.dp).rise(1), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(20.dp))
            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp), content = content)
        }
        Spacer(Modifier.height(14.dp))
        Row(
            Modifier.fillMaxWidth().rise(6).softCard(shape = MaterialTheme.shapes.medium).padding(10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            content = bottom,
        )
    }
}

// The notice that Sumizuri is open, sliding in and out as it opens and closes.
@Composable
internal fun RunningNotice(model: SetupModel) {
    AnimatedVisibility(model.runningCount > 0, enter = expandVertically() + fadeIn(), exit = shrinkVertically() + fadeOut()) {
        Notice(stringResource(Res.string.setup_running))
    }
}

// A folder in a card, with a button to choose another. A new folder slides in over the old.
@Composable
private fun PathCard(icon: ImageVector, folder: File, modifier: Modifier = Modifier, onChange: () -> Unit) {
    AppCard(modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Box(Modifier.size(42.dp).clip(RoundedCornerShape(12.dp)).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)), contentAlignment = Alignment.Center) {
                Icon(icon, null, Modifier.size(22.dp), tint = MaterialTheme.colorScheme.primary)
            }
            AnimatedContent(folder, Modifier.weight(1f), transitionSpec = { (slideInVertically { it } + fadeIn()) togetherWith (slideOutVertically { -it } + fadeOut()) }, label = "path") { shown ->
                Column {
                    Text(shown.name.ifEmpty { shown.path }, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(shown.path, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline, maxLines = 1, overflow = TextOverflow.MiddleEllipsis)
                }
            }
            QuietButton(stringResource(Res.string.setup_change), onChange)
        }
    }
}

// A short line under a folder that says whether it is fine, in the color of the theme or of a problem, changing with a fade.
@Composable
private fun StatusLine(text: String, ok: Boolean, modifier: Modifier = Modifier) {
    val tint by animateColorAsState(if (ok) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error, label = "status")
    AnimatedContent(text to ok, modifier, transitionSpec = { fadeIn(tween(220)) togetherWith fadeOut(tween(160)) }, label = "status") { (line, good) ->
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(start = 4.dp)) {
            Icon(if (good) Icons.Outlined.CheckCircle else Icons.Outlined.WarningAmber, null, Modifier.size(18.dp), tint = tint)
            Text(line, style = MaterialTheme.typography.bodyMedium, color = tint)
        }
    }
}

@Composable
internal fun WelcomePage(model: SetupModel) {
    val text = when {
        !model.updating -> stringResource(Res.string.setup_welcome_text)
        model.installed?.version != null -> stringResource(Res.string.setup_update_text, model.installed.version, model.version)
        else -> stringResource(Res.string.setup_update_text_plain, model.version)
    }
    SetupPage(
        stringResource(if (model.updating) Res.string.setup_update_title else Res.string.setup_welcome_title),
        text,
        bottom = {
            if (!model.updating) QuietButton(stringResource(Res.string.setup_customize), model::customize, Icons.Rounded.Tune)
            Spacer(Modifier.weight(1f))
            MainButton(stringResource(if (model.updating) Res.string.setup_update else Res.string.setup_install), model::install)
        },
    ) {
        KindTiles(2)
        Spacer(Modifier.height(4.dp))
        Fact(Icons.Outlined.PersonOutline, stringResource(Res.string.setup_fact_user), Modifier.rise(5))
        if (model.size > 0) Fact(Icons.Outlined.Storage, stringResource(Res.string.setup_fact_size, byteSizeText(model.size)), Modifier.rise(6))
        RunningNotice(model)
    }
}

// The choices of a custom install on one page: where the app goes, where the library lives, and the shortcuts.
@Composable
internal fun OptionsPage(model: SetupModel, window: Window?) {
    val scope = rememberCoroutineScope()
    val pick = stringResource(Res.string.setup_pick_folder)
    val free = model.freeSpace()
    SetupPage(
        stringResource(Res.string.setup_options_title),
        stringResource(Res.string.setup_options_text),
        bottom = {
            QuietButton(stringResource(Res.string.setup_back), model::back)
            Spacer(Modifier.weight(1f))
            MainButton(stringResource(Res.string.setup_install), model::install, enabled = model.canInstall)
        },
        scroll = true,
    ) {
        Column(Modifier.rise(2), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SettingsHeading(stringResource(Res.string.setup_options_app))
            PathCard(Icons.Outlined.FolderOpen, model.appFolder) {
                scope.launch { WindowsFileDialog.folder(window, pick, nearestFolder(model.appFolder))?.let(model::pickedApp) }
            }
            val line = if (model.enoughSpace) {
                stringResource(Res.string.setup_space, byteSizeText(model.size), free?.let(::byteSizeText) ?: "?")
            } else {
                stringResource(Res.string.setup_space_low)
            }
            StatusLine(line, model.enoughSpace)
        }
        Column(Modifier.rise(3), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SettingsHeading(stringResource(Res.string.setup_options_library))
            PathCard(Icons.AutoMirrored.Outlined.LibraryBooks, model.dataFolder) {
                scope.launch { WindowsFileDialog.folder(window, pick, nearestFolder(model.dataFolder))?.let(model::pickedLibrary) }
            }
            val line = when {
                model.libraryInsideApp -> stringResource(Res.string.setup_library_inside)
                model.libraryFound -> stringResource(Res.string.setup_library_found)
                else -> stringResource(Res.string.setup_library_new)
            }
            StatusLine(line, !model.libraryInsideApp)
        }
        Box(Modifier.rise(4)) {
            SettingsSection(stringResource(Res.string.setup_shortcuts_title)) {
                padded { SwitchSetting(stringResource(Res.string.setup_start_menu), model.menu, { model.menu = it }, stringResource(Res.string.setup_start_menu_hint), Icons.Outlined.Apps) }
                padded { SwitchSetting(stringResource(Res.string.setup_desktop), model.desktop, { model.desktop = it }, stringResource(Res.string.setup_desktop_hint), Icons.Outlined.DesktopWindows) }
                padded { SwitchSetting(stringResource(Res.string.setup_startup), model.startup, { model.startup = it }, stringResource(Res.string.setup_startup_hint), Icons.Outlined.RocketLaunch) }
            }
        }
        RunningNotice(model)
    }
}

// The folder to open the picker in: the one given, or the nearest one above it that is there.
private fun nearestFolder(folder: File): File? = generateSequence(folder) { it.parentFile }.firstOrNull { it.isDirectory }
