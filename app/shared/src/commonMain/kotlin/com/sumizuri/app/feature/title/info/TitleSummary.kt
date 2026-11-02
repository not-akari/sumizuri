package com.sumizuri.app.feature.title.info

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.text.style.TextOverflow
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.less
import com.sumizuri.app.shared.resources.more
import org.jetbrains.compose.resources.stringResource

private const val ShortLines = 3

// The description cut to a few lines. A tap opens it in full, or when onMore is given, goes to where the whole description is.
@Composable
internal fun TitleSummary(
    text: String,
    modifier: Modifier = Modifier,
    lines: Int = ShortLines,
    onMore: (() -> Unit)? = null,
    overCover: Boolean = false,
) {
    var open by rememberSaveable { mutableStateOf(false) }
    val colors = MaterialTheme.colorScheme
    // Over the cover the text is a step brighter with a glow of the page colour, so a busy picture does not swallow it.
    val glow = if (overCover) Shadow(colors.background, blurRadius = 24f) else null
    Column(modifier.clickable { if (onMore != null) onMore() else open = !open }.animateContentSize()) {
        Text(
            text,
            style = MaterialTheme.typography.bodyMedium.copy(shadow = glow),
            color = if (overCover) colors.onSurface.copy(alpha = 0.9f) else colors.onSurfaceVariant,
            maxLines = if (open) Int.MAX_VALUE else lines,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            if (open) stringResource(Res.string.less) else stringResource(Res.string.more),
            style = MaterialTheme.typography.labelMedium.copy(shadow = glow),
            color = colors.primary,
        )
    }
}
