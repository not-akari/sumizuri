package com.sumizuri.app.feature.settings.system

import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.RestartAlt
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.SingletonImageLoader
import coil3.compose.LocalPlatformContext
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.LogLevel
import com.sumizuri.app.core.perf.Perf
import com.sumizuri.app.core.perf.StartMark
import com.sumizuri.app.core.perf.memoryUse
import com.sumizuri.app.core.perf.oneDecimal
import com.sumizuri.app.core.perf.rememberFrameStats
import com.sumizuri.app.core.perf.systemUse
import com.sumizuri.app.core.perf.threadCount
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.perf_app_memory
import com.sumizuri.app.shared.resources.perf_calls_value
import com.sumizuri.app.shared.resources.perf_cpu
import com.sumizuri.app.shared.resources.perf_details
import com.sumizuri.app.shared.resources.perf_details_page_hint
import com.sumizuri.app.shared.resources.perf_first_frame
import com.sumizuri.app.shared.resources.perf_frames
import com.sumizuri.app.shared.resources.perf_frames_value
import com.sumizuri.app.shared.resources.perf_images
import com.sumizuri.app.shared.resources.perf_library_shown
import com.sumizuri.app.shared.resources.perf_memory
import com.sumizuri.app.shared.resources.perf_nothing
import com.sumizuri.app.shared.resources.perf_now
import com.sumizuri.app.shared.resources.perf_reset
import com.sumizuri.app.shared.resources.perf_sources
import com.sumizuri.app.shared.resources.perf_start
import com.sumizuri.app.shared.resources.perf_threads
import com.sumizuri.app.shared.resources.perf_unknown
import com.sumizuri.app.shared.resources.perf_warnings
import com.sumizuri.app.shared.resources.perf_work
import com.sumizuri.app.shared.resources.perf_work_value
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// How many of the latest performance warnings the page lists.
private const val WarningsShown = 8

// The page of measurements, opened from the advanced settings: how long the start took, the frames while the page is open, the memory, the processor, the image cache, the work of the app, the calls to each source and the latest warnings of the watch.
@Composable
fun PerformanceRoute(onBack: () -> Unit) {
    val marks by Perf.marks.collectAsStateWithLifecycle()
    val work by Perf.work.collectAsStateWithLifecycle()
    val calls by Perf.calls.collectAsStateWithLifecycle()
    val log by AppLog.entries.collectAsStateWithLifecycle()
    val frames by rememberFrameStats()
    val context = LocalPlatformContext.current
    var memory by remember { mutableStateOf(memoryUse()) }
    var cpu by remember { mutableStateOf<Float?>(null) }
    var threads by remember { mutableStateOf(threadCount()) }
    var images by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(Unit) {
        while (true) {
            val now = systemUse()
            memory = now.memory
            cpu = now.cpu
            threads = now.threads
            images =
                SingletonImageLoader
                    .get(
                        context,
                    ).memoryCache
                    ?.let { "${byteSizeText(it.size)} / ${byteSizeText(it.maxSize)}" }
            delay(1_000)
        }
    }
    val unknown = stringResource(Res.string.perf_unknown)
    SettingsPageFrame(Res.string.perf_details, onBack, subtitle = Res.string.perf_details_page_hint) {
        SettingsSection(Res.string.perf_start) {
            row { Value(Res.string.perf_first_frame, marks[StartMark.FirstFrame]?.let { "$it ms" } ?: unknown) }
            row { Value(Res.string.perf_library_shown, marks[StartMark.LibraryShown]?.let { "$it ms" } ?: unknown) }
        }
        SettingsSection(Res.string.perf_now) {
            row {
                Value(
                    Res.string.perf_frames,
                    if (frames.total ==
                        0
                    ) {
                        unknown
                    } else {
                        stringResource(
                            Res.string.perf_frames_value,
                            frames.fps.oneDecimal(),
                            frames.averageMs.oneDecimal(),
                            frames.worstMs.oneDecimal(),
                            frames.slow,
                        )
                    },
                )
            }
            row {
                Value(
                    Res.string.perf_memory,
                    "${memory.usedMb} / ${memory.maxMb} MB" + (memory.nativeMb?.let { ", native $it MB" } ?: ""),
                )
            }
            memory.processMb?.let { ram -> row { Value(Res.string.perf_app_memory, "$ram MB") } }
            row { Value(Res.string.perf_cpu, cpu?.let { it.oneDecimal() + "%" } ?: unknown) }
            row { Value(Res.string.perf_threads, threads.toString()) }
            row { Value(Res.string.perf_images, images ?: unknown) }
        }
        SettingsSection(Res.string.perf_work) {
            if (work.isEmpty()) row { SettingRow(stringResource(Res.string.perf_nothing)) }
            for (each in work.values.sortedByDescending { it.totalMs }) {
                row {
                    SettingRow(
                        each.name,
                        subtitle = stringResource(
                            Res.string.perf_work_value,
                            each.count,
                            each.lastMs,
                            each.averageMs,
                            each.worstMs,
                        ),
                    )
                }
            }
        }
        SettingsSection(Res.string.perf_sources) {
            if (calls.isEmpty()) row { SettingRow(stringResource(Res.string.perf_nothing)) }
            for (each in calls.values.sortedByDescending { it.totalMs }) {
                row {
                    SettingRow(
                        each.source,
                        subtitle = stringResource(
                            Res.string.perf_calls_value,
                            each.calls,
                            each.failures,
                            each.averageMs,
                            each.worstMs,
                        ),
                    )
                }
            }
        }
        SettingsSection(Res.string.perf_warnings) {
            val warnings = log
                .filter { it.tag == "perf" && it.level >= LogLevel.Warn }
                .takeLast(
                    WarningsShown,
                ).asReversed()
            if (warnings.isEmpty()) row { SettingRow(stringResource(Res.string.perf_nothing)) }
            for (entry in warnings) {
                // The text of a warning can be long, with the code that caused it, so it can be selected and copied.
                row { SelectionContainer { SettingRow(entry.message, subtitleLines = 1) } }
            }
        }
        SettingsSection {
            row {
                SettingRow(
                    stringResource(Res.string.perf_reset),
                    leading = {
                        Icon(
                            Icons.Outlined.RestartAlt,
                            null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    },
                    onClick = Perf::reset,
                )
            }
        }
    }
}

// A name with what it measures now.
@Composable
private fun Value(name: StringResource, value: String) {
    SettingRow(stringResource(name), subtitle = value)
}
