package com.sumizuri.app.playback

import android.graphics.Color
import android.graphics.Typeface
import android.util.TypedValue
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.PlayerView
import com.sumizuri.app.data.model.player.SubtitleBackground

@Composable
actual fun PlayerSurface(engine: PlayerEngine, aspect: AspectMode, modifier: Modifier) {
    val exo = engine as? ExoEngine ?: return
    val style by exo.style.collectAsState()
    val lifted by exo.lift.collectAsState()
    val lit = exo.ambient
        .collectAsState()
        .value
        .isNotEmpty()
    var shown by remember { mutableStateOf<PlayerView?>(null) }
    LaunchedEffect(shown) { shown?.let { readAmbient(it, exo) } }
    AndroidView(
        factory = { context ->
            PlayerView(context)
                .apply {
                    useController = false
                    player = exo.exo
                    setShutterBackgroundColor(Color.BLACK)
                }.also { shown = it }
        },
        modifier = modifier,
        update = { view ->
            // The bars around the picture stay clear while the light around the video shows behind them.
            val back = if (lit) Color.TRANSPARENT else Color.BLACK
            view.setBackgroundColor(back)
            view.setShutterBackgroundColor(back)
            view.resizeMode = when (aspect) {
                AspectMode.Fit -> AspectRatioFrameLayout.RESIZE_MODE_FIT
                AspectMode.Fill -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                AspectMode.Stretch -> AspectRatioFrameLayout.RESIZE_MODE_FILL
            }
            view.subtitleView?.let { subtitles ->
                val box = style.background == SubtitleBackground.Box
                val edge = if (style.background ==
                    SubtitleBackground.Outline
                ) {
                    CaptionStyleCompat.EDGE_TYPE_DROP_SHADOW
                } else {
                    CaptionStyleCompat.EDGE_TYPE_NONE
                }
                subtitles.setStyle(
                    CaptionStyleCompat(
                        style.color.toInt(),
                        if (box) 0xB3000000.toInt() else Color.TRANSPARENT,
                        Color.TRANSPARENT,
                        edge,
                        Color.BLACK,
                        if (style.bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT,
                    ),
                )
                subtitles.setFixedTextSize(TypedValue.COMPLEX_UNIT_SP, style.sizeSp.toFloat())
                // The room under the letters is a part of the height of the picture.
                val density = view.resources.displayMetrics.density
                val height = (view.height / density).takeIf { it > 0 } ?: 360f
                val room = SubtitleStyle.RaiseDp[style.raise.coerceIn(0, 2)]
                subtitles.setBottomPaddingFraction((room / height + lifted).coerceIn(0.02f, 0.5f))
            }
        },
    )
}
