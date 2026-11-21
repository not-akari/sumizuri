package com.sumizuri.app.feature.library.tile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.BiasAlignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.CoverPick
import com.sumizuri.app.ui.kit.cover.ReadProgress
import com.sumizuri.app.ui.kit.cover.badge.PickBadge
import com.sumizuri.app.ui.kit.cover.coverFlightFrom
import com.sumizuri.app.ui.text.displayName
import com.sumizuri.app.ui.theme.LocalThemeSpec

// The cover with its marks, the ring for picking, a thin bar of how far the reader is, and when asked the name over the bottom of it.
@Composable
internal fun TileCover(
    title: Title,
    context: TileContext,
    pick: CoverPick,
    nameOver: Boolean,
    aspect: Float = LocalThemeSpec.current.options.covers.aspect.ratio,
    marks: Boolean = true,
) {
    val progress = if (context.showProgress) title.readPart else null
    Column {
        Box {
            CoverArt(
                title,
                Modifier.coverFlightFrom(title.id).alpha(if (pick.picked) 0.55f else 1f),
                aspect = aspect,
                alignment = if (aspect > 1f) BiasAlignment(0f, -0.6f) else Alignment.Center,
            )
            if (nameOver) {
                Text(
                    title.displayName(),
                    Modifier
                        .align(Alignment.BottomStart)
                        .fillMaxWidth()
                        .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.72f))))
                        .padding(start = 8.dp, end = 8.dp, top = 22.dp, bottom = if (progress != null) 10.dp else 6.dp),
                    style = MaterialTheme.typography.labelMedium.scaled(context.nameScale),
                    color = Color.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            if (marks) CoverMarks(title, context, pick.picking)
            if (pick.picking) PickBadge(pick.picked, Modifier.align(Alignment.TopStart).padding(6.dp))
            if (progress != null) ReadProgress(progress, Modifier.align(Alignment.BottomCenter))
        }
    }
}
