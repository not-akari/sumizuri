package com.sumizuri.app.core.log

import kotlin.experimental.ExperimentalNativeApi
import kotlin.native.ReportUnhandledExceptionHook
import kotlin.native.setUnhandledExceptionHook

// Kotlin on the iPhone calls one hook for an error nothing caught, and then ends the app. The report is written first, then the hook that was there before runs.
@OptIn(ExperimentalNativeApi::class)
internal actual fun installCrashHook(onCrash: (Throwable) -> Unit) {
    var before: ReportUnhandledExceptionHook? = null
    before = setUnhandledExceptionHook { error ->
        runCatching { onCrash(error) }
        before?.invoke(error)
    }
}
