package com.sumizuri.app

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.window.WindowDraggableArea
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowPlacement
import androidx.compose.ui.window.WindowState
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import com.sumizuri.app.core.AppBuild
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.FileLogSink
import com.sumizuri.app.data.AppContainer
import com.sumizuri.app.data.db.databaseBuilder
import com.sumizuri.app.data.profile.ProfileHost
import com.sumizuri.app.data.profile.ProfileRegistry
import com.sumizuri.app.data.sync.DesktopFront
import com.sumizuri.app.navigation.AppLinks
import com.sumizuri.app.playback.LocalFullscreen
import com.sumizuri.app.playback.LocalMiniPlayer
import com.sumizuri.app.setup.ClassArchive
import com.sumizuri.app.setup.LaunchSplash
import com.sumizuri.app.setup.SetupMode
import com.sumizuri.app.setup.refreshAppLinks
import com.sumizuri.app.setup.runSetup
import com.sumizuri.app.setup.warmUp
import com.sumizuri.app.source.browser.page.DesktopBrowserRuntime
import com.sumizuri.app.source.browser.page.DesktopChallengeSolver
import com.sumizuri.app.source.browser.page.DesktopRenderPageFactory
import com.sumizuri.app.ui.kit.web.DesktopWeb
import com.sumizuri.app.ui.kit.window.WindowBar
import com.sumizuri.app.ui.kit.window.appIcon
import com.sumizuri.app.ui.text.appName
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import okio.Path.Companion.toPath
import org.jetbrains.skia.Graphics
import java.awt.Desktop
import java.awt.Dimension
import java.awt.GraphicsEnvironment
import java.awt.Toolkit
import java.beans.PropertyChangeListener
import java.io.File
import kotlin.concurrent.thread
import kotlin.math.max
import kotlin.math.sqrt
import kotlin.system.exitProcess

// macOS and Linux use the system frame, and Windows uses the bar and resize handles the app draws.
private val isMac = System.getProperty("os.name").orEmpty().startsWith("Mac")

// The smallest the window can be made, in pixels.
private const val MinWidth = 640
private const val MinHeight = 480

// How much Skia may keep of its drawing work and of the shapes of letters.
private const val SkiaWorkBytes = 24 * 1024 * 1024
private const val SkiaLetterBytes = 4 * 1024 * 1024
private const val LinuxMinimumUiScale = 1.2f
internal val isLinux = System.getProperty("os.name").lowercase().contains("linux")

fun main(args: Array<String>) {
    // A run from Gradle is the debug build, which shows Debug in its name and a red icon.
    AppBuild.isDebug = System.getProperty("sumizuri.debug") == "true"
    // Skia keeps little of its drawing work: shapes, shadows and blurs that are cheap to make again, and the shapes of letters. The pictures of covers and pages have caches of their own with limits the person sets.
    Graphics.resourceCacheTotalLimit = SkiaWorkBytes
    Graphics.fontCacheLimit = SkiaLetterBytes
    // The installer starts the app with --setup to show its own setup, and Windows starts it with --uninstall to take it away. Neither opens the library. The setup file of Windows passes the window it shows while it unpacks, which the setup hides once its own is up.
    val splash = args.firstOrNull { it.startsWith("--splash=") }?.substringAfter('=')?.toLongOrNull()
    // The launcher shows the picture of the app starting before this runs, which only a normal start keeps.
    val quiet = "--setup" in args || "--uninstall" in args || "--warm" in args || "--class-archive" in args
    if (quiet) LaunchSplash.close() else LaunchSplash.animate()
    // The install script of the Linux package makes the archive of classes this way, as root, with no window.
    if ("--class-archive" in args) {
        ClassArchive.makeNow()
        exitProcess(0)
    }
    if ("--setup" in args) runSetup(SetupMode.Install, splash)
    if ("--uninstall" in args) runSetup(SetupMode.Uninstall)
    // A hidden run that only loads the code of the app and ends, which the archive of classes is made from.
    if ("--warm" in args) warmUp()
    val folder = InstallSettings.dataFolder()
    // A sumizuri link the app was opened with, such as from an Open in Sumizuri button. When a copy already runs on this library, it gets the link and comes forward, and this start ends. A run from the build always opens its own window.
    val link = args.firstOrNull { it.startsWith("${AppLinks.Scheme}:", ignoreCase = true) }
    if (!AppBuild.isDebug && SingleInstance.handOver(folder, link)) exitProcess(0)
    AppLinks.open(link)
    val sink = FileLogSink(File(folder, "logs/sumizuri.log"))
    AppLog.sink = sink
    AppLog.info("app", "desktop start, log file ${sink.file.absolutePath}")
    // A Mac does not pass a link in the arguments. It hands the link to the running app, which comes forward for it.
    if (isMac && Desktop.isDesktopSupported() && Desktop.getDesktop().isSupported(Desktop.Action.APP_OPEN_URI)) {
        Desktop.getDesktop().setOpenURIHandler { event ->
            AppLinks.open(event.uri.toString())
            Forward.value++
        }
    }
    val runtime = DesktopBrowserRuntime(File(folder, "browser"))
    // The pages that show a site inside the app use the same browser, and so the same cookies, as the sources.
    DesktopWeb.runtime = runtime
    if (!AppBuild.isDebug) {
        SingleInstance.listen(folder) { later ->
            AppLinks.open(later)
            Forward.value++
        }
        thread(isDaemon = true, name = "app-links") { refreshAppLinks() }
        ClassArchive.makeLater()
        System.getProperty("compose.application.resources.dir")?.let { resources ->
            thread(isDaemon = true, name = "splash-look") { LaunchSplash.follow(File(resources)) }
        }
    }
    // The app does not end the process itself, so the browser can be shut down first, away from the window thread it needs.
    application(exitProcessOnExit = false) {
        val profiles = remember {
            val pages = DesktopRenderPageFactory(runtime)
            val solver = DesktopChallengeSolver(runtime)
            val registry =
                ProfileRegistry(folder.absolutePath.toPath(), File(folder, "sumizuri.db").absolutePath.toPath())
            ProfileHost(
                registry,
            ) { file -> AppContainer(databaseBuilder(file.toString()), pages, solver, file.toString()) }
        }
        val icon = appIcon()
        val state = rememberWindowState(width = 1000.dp, height = 720.dp)
        // Windows uses the app-drawn bar. macOS and Linux use the native frame.
        Window(
            onCloseRequest = ::exitApplication,
            title = appName(),
            icon = icon,
            state = state,
            undecorated = !isMac && !isLinux,
            resizable = true,
        ) {
            val usualMinimum = remember { Dimension(MinWidth, MinHeight) }
            LaunchedEffect(window) { window.minimumSize = usualMinimum }
            val mini = rememberMiniWindow(window, state, usualMinimum)
            // A later start comes here instead, so the window comes out from the task bar and to the front.
            val forward by Forward.collectAsState()
            LaunchedEffect(forward) { if (forward > 0) toFront(window, state) }
            LaunchedEffect(window) { DesktopFront.bring = { toFront(window, state) } }
            // A window put away lets go of the work Skia keeps for drawing, which it makes again when the window comes back.
            LaunchedEffect(state.isMinimized) { if (state.isMinimized) Graphics.purgeAllCaches() }
            val maximized = state.placement == WindowPlacement.Maximized
            val platformDensity = LocalDensity.current
            val displayDensity = remember(window) { mutableStateOf(linuxDisplayDensity(window)) }
            DisposableEffect(window) {
                val refreshDisplayDensity = { displayDensity.value = linuxDisplayDensity(window) }
                val graphicsConfigurationListener = PropertyChangeListener { event ->
                    if (event.propertyName == "graphicsConfiguration") refreshDisplayDensity()
                }
                window.addPropertyChangeListener("graphicsConfiguration", graphicsConfigurationListener)
                onDispose {
                    window.removePropertyChangeListener("graphicsConfiguration", graphicsConfigurationListener)
                }
            }
            val appDensity = remember(platformDensity, displayDensity.value) {
                if (isLinux) {
                    Density(maxOf(platformDensity.density, displayDensity.value), platformDensity.fontScale)
                } else {
                    platformDensity
                }
            }
            // The player asks for the whole screen, and the bar of the window and its handles stay away while it has it.
            val control = rememberScreenCover(window, state, native = isMac || isLinux)
            val fullscreen = control.active
            CompositionLocalProvider(
                LocalDensity provides appDensity,
                LocalFullscreen provides control,
                LocalMiniPlayer provides mini,
            ) {
                Box(Modifier.fillMaxSize()) {
                    App(profiles) {
                        if (!fullscreen && !mini.active && !isMac && !isLinux) {
                            WindowBar(
                                maximized = maximized,
                                onMinimize = { state.isMinimized = true },
                                onToggleMaximize = { toggleMaximized(window, state) },
                                onClose = ::exitApplication,
                                drag = { content ->
                                    if (nativeDragAvailable) {
                                        NativeDragArea(
                                            window,
                                            enabled = !maximized,
                                            content,
                                        )
                                    } else {
                                        WindowDraggableArea(Modifier.fillMaxSize(), content)
                                    }
                                },
                            )
                        }
                    }
                    if (!maximized && !fullscreen && !isMac && !isLinux) ResizeHandles(window)
                    // The small player has no bar, so a strip along its top moves the window.
                    if (mini.active) {
                        WindowDraggableArea(
                            Modifier.fillMaxWidth().height(28.dp).align(Alignment.TopCenter),
                        ) {}
                    }
                }
            }
        }
    }
    quit(runtime)
}

// How long a closed app may take to end before it is stopped.
private const val QuitWaitMs = 20_000L

// Counts the later starts that were handed to this copy.
private val Forward = MutableStateFlow(0)

// Brings the window back from the task bar and in front of the others. Windows keeps a window from taking the front on its own, so it is put on top for a moment.
private fun toFront(window: java.awt.Frame, state: WindowState) {
    state.isMinimized = false
    window.isAlwaysOnTop = true
    window.toFront()
    window.requestFocus()
    window.isAlwaysOnTop = false
}

// Follow Linux's display scale and DPI, with a resolution-based fallback when neither is configured.
private fun linuxDisplayDensity(window: java.awt.Window): Float {
    if (!isLinux) return 1f
    val configuration = window.graphicsConfiguration
    val transform = configuration?.defaultTransform
    val deviceScale = max(transform?.scaleX ?: 1.0, transform?.scaleY ?: 1.0).toFloat()
    val bounds = configuration?.bounds
    val resolutionScale = if (bounds != null && bounds.width > 0 && bounds.height > 0) {
        sqrt(bounds.width.toDouble() * bounds.height / (1920.0 * 1080.0)).toFloat().coerceIn(1f, 2.5f)
    } else {
        1f
    }
    val dpiScale = runCatching { Toolkit.getDefaultToolkit().screenResolution / 96f }.getOrDefault(1f)
    return maxOf(LinuxMinimumUiScale, deviceScale, resolutionScale, dpiScale)
}

// Ends the app once its window is closed. The browser keeps threads and helper programs that would hold the process open, so it is shut down first, and if anything still hangs the process is stopped after a while. The wait is long enough for Java to write the file of loaded classes at exit, which makes the next start quicker and was cut off when the process was stopped after five seconds.
private fun quit(runtime: DesktopBrowserRuntime) {
    AppLog.info("app", "desktop quit")
    thread(isDaemon = true, name = "quit-watchdog") {
        Thread.sleep(QuitWaitMs)
        Runtime.getRuntime().halt(0)
    }
    val closer =
        thread(isDaemon = true, name = "browser-shutdown") { runBlocking { runCatching { runtime.dispose() } } }
    closer.join(3_000)
    exitProcess(0)
}

// Maximizes the window, or puts it back. A window without a bar would cover the task bar, so it is kept to the room that is free.
private fun toggleMaximized(window: java.awt.Frame, state: WindowState) {
    if (state.placement == WindowPlacement.Maximized) {
        state.placement = WindowPlacement.Floating
    } else {
        window.maximizedBounds = GraphicsEnvironment.getLocalGraphicsEnvironment().maximumWindowBounds
        state.placement = WindowPlacement.Maximized
    }
}
