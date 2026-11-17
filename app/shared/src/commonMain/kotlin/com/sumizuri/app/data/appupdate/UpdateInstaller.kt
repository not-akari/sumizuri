package com.sumizuri.app.data.appupdate

import okio.Path

// What each system does with an update: which file of a release fits it, where the file is saved, and how it is installed.
expect object UpdateInstaller {
    // The file of a release for this device, or null when the release has none.
    fun pick(assets: List<ReleaseAsset>): ReleaseAsset?

    fun folder(): Path

    // Opens the installer of the system with the file. On a phone that does not let the app install yet, it opens the setting that allows it.
    suspend fun install(file: String): InstallResult
}
