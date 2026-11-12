package com.sumizuri.app

import android.app.Application
import android.content.pm.ApplicationInfo
import com.sumizuri.app.core.AppBuild
import com.sumizuri.app.core.log.AndroidLogSink
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.CrashReport
import com.sumizuri.app.data.AppContainer
import com.sumizuri.app.data.db.databaseBuilder
import com.sumizuri.app.data.db.legacyDatabaseFile
import com.sumizuri.app.data.profile.ProfileHost
import com.sumizuri.app.data.profile.ProfileRegistry
import com.sumizuri.app.source.browser.page.AndroidRenderPageFactory
import okio.Path.Companion.toPath

// The database lives as long as the process, so a rotation does not open it a second time.
class SumizuriApplication : Application() {
    val profiles by lazy {
        val pages = AndroidRenderPageFactory(this)
        val solver = AndroidChallengeSolver(this)
        val registry = ProfileRegistry(filesDir.absolutePath.toPath(), legacyDatabaseFile(this).toPath())
        ProfileHost(
            registry,
        ) { file -> AppContainer(databaseBuilder(this, file.toString()), pages, solver, file.toString()) }
    }

    override fun onCreate() {
        super.onCreate()
        AppLog.sink = AndroidLogSink()
        CrashReport.install(filesDir.absolutePath.toPath())
        AppBuild.isDebug = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        // The check while the app is closed reaches the profiles through this.
        AndroidApp.context = this
        AndroidApp.profiles = { profiles }
        AppLog.info("app", "android start")
    }
}
