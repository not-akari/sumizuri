package com.sumizuri.app.data.library

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.data.text.statusFromText
import com.sumizuri.app.source.model.SourceEntry
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

// The parts of a title the person can write over by hand. A part written over is not replaced when the source says otherwise.
enum class EditedPart { Name, Author, Summary, Status, Genres }

// What the person wrote for a title.
data class DetailsEdit(
    val name: String,
    val author: String,
    val summary: String,
    val status: Status,
    val genres: List<String>,
)

// What the person changed on a title by hand, its details and its cover, and the source's say over the rest. The marks are kept with the settings, so the title table needs nothing new.
class TitleEdits(private val db: AppDatabase) {
    private fun editedKey(titleId: Long) = "title.edited.$titleId"

    private fun nameKey(titleId: Long) = "title.sourceName.$titleId"

    private fun customCoverKey(titleId: Long) = "cover.custom.$titleId"

    private fun partsOf(value: String?): Set<EditedPart> = value
        .orEmpty()
        .split(',')
        .mapNotNull { name -> EditedPart.entries.firstOrNull { it.name == name } }
        .toSet()

    fun observeEdited(titleId: Long): Flow<Set<EditedPart>> = db.settings().observe(editedKey(titleId)).map(::partsOf)

    fun observeCustomCover(titleId: Long): Flow<Boolean> = db.settings().observe(customCoverKey(titleId)).map {
        it ==
            "true"
    }

    // Saves the details. A part that differs from what is saved now is kept from then on.
    suspend fun save(titleId: Long, edit: DetailsEdit) {
        val now = db.titles().get(titleId) ?: return
        val genres = edit.genres.map(String::trim).filter(String::isNotEmpty)
        val changed = buildSet {
            if (edit.name.trim() != now.name) add(EditedPart.Name)
            if (edit.author.trim() != now.author) add(EditedPart.Author)
            if (edit.summary.trim() != now.summary) add(EditedPart.Summary)
            if (edit.status.code != now.status) add(EditedPart.Status)
            if (genres.joinToString("\n") != now.genres) add(EditedPart.Genres)
        }
        if (changed.isEmpty()) return
        // The name the source gave is kept once, so a reset can put it back. The source never says the name again.
        if (EditedPart.Name in changed && db.settings().get(nameKey(titleId)) == null) {
            db.settings().put(SettingEntity(nameKey(titleId), now.name))
        }
        db.titles().setDetails(
            id = titleId,
            name = edit.name.trim().ifEmpty { now.name },
            author = edit.author.trim(),
            summary = edit.summary.trim(),
            status = edit.status.code,
            genres = genres.joinToString("\n"),
            now = nowMillis(),
        )
        val parts = partsOf(db.settings().get(editedKey(titleId))) + changed
        db.settings().put(SettingEntity(editedKey(titleId), parts.joinToString(",") { it.name }))
    }

    // Gives the source its say again. The name it gave comes back at once, and the rest with the next look at the source.
    suspend fun reset(titleId: Long) {
        db.settings().get(nameKey(titleId))?.let { name ->
            val now = db.titles().get(titleId)
            if (now !=
                null
            ) {
                db.titles().setDetails(titleId, name, now.author, now.summary, now.status, now.genres, nowMillis())
            }
        }
        db.settings().delete(nameKey(titleId))
        db.settings().delete(editedKey(titleId))
    }

    // Makes a picture the cover of a title, and keeps it there when the source says its own cover again.
    suspend fun setCustomCover(titleId: Long, url: String) {
        db.titles().setCover(titleId, url, nowMillis())
        db.settings().put(SettingEntity(customCoverKey(titleId), "true"))
    }

    // Lets the source give the cover again, from the next look at it.
    suspend fun clearCustomCover(titleId: Long) = db.settings().delete(customCoverKey(titleId))

    // Takes in what a source says about a title it already has. A cover the person chose and the parts they wrote are not replaced.
    suspend fun applyDetails(titleId: Long, entry: SourceEntry) {
        val edited = partsOf(db.settings().get(editedKey(titleId)))
        db.titles().updateDetails(
            id = titleId,
            coverUrl = if (db.settings().get(customCoverKey(titleId)) == "true") null else entry.coverUrl,
            status = if (EditedPart.Status in edited) 0 else statusFromText(entry.status).code,
            summary = if (EditedPart.Summary in edited) "" else entry.description.orEmpty(),
            author = if (EditedPart.Author in edited) "" else entry.author.orEmpty(),
            genres = if (EditedPart.Genres in edited) "" else entry.genres.joinToString("\n"),
            rating = entry.rating,
            webUrl = entry.webUrl,
            volumesId = entry.volumesId,
            now = nowMillis(),
        )
    }
}
