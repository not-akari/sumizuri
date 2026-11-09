package com.sumizuri.app.data.settings

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.model.player.PlayerPrefs
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private const val Prefix = "player."

// How the player is set, kept as a setting row for each choice. A choice that was never made has its usual value.
class PlayerPrefsRepository(private val db: AppDatabase) {
    val prefs: Flow<PlayerPrefs> = db.settings().observeWithPrefix(Prefix).distinctUntilChanged().map { rows ->
        read(SavedChoices(rows.associate { it.name.removePrefix(Prefix) to it.value }))
    }

    // Applies a change to the choices as they are now, and saves what it made different.
    suspend fun update(change: (PlayerPrefs) -> PlayerPrefs) {
        val before = write(prefs.first())
        val after = write(change(prefs.first()))
        for ((name, value) in after) if (before[name] != value) db.settings().put(SettingEntity(Prefix + name, value))
    }

    private fun read(saved: SavedChoices): PlayerPrefs {
        val usual = PlayerPrefs()
        return PlayerPrefs(
            qualityMode = saved.choice("qualityMode", usual.qualityMode),
            audioPreference = saved.choice("audioPreference", usual.audioPreference),
            preferredQuality = saved["preferredQuality"].orEmpty(),
            speed = saved.fraction("speed", usual.speed, 0.25f..4f),
            subtitleLanguage = saved["subtitleLanguage"].orEmpty(),
            showSubtitles = saved.flag("showSubtitles", usual.showSubtitles),
            subtitleSize = saved.whole("subtitleSize", usual.subtitleSize, 0..2),
            subtitleColor = saved.whole("subtitleColor", usual.subtitleColor, 0..3),
            subtitleBackground = saved.choice("subtitleBackground", usual.subtitleBackground),
            subtitleBold = saved.flag("subtitleBold", usual.subtitleBold),
            subtitleRaise = saved.whole("subtitleRaise", usual.subtitleRaise, 0..2),
            doubleTapSeconds = saved.whole("doubleTapSeconds", usual.doubleTapSeconds, 1..120),
            skipSeconds = saved.whole("skipSeconds", usual.skipSeconds, 1..600),
            hideControlsSeconds = saved.whole("hideControlsSeconds", usual.hideControlsSeconds, 0..30),
            swipeGestures = saved.flag("swipeGestures", usual.swipeGestures),
            doubleTapSeek = saved.flag("doubleTapSeek", usual.doubleTapSeek),
            holdSpeed = saved.fraction("holdSpeed", usual.holdSpeed, 1f..4f),
            showLog = saved.flag("showLog", usual.showLog),
            autoNext = saved.flag("autoNext", usual.autoNext),
            autoNextServer = saved.flag("autoNextServer", usual.autoNextServer),
            watchedAt = saved.whole("watchedAt", usual.watchedAt, 50..100),
            resume = saved.flag("resume", usual.resume),
            aspect = saved.choice("aspect", usual.aspect),
            ambient = saved.flag("ambient", usual.ambient),
        )
    }

    private fun write(p: PlayerPrefs): Map<String, String> = mapOf(
        "qualityMode" to p.qualityMode.name,
        "audioPreference" to p.audioPreference.name,
        "preferredQuality" to p.preferredQuality,
        "speed" to p.speed.toString(),
        "subtitleLanguage" to p.subtitleLanguage,
        "showSubtitles" to p.showSubtitles.toString(),
        "subtitleSize" to p.subtitleSize.toString(),
        "subtitleColor" to p.subtitleColor.toString(),
        "subtitleBackground" to p.subtitleBackground.name,
        "subtitleBold" to p.subtitleBold.toString(),
        "subtitleRaise" to p.subtitleRaise.toString(),
        "doubleTapSeconds" to p.doubleTapSeconds.toString(),
        "skipSeconds" to p.skipSeconds.toString(),
        "hideControlsSeconds" to p.hideControlsSeconds.toString(),
        "swipeGestures" to p.swipeGestures.toString(),
        "doubleTapSeek" to p.doubleTapSeek.toString(),
        "holdSpeed" to p.holdSpeed.toString(),
        "showLog" to p.showLog.toString(),
        "autoNext" to p.autoNext.toString(),
        "autoNextServer" to p.autoNextServer.toString(),
        "watchedAt" to p.watchedAt.toString(),
        "resume" to p.resume.toString(),
        "aspect" to p.aspect.name,
        "ambient" to p.ambient.toString(),
    )
}
