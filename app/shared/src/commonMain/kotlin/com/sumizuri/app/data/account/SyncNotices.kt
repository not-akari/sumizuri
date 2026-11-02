package com.sumizuri.app.data.account

import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.sync_notice_offline
import com.sumizuri.app.shared.resources.sync_state_failed
import org.jetbrains.compose.resources.getString

// The problem the person was last told about, kept on this device only, so the same problem is told once.
private const val ToldKey = "sync.noticeTold"

// A device that is only offline is told after this long without a sync that worked, as being away from the internet for a while is normal.
private const val OfflineQuietMs = 24L * 60 * 60 * 1000

// Tells the person when a sync the app started by itself did not finish and needs them, once for each problem, and takes the notice away when a sync works again.
internal object SyncNotices {
    suspend fun failed(settings: SettingsRepository, problem: SyncProblem) {
        val lastGood = settings.textNow(LibrarySyncer.LastAtKey)?.toLongOrNull()
        val offline = problem.code == SyncProblem.Unreachable
        if (offline && lastGood != null && nowMillis() - lastGood < OfflineQuietMs) return
        if (settings.textNow(ToldKey) == problem.code) return
        settings.setText(ToldKey, problem.code)
        val text = if (offline) getString(Res.string.sync_notice_offline) else problem.message.orEmpty()
        SyncPlatform.showFailure(getString(Res.string.sync_state_failed), text)
    }

    suspend fun worked(settings: SettingsRepository) {
        if (settings.textNow(ToldKey).isNullOrEmpty()) return
        settings.setText(ToldKey, "")
        SyncPlatform.clearFailure()
    }
}
