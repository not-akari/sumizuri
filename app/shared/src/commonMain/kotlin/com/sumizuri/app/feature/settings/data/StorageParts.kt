package com.sumizuri.app.feature.settings.data

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.storage_copy_path
import com.sumizuri.app.shared.resources.storage_free
import com.sumizuri.app.shared.resources.storage_gigabytes
import com.sumizuri.app.shared.resources.storage_group_paths
import com.sumizuri.app.shared.resources.storage_megabytes
import com.sumizuri.app.shared.resources.storage_open_folder
import com.sumizuri.app.shared.resources.storage_path_data
import com.sumizuri.app.shared.resources.storage_path_database
import com.sumizuri.app.shared.resources.storage_path_images
import com.sumizuri.app.shared.resources.storage_paths_hint
import com.sumizuri.app.shared.resources.storage_used
import com.sumizuri.app.ui.kit.canOpenFolders
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.card.Hairline
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.kit.image.PageImages
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.kit.openFolder
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// One kind of file in the usage bar, with its color.
internal class UsePart(val label: String, val bytes: Long, val color: Color)

// How much the app takes on the drive: the total, a bar split by kind that grows in, what each color is, and the room left.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun UsageCard(parts: List<UsePart>, free: Long?) {
    val total = parts.sumOf { it.bytes }
    val grow = remember { Animatable(0f) }
    val growMs = motionMs(AppMotion.Page * 2)
    LaunchedEffect(Unit) { grow.animateTo(1f, tween(growMs, easing = AppMotion.Entrance)) }
    AppCard(Modifier.entrance()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    byteSizeText(total),
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    stringResource(Res.string.storage_used),
                    Modifier.padding(bottom = 5.dp),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(12.dp)
                    .clip(CircleShape)
                    .background(softFill()),
            ) {
                if (total > 0) {
                    Row(
                        Modifier.fillMaxWidth(grow.value).fillMaxHeight(),
                        horizontalArrangement = Arrangement.spacedBy(3.dp),
                    ) {
                        for (part in parts) {
                            if (part.bytes <= 0) continue
                            key(part.label) {
                                val share by animateFloatAsState(
                                    part.bytes.toFloat() / total,
                                    tween(motionMs(AppMotion.Medium)),
                                    label = "share",
                                )
                                Box(Modifier.weight(share.coerceAtLeast(0.01f)).fillMaxHeight().background(part.color))
                            }
                        }
                    }
                }
            }
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                for (part in parts) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Box(Modifier.size(8.dp).clip(CircleShape).background(part.color))
                        Text(part.label, style = MaterialTheme.typography.bodySmall)
                        Text(
                            byteSizeText(part.bytes),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
            if (free != null) {
                Text(
                    stringResource(Res.string.storage_free, byteSizeText(free)),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
        }
    }
}

// How much the two picture caches hold on the drive, counted again when the round or the limit changes.
@Composable
internal fun rememberImageBytes(round: Int, diskMb: Int): Long {
    val context = LocalPlatformContext.current
    val bytes by produceState(0L, round, diskMb) {
        value = withContext(Dispatchers.IO) {
            (SingletonImageLoader.get(context).diskCache?.size ?: 0L) + (PageImages.get(context).diskCache?.size ?: 0L)
        }
    }
    return bytes
}

// Empties both picture caches, on the drive and in memory.
internal fun clearImageCaches(context: PlatformContext) {
    val loader = SingletonImageLoader.get(context)
    loader.diskCache?.clear()
    loader.memoryCache?.clear()
    PageImages.get(context).diskCache?.clear()
}

// The words for a size in megabytes, in gigabytes from one up.
@Composable
internal fun sizeLabel(megabytes: Int): String = if (megabytes >= 1024) {
    stringResource(Res.string.storage_gigabytes, megabytes / 1024)
} else {
    stringResource(Res.string.storage_megabytes, megabytes)
}

// The places the app keeps its files, folded away under one row until asked for.
@Composable
internal fun LocationsFold(database: String, dataFolder: String, imageFolder: String) {
    var open by rememberSaveable { mutableStateOf(false) }
    val turn by animateFloatAsState(if (open) 180f else 0f, tween(motionMs(AppMotion.Fast)), label = "fold")
    val ms = motionMs(AppMotion.Medium)
    SettingsSection {
        row {
            Column {
                SettingRow(
                    stringResource(Res.string.storage_group_paths),
                    subtitle = stringResource(Res.string.storage_paths_hint),
                    leading = { SettingIcon(Icons.Outlined.FolderOpen) },
                    trailing = {
                        Icon(
                            Icons.Outlined.ExpandMore,
                            null,
                            Modifier.rotate(turn),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    },
                    onClick = { open = !open },
                )
                AnimatedVisibility(
                    open,
                    enter = expandVertically(tween(ms)) + fadeIn(tween(ms)),
                    exit = shrinkVertically(tween(ms)) + fadeOut(tween(ms)),
                ) {
                    Column {
                        PathRow(Res.string.storage_path_database, database, Icons.Outlined.Description)
                        PathRow(Res.string.storage_path_data, dataFolder, Icons.Outlined.Folder)
                        PathRow(Res.string.storage_path_images, imageFolder, Icons.Outlined.PhotoLibrary)
                    }
                }
            }
        }
    }
}

// A place where the app keeps files, written out in full. Tapping the row copies it, and on a computer a button opens the folder.
@Composable
private fun PathRow(title: StringResource, path: String, icon: ImageVector) {
    if (path.isBlank()) return
    val copy = rememberCopyText()
    val tint = MaterialTheme.colorScheme.onSurfaceVariant
    Hairline(Modifier.padding(horizontal = 14.dp))
    SettingRow(
        stringResource(title),
        subtitle = path,
        subtitleLines = 3,
        leading = { SettingIcon(icon) },
        trailing = {
            Row {
                IconButton({ copy(path) }) {
                    Icon(Icons.Outlined.ContentCopy, stringResource(Res.string.storage_copy_path), tint = tint)
                }
                if (canOpenFolders()) {
                    IconButton({ openFolder(path) }) {
                        Icon(Icons.Outlined.FolderOpen, stringResource(Res.string.storage_open_folder), tint = tint)
                    }
                }
            }
        },
        onClick = { copy(path) },
    )
}
