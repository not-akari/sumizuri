package com.sumizuri.app.feature.web

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.ArrowForward
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.net.siteNameOf
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.web_back
import com.sumizuri.app.shared.resources.web_forward
import com.sumizuri.app.shared.resources.web_open_outside
import com.sumizuri.app.shared.resources.web_reload
import com.sumizuri.app.shared.resources.web_stop
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.web.WebBrowserState
import com.sumizuri.app.ui.kit.web.WebBrowserView
import org.jetbrains.compose.resources.stringResource

// A site inside the app: the bar with the name of the page and its address, the buttons to go back and forward in the site, to load it again and to open it in the person's own browser, a line while it loads, and the site under it. Going back moves back in the site first and leaves the page when there is nowhere to go.
@Composable
fun WebPage(url: String, onBack: () -> Unit) {
    val state = remember(url) { WebBrowserState(url) }
    val uri = LocalUriHandler.current
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = state.canGoBack) {
        state.back()
    }
    Column(Modifier.fillMaxSize()) {
        PageTopBar(
            state.title.ifBlank { siteNameOf(state.url) },
            subtitle = state.url,
            onBack = onBack,
        ) {
            IconButton({
                state.back()
            }, enabled = state.canGoBack) {
                Icon(
                    Icons.AutoMirrored.Outlined.ArrowBack,
                    stringResource(Res.string.web_back),
                )
            }
            IconButton({
                state.forward()
            }, enabled = state.canGoForward) {
                Icon(Icons.AutoMirrored.Outlined.ArrowForward, stringResource(Res.string.web_forward))
            }
            if (state.loading) {
                IconButton({ state.stop() }) { Icon(Icons.Outlined.Close, stringResource(Res.string.web_stop)) }
            } else {
                IconButton({ state.reload() }) { Icon(Icons.Outlined.Refresh, stringResource(Res.string.web_reload)) }
            }
            IconButton({
                runCatching {
                    uri.openUri(state.url)
                }
            }) { Icon(Icons.AutoMirrored.Outlined.OpenInNew, stringResource(Res.string.web_open_outside)) }
        }
        AnimatedVisibility(state.loading && state.problem == null) {
            InkLinearProgressIndicator(Modifier.fillMaxWidth().height(2.dp))
        }
        WebBrowserView(state, Modifier.fillMaxWidth().weight(1f))
    }
}

// The site part of an address, for the bar before the page has a name.
