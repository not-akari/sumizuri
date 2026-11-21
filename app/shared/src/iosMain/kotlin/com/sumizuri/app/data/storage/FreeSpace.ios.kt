package com.sumizuri.app.data.storage

import kotlinx.cinterop.ExperimentalForeignApi
import platform.Foundation.NSFileManager
import platform.Foundation.NSFileSystemFreeSize
import platform.Foundation.NSHomeDirectory
import platform.Foundation.NSNumber

@OptIn(ExperimentalForeignApi::class)
actual fun freeBytes(path: String): Long? = runCatching {
    val place = path.ifBlank { NSHomeDirectory() }
    val facts = NSFileManager.defaultManager.attributesOfFileSystemForPath(place, null)
    (facts?.get(NSFileSystemFreeSize) as? NSNumber)?.longLongValue
}.getOrNull()
