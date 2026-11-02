package com.sumizuri.app.data.account

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.sumizuri.app.AndroidApp
import com.sumizuri.app.data.sync.canNotify
import com.sumizuri.app.data.sync.noticeIcon
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_notice_channel
import org.jetbrains.compose.resources.getString

// The kind of notice for syncs that did not finish, which the person can turn off on its own in the settings of the system.
private const val ProblemChannel = "sync_problems"
private const val ProblemNotice = 5

// A notice that the sync did not finish, which opens the app on Profile, where the row of Sync says what went wrong.
internal suspend fun showSyncFailure(title: String, text: String) {
    val context = AndroidApp.context
    if (!canNotify(context)) return
    if (Build.VERSION.SDK_INT >= 26) {
        context.getSystemService(NotificationManager::class.java)?.createNotificationChannel(
            NotificationChannel(
                ProblemChannel,
                getString(Res.string.sync_notice_channel),
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
    }
    val notice = NotificationCompat
        .Builder(context, ProblemChannel)
        .setSmallIcon(noticeIcon(context))
        .setContentTitle(title)
        .setContentText(text)
        .setStyle(NotificationCompat.BigTextStyle().bigText(text))
        .setContentIntent(openProfile(context))
        .setAutoCancel(true)
        .build()
    @Suppress("MissingPermission")
    NotificationManagerCompat.from(context).notify(ProblemNotice, notice)
}

internal fun clearSyncFailure() = NotificationManagerCompat.from(AndroidApp.context).cancel(ProblemNotice)

private fun openProfile(context: Context): PendingIntent {
    val intent = (context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()).apply {
        putExtra("tab", "Profile")
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
    return PendingIntent.getActivity(
        context,
        ProblemNotice,
        intent,
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}
