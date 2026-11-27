package com.sumizuri.app.data.account

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.backup.AutoBackups
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

// A sync that would take a lot away from this device, waiting for the person: how many titles would leave the library out of how many, how many read chapters would turn unread, and the names of the first titles.
data class BigChange(val removed: Int, val library: Int, val unread: Int, val names: List<String>)

// What the person chose for a big change: keep what this device has, or let the change through after a backup.
enum class BigChoice { KeepMine, Allow }

// The code of the problem a sync ends with while it waits for the person.
const val BigChangeCode = "big_change"

// How many names a big change shows.
private const val NamesShown = 8

// Whether a merge takes so much from this device that it should wait: many titles out of the library, or many read chapters turned unread. A small library or a few marks never wait.
fun bigChangeOf(local: SyncState, merged: SyncState, names: Map<String, String>): BigChange? {
    val gone = local.titles.filter { (key, title) -> title.inLibrary && merged.titles[key]?.inLibrary != true }.keys
    val library = local.titles.count { it.value.inLibrary }
    var read = 0
    var unread = 0
    for ((key, title) in local.titles) {
        val after = merged.titles[key]?.chapters.orEmpty()
        for ((chapter, mark) in title.chapters) {
            if (!mark.read) continue
            read++
            if (after[chapter]?.read != true) unread++
        }
    }
    val manyGone = gone.size >= 100 || (gone.size >= 10 && gone.size * 4 >= library)
    val manyUnread = unread >= 500 || (unread >= 100 && unread * 4 >= read)
    if (!manyGone && !manyUnread) return null
    return BigChange(gone.size, library, unread, gone.take(NamesShown).map { names[it] ?: it.substringAfter("\n") })
}

// The merge with this device winning for what a big change would take: its titles stay in the library and its read chapters stay read. The next send then puts them back on the server too.
fun keepMine(local: SyncState, merged: SyncState): SyncState {
    val kept = local.titles.mapNotNull { (key, mine) ->
        val now = merged.titles[key] ?: TitleMark()
        val inLibrary = now.inLibrary || mine.inLibrary
        val chapters =
            now.chapters + mine.chapters.filter { (chapter, mark) -> mark.read && now.chapters[chapter]?.read != true }
        if (inLibrary == now.inLibrary &&
            chapters == now.chapters
        ) {
            null
        } else {
            key to now.copy(inLibrary = inLibrary, chapters = chapters)
        }
    }
    return merged.copy(titles = merged.titles + kept)
}

// Stops a merge that takes a lot from this device until the person chooses: keep what this device has, or let it through after a backup made first.
class BigChangeGuard(private val backups: AutoBackups?) {
    private val mutable = MutableStateFlow<BigChange?>(null)
    val waiting: StateFlow<BigChange?> = mutable

    suspend fun check(local: SyncState, merged: SyncState, names: Map<String, String>, choice: BigChoice?): SyncState {
        val big = bigChangeOf(local, merged, names)
        if (big == null) {
            mutable.value = null
            return merged
        }
        AppLog.warn(
            "sync",
            "the merge would take ${big.removed} of ${big.library} titles out and mark ${big.unread} chapters unread, choice ${choice?.name ?: "none yet"}",
        )
        return when (choice) {
            null -> {
                mutable.value = big
                throw SyncProblem(
                    BigChangeCode,
                    "This sync would take ${big.removed} titles out of this device and mark ${big.unread} chapters unread, so it waits for you.",
                )
            }

            BigChoice.KeepMine -> keepMine(local, merged).also { mutable.value = null }

            BigChoice.Allow -> {
                val saved = backups?.makeNow()
                    ?: throw SyncProblem(
                        BigChangeCode,
                        "The backup before the change could not be made, so nothing was changed.",
                    )
                AppLog.info("sync", "made the backup ${saved.name} before the big change")
                mutable.value = null
                merged
            }
        }
    }
}
