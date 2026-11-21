package com.sumizuri.app.ui.kit.text

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator

// A quiet line of text across the page, in the color of errors when something went wrong.
@Composable
fun NoteText(text: String, modifier: Modifier = Modifier, error: Boolean = false) {
    Text(
        text,
        modifier.fillMaxWidth().padding(vertical = 4.dp),
        style = MaterialTheme.typography.bodyMedium,
        color = if (error) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.outline,
    )
}

// A small turning ring with what is being done beside it.
@Composable
fun WorkingRow(text: String, modifier: Modifier = Modifier) {
    Row(
        modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        InkCircularProgressIndicator(Modifier.size(20.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium)
    }
}
