package com.sumizuri.app.data.settings

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.model.reader.ReaderBackground
import com.sumizuri.app.data.model.reader.ReaderDual
import com.sumizuri.app.data.model.reader.ReaderFont
import com.sumizuri.app.data.model.reader.ReaderGap
import com.sumizuri.app.data.model.reader.ReaderLookup
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.data.model.reader.ReaderOrientation
import com.sumizuri.app.data.model.reader.ReaderPageTurn
import com.sumizuri.app.data.model.reader.ReaderProgressBar
import com.sumizuri.app.data.model.reader.ReaderQuality
import com.sumizuri.app.data.model.reader.ReaderScale
import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.data.model.reader.ReaderTextAlign
import com.sumizuri.app.data.model.reader.ReaderWidth
import com.sumizuri.app.data.model.reader.ReaderZoomStart
import com.sumizuri.app.data.text.enumNamed
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private const val Prefix = "reader."

// Marks a check that looked at several pages.
private const val CheckedVersion = "pages"

// The choices of the reader. Each is kept for every title, or for one title when that title has its own set.
class ReaderSettingsRepository(private val db: AppDatabase) {
    fun observe(titleId: Long): Flow<ReaderSettings> = db.settings().observeWithPrefix(Prefix).map { rows ->
        resolve(
            rows.associate {
                it.name to
                    it.value
            },
            titleId,
        )
    }

    // The mode picked or found for one title, or null when there is none yet.
    suspend fun titleMode(titleId: Long): ReaderMode? =
        db.settings().get(titleKey(titleId, "mode"))?.let { saved -> enumNamed<ReaderMode>(saved) }

    suspend fun setTitleMode(titleId: Long, mode: ReaderMode) = put(titleKey(titleId, "mode"), mode.name)

    // Whether the shape of the pages was already looked at for this title. An older check that only looked at the first page, saved as true, does not count.
    suspend fun modeChecked(titleId: Long): Boolean = db.settings().get(titleKey(titleId, "checked")) == CheckedVersion

    suspend fun setModeChecked(titleId: Long) = put(titleKey(titleId, "checked"), CheckedVersion)

    suspend fun setDefaultMode(mode: ReaderMode) = put("${Prefix}mode", mode.name)

    // Gives a title the choices another title kept for itself, its mode and its own set, for a title that moved. The choices it has already stay. With forget, the other title loses its own, as when it is removed.
    suspend fun carryOver(from: Long, to: Long, forget: Boolean) {
        val source = titleKey(from, "")
        val target = titleKey(to, "")
        val own = db
            .settings()
            .withPrefix(target)
            .map { it.name }
            .toSet()
        for (row in db.settings().withPrefix(source)) {
            val name = target + row.name.removePrefix(source)
            if (name !in own) put(name, row.value)
            if (forget) db.settings().delete(row.name)
        }
    }

    // Writes the choices where the scope says, for this title or for all of them.
    suspend fun save(titleId: Long, settings: ReaderSettings) {
        if (settings.override) {
            put(
                titleKey(titleId, "override"),
                "true",
            )
        } else {
            db.settings().delete(titleKey(titleId, "override"))
        }
        val scope = if (settings.override) "${Prefix}title.$titleId." else Prefix
        put(scope + "scale", settings.scale.name)
        put(scope + "background", settings.background.name)
        put(scope + "gap", settings.gap.name)
        put(scope + "width", settings.width.name)
        put(scope + "customWidth", settings.customWidth.toString())
        put(scope + "dual", settings.dual.name)
        put(scope + "invert", settings.invertTaps.toString())
        put(scope + "font", settings.font.name)
        put(scope + "fontSize", settings.fontSize.toString())
        put(scope + "lineHeight", settings.lineHeight.toString())
        put(scope + "paragraphGap", settings.paragraphGap.toString())
        put(scope + "textAlign", settings.textAlign.name)
        put(scope + "orientation", settings.orientation.name)
        put(scope + "zoomStart", settings.zoomStart.name)
    }

    // Writes the choices that are always for every title.
    suspend fun saveGlobal(settings: ReaderSettings) {
        put("${Prefix}dim", settings.dim.toString())
        put("${Prefix}warmth", settings.warmth.toString())
        put("${Prefix}autoSpeed", settings.autoSpeed.toString())
        put("${Prefix}readingWpm", settings.readingWpm.toString())
        put("${Prefix}quality", settings.quality.name)
        put("${Prefix}progressBar", settings.progressBar.name)
        put("${Prefix}pageNumber", settings.pageNumber.toString())
        put("${Prefix}controlShade", settings.controlShade.toString())
        put("${Prefix}pageStrip", settings.pageStrip.toString())
        put("${Prefix}lookup", settings.lookup.name)
        put("${Prefix}inlineNext", settings.inlineNext.toString())
        put("${Prefix}incognito", settings.incognito.toString())
        put("${Prefix}keepScreenOn", settings.keepScreenOn.toString())
        put("${Prefix}hideSystemBars", settings.hideSystemBars.toString())
        put("${Prefix}animatePages", settings.animatePages.toString())
        put("${Prefix}pageTurn", settings.pageTurn.name)
        put("${Prefix}panelZoom", settings.panelZoom.toString())
        put("${Prefix}cropBorders", settings.cropBorders.toString())
        put("${Prefix}grayscale", settings.grayscale.toString())
        put("${Prefix}invertColors", settings.invertColors.toString())
        put("${Prefix}sepia", settings.sepia.toString())
        put("${Prefix}contrast", settings.contrast.toString())
        put("${Prefix}bedtime", settings.bedtime.toString())
        put("${Prefix}bedtimeFrom", settings.bedtimeFrom.toString())
        put("${Prefix}bedtimeTo", settings.bedtimeTo.toString())
        put("${Prefix}bedtimeWarmth", settings.bedtimeWarmth.toString())
        put("${Prefix}bedtimeDim", settings.bedtimeDim.toString())
    }

    private fun resolve(rows: Map<String, String>, titleId: Long): ReaderSettings {
        val own = rows[titleKey(titleId, "override")] == "true"
        fun read(field: String): String? =
            (if (own) rows["${Prefix}title.$titleId.$field"] else null) ?: rows[Prefix + field]
        val usual = ReaderSettings()
        return ReaderSettings(
            mode = enumNamed<ReaderMode>(rows["${Prefix}mode"]) ?: usual.mode,
            titleMode = enumNamed<ReaderMode>(rows[titleKey(titleId, "mode")]),
            scale = enumNamed<ReaderScale>(read("scale")) ?: usual.scale,
            background = enumNamed<ReaderBackground>(read("background")) ?: usual.background,
            gap = enumNamed<ReaderGap>(read("gap")) ?: usual.gap,
            width = enumNamed<ReaderWidth>(read("width")) ?: usual.width,
            customWidth =
            read("customWidth")?.toIntOrNull()?.coerceIn(ReaderWidth.CustomLeast, ReaderWidth.CustomMost)
                ?: usual.customWidth,
            dual = enumNamed<ReaderDual>(read("dual")) ?: usual.dual,
            invertTaps = read("invert") == "true",
            font = enumNamed<ReaderFont>(read("font")) ?: usual.font,
            fontSize = read("fontSize")?.toIntOrNull()?.coerceIn(12, 40) ?: usual.fontSize,
            lineHeight = read("lineHeight")?.toFloatOrNull()?.coerceIn(1f, 3f) ?: usual.lineHeight,
            paragraphGap = read("paragraphGap")?.toIntOrNull()?.coerceIn(0, 40) ?: usual.paragraphGap,
            textAlign = enumNamed<ReaderTextAlign>(read("textAlign")) ?: usual.textAlign,
            override = own,
            dim = rows["${Prefix}dim"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: 0f,
            warmth = rows["${Prefix}warmth"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: 0f,
            autoSpeed = rows["${Prefix}autoSpeed"]?.toIntOrNull()?.coerceIn(20, 600) ?: usual.autoSpeed,
            readingWpm = rows["${Prefix}readingWpm"]?.toIntOrNull()?.coerceIn(80, 600) ?: usual.readingWpm,
            quality = enumNamed<ReaderQuality>(rows["${Prefix}quality"]) ?: usual.quality,
            progressBar = enumNamed<ReaderProgressBar>(rows["${Prefix}progressBar"]) ?: usual.progressBar,
            pageNumber = rows["${Prefix}pageNumber"] != "false",
            controlShade = rows["${Prefix}controlShade"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: usual.controlShade,
            pageStrip = rows["${Prefix}pageStrip"] == "true",
            lookup = enumNamed<ReaderLookup>(rows["${Prefix}lookup"]) ?: usual.lookup,
            inlineNext = rows["${Prefix}inlineNext"] != "false",
            incognito = rows["${Prefix}incognito"] == "true",
            keepScreenOn = rows["${Prefix}keepScreenOn"] != "false",
            hideSystemBars = rows["${Prefix}hideSystemBars"] != "false",
            orientation = enumNamed<ReaderOrientation>(read("orientation")) ?: usual.orientation,
            zoomStart = enumNamed<ReaderZoomStart>(read("zoomStart")) ?: usual.zoomStart,
            animatePages = rows["${Prefix}animatePages"] != "false",
            pageTurn = enumNamed<ReaderPageTurn>(read("pageTurn")) ?: usual.pageTurn,
            panelZoom = rows["${Prefix}panelZoom"] == "true",
            cropBorders = rows["${Prefix}cropBorders"] == "true",
            grayscale = rows["${Prefix}grayscale"] == "true",
            invertColors = rows["${Prefix}invertColors"] == "true",
            sepia = rows["${Prefix}sepia"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: usual.sepia,
            contrast = rows["${Prefix}contrast"]?.toFloatOrNull()?.coerceIn(0.5f, 2f) ?: usual.contrast,
            bedtime = rows["${Prefix}bedtime"] == "true",
            bedtimeFrom = rows["${Prefix}bedtimeFrom"]?.toIntOrNull()?.coerceIn(0, 23) ?: usual.bedtimeFrom,
            bedtimeTo = rows["${Prefix}bedtimeTo"]?.toIntOrNull()?.coerceIn(0, 23) ?: usual.bedtimeTo,
            bedtimeWarmth = rows["${Prefix}bedtimeWarmth"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: usual.bedtimeWarmth,
            bedtimeDim = rows["${Prefix}bedtimeDim"]?.toFloatOrNull()?.coerceIn(0f, 1f) ?: usual.bedtimeDim,
        )
    }

    private fun titleKey(titleId: Long, field: String) = "${Prefix}title.$titleId.$field"

    private suspend fun put(name: String, value: String) = db.settings().put(SettingEntity(name, value))
}
