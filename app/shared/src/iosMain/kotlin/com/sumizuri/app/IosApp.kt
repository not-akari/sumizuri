@file:OptIn(ExperimentalForeignApi::class, ExperimentalNativeApi::class)

package com.sumizuri.app

import androidx.compose.ui.window.ComposeUIViewController
import com.sumizuri.app.core.AppBuild
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.log.CrashReport
import com.sumizuri.app.core.log.IosLogSink
import com.sumizuri.app.data.AppContainer
import com.sumizuri.app.data.db.databaseBuilder
import com.sumizuri.app.data.profile.ProfileHost
import com.sumizuri.app.data.profile.ProfileRegistry
import com.sumizuri.app.navigation.AppLinks
import com.sumizuri.app.source.browser.IosChallengeSolver
import com.sumizuri.app.source.browser.page.IosRenderPageFactory
import kotlinx.cinterop.ExperimentalForeignApi
import okio.Path.Companion.toPath
import platform.Foundation.*
import platform.UIKit.*
import platform.UserNotifications.*
import platform.darwin.*
import kotlin.experimental.ExperimentalNativeApi

// The folder the app keeps its libraries, settings and log in, which the person cannot reach from the Files app.
private fun appFolder(): String {
    val url = NSFileManager.defaultManager.URLForDirectory(
        NSApplicationSupportDirectory,
        inDomain = NSUserDomainMask,
        appropriateForURL = null,
        create = true,
        error = null,
    )
    return url?.path ?: error("The folder of the app could not be made")
}

// A notice that comes while the app is open is shown like one that comes while it is closed.
private class NoticeShower :
    NSObject(),
    UNUserNotificationCenterDelegateProtocol {
    override fun userNotificationCenter(
        center: UNUserNotificationCenter,
        willPresentNotification: UNNotification,
        withCompletionHandler: (UNNotificationPresentationOptions) -> Unit,
    ) {
        withCompletionHandler(UNNotificationPresentationOptionBanner or UNNotificationPresentationOptionSound)
    }
}

// What the screen of the iPhone needs from the app: the libraries, which live as long as the process, and the start of the things that run without a screen. The project in iosApp calls these.
object IosApp {
    val profiles: ProfileHost by lazy {
        val folder = appFolder()
        val pages = IosRenderPageFactory()
        val solver = IosChallengeSolver()
        val registry = ProfileRegistry(folder.toPath(), "$folder/sumizuri.db".toPath())
        ProfileHost(registry) { file -> AppContainer(databaseBuilder(file.toString()), pages, solver, file.toString()) }
    }

    private val shower = NoticeShower()
    private var started = false

    // Sets up the log, the build kind and the lock that counts the time the app is away. It is safe to call again.
    fun start() {
        if (started) return
        started = true
        AppLog.sink = IosLogSink()
        CrashReport.install(appFolder().toPath())
        AppBuild.isDebug = Platform.isDebugBinary
        UNUserNotificationCenter.currentNotificationCenter().delegate = shower
        val center = NSNotificationCenter.defaultCenter
        center.addObserverForName(
            UIApplicationDidEnterBackgroundNotification,
            `object` = null,
            queue = NSOperationQueue.mainQueue,
        ) {
            profiles.container.value.lock
                .onAway()
        }
        center.addObserverForName(
            UIApplicationWillEnterForegroundNotification,
            `object` = null,
            queue = NSOperationQueue.mainQueue,
        ) {
            profiles.container.value.lock
                .onBack()
        }
        AppLog.info("app", "ios start")
    }

    // A link of the app the system opened, such as from a button on a site.
    fun open(link: String) {
        AppLinks.open(link)
    }
}

// The screen the project in iosApp shows.
fun MainViewController(): UIViewController {
    IosApp.start()
    return ComposeUIViewController { App(IosApp.profiles) }
}
