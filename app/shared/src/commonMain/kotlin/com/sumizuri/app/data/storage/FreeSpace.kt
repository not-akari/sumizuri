package com.sumizuri.app.data.storage

// The room left on the drive that holds the given path, or null when the system does not say.
expect fun freeBytes(path: String): Long?
