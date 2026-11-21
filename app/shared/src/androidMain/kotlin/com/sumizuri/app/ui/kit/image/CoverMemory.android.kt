package com.sumizuri.app.ui.kit.image

import android.app.ActivityManager
import android.content.Context
import coil3.PlatformContext
import com.sumizuri.app.core.perf.memoryUse

// Covers on Android are kept on the graphics side, outside the heap of the app, so a phone with enough memory takes the share of all its memory. A phone the system calls low on memory keeps the share of the heap, as before.
actual fun coverMemoryBaseMb(context: PlatformContext): Int {
    val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return memoryUse().maxMb
    if (manager.isLowRamDevice) return memoryUse().maxMb
    val info = ActivityManager.MemoryInfo().also { manager.getMemoryInfo(it) }
    return maxOf(memoryUse().maxMb, (info.totalMem / (1024 * 1024)).toInt())
}
