package com.sumizuri.app.data.sync

import androidx.compose.runtime.Composable
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.navigation.AppLinks
import com.sumizuri.app.shared.resources.Res
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.awt.SystemTray
import java.awt.TrayIcon
import java.awt.image.BufferedImage
import javax.imageio.ImageIO

// How long the icon that carries a notice stays in the tray, so the notice can be read and clicked away.
private const val TrayMs = 15_000L

// A computer has no system that runs the app while it is closed. The app checks while it is open and shows a notice of the system itself.
actual object UpdatePlatform {
    actual val runsInBackground: Boolean = false
    actual val noticeFromApp: Boolean = true

    actual fun plan(plan: UpdatePlan) = Unit

    actual suspend fun showNews(news: List<ChapterNews>) {
        if (news.isEmpty()) return
        val (head, lines) = newsWords(news, lines = 3)
        // A click on the notice opens the updates in the window, brought to the front.
        showTrayNotice(head, lines.joinToString("\n")) { AppLinks.open("${AppLinks.Scheme}://updates") }
    }
}

// Shows a notice with an icon put in the tray of the system for a short while, since that is how Java shows one. A click brings the window to the front after doing what it is given.
internal suspend fun showTrayNotice(head: String, text: String, onClick: () -> Unit = {}) {
    if (!SystemTray.isSupported()) return
    val image =
        runCatching { ImageIO.read(Res.readBytes("drawable/app_icon.png").inputStream()) }.getOrNull()
            ?: BufferedImage(16, 16, BufferedImage.TYPE_INT_ARGB)
    withContext(Dispatchers.IO) {
        val tray = SystemTray.getSystemTray()
        val icon = TrayIcon(image, "Sumizuri").apply {
            isImageAutoSize = true
            addActionListener {
                onClick()
                DesktopFront.bring()
            }
        }
        try {
            tray.add(icon)
            icon.displayMessage(head, text, TrayIcon.MessageType.INFO)
            delay(TrayMs)
        } catch (error: Exception) {
            AppLog.warn("updates", "the notice could not be shown, ${error.message}")
        } finally {
            runCatching { tray.remove(icon) }
        }
    }
}

@Composable
actual fun rememberNoticePermission(): () -> Unit = {}

// Brings the window of the app to the front, set by the window once it is made.
object DesktopFront {
    var bring: () -> Unit = {}
}
