package com.sumizuri.app

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.withContext
import java.io.File

private const val FileName = "start-color.txt"

// How long the background has to stay the same before it is written, so a fade between themes writes once.
private const val KeepAfterMs = 1500L

// The background of the theme kept in a small file of the data folder, so the next start paints it before anything is read.
internal object StartColor {
    fun load(folder: File) {
        AppStart.remembered = runCatching {
            File(folder, FileName)
                .readText()
                .trim()
                .toLong(16)
                .toInt()
        }.getOrNull()
    }

    suspend fun keep(folder: File) {
        var written = AppStart.remembered
        AppStart.background.filterNotNull().collectLatest { argb ->
            delay(KeepAfterMs)
            if (argb == written) return@collectLatest
            withContext(Dispatchers.IO) { runCatching { File(folder, FileName).writeText(Integer.toHexString(argb)) } }
            written = argb
        }
    }
}
