package com.sumizuri.app.feature.profile.arrange

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.AutoAwesomeMosaic
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.feature.profile.BlockCalls
import com.sumizuri.app.feature.profile.blocks.AddBlockSheet
import com.sumizuri.app.feature.profile.blocks.BlockEnv
import com.sumizuri.app.feature.profile.blocks.BlockGrid
import com.sumizuri.app.feature.profile.blocks.name
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.arrange_hint
import com.sumizuri.app.shared.resources.arrange_title
import com.sumizuri.app.shared.resources.blocks_add
import com.sumizuri.app.shared.resources.blocks_layouts
import com.sumizuri.app.shared.resources.script_preview
import com.sumizuri.app.shared.resources.window_close
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppSectionLabel
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import org.jetbrains.compose.resources.stringResource

// Wide enough for the page as it will look to sit beside the list.
private val WideBreakpoint = 900.dp

// The page as it will look, folded away until it is asked for. Every change to a block shows in it at once.
@Composable
private fun PagePreview(state: ArrangeState, onAdd: () -> Unit) {
    var open by rememberSaveable { mutableStateOf(false) }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth().clickable { open = !open }.padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(stringResource(Res.string.script_preview), Modifier.weight(1f), style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
            Icon(if (open) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore, null)
        }
        if (open) BlockGrid(state.blocks, BlockEnv(state.stats, state.recent, wide = false, onOpenTitle = {}), onAdd = onAdd)
    }
}

private sealed interface ArrangeWindow {
    data object None : ArrangeWindow
    data object Add : ArrangeWindow
}

// The page where the blocks of the profile are edited: the blocks as a list to drag into order, and a button that adds a block. On a phone a tap picks a block and the bar at the top turns into its actions, so the lines stay clear. Wide enough, the actions sit on each line and the page itself shows beside the list as it will look.
@Composable
internal fun ArrangeScreen(state: ArrangeState, calls: BlockCalls, onBack: () -> Unit) {
    var window by remember { mutableStateOf<ArrangeWindow>(ArrangeWindow.None) }
    // The block last tapped, which the bar at the top acts on, on a phone.
    var picked by rememberSaveable { mutableStateOf<String?>(null) }
    // No page color of its own, so the ink of the theme behind every page shows here too.
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val wide = maxWidth >= WideBreakpoint
        val pickedBlock = state.blocks.firstOrNull { it.block.id == picked }.takeIf { !wide }
        // Back lets go of the picked block before it leaves the page.
        NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = pickedBlock != null) { picked = null }
        Column(Modifier.fillMaxSize()) {
            if (pickedBlock != null) {
                PageTopBar(
                    pickedBlock.name(),
                    leading = { IconButton({ picked = null }) { Icon(Icons.Outlined.Close, stringResource(Res.string.window_close)) } },
                ) { BlockActions(pickedBlock, calls, onRemoved = { picked = null }) }
            } else {
                PageTopBar(stringResource(Res.string.arrange_title), onBack = onBack) {
                    IconButton(calls.onLayouts) { Icon(Icons.Outlined.AutoAwesomeMosaic, stringResource(Res.string.blocks_layouts)) }
                    IconButton({ window = ArrangeWindow.Add }) { Icon(Icons.Outlined.Add, stringResource(Res.string.blocks_add)) }
                }
            }
            val list = @Composable { modifier: Modifier ->
                Column(modifier.verticalScroll(rememberScrollState()).padding(horizontal = PageGutter).padding(top = 4.dp, bottom = 24.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(stringResource(Res.string.arrange_hint), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
                    // A phone has no room for the page beside the list, so it folds out above it.
                    if (!wide) PagePreview(state) { window = ArrangeWindow.Add }
                    ReorderList(state.blocks, picked, onPick = { picked = if (picked == it) null else it }, calls, inlineActions = wide)
                    InkOutlinedButton({ window = ArrangeWindow.Add }, Modifier.fillMaxWidth()) {
                        Icon(Icons.Outlined.Add, null)
                        Text(stringResource(Res.string.blocks_add), Modifier.padding(start = 8.dp))
                    }
                }
            }
            if (wide) {
                Row(Modifier.weight(1f).fillMaxWidth()) {
                    list(Modifier.width(520.dp).fillMaxHeight())
                    Column(
                        Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .verticalScroll(rememberScrollState())
                            .padding(end = PageGutter, bottom = 24.dp),
                    ) {
                        AppSectionLabel(stringResource(Res.string.script_preview))
                        BlockGrid(state.blocks, BlockEnv(state.stats, state.recent, wide = false, onOpenTitle = {}), onAdd = { window = ArrangeWindow.Add })
                    }
                }
            } else {
                list(Modifier.weight(1f).fillMaxWidth())
            }
        }
    }
    val close = { window = ArrangeWindow.None }
    when (window) {
        ArrangeWindow.None -> Unit
        ArrangeWindow.Add -> AddBlockSheet(calls, state.context, BlockEnv(state.stats, state.recent, wide = false, onOpenTitle = {}), close)
    }
}
