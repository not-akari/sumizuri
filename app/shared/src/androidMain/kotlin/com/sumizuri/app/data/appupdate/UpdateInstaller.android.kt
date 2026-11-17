package com.sumizuri.app.data.appupdate

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import com.sumizuri.app.AndroidApp
import okio.Path
import okio.Path.Companion.toOkioPath
import java.io.File

actual object UpdateInstaller {
    // The APK made for the processor of this phone, the one it likes best first, or else the one for every phone, or else any APK, matched by the processor at the end of the name so x86 is not mistaken for x86_64.
    actual fun pick(assets: List<ReleaseAsset>): ReleaseAsset? {
        val apks = assets.filter { it.name.endsWith(".apk", ignoreCase = true) }
        val abis = Build.SUPPORTED_ABIS.orEmpty()
        return abis.firstNotNullOfOrNull { abi ->
            apks.firstOrNull {
                it.name.endsWith(
                    "-$abi.apk",
                    ignoreCase = true,
                )
            }
        }
            ?: apks.firstOrNull { it.name.contains("universal", ignoreCase = true) }
            ?: apks.firstOrNull()
    }

    actual fun folder(): Path = File(AndroidApp.context.cacheDir, "updates").toOkioPath()

    actual suspend fun install(file: String): InstallResult {
        val context = AndroidApp.context
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !context.packageManager.canRequestPackageInstalls()) {
            val allow = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${context.packageName}"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            return runCatching {
                context.startActivity(
                    allow,
                )
            }.fold({ InstallResult.NeedsPermission }, { InstallResult.Failed })
        }
        return runCatching {
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.updates", File(file))
            val intent = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }.fold({ InstallResult.Started }, { InstallResult.Failed })
    }
}
