package com.sumizuri.app.ui.kit.image

import coil3.PlatformContext
import com.sumizuri.app.core.perf.memoryUse

// A computer keeps covers in the heap, so the share is of the heap.
actual fun coverMemoryBaseMb(context: PlatformContext): Int = memoryUse().maxMb
