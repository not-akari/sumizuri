package com.sumizuri.app.ui.kit.web

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.compose.LifecycleResumeEffect

// The system WebView. Its cookies are the ones the hidden pages of the sources use, since Android keeps one cookie store for every WebView of the app.
@SuppressLint("SetJavaScriptEnabled")
@Composable
actual fun WebBrowserView(state: WebBrowserState, modifier: Modifier) {
    val held = remember { arrayOfNulls<WebView>(1) }
    // The site stops its scripts, sound and video while the app is away, and goes on when it comes back.
    LifecycleResumeEffect(Unit) {
        held[0]?.onResume()
        onPauseOrDispose { held[0]?.onPause() }
    }
    AndroidView(
        factory = { context ->
            WebView(context).apply {
                val web = this
                held[0] = web
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                CookieManager.getInstance().apply {
                    setAcceptCookie(true)
                    setAcceptThirdPartyCookies(web, true)
                }
                webViewClient = object : WebViewClient() {
                    override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
                        state.loading = true
                        state.url = url
                    }

                    override fun onPageFinished(view: WebView, url: String) {
                        state.loading = false
                        state.url = url
                        state.canGoBack = view.canGoBack()
                        state.canGoForward = view.canGoForward()
                    }

                    override fun doUpdateVisitedHistory(view: WebView, url: String, isReload: Boolean) {
                        state.url = url
                        state.canGoBack = view.canGoBack()
                        state.canGoForward = view.canGoForward()
                    }
                }
                webChromeClient = object : WebChromeClient() {
                    override fun onReceivedTitle(view: WebView, title: String?) {
                        state.title = title.orEmpty()
                    }
                }
                state.controls = object : WebControls {
                    override fun back() = web.goBack()
                    override fun forward() = web.goForward()
                    override fun reload() = web.reload()
                    override fun stop() = web.stopLoading()
                }
                loadUrl(state.startUrl)
            }
        },
        modifier = modifier,
        onRelease = { web ->
            state.controls = null
            held[0] = null
            web.stopLoading()
            web.destroy()
        },
    )
}
