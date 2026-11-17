package com.sumizuri.app.data.appupdate

import okio.FileSystem
import okio.Path

// An app on an iPhone is updated by the store or by the tool it was installed with, never by the app itself, so no file of a release fits and nothing is installed.
actual object UpdateInstaller {
    actual fun pick(assets: List<ReleaseAsset>): ReleaseAsset? = null

    actual fun folder(): Path = FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-updates"

    actual suspend fun install(file: String): InstallResult = InstallResult.Failed
}
