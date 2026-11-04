package com.sumizuri.app.data

// One part of the icon a person can color, in the order the editor lists them.
enum class IconPart { Back, Disc, Ring, LeftPage, RightPage, Spine, Lines, EdgeLight, EdgeDark }

// The icon as a person made it: a color for every part, and no ring when the ring has none. Colors are kept as 0xAARRGGBB.
data class IconDesign(val colors: Map<IconPart, Long>, val ring: Boolean = true) {
    fun color(part: IconPart): Long = colors[part] ?: Usual.colors.getValue(part)

    fun with(part: IconPart, color: Long?): IconDesign = when {
        part == IconPart.Ring && color == null -> copy(ring = false)
        color == null -> copy(colors = colors + (part to Usual.color(part)))
        else -> copy(colors = colors + (part to color), ring = ring || part == IconPart.Ring)
    }

    // How it is kept: the colors in the order of the parts, then whether it has a ring.
    fun encode(): String =
        IconPart.entries.joinToString(",") { color(it).toString(16) } + "," + (if (ring) "1" else "0")

    // The built-in icon closest to it, which the Android launcher shows, as it can only switch between icons made beforehand.
    fun closest(): AppIcon {
        val back = IconBack.entries.minBy { distance(it.color, color(IconPart.Back)) }
        val book = IconBook.entries.minBy {
            distance(it.disc, color(IconPart.Disc)) + distance(it.leftPage, color(IconPart.LeftPage)) +
                distance(it.lines, color(IconPart.Lines))
        }
        val ringColor = color(IconPart.Ring)
        val ring = if (!ring) {
            IconRing.None
        } else {
            IconRing.entries
                .filter {
                    it.color != null
                }.minBy { distance(it.color!!, ringColor) }
        }
        return AppIcon(back, book, ring)
    }

    companion object {
        val Usual: IconDesign = of(AppIcon.Usual)

        // A built-in icon as a design to start from.
        fun of(icon: AppIcon): IconDesign = IconDesign(
            mapOf(
                IconPart.Back to icon.back.color,
                IconPart.Disc to icon.book.disc,
                IconPart.Ring to (icon.ring.color ?: IconRing.Cream.color!!),
                IconPart.LeftPage to icon.book.leftPage,
                IconPart.RightPage to icon.book.rightPage,
                IconPart.Spine to icon.book.spine,
                IconPart.Lines to icon.book.lines,
                IconPart.EdgeLight to icon.book.edgeLight,
                IconPart.EdgeDark to icon.book.edgeDark,
            ),
            ring = icon.ring != IconRing.None,
        )

        fun decode(text: String?): IconDesign? {
            val parts = text?.split(",") ?: return null
            if (parts.size != IconPart.entries.size + 1) return null
            val colors = IconPart.entries
                .mapIndexed { index, part ->
                    part to
                        (parts[index].toLongOrNull(16) ?: return null)
                }.toMap()
            return IconDesign(colors, ring = parts.last() == "1")
        }
    }
}

// How far apart two colors are, by their red, green and blue.
private fun distance(a: Long, b: Long): Long {
    fun channel(color: Long, shift: Int) = (color shr shift) and 0xFF
    return listOf(16, 8, 0).sumOf { shift -> (channel(a, shift) - channel(b, shift)).let { it * it } }
}
