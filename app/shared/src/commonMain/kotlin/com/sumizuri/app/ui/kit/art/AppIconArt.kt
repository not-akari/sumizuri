package com.sumizuri.app.ui.kit.art

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.inset
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.addPathNodes
import androidx.compose.ui.graphics.vector.toPath
import com.sumizuri.app.data.IconDesign
import com.sumizuri.app.data.IconPart

// How much of a launcher tile the ring takes, the part of the 108 wide icon a launcher shows being the middle 72.
const val ArtInTile = 0.875f

// The width of the launcher grid the shapes are measured on, and of the part of it inside the ring.
private const val Grid = 432f
private const val RingBox = 252f

// The shapes of the icon on the 432 wide grid of an adaptive launcher icon. scripts/app-icons.js draws the same ones.
private object IconShapes {
    private fun path(data: String): Path = addPathNodes(data).toPath()

    private fun band(drop: Float) = path(
        "M128,230 L128,${235 + drop} Q167.5,${220.5 + drop} 216,${242 + drop} Q250,${216 + drop} 306,${225 + drop} L306,220 Z",
    )

    val disc = path("M106.5,215.5 A109,109 0 1 1 324.5,215.5 A109,109 0 1 1 106.5,215.5 Z")
    val ring = path("M178.2,104.1 A117.5,117.5 0 1 1 128.9,136.1")
    val edgeDark = band(22f)
    val edgeLight = band(13f)
    val leftPage = path("M120,167 Q166.5,140.5 214,172 L214,242 Q167.5,220.5 121,235 Z")
    val rightPage = path("M215,170 Q263,136.5 311,159 L311,225 Q250,216 216,242 Z")
    val spine = path("M215,171 L215,242")
    val lines = path(
        "M132,181 Q159,169.5 198,186 M132,194 Q158,182 198,200 M133,208 Q158,196.5 200,213 " +
            "M226,184 Q250,166 280,173 M230,198 Q252,180 280,186 M232,212 Q254,194 288,199",
    )
}

// Draws the book in its ring in the colors of a design. Cut to the ring it fills the room it is given, and on the grid it sits where an adaptive launcher icon has it.
fun DrawScope.drawIconArt(design: IconDesign, onGrid: Boolean = false) {
    val box = if (onGrid) Grid else RingBox
    val shift = if (onGrid) 0f else -(Grid - RingBox) / 2f
    scale(size.minDimension / box, pivot = Offset.Zero) {
        translate(shift, shift) {
            fun part(p: IconPart) = Color(design.color(p))
            drawPath(IconShapes.disc, part(IconPart.Disc))
            if (design.ring) drawPath(IconShapes.ring, part(IconPart.Ring), style = Stroke(17f, cap = StrokeCap.Round))
            drawPath(IconShapes.edgeDark, part(IconPart.EdgeDark))
            drawPath(IconShapes.edgeLight, part(IconPart.EdgeLight))
            drawPath(IconShapes.leftPage, part(IconPart.LeftPage))
            drawPath(IconShapes.rightPage, part(IconPart.RightPage))
            drawPath(IconShapes.spine, part(IconPart.Spine), style = Stroke(3f))
            drawPath(IconShapes.lines, part(IconPart.Lines), style = Stroke(5.5f, cap = StrokeCap.Round))
        }
    }
}

// An icon drawn from a design: the book in its ring alone, or on its rounded tile of color as a launcher shows it.
class IconPainter(private val design: IconDesign, private val onTile: Boolean = false) : Painter() {
    override val intrinsicSize: Size get() = Size(256f, 256f)

    override fun DrawScope.onDraw() {
        if (!onTile) return drawIconArt(design)
        drawRoundRect(Color(design.color(IconPart.Back)), cornerRadius = CornerRadius(size.minDimension * 0.3f))
        inset(size.minDimension * (1f - ArtInTile) / 2f) { drawIconArt(design) }
    }
}

// The usual icon of the app, drawn so it stays sharp at any size.
val AppIconArt: Painter = IconPainter(IconDesign.Usual)

// An icon as a launcher shows it: its background filling the shape with the book in its ring in the middle.
@Composable
fun AppIconTile(design: IconDesign, shape: Shape, modifier: Modifier = Modifier) {
    val art = remember(design) { IconPainter(design) }
    Box(modifier.background(Color(design.color(IconPart.Back)), shape), contentAlignment = Alignment.Center) {
        Image(art, null, Modifier.fillMaxSize(ArtInTile))
    }
}
