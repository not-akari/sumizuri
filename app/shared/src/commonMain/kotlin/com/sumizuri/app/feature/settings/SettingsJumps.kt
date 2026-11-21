package com.sumizuri.app.feature.settings

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.SoftChip
import com.sumizuri.app.ui.kit.page.PageGutter
import kotlinx.coroutines.launch

// The parts of a long page of the settings that its pills jump to: where each part sits in the scrolling column, the column itself, and its scroll.
internal class PageJumps(val scroll: ScrollState) {
    val places = mutableStateMapOf<String, LayoutCoordinates>()
    var content by mutableStateOf<LayoutCoordinates?>(null)

    // How far down the column a part starts, or null before it was laid out.
    fun top(name: String): Int? {
        val column = content ?: return null
        val place = places[name] ?: return null
        if (!column.isAttached || !place.isAttached) return null
        return column.localPositionOf(place, Offset.Zero).y.toInt()
    }
}

// The jumps of the page the content is on, or null on a page that has none, such as a sheet.
internal val LocalPageJumps = compositionLocalOf<PageJumps?> { null }

// One part of a long page: its name as a heading and its settings under it, which a pill of the page scrolls to the top.
@Composable
internal fun JumpSection(name: String, content: @Composable ColumnScope.() -> Unit) {
    val jumps = LocalPageJumps.current
    DisposableEffect(jumps, name) { onDispose { jumps?.places?.remove(name) } }
    Column(
        Modifier.fillMaxWidth().onGloballyPositioned { jumps?.places?.set(name, it) },
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text(
            name,
            Modifier.padding(start = 4.dp, top = 10.dp),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
        )
        content()
    }
}

// The names of the parts of the page as pills under its bar. A tap scrolls that part to the top, and the pill of the part being read is marked as the page scrolls.
@Composable
internal fun JumpPills(names: List<String>, jumps: PageJumps) {
    val scope = rememberCoroutineScope()
    val shown by remember(names, jumps) {
        derivedStateOf {
            val now = jumps.scroll.value + 24
            names.lastOrNull { name -> (jumps.top(name) ?: Int.MAX_VALUE) <= now } ?: names.firstOrNull()
        }
    }
    ChipRow(Modifier.padding(horizontal = PageGutter).padding(bottom = 8.dp)) {
        for (name in names) {
            SoftChip(name == shown, {
                jumps.top(name)?.let { y -> scope.launch { jumps.scroll.animateScrollTo(y) } }
            }, { Text(name) })
        }
    }
}
