package com.sumizuri.app.feature.title.layout

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.info.ContinueBlock
import com.sumizuri.app.feature.title.info.TitleHeading
import com.sumizuri.app.feature.title.info.TitleSummary
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.coverFlightTo
import com.sumizuri.app.ui.theme.LocalThemeSpec

// The top of the wide page: the cover with its shadow, and beside it the name, the facts and the description, with the continue button and the tiles along the bottom edge of the cover. A title that cannot be read has no continue button.
@Composable
internal fun WideBanner(state: TitleState, title: Title, calls: TitleCallbacks, onPreview: () -> Unit) {
    Row(
        Modifier.padding(top = 20.dp, bottom = 28.dp).fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(36.dp),
    ) {
        CoverArt(
            title,
            Modifier
                .width(
                    220.dp,
                ).coverFlightTo(title.id)
                .shadow(14.dp, MaterialTheme.shapes.small)
                .clickable(onClick = onPreview),
            letterSize = 56,
        )
        // At least as tall as the cover, so the buttons sit at its foot, and taller when the words need it, so they are never squashed.
        Column(
            Modifier.weight(1f).heightIn(min = 220.dp / LocalThemeSpec.current.options.covers.aspect.ratio),
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                TitleHeading(state, title, wide = true)
                if (title.summary.isNotBlank()) TitleSummary(title.summary, Modifier.widthIn(max = 760.dp), lines = 4)
            }
            Column(Modifier.padding(top = 16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                ContinueBlock(state, title, calls, Modifier.widthIn(max = 520.dp))
            }
        }
    }
}
