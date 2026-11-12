package com.sumizuri.app.feature.logs

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.CrashReport
import com.sumizuri.app.ui.kit.input.rememberCopyText
import kotlin.time.Instant

@Composable
fun LogsRoute(onBack: () -> Unit) {
    val entries by AppLog.entries.collectAsStateWithLifecycle()
    val crash by CrashReport.last.collectAsStateWithLifecycle()
    val copy = rememberCopyText()
    LogsScreen(
        entries = entries,
        startedAt = AppLog.startedAt,
        crash = crash?.let { report -> CrashCard(report, onCopy = { copy(report) }, onDismiss = CrashReport::dismiss) },
        // The copy starts with the version and the time this run began, which the times of the lines count from.
        onCopy = {
            copy(
                "Sumizuri ${BuildInfo.Version}, this run began ${Instant.fromEpochMilliseconds(
                    AppLog.startedAt,
                )}\n${AppLog.text()}",
            )
        },
        onClear = AppLog::clear,
        onBack = onBack,
    )
}
