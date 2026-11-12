package com.sumizuri.app.feature.logs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.core.log.LogEntry
import com.sumizuri.app.core.log.LogLevel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.clear
import com.sumizuri.app.shared.resources.logs_all
import com.sumizuri.app.shared.resources.logs_copy
import com.sumizuri.app.shared.resources.logs_crash_copy
import com.sumizuri.app.shared.resources.logs_crash_dismiss
import com.sumizuri.app.shared.resources.logs_crash_hint
import com.sumizuri.app.shared.resources.logs_crash_title
import com.sumizuri.app.shared.resources.logs_info
import com.sumizuri.app.shared.resources.logs_lines
import com.sumizuri.app.shared.resources.logs_no_match
import com.sumizuri.app.shared.resources.logs_problems
import com.sumizuri.app.shared.resources.logs_search
import com.sumizuri.app.shared.resources.logs_title
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.chips.ChipRow
import com.sumizuri.app.ui.kit.chips.ChoiceChip
import com.sumizuri.app.ui.kit.input.AppSearchBar
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.scroll.RegisterScrollTarget
import com.sumizuri.app.ui.kit.scroll.mouseDragScroll
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// A report of the last time the app stopped, with copy and dismiss, or null when there is none.
class CrashCard(val report: String, val onCopy: () -> Unit, val onDismiss: () -> Unit)

// The lines the app has logged, newest first, with a search, the level filter, copy and clear, and the report of the last crash on top when there is one.
@Composable
fun LogsScreen(
    entries: List<LogEntry>,
    startedAt: Long,
    crash: CrashCard?,
    onCopy: () -> Unit,
    onClear: () -> Unit,
    onBack: () -> Unit,
) {
    var show by rememberSaveable { mutableStateOf(LogFilter.All) }
    var query by rememberSaveable { mutableStateOf("") }
    val words = query.trim()
    val shown = entries.asReversed().filter { entry ->
        entry.level.ordinal >= show.lowest.ordinal &&
            (
                words.isEmpty() || entry.tag.contains(words, ignoreCase = true) ||
                    entry.message.contains(words, ignoreCase = true)
                )
    }
    ReadableColumn {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(
                stringResource(Res.string.logs_title),
                subtitle = stringResource(Res.string.logs_lines, entries.size),
                onBack = onBack,
            ) {
                IconButton(onCopy) { Icon(Icons.Outlined.ContentCopy, stringResource(Res.string.logs_copy)) }
                IconButton(onClear) { Icon(Icons.Outlined.DeleteOutline, stringResource(Res.string.clear)) }
            }
            AppSearchBar(
                query,
                { query = it },
                stringResource(Res.string.logs_search),
                Modifier.padding(horizontal = PageGutter, vertical = 4.dp),
            )
            ChipRow(Modifier.padding(horizontal = PageGutter)) {
                for (filter in LogFilter.entries) {
                    ChoiceChip(stringResource(filter.label), show == filter) { show = filter }
                }
            }
            crash?.let { CrashReportCard(it) }
            SelectionContainer {
                val list = rememberLazyListState()
                RegisterScrollTarget(list)
                LazyColumn(
                    Modifier.mouseDragScroll(list),
                    state = list,
                    contentPadding = PaddingValues(horizontal = PageGutter, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    if (shown.isEmpty() && words.isNotEmpty()) {
                        item {
                            Text(stringResource(Res.string.logs_no_match), color = MaterialTheme.colorScheme.outline)
                        }
                    }
                    itemsIndexed(shown) { _, entry ->
                        Text(
                            entry.line(startedAt),
                            color = colorOf(entry.level),
                            fontFamily = FontFamily.Monospace,
                            fontSize = 12.sp,
                            lineHeight = 16.sp,
                        )
                    }
                }
            }
        }
    }
}

// The error that stopped the app, the way to copy the whole report into a bug report, and the way to put it away.
@Composable
private fun CrashReportCard(crash: CrashCard) {
    val error = crash.report
        .lineSequence()
        .firstOrNull { it.startsWith("Error: ") }
        ?.removePrefix("Error: ")
    AppCard(Modifier.fillMaxWidth().padding(horizontal = PageGutter, vertical = 8.dp)) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(
                stringResource(Res.string.logs_crash_title),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.error,
            )
            Text(
                stringResource(Res.string.logs_crash_hint),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            error?.let {
                Text(it, fontFamily = FontFamily.Monospace, fontSize = 12.sp, lineHeight = 16.sp, maxLines = 3)
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                TextButton(crash.onDismiss) { Text(stringResource(Res.string.logs_crash_dismiss)) }
                TextButton(crash.onCopy) { Text(stringResource(Res.string.logs_crash_copy)) }
            }
        }
    }
}

@Composable
private fun colorOf(level: LogLevel): Color = when (level) {
    LogLevel.Error -> MaterialTheme.colorScheme.error
    LogLevel.Warn -> MaterialTheme.colorScheme.tertiary
    LogLevel.Info -> MaterialTheme.colorScheme.onSurface
    LogLevel.Debug -> MaterialTheme.colorScheme.outline
}

// The tabs of the Logs page, each showing the lines from a level upward.
internal enum class LogFilter(val label: StringResource, val lowest: LogLevel) {
    All(Res.string.logs_all, LogLevel.Debug),
    Info(Res.string.logs_info, LogLevel.Info),
    Problems(Res.string.logs_problems, LogLevel.Warn),
}
