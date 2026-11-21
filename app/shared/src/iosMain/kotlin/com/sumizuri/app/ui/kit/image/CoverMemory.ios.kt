package com.sumizuri.app.ui.kit.image

import coil3.PlatformContext
import com.sumizuri.app.core.perf.memoryUse

// An iPhone keeps the share it had, as some still have little memory.
actual fun coverMemoryBaseMb(context: PlatformContext): Int = memoryUse().maxMb
