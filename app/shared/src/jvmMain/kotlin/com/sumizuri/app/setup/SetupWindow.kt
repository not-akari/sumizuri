package com.sumizuri.app.setup

import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.window.WindowDraggableArea
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.FrameWindowScope
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowPosition
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.FileLogSink
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.setup_title
import com.sumizuri.app.ui.kit.window.appIcon
import com.sumizuri.app.ui.theme.SumizuriTheme
import com.sumizuri.app.ui.theme.ThemeMode
import com.sumizuri.app.ui.theme.spec.ThemePresets
import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.stringResource
import java.io.File
import kotlin.system.exitProcess

// The size of the card the setup draws and the room round it for its shadow.
private val CardSize = DpSize(720.dp, 600.dp)
internal val ShadowRoom = 20.dp

@Suppress("FunctionName")
private interface Kernel32Exit : Library {
    fun ExitProcess(code: Int)
}

@Suppress("FunctionName")
private interface User32Show : Library {
    fun ShowWindow(window: Pointer, command: Int): Boolean
}

// Hides a window of another program by its handle.
private fun hideWindow(handle: Long) {
    runCatching { Native.load("user32", User32Show::class.java).ShowWindow(Pointer(handle), 0) }
}

// Runs the setup in a window of its own until it closes, then does what the person chose last, such as opening the app, and ends the process. The setup file of Windows gives the handle of the short window it shows while it unpacks the app, to be hidden once this one is up, and the folder it unpacks the rest of the app into meanwhile.
fun runSetup(mode: SetupMode, splash: Long? = null, later: File? = null): Nothing {
    val log = File(System.getProperty("java.io.tmpdir"), "sumizuri-setup.log")
    val sink = FileLogSink(log)
    AppLog.sink = sink
    AppLog.info("setup", "the setup of ${BuildInfo.Version} started to ${mode.name.lowercase()}")
    var after: (() -> Unit)? = null
    application(exitProcessOnExit = false) {
        val scope = rememberCoroutineScope()
        val model = remember { SetupModel(mode, scope, later) }
        val state =
            rememberWindowState(
                size = DpSize(CardSize.width + ShadowRoom * 2, CardSize.height + ShadowRoom * 2),
                position = WindowPosition(Alignment.Center),
            )
        val close = {
            if (model.canClose) {
                after = model.afterClose
                exitApplication()
            }
        }
        Window(
            onCloseRequest = close,
            title = stringResource(Res.string.setup_title),
            icon = appIcon(),
            state = state,
            undecorated = true,
            transparent = true,
            resizable = false,
        ) {
            SumizuriTheme(ThemeMode.System, ThemePresets.first()) {
                SetupFrame(model, log, onMinimize = { state.isMinimized = true }, onClose = close)
            }
            // The window of the setup file goes once this one has drawn, so one takes the place of the other with nothing between.
            if (splash != null) {
                LaunchedEffect(Unit) {
                    withFrameNanos { }
                    hideWindow(splash)
                }
            }
        }
    }
    runCatching { after?.invoke() }.onFailure { AppLog.error("setup", "what was to follow the setup failed", it) }
    sink.flush()
    endProcess()
}

// Ends the process at once. The usual end would have Java write its archive of classes, which the setup, run from a temporary folder, has no use for.
private fun endProcess(): Nothing {
    if (System
            .getProperty("os.name")
            .orEmpty()
            .lowercase()
            .contains("win")
    ) {
        runCatching { Native.load("kernel32", Kernel32Exit::class.java).ExitProcess(0) }
    }
    exitProcess(0)
}

// The setup in its window, where the side panel and the bar move the window.
@Composable
private fun FrameWindowScope.SetupFrame(model: SetupModel, log: File, onMinimize: () -> Unit, onClose: () -> Unit) {
    LaunchedEffect(Unit) {
        while (true) {
            model.runningCount = withContext(Dispatchers.IO) { model.countRunning() }
            delay(1_500)
        }
    }
    SetupCard(
        model,
        window,
        log,
        onMinimize,
        onClose,
    ) { modifier, content -> WindowDraggableArea(modifier) { content() } }
}
