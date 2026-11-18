package com.sumizuri.app.feature.trackers

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tracker_anilist
import com.sumizuri.app.shared.resources.tracker_kitsu
import com.sumizuri.app.shared.resources.tracker_mal
import org.jetbrains.compose.resources.DrawableResource
import org.jetbrains.compose.resources.painterResource

// The logo of a tracker on the tile of its own color, as on its own site, so it reads the same on a light and a dark page. A tracker with no logo of its own shows its short name.
@Composable
internal fun TrackerLogo(tracker: TrackerId, size: Dp = 36.dp) {
    Box(
        Modifier.size(size).background(tileOf(tracker), RoundedCornerShape(size * 0.24f)),
        contentAlignment = Alignment.Center,
    ) {
        val logo = logoOf(tracker)
        if (logo != null) {
            Image(painterResource(logo), tracker.label, Modifier.size(size * 0.78f))
        } else {
            Text(
                shortOf(tracker),
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = (size.value * 0.36f).sp,
            )
        }
    }
}

private fun tileOf(tracker: TrackerId): Color = when (tracker) {
    TrackerId.AniList -> Color(0xFF152232)
    TrackerId.Mal -> Color(0xFF2F52A2)
    TrackerId.Kitsu -> Color(0xFFF75239)
    TrackerId.MangaBaka -> Color(0xFF1F4A4F)
}

// MangaBaka has only a picture of a character from an anime as its icon, which is not its own to give, so it has its short name.
private fun logoOf(tracker: TrackerId): DrawableResource? = when (tracker) {
    TrackerId.AniList -> Res.drawable.tracker_anilist
    TrackerId.Mal -> Res.drawable.tracker_mal
    TrackerId.Kitsu -> Res.drawable.tracker_kitsu
    TrackerId.MangaBaka -> null
}

private fun shortOf(tracker: TrackerId): String = when (tracker) {
    TrackerId.MangaBaka -> "MB"
    else -> tracker.label.take(2)
}
