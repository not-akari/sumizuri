package com.sumizuri.app.feature.tv.settings.system

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.CrashReport
import com.sumizuri.app.core.log.LogEntry
import com.sumizuri.app.core.log.LogLevel
import com.sumizuri.app.feature.logs.LogFilter
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.clear
import com.sumizuri.app.shared.resources.logs_crash_dismiss
import com.sumizuri.app.shared.resources.logs_crash_title
import com.sumizuri.app.shared.resources.logs_lines
import com.sumizuri.app.shared.resources.logs_title
import com.sumizuri.app.shared.resources.tv_logs_show
import com.sumizuri.app.shared.resources.tv_logs_text
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.TvChoiceRow
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// How far one press of up or down moves the lines.
private val Step = 180.dp

// The log on a TV: which lines to show, the report of the last crash when there is one, and the lines in a box that up and down scroll once it has the focus.
@Composable
internal fun TvLogsRoute() {
    val entries by AppLog.entries.collectAsStateWithLifecycle()
    val crash by CrashReport.last.collectAsStateWithLifecycle()
    var show by remember { mutableStateOf(LogFilter.All) }
    val shown = remember(entries, show) { entries.asReversed().filter { it.level.ordinal >= show.lowest.ordinal } }
    TvSystemPage(
        stringResource(Res.string.logs_title),
        stringResource(Res.string.tv_logs_text) + " " + stringResource(Res.string.logs_lines, entries.size),
    ) { first ->
        TvChoiceRow(
            stringResource(Res.string.tv_logs_show),
            LogFilter.entries,
            show,
            { stringResource(it.label) },
            { show = it },
            Modifier.focusRequester(first),
        )
        crash?.let { report ->
            TvInfoRow(
                stringResource(Res.string.logs_crash_title),
                report.lineSequence().firstOrNull { it.isNotBlank() },
                stringResource(Res.string.logs_crash_dismiss),
                CrashReport::dismiss,
                valueColor = MaterialTheme.colorScheme.error,
            )
        }
        Lines(shown)
        TvButton(stringResource(Res.string.clear), AppLog::clear, Modifier.padding(top = 6.dp), main = false)
    }
}

// The lines, newest first. Once the box has the focus, down scrolls on, and up scrolls back until the top, where up leaves the box.
@Composable
private fun Lines(shown: List<LogEntry>) {
    val colors = MaterialTheme.colorScheme
    val list = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val step = with(LocalDensity.current) { Step.toPx() }
    var focused by remember { mutableStateOf(false) }
    val shape = RoundedCornerShape(16.dp)
    Box(
        Modifier
            .fillMaxWidth()
            .height(440.dp)
            .border(2.5.dp, if (focused) colors.onSurface else Color.Transparent, shape)
            .padding(3.dp)
            .clip(shape)
            .background(colors.surfaceContainer.copy(alpha = 0.5f))
            .onFocusChanged { focused = it.isFocused }
            .onPreviewKeyEvent { event ->
                if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                when (event.key) {
                    Key.DirectionDown -> {
                        if (list.canScrollForward) scope.launch { list.animateScrollBy(step) }
                        list.canScrollForward
                    }

                    Key.DirectionUp -> {
                        if (list.canScrollBackward) scope.launch { list.animateScrollBy(-step) }
                        list.canScrollBackward
                    }

                    else -> false
                }
            }.focusable(),
    ) {
        LazyColumn(
            state = list,
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            items(shown) { entry ->
                Text(
                    entry.line(AppLog.startedAt),
                    color = when (entry.level) {
                        LogLevel.Error -> colors.error
                        LogLevel.Warn -> colors.tertiary
                        LogLevel.Info -> colors.onSurface
                        LogLevel.Debug -> colors.outline
                    },
                    fontFamily = FontFamily.Monospace,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                )
            }
        }
    }
}
