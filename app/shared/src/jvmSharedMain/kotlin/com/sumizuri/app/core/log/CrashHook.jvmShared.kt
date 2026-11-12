package com.sumizuri.app.core.log

// Java hands every error no thread caught to one handler. The report is written first, then the handler that was there before does what it did, which on Android closes the app.
internal actual fun installCrashHook(onCrash: (Throwable) -> Unit) {
    val before = Thread.getDefaultUncaughtExceptionHandler()
    Thread.setDefaultUncaughtExceptionHandler { thread, error ->
        runCatching { onCrash(error) }
        before?.uncaughtException(thread, error) ?: error.printStackTrace()
    }
}
