package com.sumizuri.app.feature.sync.signin

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

// A key of groups such as ABCD-EFGH, wrapped only between groups, so no group is ever broken in two across lines.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun KeyGroups(key: String) {
    val groups = key.split('-')
    FlowRow(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        groups.forEachIndexed { index, group ->
            Text(
                if (index < groups.lastIndex) "$group-" else group,
                style = MaterialTheme.typography.titleMedium,
                fontFamily = FontFamily.Monospace,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}
