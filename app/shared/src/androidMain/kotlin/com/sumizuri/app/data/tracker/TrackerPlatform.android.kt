package com.sumizuri.app.data.tracker

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.sumizuri.app.AndroidApp
import com.sumizuri.app.core.log.AppLog
import java.util.concurrent.TimeUnit

private const val WorkName = "tracker-sync"

// The system runs planned work at most this often.
private const val ShortestMinutes = 15L

// Plans the sync of the trackers while the app is closed with WorkManager, which keeps to Wi-Fi when the rules ask.
actual object TrackerPlatform {
    actual val canPlan: Boolean = true

    actual fun plan(minutes: Int, inBackground: Boolean, wifiOnly: Boolean) {
        val work = WorkManager.getInstance(AndroidApp.context)
        if (!inBackground || minutes <= 0) {
            work.cancelUniqueWork(WorkName)
            return
        }
        val constraints = Constraints
            .Builder()
            .setRequiredNetworkType(if (wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(true)
            .build()
        val every = minutes.toLong().coerceAtLeast(ShortestMinutes)
        val request = PeriodicWorkRequestBuilder<TrackerSyncWorker>(
            every,
            TimeUnit.MINUTES,
        ).setConstraints(constraints).build()
        work.enqueueUniquePeriodicWork(WorkName, ExistingPeriodicWorkPolicy.UPDATE, request)
        AppLog.info("tracker", "tracker sync while the app is closed every $every minutes")
    }
}

// Syncs the trackers of the open profile while the app is closed, as planned. It is short, so it needs no notice.
class TrackerSyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        AndroidApp
            .profiles()
            .container.value.trackerSync
            .syncAll(auto = true)
        return Result.success()
    }
}
