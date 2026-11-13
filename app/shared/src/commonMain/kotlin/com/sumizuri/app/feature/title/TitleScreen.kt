package com.sumizuri.app.feature.title

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.title.info.CoverFocusDialog
import com.sumizuri.app.feature.title.info.CoverPreview
import com.sumizuri.app.feature.title.info.EditTitleDialog
import com.sumizuri.app.feature.title.layout.PhoneTitle
import com.sumizuri.app.feature.title.layout.SplitTitle
import com.sumizuri.app.feature.title.layout.TitleBar
import com.sumizuri.app.feature.title.layout.WideTitle
import com.sumizuri.app.ui.kit.scroll.PullRefresh
import com.sumizuri.app.ui.theme.CoverTheme

// A window at least this wide gets the wide page, with the chapters in the middle and the details beside them.
private val WideWidth = 840.dp

// The windows the page can open over itself.
private enum class TitleDialog { None, Cover, Focus, Edit }

// One page for a saved title and for a preview of an entry that is not saved yet. A phone gets the cover behind the page and a wide window gets a side panel. Pulling the page down asks the source again.
@Composable
fun TitleScreen(state: TitleState, asked: TitleCallbacks) {
    // A title that cannot be reached shows its data, and only its chapters saved to the device open. A title whose chapters cannot be saved has no download buttons.
    val container = LocalAppContainer.current
    val split by remember(container) { container.settings.flag(SettingKey.TitleSplit, true) }.collectAsState(true)
    var dialog by remember { mutableStateOf(TitleDialog.None) }
    val fitting = asked.fitting(state)
    val calls = remember(fitting) { fitting.copy(onEdit = { dialog = TitleDialog.Edit }) }
    // Back while chapters are picked ends the picking, and only the next one leaves the page.
    NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = state.selecting) {
        calls.selection.onClose()
    }
    // The page takes its colors from the cover of the title, so the bar, the buttons and the cards belong to it.
    CoverTheme(state.title?.coverUrl) {
        BoxWithConstraints(Modifier.fillMaxSize()) {
            val title = state.title
            if (title == null) {
                TitleBar("", 1f, calls.onBack)
            } else {
                val wide = maxWidth >= WideWidth
                val height = maxHeight
                val onPreview = { dialog = TitleDialog.Cover }
                val onBackground = { dialog = TitleDialog.Focus }
                PullRefresh(state.loading, calls.onRefresh, Modifier.fillMaxSize()) {
                    if (wide && split) {
                        SplitTitle(state, title, calls, onPreview, onBackground)
                    } else if (wide) {
                        WideTitle(state, title, calls, onPreview, onBackground)
                    } else {
                        PhoneTitle(state, title, calls, height, onPreview, onBackground)
                    }
                }
                when (dialog) {
                    TitleDialog.None -> Unit

                    TitleDialog.Cover -> CoverPreview(title) { dialog = TitleDialog.None }

                    TitleDialog.Edit -> EditTitleDialog(title, calls.onRefresh) { dialog = TitleDialog.None }

                    TitleDialog.Focus -> CoverFocusDialog(
                        title,
                        state.focus,
                        onSave = { x, y ->
                            calls.onSetFocus(x, y)
                            dialog = TitleDialog.None
                        },
                        onAuto = {
                            calls.onClearFocus()
                            dialog = TitleDialog.None
                        },
                        onDismiss = { dialog = TitleDialog.None },
                    )
                }
            }
        }
    }
}
