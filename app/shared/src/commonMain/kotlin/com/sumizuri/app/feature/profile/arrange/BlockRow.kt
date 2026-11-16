package com.sumizuri.app.feature.profile.arrange

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.AddToPhotos
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.DragIndicator
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.blocks.BlockView
import com.sumizuri.app.data.blocks.blockData
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.feature.profile.BlockCalls
import com.sumizuri.app.feature.profile.ShownBlock
import com.sumizuri.app.feature.profile.blocks.MostRows
import com.sumizuri.app.feature.profile.blocks.fit
import com.sumizuri.app.feature.profile.blocks.icon
import com.sumizuri.app.feature.profile.blocks.kindName
import com.sumizuri.app.feature.profile.blocks.name
import com.sumizuri.app.feature.profile.blocks.size
import com.sumizuri.app.feature.share.ShareDialog
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.blocks_duplicate
import com.sumizuri.app.shared.resources.blocks_edit_script
import com.sumizuri.app.shared.resources.blocks_remove_message
import com.sumizuri.app.shared.resources.blocks_remove_title
import com.sumizuri.app.shared.resources.blocks_reorder
import com.sumizuri.app.shared.resources.blocks_size
import com.sumizuri.app.shared.resources.blocks_size_content
import com.sumizuri.app.shared.resources.blocks_size_height
import com.sumizuri.app.shared.resources.blocks_size_rows
import com.sumizuri.app.shared.resources.blocks_size_width
import com.sumizuri.app.shared.resources.remove
import com.sumizuri.app.shared.resources.share_action
import com.sumizuri.app.shared.resources.share_title
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.page.AppSheet
import org.jetbrains.compose.resources.stringResource

// The sizes a block can be set to: columns by rows, then the widths that fit their content, shown with ↕.
private val Sizes = listOf(1 to 1, 2 to 1, 2 to 2, 3 to 2, 4 to 1, 4 to 2, 4 to 3, 4 to 4, 2 to 0, 3 to 0, 4 to 0)

private fun sizeText(w: Int, h: Int) = if (h > 0) "$w × $h" else "$w × ↕"

// One block in the list, on one line: a handle to drag it by, and what it shows with its size. A tap picks the block. On a wide screen its actions sit at the end of the line, and on a phone they go to the bar at the top while it is picked.
@Composable
internal fun BlockRow(
    item: ShownBlock,
    picked: Boolean,
    lifted: Boolean,
    onPick: () -> Unit,
    handle: Modifier,
    trailing: @Composable () -> Unit = {},
) {
    val scheme = MaterialTheme.colorScheme
    val (w, h) = item.size
    val ring = if (picked || lifted) Modifier.border(2.dp, scheme.primary, MaterialTheme.shapes.medium) else Modifier
    AppCard(Modifier.fillMaxWidth().then(ring)) {
        Row(
            Modifier.fillMaxWidth().clickable(onClick = onPick).padding(end = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                Icons.Outlined.DragIndicator,
                stringResource(Res.string.blocks_reorder),
                handle.padding(start = 8.dp, end = 4.dp, top = 20.dp, bottom = 20.dp).size(24.dp),
                tint = scheme.outline,
            )
            Icon(item.view.icon(), null, Modifier.size(20.dp), tint = scheme.primary)
            Column(Modifier.weight(1f).padding(horizontal = 12.dp, vertical = 12.dp)) {
                Text(
                    item.name(),
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                val kind = item.kindName()
                Text(
                    if (kind ==
                        item.name()
                    ) {
                        sizeText(w, h)
                    } else {
                        "$kind · ${sizeText(w, h)}"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = scheme.outline,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            trailing()
        }
    }
}

// What can be done with a block, as icons: its size, a picture of its shape that lists the sizes it fits in, its script, a copy of it, sharing it and removing it, which asks first. A part of the profile as it came has no script worth changing and no reason for two of it, so it only goes.
@Composable
internal fun BlockActions(item: ShownBlock, calls: BlockCalls, onRemoved: () -> Unit = {}) {
    val scheme = MaterialTheme.colorScheme
    var removing by remember { mutableStateOf(false) }
    var sharing by remember { mutableStateOf(false) }
    val id = item.block.id
    val (w, h) = item.size
    val choices = Sizes.filter { (cw, ch) -> item.fit.allows(cw, ch) }
    if (choices.size > 1) SizeButton(item) { columns, rows -> calls.onResize(id, columns, rows) }
    if (item.view !is BlockView.Classic) {
        SmallAction(Icons.Outlined.Edit, stringResource(Res.string.blocks_edit_script)) { calls.onEdit(id) }
        SmallAction(Icons.Outlined.AddToPhotos, stringResource(Res.string.blocks_duplicate)) { calls.onDuplicate(id) }
        SmallAction(Icons.Outlined.Share, stringResource(Res.string.share_action)) { sharing = true }
    }
    SmallAction(Icons.Outlined.Delete, stringResource(Res.string.remove), scheme.error) { removing = true }
    if (sharing) {
        val name = item.name()
        val data = remember(item.block) { blockData(item.block) }
        ShareDialog(stringResource(Res.string.share_title, name), name, ShareKind.Block, data) { sharing = false }
    }
    if (removing) {
        ConfirmDialog(
            title = stringResource(Res.string.blocks_remove_title),
            message = stringResource(Res.string.blocks_remove_message, item.name()),
            confirm = stringResource(Res.string.remove),
            onConfirm = {
                removing = false
                calls.onRemove(id)
                onRemoved()
            },
            onDismiss = { removing = false },
        )
    }
}

// An icon button a little smaller than usual, so a line has room for its name and all its actions.
@Composable
private fun SmallAction(
    icon: ImageVector,
    label: String,
    tint: Color = MaterialTheme.colorScheme.onSurfaceVariant,
    onClick: () -> Unit,
) {
    IconButton(onClick, Modifier.size(40.dp)) { Icon(icon, label, Modifier.size(22.dp), tint = tint) }
}

// The size of a block as an icon of its shape, which opens a sheet to set how many columns wide it is and how many rows tall, or that it is as tall as its content.
@Composable
private fun SizeButton(item: ShownBlock, onResize: (columns: Int, rows: Int) -> Unit) {
    var open by remember { mutableStateOf(false) }
    val (w, h) = item.size
    IconButton({ open = true }, Modifier.size(40.dp)) { SizeGlyph(w, h) }
    if (open) SizeSheet(item, onResize) { open = false }
}

// The size of one block as plain choices: its width in columns, and its height as a number of rows or as tall as it needs. A choice that the block's content cannot go below is greyed out. Each tap changes the block at once, so the preview shows it.
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SizeSheet(item: ShownBlock, onResize: (columns: Int, rows: Int) -> Unit, onDismiss: () -> Unit) {
    val fit = item.fit
    val (w, h) = item.size
    AppSheet(onDismiss, spacing = 12.dp, title = stringResource(Res.string.blocks_size)) {
        AppSectionLabel(stringResource(Res.string.blocks_size_width))
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for (columns in 1..4) {
                FilterChip(selected = columns == w, enabled = fit.allows(columns, h), onClick = {
                    onResize(columns, h)
                }, label = { Text(columns.toString()) })
            }
        }
        AppSectionLabel(stringResource(Res.string.blocks_size_height))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            FilterChip(selected = h == 0, enabled = fit.allows(w, 0), onClick = {
                onResize(w, 0)
            }, label = { Text(stringResource(Res.string.blocks_size_content)) })
            Spacer(Modifier.weight(1f))
            // A row less, or a row more, only when the content of the block still fits in it.
            IconButton(
                { onResize(w, h - 1) },
                enabled = h > 1 && fit.allows(w, h - 1),
            ) { Icon(Icons.Outlined.Remove, null) }
            Text(
                if (h >
                    0
                ) {
                    stringResource(Res.string.blocks_size_rows, h)
                } else {
                    "—"
                },
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.widthIn(min = 64.dp),
                textAlign = TextAlign.Center,
            )
            val taller = if (h == 0) fit.minH.coerceAtLeast(1) else h + 1
            IconButton({
                onResize(w, taller)
            }, enabled = taller <= MostRows && fit.allows(w, taller)) { Icon(Icons.Outlined.Add, null) }
        }
    }
}

// A small picture of a size: the four columns of the page, with the block filled in, as tall as its rows, or two rows and fainter for one that fits its content.
@Composable
private fun SizeGlyph(w: Int, h: Int) {
    val ink = MaterialTheme.colorScheme.primary
    val frame = MaterialTheme.colorScheme.outline.copy(alpha = 0.35f)
    Canvas(Modifier.size(width = 22.dp, height = 18.dp)) {
        val gap = 1.5.dp.toPx()
        val cell = (size.width - gap * 3) / 4
        val rows = if (h > 0) h.coerceAtMost(4) else 2
        val row = (size.height - gap * 3) / 4
        for (x in 0 until 4) {
            for (y in 0 until 4) {
                drawRoundRect(
                    frame,
                    Offset(x * (cell + gap), y * (row + gap)),
                    Size(cell, row),
                    CornerRadius(1.dp.toPx()),
                )
            }
        }
        drawRoundRect(
            ink,
            Offset.Zero,
            Size(cell * w + gap * (w - 1), row * rows + gap * (rows - 1)),
            CornerRadius(1.5.dp.toPx()),
            alpha = if (h >
                0
            ) {
                1f
            } else {
                0.6f
            },
        )
    }
}
