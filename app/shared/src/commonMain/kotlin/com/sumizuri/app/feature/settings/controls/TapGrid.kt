package com.sumizuri.app.feature.settings.controls

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.controls.ReaderAction
import com.sumizuri.app.data.model.controls.TapGeometry
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tap_zone_nothing
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import org.jetbrains.compose.resources.stringResource

// A bar never gets thinner than this share, so a cell can always be tapped.
private const val Thinnest = 0.05f

// The grid of the screen as the reader sees it, nine cells with the bands sized as chosen. A cell shows what a tap on it does and opens a list to choose another action.
@Composable
internal fun TapGrid(zones: List<ReaderAction?>, geometry: TapGeometry, onZone: (Int, ReaderAction?) -> Unit) {
    val rows = listOf(geometry.edgeY, 1f - 2 * geometry.edgeY, geometry.edgeY)
    val columns = listOf(geometry.edgeX, 1f - 2 * geometry.edgeX, geometry.edgeX)
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        Column(Modifier.width(260.dp).height(380.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            rows.forEachIndexed { row, rowShare ->
                Row(
                    Modifier.weight(rowShare.coerceAtLeast(Thinnest)).fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    columns.forEachIndexed { column, columnShare ->
                        val zone = row * 3 + column
                        Cell(
                            zones[zone],
                            Modifier.weight(columnShare.coerceAtLeast(Thinnest)).fillMaxSize(),
                        ) { onZone(zone, it) }
                    }
                }
            }
        }
    }
}

@Composable
private fun Cell(action: ReaderAction?, modifier: Modifier, onPick: (ReaderAction?) -> Unit) {
    var open by remember { mutableStateOf(false) }
    val colors = MaterialTheme.colorScheme
    Box(modifier) {
        Surface(
            { open = true },
            Modifier.fillMaxSize(),
            shape = MaterialTheme.shapes.small,
            color = if (action == null) colors.surfaceContainer else colors.primaryContainer.copy(alpha = 0.55f),
            border = BorderStroke(1.dp, colors.outlineVariant),
        ) {
            Box(Modifier.padding(4.dp), contentAlignment = Alignment.Center) {
                Text(
                    stringResource(action?.label ?: Res.string.tap_zone_nothing),
                    style = MaterialTheme.typography.labelSmall,
                    textAlign = TextAlign.Center,
                    color = if (action == null) colors.outline else colors.onSurface,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        AppMenu(open, { open = false }) {
            AppMenuItem({ Text(stringResource(Res.string.tap_zone_nothing)) }, {
                open = false
                onPick(null)
            })
            for (choice in ReaderAction.entries) {
                AppMenuItem({ Text(stringResource(choice.label)) }, {
                    open = false
                    onPick(choice)
                })
            }
        }
    }
}
