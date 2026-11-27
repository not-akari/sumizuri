package com.sumizuri.app.data.account

import com.sumizuri.app.data.backup.BackupPart
import com.sumizuri.app.data.backup.BackupWriter
import kotlinx.serialization.json.Json
import okio.Buffer
import okio.FileSystem
import okio.Path

private val json = Json { ignoreUnknownKeys = true }

// A profile as a backup, with sources and settings when they sync. Sign ins never go.
internal suspend fun packLibrary(writer: BackupWriter, withSources: Boolean, withSettings: Boolean): String {
    val parts = buildSet {
        if (withSources) addAll(listOf(BackupPart.Sources, BackupPart.SourceSettings))
        if (withSettings) add(BackupPart.Settings)
    }
    return Buffer().also { writer.write(it, parts, { _, _ -> }, { false }) }.readUtf8()
}

// What this device and the server agreed on in the older way of syncing, or nothing when it is not there or cannot be read.
internal fun readOldBase(path: Path): SyncState = runCatching {
    if (!FileSystem.SYSTEM.exists(
            path,
        )
    ) {
        SyncState()
    } else {
        json.decodeFromString(
            SyncState.serializer(),
            FileSystem.SYSTEM.read(path) {
                readUtf8()
            },
        )
    }
}.getOrElse { SyncState() }
