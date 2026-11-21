package com.sumizuri.app.ui.kit.image

import coil3.PlatformContext

// The memory, in megabytes, that the share of the cover cache is taken from. Where covers are kept on the graphics side and not in the heap of the app, this is more than the heap.
expect fun coverMemoryBaseMb(context: PlatformContext): Int
