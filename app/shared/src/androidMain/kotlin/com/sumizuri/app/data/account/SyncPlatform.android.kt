package com.sumizuri.app.data.account

import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ForegroundInfo
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.sumizuri.app.AndroidApp
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.sync.CheckingChannel
import com.sumizuri.app.data.sync.makeChannels
import com.sumizuri.app.data.sync.noticeIcon
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.busy_progress
import com.sumizuri.app.shared.resources.busy_sync
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.getString
import java.util.concurrent.TimeUnit

private const val WorkName = "library-sync"

// The system runs planned work at most this often.
private const val ShortestMinutes = 15L

// A sync running this long shows its notice, which then shows how far it got this often.
private const val NoticeAfterMs = 3_000L
private const val ProgressEveryMs = 2_000L
private const val SyncingNotice = 4

// Plans the sync while the app is closed with WorkManager, which keeps to Wi-Fi or charging when asked.
actual object SyncPlatform {
    actual fun plan(plan: SyncPlan) {
        val work = WorkManager.getInstance(AndroidApp.context)
        if (!plan.inBackground || plan.minutes <= 0) {
            work.cancelUniqueWork(WorkName)
            return
        }
        val constraints = Constraints
            .Builder()
            .setRequiredNetworkType(if (plan.wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED)
            .setRequiresCharging(plan.charging)
            .setRequiresBatteryNotLow(true)
            .build()
        val minutes = plan.minutes.toLong().coerceAtLeast(ShortestMinutes)
        val request = PeriodicWorkRequestBuilder<LibrarySyncWorker>(
            minutes,
            TimeUnit.MINUTES,
        ).setConstraints(constraints).build()
        work.enqueueUniquePeriodicWork(WorkName, ExistingPeriodicWorkPolicy.UPDATE, request)
        AppLog.info("sync", "sync while the app is closed every $minutes minutes")
    }

    actual suspend fun showFailure(title: String, text: String) = showSyncFailure(title, text)

    actual fun clearFailure() = clearSyncFailure()
}

// Syncs the open profile while the app is closed, as planned. A sync that goes on, such as a first one of a big library, shows a quiet notice with how far it got, which Android needs to let long work finish.
class LibrarySyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val syncer = AndroidApp
            .profiles()
            .container.value.librarySync
        coroutineScope {
            val shown = launch {
                delay(NoticeAfterMs)
                makeChannels(applicationContext)
                while (true) {
                    showSyncing(syncer.progress.value)
                    delay(ProgressEveryMs)
                }
            }
            try {
                syncer.syncAuto()
            } finally {
                shown.cancel()
            }
        }
        return Result.success()
    }

    private suspend fun showSyncing(progress: SyncProgress?) {
        val notice = NotificationCompat
            .Builder(applicationContext, CheckingChannel)
            .setSmallIcon(noticeIcon(applicationContext))
            .setContentTitle(
                if (progress != null &&
                    progress.total > 0
                ) {
                    getString(Res.string.busy_sync) + " · " +
                        getString(Res.string.busy_progress, progress.done, progress.total)
                } else {
                    getString(Res.string.busy_sync)
                },
            ).apply {
                if (progress != null && progress.total > 0) {
                    setProgress(progress.total, progress.done.coerceAtMost(progress.total), false)
                } else {
                    setProgress(0, 0, true)
                }
            }.setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .build()
        val info = if (Build.VERSION.SDK_INT >=
            29
        ) {
            ForegroundInfo(SyncingNotice, notice, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(SyncingNotice, notice)
        }
        try {
            setForeground(info)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Throwable) {
            AppLog.debug("sync", "the sync runs without its notice, ${error.message}")
        }
    }
}
