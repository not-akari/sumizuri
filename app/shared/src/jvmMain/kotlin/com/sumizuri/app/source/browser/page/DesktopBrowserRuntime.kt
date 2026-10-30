package com.sumizuri.app.source.browser.page

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.net.Network
import dev.datlag.kcef.KCEF
import dev.datlag.kcef.KCEFBuilder
import dev.datlag.kcef.KCEFClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.io.File

// Starts the embedded Chromium on first use, and downloads it first if it is missing.
class DesktopBrowserRuntime(
    private val installDir: File,
    // Kept apart from the install so a second copy of the app can use its own.
    private val cacheDir: File = File(installDir, "cache"),
    private val onProgress: (String) -> Unit = {},
) {
    private val lock = Mutex()
    private var failure: String? = null

    // The start of the browser runs on its own, so the request that happened to need it first can be cancelled without cutting a download or an unpacking in half, which left a broken install behind. Every request waits for the same start.
    private val starter = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var starting: Deferred<String?>? = null

    suspend fun client(): KCEFClient {
        requireOpenModules()
        requireNoBuiltInBrowser()
        val start = lock.withLock { starting ?: starter.async { start() }.also { starting = it } }
        start.await()?.let { throw BrowserUnavailableException(it) }
        return KCEF.newClientOrNull() ?: throw BrowserUnavailableException("Could not start the embedded browser.")
    }

    // Starts the browser once, downloading and unpacking it first when it is missing. Gives why it could not start, or null.
    private suspend fun start(): String? {
        AppLog.info(
            TAG,
            "starting the embedded browser, folder ${installDir.absolutePath}, java ${System.getProperty(
                "java.version",
            )}, ${System.getProperty("java.vendor")}",
        )
        clearBrokenInstall()
        trimBrowserFolder(cacheDir)
        var lastTen = -1
        try {
            KCEF.init(
                builder = {
                    // The browser goes through the router of the app too, which picks the way for each site. It is told once as it starts, so turning the router on or off takes a restart of the app.
                    val proxy = Network.routerPort?.let { listOf("--proxy-server=socks5://127.0.0.1:$it") }.orEmpty()
                    // Chromium only reads its switches from the app handler, the list given to the start is dropped on Windows and Linux.
                    appHandler(KCEF.AppHandler((proxy + TrimmedSwitches).toTypedArray()))
                    installDir(installDir)
                    progress {
                        onDownloading { percent ->
                            // Said once for every tenth, where every small step used to fill the log.
                            val ten = percent.toInt() / 10
                            if (ten != lastTen) {
                                lastTen = ten
                                AppLog.info(TAG, "downloading the browser, ${ten * 10} percent")
                            }
                            onProgress("Downloading the browser, ${percent.toInt()} percent")
                        }
                        onExtracting {
                            AppLog.info(TAG, "unpacking the browser")
                            onProgress("Unpacking the browser")
                        }
                        onInitialized {
                            AppLog.info(TAG, "the browser engine is ready")
                            onProgress("Browser ready")
                        }
                    }
                    settings {
                        locale = "en-US"
                        // Only errors go to the log file of Chromium, which kept growing in the cache folder.
                        logSeverity = KCEFBuilder.Settings.LogSeverity.Error
                        // Chromium cannot find these from where the Java runtime is on Windows and Linux, so they are named here. On a Mac they sit inside the framework of Chromium, which the browser finds on its own, and naming other folders made it start on a null pointer.
                        if (!isMac) {
                            localesDirPath = File(installDir, "locales").absolutePath
                            resourcesDirPath = installDir.absolutePath
                            listOf("jcef_helper.exe", "jcef_helper")
                                .map { File(installDir, it) }
                                .firstOrNull { it.exists() }
                                ?.let { browserSubProcessPath = it.absolutePath }
                        }
                        // Kept on disk, so a bot check that was passed once stays passed.
                        cachePath = cacheDir.absolutePath
                    }
                },
                onError = { error ->
                    AppLog.error(TAG, "the browser engine reported an error", error)
                    failure = "Could not start the embedded browser: ${error?.message}"
                },
                onRestartRequired = {
                    AppLog.warn(TAG, "the browser was installed and the app must be restarted")
                    failure = "The embedded browser was installed. Restart the app to start it."
                },
            )
        } catch (error: Exception) {
            AppLog.error(TAG, "the browser engine could not be started", error)
            failure = "Could not start the embedded browser: ${error.message}"
        }
        return failure
    }

    // An unpacking that was cut short leaves the files of Chromium without the program it starts its helpers with, and the browser then never starts. Such a folder is cleared so the next start installs it again, and the cache with the passed bot checks stays.
    private fun clearBrokenInstall() {
        val windowsOrLinux = System.getProperty("os.name").orEmpty().let {
            it.startsWith("Windows") ||
                it.startsWith("Linux")
        }
        if (!windowsOrLinux || !installDir.isDirectory) return
        val parts = installDir.listFiles().orEmpty().filter { it.name != cacheDir.name }
        if (parts.isEmpty()) return
        val helper = listOf("jcef_helper.exe", "jcef_helper").any { File(installDir, it).exists() }
        if (helper) return
        AppLog.warn(TAG, "the browser folder holds an unfinished install, clearing it to install again")
        parts.forEach { runCatching { it.deleteRecursively() } }
    }

    suspend fun dispose() = KCEF.dispose()

    // The browser reaches into parts of the Java desktop library, and a Java that keeps them closed makes it hang without a word.
    private fun requireOpenModules() {
        val desktop = ModuleLayer.boot().findModule("java.desktop").orElse(null) ?: return
        val ours = DesktopBrowserRuntime::class.java.module
        val closed = listOf("sun.awt", "java.awt.peer").filter { !desktop.isOpen(it, ours) }
        if (closed.isEmpty()) return
        val options = closed.joinToString(" ") { "--add-opens java.desktop/$it=ALL-UNNAMED" }
        AppLog.error(TAG, "these Java options are missing, $options")
        throw BrowserUnavailableException(
            "The embedded browser needs these Java options, $options. Start the app with the Gradle run tasks, or add them to the run configuration.",
        )
    }

    // A JetBrains Runtime with its own browser module replaces the one the app ships, and the page is then never created.
    private fun requireNoBuiltInBrowser() {
        if (ModuleLayer.boot().findModule("jcef").isEmpty) return
        AppLog.error(
            TAG,
            "this Java has its own browser module, which replaces the one the app uses, runtime ${System.getProperty(
                "java.home",
            )}",
        )
        throw BrowserUnavailableException(
            "This Java comes with its own browser module, which breaks the embedded browser. Run the app with a plain JDK 21, for example with the Gradle run task, and not with the hot reload run.",
        )
    }

    private companion object {
        const val TAG = "desktop-browser"
        val isMac = System.getProperty("os.name").orEmpty().startsWith("Mac")
    }
}
