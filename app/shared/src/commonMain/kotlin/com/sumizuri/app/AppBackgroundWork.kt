package com.sumizuri.app

import androidx.compose.foundation.background
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import coil3.ImageLoader
import com.sumizuri.app.core.perf.FrameActivity
import com.sumizuri.app.core.perf.Perf
import com.sumizuri.app.core.perf.PerfWatch
import com.sumizuri.app.core.perf.StartMark
import com.sumizuri.app.data.AppContainer
import com.sumizuri.app.data.account.SyncPlan
import com.sumizuri.app.data.account.SyncPlatform
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.sync.UpdatePlan
import com.sumizuri.app.data.sync.UpdatePlatform
import com.sumizuri.app.data.sync.rememberNoticePermission
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.sync.account.DefaultSyncMinutes
import com.sumizuri.app.ui.kit.cover.CoverMemo
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first

// How often the app looks whether the library is due for a check for new chapters while it stays open.
private const val DueLookEveryMs = 10 * 60 * 1000L

// How often the open app asks the sync server whether another device sent a newer copy.
private const val ChangeLookEveryMs = 60_000L

// The checks that use the network wait this long after the app opens, so the first screen and its covers load first.
internal const val StartQuietMs = 10_000L

// How long the app must be left alone before a check starts, how often that is looked at, and the longest a check waits for it.
private const val QuietForMs = 2_000L
private const val QuietLookMs = 500L
private const val QuietMostMs = 60_000L

// How far apart the checks that start with the app begin.
private const val StaggerMs = 5_000L

// Waits until the app has been left alone for a moment, so a check that uses the network and the processor never starts while the person scrolls or opens pages. It waits a minute at most, so a busy person still gets the checks.
private suspend fun awaitQuiet() {
    val until = nowMillis() + QuietMostMs
    while (nowMillis() < until && nowMillis() - FrameActivity.last.value < QuietForMs) delay(QuietLookMs)
}

// What the app does on its own while it is open: the checks for new chapters and new versions of sources, the plan of the check while it is closed, the question about notices, and the watch over its speed.
@Composable
internal fun AppBackgroundWork(container: AppContainer, loader: ImageLoader) {
    // Looks for new chapters of the titles in the library when the app opens. Where nothing else tells about them, the app shows the notice itself.
    LaunchedEffect(container) {
        delay(StartQuietMs)
        while (true) {
            awaitQuiet()
            val ran = container.sync.refreshLibraryIfDue()
            if (ran && UpdatePlatform.noticeFromApp &&
                container.settings.flag(SettingKey.UpdateNotify, true).first()
            ) {
                UpdatePlatform.showNews(container.sync.lastNews())
            }
            delay(DueLookEveryMs)
        }
    }
    // Makes the backup the app makes by itself when it is due, a little after the library check so the two do not start together.
    LaunchedEffect(container) {
        delay(StartQuietMs * 3)
        container.autoBackups.refresh()
        while (true) {
            container.autoBackups.runIfDue()
            delay(DueLookEveryMs)
        }
    }
    // Keeps this profile in step with its sync server: once after the app opens when asked, then as often as chosen while the app stays open.
    LaunchedEffect(container) {
        val settings = container.settings
        // A little after the library check, so the two do not start together.
        delay(StartQuietMs + StaggerMs)
        awaitQuiet()
        if (settings.flag(SettingKey.SyncOnOpen, true).first()) container.librarySync.syncAuto()
        while (true) {
            val minutes = settings.number(SettingKey.SyncEveryMinutes, DefaultSyncMinutes).first()
            delay(if (minutes > 0) minutes * 60_000L else DueLookEveryMs)
            if (minutes > 0) container.librarySync.syncAuto()
        }
    }
    // While the app is open it looks every minute whether another device synced, and if so syncs, so changes arrive quickly without a whole sync each time.
    LaunchedEffect(container) {
        delay(StartQuietMs)
        while (true) {
            delay(ChangeLookEveryMs)
            if (container.settings.number(SettingKey.SyncEveryMinutes, DefaultSyncMinutes).first() >
                0
            ) {
                container.librarySync.checkForChanges()
            }
        }
    }
    // And the sync while the app is closed is planned again whenever one of its settings changes.
    LaunchedEffect(container) {
        val settings = container.settings
        combine(
            settings.number(SettingKey.SyncEveryMinutes, DefaultSyncMinutes),
            settings.flag(SettingKey.SyncBackground, true),
            settings.flag(SettingKey.SyncWifiOnly, false),
            settings.flag(SettingKey.SyncCharging, false),
        ) { minutes, background, wifi, charging -> SyncPlan(minutes, background, wifi, charging) }
            .distinctUntilChanged()
            .collect { SyncPlatform.plan(it) }
    }
    // The check while the app is closed is planned again whenever one of its settings changes.
    LaunchedEffect(container) {
        val settings = container.settings
        combine(
            settings.number(SettingKey.UpdateHours, SettingKey.DefaultUpdateHours),
            settings.flag(SettingKey.UpdateInBackground, true),
            settings.flag(SettingKey.UpdateWifiOnly, false),
            settings.flag(SettingKey.UpdateCharging, false),
        ) { hours, background, wifi, charging -> UpdatePlan(hours, background, wifi, charging) }
            .distinctUntilChanged()
            .collect { UpdatePlatform.plan(it) }
    }
    // Notices need a yes from the person on newer phones, asked once while notices are on, after the first steps, which ask it themselves.
    val askNotices = rememberNoticePermission()
    LaunchedEffect(container) {
        val settings = container.settings
        if (settings.flag(SettingKey.OnboardingDone, false).first() &&
            settings.flag(SettingKey.UpdateNotify, true).first() &&
            !settings.flag(SettingKey.NoticeAsked, false).first()
        ) {
            settings.setFlag(SettingKey.NoticeAsked, true)
            askNotices()
        }
    }
    // And for newer versions of the sources that are installed, which the repos they came from may have. It is looked at as often as the check of the library, so a check that could not reach a repo is tried again.
    LaunchedEffect(container) {
        delay(StartQuietMs + StaggerMs * 2)
        while (true) {
            awaitQuiet()
            container.updates.checkIfDue()
            delay(DueLookEveryMs)
        }
    }

    // The watch over freezes, the processor and the memory runs as long as the app does, and says what the app was doing when it warns. What was learned about covers is kept in the settings of the profile, so a cover is only looked at once.
    LaunchedEffect(container) {
        CoverMemo.read = { key -> container.settings.textNow("memo.$key") }
        CoverMemo.write = { key, value -> container.settings.setText("memo.$key", value) }
        CoverMemo.preload(container.settings.withPrefix("memo.").mapKeys { it.key.removePrefix("memo.") })
    }
    LaunchedEffect(container, loader) {
        PerfWatch.activity = {
            listOfNotNull(
                container.sync.progress.value
                    ?.let { "checking for new chapters ${it.done} of ${it.total}" },
                loader.memoryCache?.let {
                    "images ${it.size / (1024 * 1024)} of ${it.maxSize / (1024 * 1024)} MB in memory"
                },
            )
        }
    }
    // Only while the app is on screen, so it does not wake a phone that has the app in the background.
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(lifecycle) { lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) { PerfWatch.run() } }
    LaunchedEffect(Unit) {
        withFrameNanos { }
        Perf.mark(StartMark.FirstFrame)
    }
}
