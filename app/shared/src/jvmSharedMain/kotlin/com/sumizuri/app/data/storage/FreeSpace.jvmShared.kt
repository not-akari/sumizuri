package com.sumizuri.app.data.storage

import java.io.File

// A path that is not made yet is measured by the nearest folder above it that is.
actual fun freeBytes(path: String): Long? = runCatching {
    generateSequence(File(path)) { it.parentFile }.firstOrNull { it.exists() }?.usableSpace
}.getOrNull()?.takeIf { it > 0 }
