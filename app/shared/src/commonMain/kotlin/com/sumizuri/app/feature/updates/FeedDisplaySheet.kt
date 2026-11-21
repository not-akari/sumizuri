package com.sumizuri.app.feature.updates

import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.feed.FeedPrefs
import com.sumizuri.app.data.model.feed.FeedRowStyle
import com.sumizuri.app.data.model.feed.UpcomingSide
import com.sumizuri.app.data.model.library.LibraryDisplayStyle
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_cover_size
import com.sumizuri.app.shared.resources.display_row_style
import com.sumizuri.app.shared.resources.display_style
import com.sumizuri.app.shared.resources.updates_side
import com.sumizuri.app.shared.resources.updates_side_hint
import com.sumizuri.app.shared.resources.updates_swipe_marks_read
import com.sumizuri.app.shared.resources.updates_swipe_marks_read_hint
import com.sumizuri.app.ui.kit.page.AppSheet
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// How a feed page is laid out: the style, the rows when it is a list, how big the covers are when it is a grid, and, on the updates page, what shows beside the list and whether a swipe marks a row read. Each choice is saved as it is made.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun FeedDisplaySheet(
    title: StringResource,
    prefs: FeedPrefs,
    coverSize: Int,
    onPrefs: ((FeedPrefs) -> FeedPrefs) -> Unit,
    onCoverSize: (Int) -> Unit,
    onDismiss: () -> Unit,
    swipeSwitch: Boolean = false,
) {
    AppSheet(onDismiss, spacing = 12.dp, title = stringResource(title)) {
        SettingsSection {
            padded {
                ChoiceSetting(Res.string.display_style, LibraryDisplayStyle.entries, prefs.style, {
                    stringResource(it.label)
                }) { style -> onPrefs { it.copy(style = style) } }
            }
            if (prefs.style.isGrid) {
                padded {
                    SliderSetting(Res.string.display_cover_size, coverSize.toFloat(), LibraryPrefs.CellRange, {
                        "${it.roundToInt()} dp"
                    }) { onCoverSize(it.roundToInt()) }
                }
            } else {
                padded {
                    ChoiceSetting(Res.string.display_row_style, FeedRowStyle.entries, prefs.rowStyle, {
                        stringResource(it.label)
                    }) { row -> onPrefs { it.copy(rowStyle = row) } }
                }
            }
            if (swipeSwitch && !prefs.style.isGrid) {
                padded {
                    ChoiceSetting(Res.string.updates_side, UpcomingSide.entries, prefs.upcomingSide, {
                        stringResource(it.label)
                    }, hint = Res.string.updates_side_hint) { side -> onPrefs { it.copy(upcomingSide = side) } }
                }
            }
            if (swipeSwitch) {
                padded {
                    SwitchSetting(Res.string.updates_swipe_marks_read, prefs.swipeMarksRead, { on ->
                        onPrefs {
                            it.copy(swipeMarksRead = on)
                        }
                    }, Res.string.updates_swipe_marks_read_hint)
                }
            }
        }
    }
}
