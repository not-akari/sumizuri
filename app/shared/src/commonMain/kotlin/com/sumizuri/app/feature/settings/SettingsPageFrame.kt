package com.sumizuri.app.feature.settings

import androidx.compose.foundation.gestures.ScrollableState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.RestartAlt
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.advanced_reset_action
import com.sumizuri.app.shared.resources.settings_reset_page
import com.sumizuri.app.shared.resources.settings_reset_page_message
import com.sumizuri.app.ui.kit.dialog.ConfirmDialog
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.page.ReadableWidth
import com.sumizuri.app.ui.kit.page.pageScroll
import com.sumizuri.app.ui.kit.scroll.LocalScrollTarget
import com.sumizuri.app.ui.kit.scroll.PullRefresh
import com.sumizuri.app.ui.kit.scroll.scrollFrom
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The frame every page of the settings has: the bar with the back arrow, the name of the page and a line about it, and the rows in a scrolling column. A page that can take its choices back gives onReset, and the bar shows a button for it that asks first.
@Composable
internal fun SettingsPageFrame(
    title: StringResource,
    onBack: () -> Unit,
    subtitle: StringResource? = null,
    onReset: (suspend () -> Unit)? = null,
    // How wide the page may get on a wide window.
    maxWidth: Dp = ReadableWidth,
    // A page that can be pulled down to load again, such as the server tabs of sync, gives what is running and what to do.
    refresh: PageRefresh? = null,
    // The names of the parts of a long page, shown as pills under the bar that jump to each part.
    jumps: List<String> = emptyList(),
    // Buttons of the page at the right of its bar, such as Save on a page that edits something.
    actions: @Composable RowScope.() -> Unit = {},
    content: @Composable ColumnScope.() -> Unit,
) {
    val scroll = rememberScrollState()
    val pageJumps = remember(scroll) { PageJumps(scroll) }
    val scope = rememberCoroutineScope()
    var asking by remember { mutableStateOf(false) }
    // Beside the list of a wide window the page starts at the list, and alone it stands in the middle of the window.
    val beside = LocalSettingsBeside.current
    val frame: @Composable (@Composable () -> Unit) -> Unit = { inner ->
        if (beside) {
            // The wheel scrolls the page from the empty space beside it too.
            var target by remember { mutableStateOf<ScrollableState?>(null) }
            CompositionLocalProvider(LocalScrollTarget provides { target = it }) {
                Box(Modifier.fillMaxSize().scrollFrom { target }.padding(start = 12.dp)) {
                    Box(Modifier.widthIn(max = maxWidth)) { inner() }
                }
            }
        } else {
            ReadableColumn(maxWidth) { inner() }
        }
    }
    frame {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(
                stringResource(title),
                // The line about the page sits under its name, as the list beside it says the same.
                subtitle = subtitle?.let { stringResource(it) },
                onBack = onBack,
                actions = {
                    actions()
                    if (onReset !=
                        null
                    ) {
                        IconButton(
                            { asking = true },
                        ) { Icon(Icons.Outlined.RestartAlt, stringResource(Res.string.settings_reset_page)) }
                    }
                },
            )
            if (jumps.isNotEmpty()) JumpPills(jumps, pageJumps)
            val list: @Composable (Modifier) -> Unit = { outer ->
                Column(
                    outer
                        .pageScroll(
                            given = scroll,
                        ).padding(horizontal = PageGutter, vertical = 8.dp)
                        .onGloballyPositioned {
                            pageJumps.content =
                                it
                        },
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    CompositionLocalProvider(
                        LocalPageJumps provides pageJumps.takeIf { jumps.isNotEmpty() },
                    ) { content() }
                }
            }
            if (refresh == null) {
                list(Modifier.weight(1f))
            } else {
                PullRefresh(refresh.running, refresh.onRefresh, Modifier.weight(1f)) { list(Modifier.fillMaxSize()) }
            }
        }
    }
    if (asking && onReset != null) {
        ConfirmDialog(
            stringResource(Res.string.settings_reset_page),
            stringResource(Res.string.settings_reset_page_message, stringResource(title)),
            stringResource(Res.string.advanced_reset_action),
            onConfirm = {
                asking = false
                scope.launch { onReset() }
            },
            onDismiss = { asking = false },
        )
    }
}

// What a page that can be pulled down to load again is doing, and what a pull asks for.
internal class PageRefresh(val running: Boolean, val onRefresh: () -> Unit)

// Whether the page stands beside the list of the settings on a wide window.
internal val LocalSettingsBeside = compositionLocalOf { false }
