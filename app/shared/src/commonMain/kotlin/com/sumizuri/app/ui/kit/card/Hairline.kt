package com.sumizuri.app.ui.kit.card

import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

// The thin line that parts rows and bars, in the outline color of the theme a little see through.
@Composable
fun Hairline(modifier: Modifier = Modifier, alpha: Float = 0.6f) {
    HorizontalDivider(modifier, color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = alpha))
}
