package com.sumizuri.app.data.appupdate

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.setup.StartApart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import java.awt.Desktop
import java.io.File

private const val Tag = "appupdate"

private val onWindows = System
    .getProperty("os.name")
    .orEmpty()
    .lowercase()
    .startsWith("win")

actual object UpdateInstaller {
    // The installer for this system: an MSI or EXE on Windows, a DMG or PKG on a Mac, and a package or AppImage on Linux.
    actual fun pick(assets: List<ReleaseAsset>): ReleaseAsset? {
        val system = System.getProperty("os.name").orEmpty().lowercase()
        val kinds = when {
            "win" in system -> listOf(".msi", ".exe")
            "mac" in system -> listOf(".dmg", ".pkg")
            else -> listOf(".deb", ".rpm", ".appimage", ".tar.gz")
        }
        return kinds.firstNotNullOfOrNull { kind -> assets.firstOrNull { it.name.lowercase().endsWith(kind) } }
    }

    actual fun folder(): Path = FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-updates"

    // Opens the installer, which closes the app when it needs to replace its files. Starting a program apart waits for Windows, so it is done away from the screen.
    actual suspend fun install(file: String): InstallResult = withContext(Dispatchers.IO) {
        val installer = File(file)
        // On Windows the launcher runs the app inside a job that ends everything the app starts. A setup opened the usual way would be in that job, so it could not close the app to replace its files. It is started apart instead.
        if (onWindows &&
            StartApart.start("\"${installer.absolutePath}\"", installer.absoluteFile.parentFile, hidden = false)
        ) {
            AppLog.info(Tag, "started the setup ${installer.name} apart from the app")
            return@withContext InstallResult.Started
        }
        if (!Desktop.isDesktopSupported() || !Desktop.getDesktop().isSupported(Desktop.Action.OPEN)) {
            AppLog.warn(Tag, "this system cannot open ${installer.name}")
            return@withContext InstallResult.Failed
        }
        runCatching { Desktop.getDesktop().open(installer) }.fold(
            {
                AppLog.info(Tag, "opened ${installer.name}")
                InstallResult.Started
            },
            {
                AppLog.warn(Tag, "could not open ${installer.name}, ${it.message}")
                InstallResult.Failed
            },
        )
    }
}
