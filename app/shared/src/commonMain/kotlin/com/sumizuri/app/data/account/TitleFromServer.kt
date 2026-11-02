package com.sumizuri.app.data.account

import com.sumizuri.app.data.backup.BackupRestorer
import com.sumizuri.app.data.backup.ImportedTitle
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.text.nowMillis

// Puts a title of the server's copy into the library of this device: a title this device knows only outside the library joins it, and one it does not know is made from the copy. The sync that follows brings its read marks.
class TitleFromServer(
    private val db: AppDatabase,
    private val restorer: BackupRestorer,
    private val syncer: LibrarySyncer,
) {
    suspend fun bring(title: ImportedTitle): Boolean {
        val sourceId = title.sourceId ?: return false
        val known = db.titles().findId(sourceId, title.url)
        if (known != null) {
            db.titles().setInLibrary(known, true, nowMillis())
        } else {
            restorer.insert(title.copy(inLibrary = true), sourceId)
        }
        syncer.syncSoon()
        return true
    }
}
