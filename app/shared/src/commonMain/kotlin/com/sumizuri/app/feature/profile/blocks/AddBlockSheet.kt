package com.sumizuri.app.feature.profile.blocks

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FileOpen
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.blocks.BlockContext
import com.sumizuri.app.data.blocks.BlockTemplate
import com.sumizuri.app.data.blocks.ScriptResult
import com.sumizuri.app.data.blocks.runScript
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.readSharedFile
import com.sumizuri.app.feature.profile.BlockCalls
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.add
import com.sumizuri.app.shared.resources.blocks_add
import com.sumizuri.app.shared.resources.blocks_add_ready
import com.sumizuri.app.shared.resources.blocks_add_tab_import
import com.sumizuri.app.shared.resources.blocks_add_tab_templates
import com.sumizuri.app.shared.resources.blocks_classic
import com.sumizuri.app.shared.resources.blocks_import_file
import com.sumizuri.app.shared.resources.blocks_import_file_bad
import com.sumizuri.app.shared.resources.blocks_import_file_hint
import com.sumizuri.app.shared.resources.blocks_starters
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.input.rememberFilePicker
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.setting.PartTabs
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.stringResource

// The parts of the profile as it was, which the sheet lists apart from the blocks to start from.
private val Classic = setOf(BlockTemplate.Figures, BlockTemplate.Year, BlockTemplate.Continue, BlockTemplate.Statistics)

// How tall the picture of a block is on its card, and how much smaller than life it is drawn.
private val PictureHeight = 120.dp
private const val PictureScale = 0.5f

private enum class AddTab { Templates, Import }

// Where a block is added: from a card that shows what the block looks like with your own reading in it, or from a block someone shared as text.
@Composable
internal fun AddBlockSheet(calls: BlockCalls, context: BlockContext?, env: BlockEnv, onDismiss: () -> Unit) {
    var tab by remember { mutableStateOf(AddTab.Templates) }
    AppSheet(onDismiss, title = stringResource(Res.string.blocks_add)) {
        PartTabs(AddTab.entries, tab, {
            stringResource(
                if (it ==
                    AddTab.Templates
                ) {
                    Res.string.blocks_add_tab_templates
                } else {
                    Res.string.blocks_add_tab_import
                },
            )
        }) { tab = it }
        when (tab) {
            AddTab.Templates -> Gallery(calls, context, env, onDismiss)
            AddTab.Import -> ImportBlock(calls, onDismiss)
        }
    }
}

@Composable
private fun Gallery(calls: BlockCalls, context: BlockContext?, env: BlockEnv, onDismiss: () -> Unit) {
    for ((heading, templates) in listOf(
        Res.string.blocks_starters to BlockTemplate.entries.filter { it !in Classic },
        Res.string.blocks_classic to Classic.toList(),
    )) {
        AppSectionLabel(stringResource(heading))
        // Two cards to a line.
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            for (pair in templates.chunked(2)) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    for (template in pair) {
                        TemplateCard(template, context, env, Modifier.weight(1f)) {
                            calls.onAdd(template)
                            onDismiss()
                        }
                    }
                    if (pair.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }
    }
}

// One block to start from: a picture of it, run on your own reading, its name, and the size it starts at. A tap adds it.
@Composable
private fun TemplateCard(
    template: BlockTemplate,
    context: BlockContext?,
    env: BlockEnv,
    modifier: Modifier,
    onAdd: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val result by produceState<ScriptResult?>(null, template, context) {
        val reading = context ?: return@produceState
        value = withContext(Dispatchers.Default) { runScript(template.script(), reading) }
    }
    // The corners of a card in the theme, as the blocks themselves have.
    val shape = MaterialTheme.shapes.medium
    Column(modifier.clip(shape).background(scheme.surfaceContainerLow).clickable(onClick = onAdd)) {
        BoxWithConstraints(
            Modifier
                .fillMaxWidth()
                .height(PictureHeight)
                .clipToBounds()
                .background(scheme.surfaceContainer),
        ) {
            val shown = result
            if (shown != null) {
                // The block is laid out as wide as the card is at full size, then shrunk, so a wide block still shows its whole width.
                Box(
                    Modifier
                        .wrapContentSize(Alignment.TopStart, unbounded = true)
                        .width(maxWidth / PictureScale)
                        .graphicsLayer {
                            scaleX = PictureScale
                            scaleY = PictureScale
                            transformOrigin = TransformOrigin(0f, 0f)
                        }.padding(12.dp),
                ) { BlockViewContent(shown.view, env, Modifier.fillMaxWidth()) }
            }
        }
        Column(Modifier.padding(horizontal = 12.dp, vertical = 10.dp)) {
            Text(
                stringResource(template.label),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(sizeLine(template), style = MaterialTheme.typography.bodySmall, color = scheme.outline)
        }
    }
}

// How wide and tall a block starts, as words.
@Composable
private fun sizeLine(template: BlockTemplate): String = if (template.h >
    0
) {
    "${template.w} × ${template.h}"
} else {
    stringResource(Res.string.blocks_add_ready, template.w)
}

// A block someone sent as a .sumizuri file, opened from the device and added at once.
@Composable
private fun ImportBlock(calls: BlockCalls, onDismiss: () -> Unit) {
    var bad by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val pick = rememberFilePicker { path ->
        scope.launch {
            val thing = readSharedFile(path, ShareKind.Block)
            if (thing != null && calls.onImport(thing.data)) onDismiss() else bad = true
        }
    }
    AppListRow(
        stringResource(Res.string.blocks_import_file),
        subtitle = stringResource(if (bad) Res.string.blocks_import_file_bad else Res.string.blocks_import_file_hint),
        leading = { Icon(Icons.Outlined.FileOpen, null, tint = MaterialTheme.colorScheme.onSurfaceVariant) },
        onClick = pick,
    )
}
