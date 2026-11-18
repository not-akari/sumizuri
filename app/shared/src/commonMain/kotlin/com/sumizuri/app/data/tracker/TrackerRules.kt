package com.sumizuri.app.data.tracker

import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import kotlinx.coroutines.flow.first

// Which side a field keeps when both sides changed it since they last agreed, or which a new link starts from.
enum class Keep(val code: String) {
    Higher("higher"),
    Newer("newer"),
    Tracker("tracker"),
    Here("here"),
    ;

    companion object {
        fun of(code: String?, fallback: Keep): Keep = entries.firstOrNull { it.code == code } ?: fallback

        // The choices each rule offers.
        val ForProgress = listOf(Higher, Tracker, Here)
        val ForOther = listOf(Newer, Tracker, Here)
    }
}

// What happens to a link whose entry was removed on the tracker.
enum class WhenGone(val code: String) {
    Ask("ask"),
    Unlink("unlink"),
    AddBack("addBack"),
    ;

    companion object {
        fun of(code: String?): WhenGone = entries.firstOrNull { it.code == code } ?: Ask
    }
}

// What happens on the trackers to a title taken out of the library: the person is asked, it is kept there, or it is removed there too.
enum class OnRemove(val code: String) {
    Ask("ask"),
    Keep("keep"),
    Remove("remove"),
    ;

    companion object {
        fun of(code: String?): OnRemove = entries.firstOrNull { it.code == code } ?: Ask
    }
}

// The rules of the sync with the trackers, the same for every tracker. The defaults keep the further place and the newer change, and ask before anything is removed.
data class TrackerRules(
    val afterReading: Boolean = true,
    val wifiOnly: Boolean = false,
    val bothProgress: Keep = Keep.Higher,
    val bothOther: Keep = Keep.Newer,
    val readingMoves: Boolean = true,
    val statusFollows: Boolean = true,
    val reread: Boolean = false,
    val onLink: Keep = Keep.Higher,
    val matchList: Boolean = true,
    val addNew: Boolean = true,
    val gone: WhenGone = WhenGone.Ask,
    val onRemove: OnRemove = OnRemove.Ask,
)

suspend fun SettingsRepository.trackerRules(): TrackerRules {
    val base = TrackerRules()
    return TrackerRules(
        afterReading = flag(SettingKey.TrackerAfterReading, base.afterReading).first(),
        wifiOnly = flag(SettingKey.TrackerWifiOnly, base.wifiOnly).first(),
        bothProgress = Keep.of(textNow(SettingKey.TrackerBothProgress), base.bothProgress),
        bothOther = Keep.of(textNow(SettingKey.TrackerBothOther), base.bothOther),
        readingMoves = flag(SettingKey.TrackerReadingMoves, base.readingMoves).first(),
        statusFollows = flag(SettingKey.TrackerStatusFollows, base.statusFollows).first(),
        reread = flag(SettingKey.TrackerReread, base.reread).first(),
        onLink = Keep.of(textNow(SettingKey.TrackerOnLink), base.onLink),
        matchList = flag(SettingKey.TrackerMatchList, base.matchList).first(),
        addNew = flag(SettingKey.TrackerAddNew, base.addNew).first(),
        gone = WhenGone.of(textNow(SettingKey.TrackerGone)),
        onRemove = OnRemove.of(textNow(SettingKey.TrackerOnRemove)),
    )
}
