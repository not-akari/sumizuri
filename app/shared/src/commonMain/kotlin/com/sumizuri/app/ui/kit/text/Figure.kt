package com.sumizuri.app.ui.kit.text

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp

// How big a figure is: large for a card of its own, medium for a row of them, small for a figure inside a card.
enum class FigureSize { Large, Medium, Small }

// A number large with what it counts under it. A large one with a long number gets a little smaller so it stays on one line.
@Composable
fun Figure(value: String, label: String, modifier: Modifier = Modifier, size: FigureSize = FigureSize.Medium) {
    val colors = MaterialTheme.colorScheme
    val type = MaterialTheme.typography
    val small = size == FigureSize.Small
    Column(modifier, horizontalAlignment = if (small) Alignment.CenterHorizontally else Alignment.Start) {
        Text(
            value,
            style = when (size) {
                FigureSize.Large -> type.headlineMedium.copy(fontSize = if (value.length > 6) 20.sp else 28.sp)
                FigureSize.Medium -> type.titleLarge
                FigureSize.Small -> type.titleMedium
            },
            fontWeight = if (small) FontWeight.Bold else FontWeight.ExtraBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        // The name of a large figure may take two lines, so a narrow phone shows it whole.
        Text(
            label,
            style = when (size) {
                FigureSize.Large -> type.bodySmall
                FigureSize.Medium -> type.labelMedium
                FigureSize.Small -> type.labelSmall
            },
            color = if (small) colors.outline else colors.onSurfaceVariant,
            textAlign = if (small) TextAlign.Center else TextAlign.Start,
            maxLines = if (size == FigureSize.Large) 2 else Int.MAX_VALUE,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
