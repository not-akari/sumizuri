package com.sumizuri.app.ui.kit.art

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.PathBuilder
import androidx.compose.ui.graphics.vector.group
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

// The icon of the app drawn as shapes so it stays sharp at any size, measured from the launcher icon on its 432 wide grid and cut to the ring.
val AppIconArt: ImageVector by lazy {
    ImageVector
        .Builder("AppIcon", 64.dp, 64.dp, viewportWidth = 252f, viewportHeight = 252f)
        .apply {
            group(translationX = -89.5f, translationY = -89.5f) {
                path(fill = SolidColor(Color(0xFF1A1D24))) { circle(215.5f, 215.5f, 109f) }
                path(stroke = SolidColor(Color(0xFFE8E0B0)), strokeLineWidth = 17f, strokeLineCap = StrokeCap.Round) {
                    moveTo(178.2f, 104.1f)
                    arcTo(117.5f, 117.5f, 0f, isMoreThanHalf = true, isPositiveArc = true, 128.9f, 136.1f)
                }
                path(fill = SolidColor(Color(0xFF8E8A7E))) { band(drop = 22f) }
                path(fill = SolidColor(Color(0xFFB4B0A2))) { band(drop = 13f) }
                path(fill = SolidColor(Color(0xFFF4F1E4))) {
                    moveTo(120f, 167f)
                    quadTo(166.5f, 140.5f, 214f, 172f)
                    lineTo(214f, 242f)
                    quadTo(167.5f, 220.5f, 121f, 235f)
                    close()
                }
                path(fill = SolidColor(Color(0xFFD9D6CA))) {
                    moveTo(215f, 170f)
                    quadTo(263f, 136.5f, 311f, 159f)
                    lineTo(311f, 225f)
                    quadTo(250f, 216f, 216f, 242f)
                    close()
                }
                path(stroke = SolidColor(Color(0xFFBEBBAF)), strokeLineWidth = 3f) {
                    moveTo(215f, 171f)
                    lineTo(215f, 242f)
                }
                path(stroke = SolidColor(Color(0xFFB8B5A9)), strokeLineWidth = 5.5f, strokeLineCap = StrokeCap.Round) {
                    line(132f, 181f, 159f, 169.5f, 198f, 186f)
                    line(132f, 194f, 158f, 182f, 198f, 200f)
                    line(133f, 208f, 158f, 196.5f, 200f, 213f)
                    line(226f, 184f, 250f, 166f, 280f, 173f)
                    line(230f, 198f, 252f, 180f, 280f, 186f)
                    line(232f, 212f, 254f, 194f, 288f, 199f)
                }
            }
        }.build()
}

private fun PathBuilder.circle(x: Float, y: Float, radius: Float) {
    moveTo(x - radius, y)
    arcTo(radius, radius, 0f, isMoreThanHalf = true, isPositiveArc = true, x + radius, y)
    arcTo(radius, radius, 0f, isMoreThanHalf = true, isPositiveArc = true, x - radius, y)
    close()
}

// One edge of the pages under the open book, the given distance below the bottom of the pages. Its top hides under them.
private fun PathBuilder.band(drop: Float) {
    moveTo(128f, 230f)
    lineTo(128f, 235f + drop)
    quadTo(167.5f, 220.5f + drop, 216f, 242f + drop)
    quadTo(250f, 216f + drop, 306f, 225f + drop)
    lineTo(306f, 220f)
    close()
}

// One written line on a page, as a soft curve.
private fun PathBuilder.line(x0: Float, y0: Float, cx: Float, cy: Float, x1: Float, y1: Float) {
    moveTo(x0, y0)
    quadTo(cx, cy, x1, y1)
}
