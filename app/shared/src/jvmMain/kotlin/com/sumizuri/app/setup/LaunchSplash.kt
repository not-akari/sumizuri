package com.sumizuri.app.setup

import java.awt.AlphaComposite
import java.awt.BasicStroke
import java.awt.Color
import java.awt.RenderingHints
import java.awt.SplashScreen
import java.io.File
import javax.imageio.ImageIO
import kotlin.concurrent.thread
import kotlin.math.PI
import kotlin.math.cos

// The sizes of the picture Java picks from by the scale of the screen.
private val Sizes = listOf("", "@125pct", "@150pct", "@175pct", "@2x")

// Where the bar glides under the line of the picture, in its own points, and how long one pass takes.
private const val TrackLeft = 120f
private const val TrackRight = 220f
private const val TrackY = 196f
private const val BarWidth = 34f
private const val PassMs = 1400.0
private const val FrameMs = 16L

// The picture the launcher shows while the app starts, before any of its code runs, which closes on its own once the window of the app shows.
object LaunchSplash {
    // Closes it at once, for the runs that show a window of their own or none.
    fun close() {
        runCatching { SplashScreen.getSplashScreen()?.close() }
    }

    // Glides a small bar under its line until the window of the app takes its place.
    fun animate() {
        val splash = runCatching { SplashScreen.getSplashScreen() }.getOrNull() ?: return
        // The bar follows the picture that shows, which was picked at the start before, not the setting of Windows now.
        val dark = runCatching {
            val picture = ImageIO.read(splash.imageURL)
            val page = Color(picture.getRGB(picture.width / 2, picture.height / 10))
            page.red + page.green + page.blue < 384
        }.getOrDefault(true)
        val track = if (dark) Color(0x2A, 0x2D, 0x34) else Color(0xDD, 0xD8, 0xCC)
        val bar = if (dark) Color(0xE9, 0xDF, 0xAE) else Color(0x8A, 0x7A, 0x3A)
        thread(isDaemon = true, name = "splash") {
            val started = System.nanoTime()
            runCatching {
                while (splash.isVisible) {
                    val time = (System.nanoTime() - started) / 1_000_000.0
                    val g = splash.createGraphics()
                    g.composite = AlphaComposite.Clear
                    g.fillRect(0, 0, splash.size.width, splash.size.height)
                    g.composite = AlphaComposite.SrcOver
                    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON)
                    g.stroke = BasicStroke(2.5f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND)
                    g.color = track
                    g.draw(
                        java.awt.geom.Line2D
                            .Float(TrackLeft, TrackY, TrackRight, TrackY),
                    )
                    // The bar eases from one end to the other and back, as a calm pulse.
                    val eased = (1 - cos(time / PassMs * PI)) / 2
                    val left = TrackLeft + (TrackRight - TrackLeft - BarWidth) * eased.toFloat()
                    g.color = bar
                    g.draw(
                        java.awt.geom.Line2D
                            .Float(left, TrackY, left + BarWidth, TrackY),
                    )
                    g.dispose()
                    splash.update()
                    Thread.sleep(FrameMs)
                }
            }
        }
    }

    // Puts the light or dark picture in place to match Windows, for the next start, as the launcher reads it before any code can choose.
    fun follow(resources: File, dark: Boolean? = windowsDark()) {
        if (dark == null || !resources.isDirectory) return
        val look = if (dark) "dark" else "light"
        for (size in Sizes) {
            val from = File(resources, "splash-$look$size.png")
            val to = File(resources, "splash$size.png")
            if (!from.isFile) continue
            runCatching {
                if (!to.isFile ||
                    !to.readBytes().contentEquals(from.readBytes())
                ) {
                    from.copyTo(to, overwrite = true)
                }
            }
        }
    }

    // Whether Windows shows its apps dark, or null away from Windows.
    private fun windowsDark(): Boolean? {
        if (File.separatorChar != '\\') return null
        val light = runCatching {
            WinRegistry.number("Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize", "AppsUseLightTheme")
        }.getOrNull() ?: return null
        return light == 0
    }
}
