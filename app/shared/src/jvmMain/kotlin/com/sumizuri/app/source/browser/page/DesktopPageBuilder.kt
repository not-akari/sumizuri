package com.sumizuri.app.source.browser.page

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.withoutQuery
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import org.cef.browser.CefBrowser
import org.cef.browser.CefFrame
import org.cef.browser.CefRendering
import org.cef.handler.CefLifeSpanHandlerAdapter
import org.cef.handler.CefLoadHandler
import org.cef.handler.CefLoadHandlerAdapter
import org.cef.network.CefRequest
import java.awt.BorderLayout
import java.awt.GraphicsEnvironment
import java.awt.Window
import java.awt.event.ComponentAdapter
import java.awt.event.ComponentEvent
import javax.swing.JWindow
import javax.swing.SwingUtilities
import kotlin.time.TimeSource

// Creates a hidden Chromium page in a real window parked outside the screen, since bot checks refuse a page drawn off screen.
internal object DesktopPageBuilder {
    private const val VIEW_WIDTH = 1280
    private const val VIEW_HEIGHT = 800
    private const val START_TIMEOUT_MS = 30_000L
    private const val TAG = "desktop-browser"
    private const val PARKED = -32_000

    suspend fun create(runtime: DesktopBrowserRuntime): DesktopRenderPage {
        if (GraphicsEnvironment.isHeadless()) {
            throw BrowserUnavailableException(
                "This computer has no screen for the embedded browser.",
            )
        }
        val started = TimeSource.Monotonic.markNow()
        val client = runtime.client()
        AppLog.debug(TAG, "browser client ready after ${started.elapsedNow().inWholeMilliseconds} ms")
        val state = DesktopLoadState()
        client.addLoadHandler(loadHandler(state))
        val created = CompletableDeferred<Unit>()
        client.addLifeSpanHandler(
            object : CefLifeSpanHandlerAdapter() {
                override fun onAfterCreated(browser: CefBrowser) {
                    created.complete(Unit)
                }
            },
        )
        val browser = try {
            client.createBrowser("about:blank", CefRendering.DEFAULT)
        } catch (error: Throwable) {
            AppLog.error(TAG, "the hidden page could not be created", error)
            throw BrowserUnavailableException("The hidden page could not be created, ${error.message}")
        }
        // The window has no frame, no taskbar entry and never takes focus, and it sits where no screen reaches.
        val window = try {
            onSwing {
                JWindow().apply {
                    layout = BorderLayout()
                    add(browser.uiComponent, BorderLayout.CENTER)
                    focusableWindowState = false
                    // A popup is not managed by the window manager on X11, so KWin cannot pull it back on screen.
                    type = Window.Type.POPUP
                    setBounds(PARKED, PARKED, VIEW_WIDTH, VIEW_HEIGHT)
                    hideIfShown()
                    // Some window managers move it into view anyway; it goes straight back.
                    addComponentListener(
                        object : ComponentAdapter() {
                            override fun componentMoved(e: ComponentEvent) {
                                if (x != PARKED || y != PARKED) setLocation(PARKED, PARKED)
                            }
                        },
                    )
                    isVisible = true
                }
            }
        } catch (error: Throwable) {
            AppLog.error(TAG, "the hidden window could not be opened", error)
            browser.dispose()
            client.dispose()
            throw BrowserUnavailableException("The hidden window could not be opened, ${error.message}")
        }
        try {
            withTimeout(START_TIMEOUT_MS) { created.await() }
            AppLog.debug(TAG, "hidden page created after ${started.elapsedNow().inWholeMilliseconds} ms")
        } catch (error: TimeoutCancellationException) {
            AppLog.error(TAG, "the hidden page was not created within ${START_TIMEOUT_MS / 1000} seconds")
            onSwing { window.dispose() }
            browser.dispose()
            client.dispose()
            throw BrowserUnavailableException("The embedded browser did not start.")
        }
        return DesktopRenderPage(client, browser, window, state)
    }

    // Fully transparent where the system can draw translucent windows, so it shows nothing even when on screen.
    private fun JWindow.hideIfShown() {
        val device = graphicsConfiguration?.device ?: return
        if (device.isWindowTranslucencySupported(java.awt.GraphicsDevice.WindowTranslucency.TRANSLUCENT)) {
            opacity = 0f
        }
    }

    private suspend fun <T> onSwing(work: () -> T): T = withContext(Dispatchers.IO) {
        var result: Result<T>? = null
        SwingUtilities.invokeAndWait { result = runCatching(work) }
        result!!.getOrThrow()
    }

    private fun loadHandler(state: DesktopLoadState) = object : CefLoadHandlerAdapter() {
        override fun onLoadStart(browser: CefBrowser, frame: CefFrame, transitionType: CefRequest.TransitionType?) {
            if (frame.isMain && frame.url.contains("__cf_chl_")) state.sawChallenge = true
            // Sent as the document starts, which reaches the page before its own scripts run.
            state.early?.let { if (frame.isMain) frame.executeJavaScript(it, frame.url, 0) }
        }

        override fun onLoadEnd(browser: CefBrowser, frame: CefFrame, httpStatusCode: Int) {
            // The browser starts on a blank page, and its end must not count as the end of the real page.
            if (frame.isMain && !frame.url.startsWith("about:")) {
                if (frame.url.contains("__cf_chl_")) state.sawChallenge = true
                state.loading?.complete(Unit)
            }
        }

        override fun onLoadError(
            browser: CefBrowser,
            frame: CefFrame,
            errorCode: CefLoadHandler.ErrorCode?,
            errorText: String?,
            failedUrl: String?,
        ) {
            if (!frame.isMain) return
            // A navigation replaced by the next one, such as a redirect, is not a failure.
            if (errorCode == CefLoadHandler.ErrorCode.ERR_ABORTED) return
            AppLog.warn(
                TAG,
                "the page failed to load, $errorText ($errorCode) for ${failedUrl.orEmpty().withoutQuery()}",
            )
            state.error = "$errorText ($errorCode)"
            state.loading?.complete(Unit)
        }
    }
}
