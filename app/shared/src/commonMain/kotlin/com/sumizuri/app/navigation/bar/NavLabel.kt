package com.sumizuri.app.navigation.bar

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.art.StretchDot

// The name of a tab with a small bar under it that stretches out when the tab is chosen and shrinks away when another is.
@Composable
internal fun NavLabel(text: String, selected: Boolean, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        // One line, at most a fifth smaller where a long name or a big font would not fit, and cut with dots past that, so no letter falls to a second line and a big font stays big.
        val style = MaterialTheme.typography.labelMedium
        BasicText(
            text,
            style = style.copy(color = color, fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            autoSize = TextAutoSize.StepBased(minFontSize = style.fontSize * 0.8f, maxFontSize = style.fontSize),
        )
        StretchDot(selected, Modifier.padding(top = 3.dp), idle = 0.dp, wide = 18.dp, height = 4.dp)
    }
}
